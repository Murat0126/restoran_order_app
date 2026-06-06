/// События, которые сервер отправляет всем подключённым клиентам по WebSocket.
///
/// Каждое событие сериализуется как `{"type": "<type>", "payload": {...}}`.
/// Клиент диспетчеризует по полю `type`.
library;

import 'order.dart';
import 'restaurant.dart';

/// Базовый класс серверного события.
sealed class WsEvent {
  const WsEvent();

  String get type;

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload(),
      };

  Map<String, dynamic> payload();

  static WsEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final payload = json['payload'] as Map<String, dynamic>;
    return switch (type) {
      PreorderCreated.kType =>
        PreorderCreated(order: Order.fromJson(payload['order'] as Map<String, dynamic>)),
      OrderUpdated.kType =>
        OrderUpdated(order: Order.fromJson(payload['order'] as Map<String, dynamic>)),
      OrderSentToKitchen.kType => OrderSentToKitchen(
          order: Order.fromJson(payload['order'] as Map<String, dynamic>),
        ),
      KitchenItemAdded.kType => KitchenItemAdded(
          orderId: payload['orderId'] as String,
          tableNumber: payload['tableNumber'].toString(),
          item: OrderItem.fromJson(payload['item'] as Map<String, dynamic>),
        ),
      KitchenItemStatusChanged.kType => KitchenItemStatusChanged(
          orderId: payload['orderId'] as String,
          itemId: payload['itemId'] as String,
          item: OrderItem.fromJson(payload['item'] as Map<String, dynamic>),
        ),
      TableStatusChanged.kType => TableStatusChanged(
          table: RestaurantTable.fromJson(
            payload['table'] as Map<String, dynamic>,
          ),
        ),
      OrderPaid.kType => OrderPaid(
          order: Order.fromJson(payload['order'] as Map<String, dynamic>),
        ),
      _ => throw FormatException('Неизвестный тип WS-события: $type'),
    };
  }
}

/// Клиент через QR оставил предзаказ. Видят официанты.
class PreorderCreated extends WsEvent {
  const PreorderCreated({required this.order});
  static const kType = 'preorder.created';
  final Order order;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {'order': order.toJson()};
}

/// Универсальное обновление заказа (новая позиция, изменение и т.д.).
class OrderUpdated extends WsEvent {
  const OrderUpdated({required this.order});
  static const kType = 'order.updated';
  final Order order;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {'order': order.toJson()};
}

/// Официант отправил заказ (или его часть) на кухню.
class OrderSentToKitchen extends WsEvent {
  const OrderSentToKitchen({required this.order});
  static const kType = 'order.sent_to_kitchen';
  final Order order;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {'order': order.toJson()};
}

/// Новая позиция появилась в очереди кухни. Триггер для звука/печати.
class KitchenItemAdded extends WsEvent {
  const KitchenItemAdded({
    required this.orderId,
    required this.tableNumber,
    required this.item,
  });
  static const kType = 'kitchen.item_added';
  final String orderId;
  final String tableNumber;
  final OrderItem item;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {
        'orderId': orderId,
        'tableNumber': tableNumber,
        'item': item.toJson(),
      };
}

/// Повар изменил статус позиции (cooking / ready).
class KitchenItemStatusChanged extends WsEvent {
  const KitchenItemStatusChanged({
    required this.orderId,
    required this.itemId,
    required this.item,
  });
  static const kType = 'kitchen.item_status';
  final String orderId;
  final String itemId;
  final OrderItem item;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {
        'orderId': orderId,
        'itemId': itemId,
        'item': item.toJson(),
      };
}

/// Изменился статус столика (занят / счёт / свободен).
class TableStatusChanged extends WsEvent {
  const TableStatusChanged({required this.table});
  static const kType = 'table.status_changed';
  final RestaurantTable table;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {'table': table.toJson()};
}

/// Заказ оплачен и закрыт.
class OrderPaid extends WsEvent {
  const OrderPaid({required this.order});
  static const kType = 'order.paid';
  final Order order;
  @override
  String get type => kType;
  @override
  Map<String, dynamic> payload() => {'order': order.toJson()};
}
