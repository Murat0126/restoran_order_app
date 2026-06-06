/// Заказы, позиции, кухонные тикеты и оплаты.
library;

import 'enums.dart';
import 'util/json_utils.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.dishId,
    required this.dishName,
    required this.qty,
    required this.priceAtMoment,
    required this.station,
    required this.createdAt,
    this.status = OrderItemStatus.draft,
    this.modifierIds = const [],
    this.modifiersTotal = 0,
    this.note = '',
    this.courseNo = 1,
    this.sentAt,
    this.startedAt,
    this.readyAt,
  });

  final String id;
  final String dishId;

  /// Денормализованное имя блюда — чтобы чек на кухне печатался
  /// даже если блюдо потом удалили из меню.
  final String dishName;
  final int qty;
  final double priceAtMoment;
  final List<String> modifierIds;
  final double modifiersTotal;
  final String note;
  final OrderItemStatus status;
  final Station station;

  /// Номер подачи: 1 — основное, 2 — после паузы и т.д.
  final int courseNo;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? startedAt;
  final DateTime? readyAt;

  double get lineTotal => (priceAtMoment + modifiersTotal) * qty;

  OrderItem copyWith({
    OrderItemStatus? status,
    DateTime? sentAt,
    DateTime? startedAt,
    DateTime? readyAt,
    int? qty,
    String? note,
  }) {
    return OrderItem(
      id: id,
      dishId: dishId,
      dishName: dishName,
      qty: qty ?? this.qty,
      priceAtMoment: priceAtMoment,
      modifierIds: modifierIds,
      modifiersTotal: modifiersTotal,
      note: note ?? this.note,
      status: status ?? this.status,
      station: station,
      courseNo: courseNo,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      startedAt: startedAt ?? this.startedAt,
      readyAt: readyAt ?? this.readyAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dishId': dishId,
        'dishName': dishName,
        'qty': qty,
        'priceAtMoment': priceAtMoment,
        'modifierIds': modifierIds,
        'modifiersTotal': modifiersTotal,
        'note': note,
        'status': status.name,
        'station': station.name,
        'courseNo': courseNo,
        'createdAt': createdAt.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        dishId: json['dishId'] as String,
        dishName: json['dishName'] as String,
        qty: parseInt(json['qty']),
        priceAtMoment: parseDouble(json['priceAtMoment']),
        modifierIds: (json['modifierIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        modifiersTotal: parseDouble(json['modifiersTotal'] ?? 0),
        note: json['note'] as String? ?? '',
        status: parseEnum(
          json['status'],
          OrderItemStatus.values,
          fallback: OrderItemStatus.draft,
        ),
        station: parseEnum(
          json['station'],
          Station.values,
          fallback: Station.hot,
        ),
        courseNo: parseInt(json['courseNo'] ?? 1),
        createdAt: parseDateTime(json['createdAt']),
        sentAt: parseDateTimeOrNull(json['sentAt']),
        startedAt: parseDateTimeOrNull(json['startedAt']),
        readyAt: parseDateTimeOrNull(json['readyAt']),
      );
}

class Order {
  const Order({
    required this.id,
    required this.tableId,
    required this.status,
    required this.source,
    required this.createdAt,
    this.waiterId,
    this.items = const [],
    this.payments = const [],
    this.note = '',
    this.guestsCount,
    this.sentAt,
    this.closedAt,
    this.discountPercent = 0,
    this.servicePercent = 0,
  });

  final String id;
  final String tableId;
  final String? waiterId;
  final OrderStatus status;
  final OrderSource source;
  final List<OrderItem> items;
  final List<Payment> payments;
  final String note;
  final int? guestsCount;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? closedAt;
  final double discountPercent;
  final double servicePercent;

  double get subtotal => items
      .where((i) => i.status != OrderItemStatus.cancelled)
      .fold<double>(0, (sum, i) => sum + i.lineTotal);

  double get discountAmount => subtotal * discountPercent / 100;
  double get serviceAmount =>
      (subtotal - discountAmount) * servicePercent / 100;
  double get total => subtotal - discountAmount + serviceAmount;
  double get paidAmount =>
      payments.fold<double>(0, (sum, p) => sum + p.amount);
  double get balance => total - paidAmount;

  /// QR-предзаказ: позиции ещё только в черновике, официант не подтвердил.
  bool get isPendingQrPreorder {
    if (source != OrderSource.qrPreorder || status != OrderStatus.open) {
      return false;
    }
    final active =
        items.where((i) => i.status != OrderItemStatus.cancelled);
    if (active.isEmpty) return false;
    return active.every((i) => i.status == OrderItemStatus.draft);
  }

  Order copyWith({
    OrderStatus? status,
    List<OrderItem>? items,
    List<Payment>? payments,
    DateTime? sentAt,
    DateTime? closedAt,
  }) {
    return Order(
      id: id,
      tableId: tableId,
      waiterId: waiterId,
      status: status ?? this.status,
      source: source,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      note: note,
      guestsCount: guestsCount,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      closedAt: closedAt ?? this.closedAt,
      discountPercent: discountPercent,
      servicePercent: servicePercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'waiterId': waiterId,
        'status': status.name,
        'source': source.name,
        'items': items.map((e) => e.toJson()).toList(growable: false),
        'payments': payments.map((e) => e.toJson()).toList(growable: false),
        'note': note,
        'guestsCount': guestsCount,
        'createdAt': createdAt.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'discountPercent': discountPercent,
        'servicePercent': servicePercent,
        'subtotal': subtotal,
        'total': total,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        tableId: json['tableId'] as String,
        waiterId: json['waiterId'] as String?,
        status: parseEnum(
          json['status'],
          OrderStatus.values,
          fallback: OrderStatus.open,
        ),
        source: parseEnum(
          json['source'],
          OrderSource.values,
          fallback: OrderSource.waiter,
        ),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        payments: (json['payments'] as List<dynamic>? ?? const [])
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        note: json['note'] as String? ?? '',
        guestsCount:
            json['guestsCount'] == null ? null : parseInt(json['guestsCount']),
        createdAt: parseDateTime(json['createdAt']),
        sentAt: parseDateTimeOrNull(json['sentAt']),
        closedAt: parseDateTimeOrNull(json['closedAt']),
        discountPercent: parseDouble(json['discountPercent'] ?? 0),
        servicePercent: parseDouble(json['servicePercent'] ?? 0),
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.paidAt,
    this.byUserId,
  });

  final String id;
  final String orderId;
  final PaymentMethod method;
  final double amount;
  final DateTime paidAt;
  final String? byUserId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'method': method.name,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        'byUserId': byUserId,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        method: parseEnum(
          json['method'],
          PaymentMethod.values,
          fallback: PaymentMethod.cash,
        ),
        amount: parseDouble(json['amount']),
        paidAt: parseDateTime(json['paidAt']),
        byUserId: json['byUserId'] as String?,
      );
}

/// Виртуальная сущность для KDS: то же самое, что подмножество позиций
/// заказа, но с денормализованной информацией для повара.
class KitchenTicket {
  const KitchenTicket({
    required this.orderId,
    required this.tableNumber,
    required this.items,
    required this.station,
    required this.sentAt,
    this.waiterName,
    this.note = '',
  });

  final String orderId;
  final String tableNumber;
  final String? waiterName;
  final List<OrderItem> items;
  final Station station;
  final DateTime sentAt;
  final String note;

  /// Чем дольше ждёт тикет — тем выше приоритет.
  Duration waitTime(DateTime now) => now.difference(sentAt);

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'tableNumber': tableNumber,
        'waiterName': waiterName,
        'items': items.map((e) => e.toJson()).toList(growable: false),
        'station': station.name,
        'sentAt': sentAt.toIso8601String(),
        'note': note,
      };

  factory KitchenTicket.fromJson(Map<String, dynamic> json) => KitchenTicket(
        orderId: json['orderId'] as String,
        tableNumber: json['tableNumber'].toString(),
        waiterName: json['waiterName'] as String?,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        station: parseEnum(
          json['station'],
          Station.values,
          fallback: Station.hot,
        ),
        sentAt: parseDateTime(json['sentAt']),
        note: json['note'] as String? ?? '',
      );
}
