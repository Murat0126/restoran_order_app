import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class OrdersRepository {
  OrdersRepository(this._db);

  final Database _db;

  Order? byId(String id) {
    final r = _db.select('SELECT * FROM orders WHERE id = ?', [id]);
    if (r.isEmpty) return null;
    return _hydrate(r.first);
  }

  List<Order> activeOrders() {
    final rows = _db.select('''
      SELECT * FROM orders
      WHERE status NOT IN ('paid', 'cancelled')
      ORDER BY created_at DESC
    ''');
    return rows.map(_hydrate).toList(growable: false);
  }

  /// Активные заказы текущего официанта (для «Мои заказы»).
  List<Order> activeOrdersForWaiter(String waiterId) {
    final rows = _db.select(
      '''
      SELECT * FROM orders
      WHERE waiter_id = ?
        AND status NOT IN ('paid', 'cancelled')
      ORDER BY created_at DESC
      ''',
      [waiterId],
    );
    return rows.map(_hydrate).toList(growable: false);
  }

  List<Order> openOrCurrentForTable(String tableId) {
    final rows = _db.select(
      '''SELECT * FROM orders
         WHERE table_id = ? AND status NOT IN ('paid', 'cancelled')
         ORDER BY created_at DESC''',
      [tableId],
    );
    return rows.map(_hydrate).toList(growable: false);
  }

  Order create({
    required String tableId,
    String? waiterId,
    OrderSource source = OrderSource.waiter,
    int? guestsCount,
    String note = '',
    List<OrderItem> initialItems = const [],
  }) {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc();
    _db.execute(
      '''INSERT INTO orders
        (id, table_id, waiter_id, status, source, note, guests_count, created_at)
        VALUES (?, ?, ?, 'open', ?, ?, ?, ?)''',
      [
        id,
        tableId,
        waiterId,
        source.name,
        note,
        guestsCount,
        createdAt.toIso8601String(),
      ],
    );
    for (final item in initialItems) {
      _insertItem(id, item);
    }
    return byId(id)!;
  }

  Order addItem(String orderId, OrderItem item) {
    _insertItem(orderId, item);
    return byId(orderId)!;
  }

  /// Удаляет позицию в статусе [OrderItemStatus.draft]. Иначе `null`.
  Order? removeDraftItem(String orderId, String itemId) {
    final order = byId(orderId);
    if (order == null) return null;
    final item = order.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null || item.status != OrderItemStatus.draft) return null;
    _db.execute(
      'DELETE FROM order_items WHERE id = ? AND order_id = ? AND status = ?',
      [itemId, orderId, OrderItemStatus.draft.name],
    );
    return byId(orderId);
  }

  /// Обновляет число гостей (только пока заказ open/sent).
  Order? updateGuests(String orderId, int guestsCount) {
    final order = byId(orderId);
    if (order == null) return null;
    if (order.status != OrderStatus.open && order.status != OrderStatus.sent) {
      return null;
    }
    _db.execute(
      'UPDATE orders SET guests_count = ? WHERE id = ?',
      [guestsCount, orderId],
    );
    return byId(orderId);
  }

  /// Привязывает официанта к заказу, если ещё не назначен (QR-предзаказ).
  Order? assignWaiterIfEmpty(String orderId, String waiterId) {
    final order = byId(orderId);
    if (order == null || order.waiterId != null) return order;
    _db.execute(
      'UPDATE orders SET waiter_id = ? WHERE id = ?',
      [waiterId, orderId],
    );
    return byId(orderId);
  }

  /// Помечает все позиции со статусом `draft` как `pending` (= отправлено).
  /// Возвращает заказ и список именно тех позиций, что были только что отправлены.
  ({Order order, List<OrderItem> sentItems}) sendToKitchen(
    String orderId, {
    String? assignWaiterId,
  }) {
    if (assignWaiterId != null) {
      assignWaiterIfEmpty(orderId, assignWaiterId);
    }
    final now = DateTime.now().toUtc();
    final drafts = _db.select(
      "SELECT id FROM order_items WHERE order_id = ? AND status = 'draft'",
      [orderId],
    );
    if (drafts.isEmpty) {
      return (order: byId(orderId)!, sentItems: const []);
    }

    _db.execute(
      '''UPDATE order_items
         SET status = 'pending', sent_at = ?
         WHERE order_id = ? AND status = 'draft' ''',
      [now.toIso8601String(), orderId],
    );

    _db.execute(
      "UPDATE orders SET status = 'sent', sent_at = COALESCE(sent_at, ?) WHERE id = ?",
      [now.toIso8601String(), orderId],
    );

    final order = byId(orderId)!;
    final sentIds = drafts.map((r) => r['id'] as String).toSet();
    final sent = order.items.where((i) => sentIds.contains(i.id)).toList();
    return (order: order, sentItems: sent);
  }

  /// Обновляет статус позиции (pending → cooking → ready → served).
  OrderItem changeItemStatus(String itemId, OrderItemStatus status) {
    final now = DateTime.now().toUtc().toIso8601String();
    final updates = <String, Object?>{'status': status.name};
    if (status == OrderItemStatus.cooking) updates['started_at'] = now;
    if (status == OrderItemStatus.ready) updates['ready_at'] = now;

    final setSql = updates.keys.map((k) => '$k = ?').join(', ');
    _db.execute(
      'UPDATE order_items SET $setSql WHERE id = ?',
      [...updates.values, itemId],
    );

    final r = _db.select('SELECT * FROM order_items WHERE id = ?', [itemId]);
    if (r.isEmpty) throw StateError('Позиция не найдена: $itemId');
    return _mapItem(r.first);
  }

  Payment addPayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
    String? byUserId,
  }) {
    final id = _uuid.v4();
    final paidAt = DateTime.now().toUtc();
    _db.execute(
      '''INSERT INTO payments(id, order_id, method, amount, paid_at, by_user_id)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [id, orderId, method.name, amount, paidAt.toIso8601String(), byUserId],
    );

    final order = byId(orderId)!;
    if (order.balance <= 0.001) {
      _db.execute(
        "UPDATE orders SET status = 'paid', closed_at = ? WHERE id = ?",
        [DateTime.now().toUtc().toIso8601String(), orderId],
      );
    }

    return Payment(
      id: id,
      orderId: orderId,
      method: method,
      amount: amount,
      paidAt: paidAt,
      byUserId: byUserId,
    );
  }

  /// Все позиции, ждущие повара или в работе — для KDS.
  List<KitchenTicket> kitchenTickets() {
    final rows = _db.select('''
      SELECT
        oi.*,
        o.id AS order_id,
        t.number AS table_number,
        u.display_name AS waiter_name
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      JOIN tables t ON t.id = o.table_id
      LEFT JOIN users u ON u.id = o.waiter_id
      WHERE oi.status IN ('pending', 'cooking')
      ORDER BY COALESCE(oi.sent_at, oi.created_at)
    ''');

    final grouped = <String, List<Row>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row['order_id'] as String, () => []).add(row);
    }

    return grouped.entries.map((e) {
      final first = e.value.first;
      return KitchenTicket(
        orderId: e.key,
        tableNumber: first['table_number'].toString(),
        waiterName: first['waiter_name'] as String?,
        items: e.value.map(_mapItem).toList(growable: false),
        station: Station.values.firstWhere(
          (s) => s.name == first['station'] as String,
          orElse: () => Station.hot,
        ),
        sentAt: DateTime.parse(
          (first['sent_at'] as String?) ?? (first['created_at'] as String),
        ),
      );
    }).toList(growable: false);
  }

  // ----------------------------- internals -----------------------------

  void _insertItem(String orderId, OrderItem item) {
    _db.execute(
      '''INSERT INTO order_items
        (id, order_id, dish_id, dish_name, qty, price_at_moment, modifier_ids,
         modifiers_total, note, status, station, course_no, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        item.id,
        orderId,
        item.dishId,
        item.dishName,
        item.qty,
        item.priceAtMoment,
        jsonEncode(item.modifierIds),
        item.modifiersTotal,
        item.note,
        item.status.name,
        item.station.name,
        item.courseNo,
        item.createdAt.toIso8601String(),
      ],
    );
  }

  Order _hydrate(Row row) {
    final id = row['id'] as String;

    final itemRows = _db.select(
      'SELECT * FROM order_items WHERE order_id = ? ORDER BY created_at',
      [id],
    );
    final payRows = _db.select(
      'SELECT * FROM payments WHERE order_id = ? ORDER BY paid_at',
      [id],
    );

    return Order(
      id: id,
      tableId: row['table_id'] as String,
      waiterId: row['waiter_id'] as String?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == row['status'] as String,
        orElse: () => OrderStatus.open,
      ),
      source: OrderSource.values.firstWhere(
        (e) => e.name == row['source'] as String,
        orElse: () => OrderSource.waiter,
      ),
      items: itemRows.map(_mapItem).toList(growable: false),
      payments: payRows.map(_mapPayment).toList(growable: false),
      note: row['note'] as String? ?? '',
      guestsCount: row['guests_count'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      sentAt: row['sent_at'] == null
          ? null
          : DateTime.parse(row['sent_at'] as String),
      closedAt: row['closed_at'] == null
          ? null
          : DateTime.parse(row['closed_at'] as String),
      discountPercent: (row['discount_percent'] as num).toDouble(),
      servicePercent: (row['service_percent'] as num).toDouble(),
    );
  }

  OrderItem _mapItem(Row r) {
    return OrderItem(
      id: r['id'] as String,
      dishId: r['dish_id'] as String,
      dishName: r['dish_name'] as String,
      qty: r['qty'] as int,
      priceAtMoment: (r['price_at_moment'] as num).toDouble(),
      modifierIds: (jsonDecode(r['modifier_ids'] as String) as List<dynamic>)
          .map((e) => e.toString())
          .toList(growable: false),
      modifiersTotal: (r['modifiers_total'] as num).toDouble(),
      note: r['note'] as String? ?? '',
      status: OrderItemStatus.values.firstWhere(
        (e) => e.name == r['status'] as String,
        orElse: () => OrderItemStatus.draft,
      ),
      station: Station.values.firstWhere(
        (e) => e.name == r['station'] as String,
        orElse: () => Station.hot,
      ),
      courseNo: r['course_no'] as int,
      createdAt: DateTime.parse(r['created_at'] as String),
      sentAt:
          r['sent_at'] == null ? null : DateTime.parse(r['sent_at'] as String),
      startedAt: r['started_at'] == null
          ? null
          : DateTime.parse(r['started_at'] as String),
      readyAt: r['ready_at'] == null
          ? null
          : DateTime.parse(r['ready_at'] as String),
    );
  }

  Payment _mapPayment(Row r) {
    return Payment(
      id: r['id'] as String,
      orderId: r['order_id'] as String,
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == r['method'] as String,
        orElse: () => PaymentMethod.cash,
      ),
      amount: (r['amount'] as num).toDouble(),
      paidAt: DateTime.parse(r['paid_at'] as String),
      byUserId: r['by_user_id'] as String?,
    );
  }
}

/// Утилита для генерации id новых позиций — клиенту тоже пригодится.
String newId() => _uuid.v4();
