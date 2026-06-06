import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

/// Состояние экрана заказа для одного столика.
@immutable
class OrderSession {
  const OrderSession({
    required this.table,
    required this.order,
    required this.menu,
    required this.selectedCategoryId,
  });

  final RestaurantTable table;
  final Order order;
  final MenuSnapshot menu;
  final String selectedCategoryId;

  List<Dish> dishesInCategory() {
    return menu.dishes
        .where((d) => d.categoryId == selectedCategoryId && d.available)
        .toList(growable: false);
  }

  List<OrderItem> draftItems() {
    return order.items
        .where((i) => i.status == OrderItemStatus.draft)
        .toList(growable: false);
  }

  /// Позиции, уже отправленные на кухню (только просмотр в корзине).
  List<OrderItem> kitchenItems() {
    return order.items
        .where(
          (i) =>
              i.status != OrderItemStatus.draft &&
              i.status != OrderItemStatus.cancelled,
        )
        .toList(growable: false);
  }

  bool get canEdit =>
      order.status == OrderStatus.open || order.status == OrderStatus.sent;

  OrderSession copyWith({
    RestaurantTable? table,
    Order? order,
    MenuSnapshot? menu,
    String? selectedCategoryId,
  }) {
    return OrderSession(
      table: table ?? this.table,
      order: order ?? this.order,
      menu: menu ?? this.menu,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}
