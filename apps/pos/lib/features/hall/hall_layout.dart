import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

/// Снимок зала: залы + столы + активные заказы (для сумм на карточках).
@immutable
class HallLayout {
  const HallLayout({
    required this.halls,
    required this.tables,
    required this.ordersById,
  });

  final List<Hall> halls;
  final List<RestaurantTable> tables;
  final Map<String, Order> ordersById;

  List<RestaurantTable> tablesInHall(String hallId) {
    return tables.where((t) => t.hallId == hallId).toList(growable: false);
  }

  Order? orderForTable(RestaurantTable table) {
    final id = table.currentOrderId;
    if (id == null) return null;
    return ordersById[id];
  }

  HallLayout copyWithTable(RestaurantTable updated) {
    return HallLayout(
      halls: halls,
      tables: [
        for (final t in tables)
          if (t.id == updated.id) updated else t,
      ],
      ordersById: ordersById,
    );
  }

  HallLayout copyWithOrder(Order order) {
    final next = Map<String, Order>.from(ordersById);
    if (order.status == OrderStatus.paid ||
        order.status == OrderStatus.cancelled) {
      next.remove(order.id);
    } else {
      next[order.id] = order;
    }
    return HallLayout(halls: halls, tables: tables, ordersById: next);
  }
}
