import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart';

class TablesRepository {
  TablesRepository(this._db);

  final Database _db;

  List<RestaurantTable> all() {
    final rows = _db.select('''
      SELECT t.* FROM tables t
      JOIN halls h ON h.id = t.hall_id
      ORDER BY h.sort_order, t.number
    ''');
    return rows.map(_map).toList(growable: false);
  }

  List<Hall> allHalls() {
    final rows = _db.select(
      'SELECT * FROM halls ORDER BY sort_order, name',
    );
    return rows
        .map(
          (r) => Hall(
            id: r['id'] as String,
            restaurantId: r['restaurant_id'] as String,
            name: r['name'] as String,
            sortOrder: r['sort_order'] as int? ?? 0,
          ),
        )
        .toList(growable: false);
  }

  RestaurantTable? byId(String id) {
    final r = _db.select('SELECT * FROM tables WHERE id = ?', [id]);
    if (r.isEmpty) return null;
    return _map(r.first);
  }

  RestaurantTable? byQrToken(String token) {
    final r = _db.select('SELECT * FROM tables WHERE qr_token = ?', [token]);
    if (r.isEmpty) return null;
    return _map(r.first);
  }

  bool isEmpty() {
    final r = _db.select('SELECT COUNT(*) AS c FROM tables');
    return (r.first['c'] as int) == 0;
  }

  void insertHall(Hall h) {
    _db.execute(
      'INSERT INTO halls(id, restaurant_id, name, sort_order) VALUES (?, ?, ?, ?)',
      [h.id, h.restaurantId, h.name, h.sortOrder],
    );
  }

  void insertTable(RestaurantTable t) {
    _db.execute(
      '''INSERT INTO tables(id, hall_id, number, capacity, status, current_order_id, qr_token)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [
        t.id,
        t.hallId,
        t.number,
        t.capacity,
        t.status.name,
        t.currentOrderId,
        t.qrToken,
      ],
    );
  }

  RestaurantTable updateStatus(
    String tableId, {
    TableStatus? status,
    String? currentOrderId,
    bool clearCurrentOrderId = false,
  }) {
    final t = byId(tableId);
    if (t == null) throw StateError('Стол не найден: $tableId');

    final newStatus = status ?? t.status;
    final newOrderId =
        clearCurrentOrderId ? null : (currentOrderId ?? t.currentOrderId);

    _db.execute(
      'UPDATE tables SET status = ?, current_order_id = ? WHERE id = ?',
      [newStatus.name, newOrderId, tableId],
    );

    return t.copyWith(
      status: newStatus,
      currentOrderId: newOrderId,
      clearCurrentOrderId: clearCurrentOrderId,
    );
  }

  RestaurantTable _map(Row r) {
    return RestaurantTable(
      id: r['id'] as String,
      hallId: r['hall_id'] as String,
      number: r['number'].toString(),
      capacity: r['capacity'] as int,
      status: TableStatus.values.firstWhere(
        (e) => e.name == r['status'] as String,
        orElse: () => TableStatus.free,
      ),
      currentOrderId: r['current_order_id'] as String?,
      qrToken: r['qr_token'] as String?,
    );
  }
}
