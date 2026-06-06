/// Сущности «физического мира» ресторана: заведение, зал, столики.
library;

import 'enums.dart';
import 'util/json_utils.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.currency = 'KGS',
    this.taxPercent = 0,
    this.servicePercent = 0,
  });

  final String id;
  final String name;
  final String currency;
  final double taxPercent;
  final double servicePercent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'taxPercent': taxPercent,
        'servicePercent': servicePercent,
      };

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        currency: json['currency'] as String? ?? 'KGS',
        taxPercent: parseDouble(json['taxPercent'] ?? 0),
        servicePercent: parseDouble(json['servicePercent'] ?? 0),
      );
}

class Hall {
  const Hall({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.sortOrder = 0,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'name': name,
        'sortOrder': sortOrder,
      };

  factory Hall.fromJson(Map<String, dynamic> json) => Hall(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        name: json['name'] as String,
        sortOrder: parseInt(json['sortOrder'] ?? 0),
      );
}

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.hallId,
    required this.number,
    this.capacity = 4,
    this.status = TableStatus.free,
    this.currentOrderId,
    this.qrToken,
  });

  final String id;
  final String hallId;

  /// Номер столика для отображения (может быть нечисловой: «VIP-1»).
  final String number;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;

  /// Токен, который зашит в QR-код столика и позволяет клиенту
  /// открыть меню без логина.
  final String? qrToken;

  RestaurantTable copyWith({
    TableStatus? status,
    String? currentOrderId,
    bool clearCurrentOrderId = false,
  }) {
    return RestaurantTable(
      id: id,
      hallId: hallId,
      number: number,
      capacity: capacity,
      status: status ?? this.status,
      currentOrderId:
          clearCurrentOrderId ? null : (currentOrderId ?? this.currentOrderId),
      qrToken: qrToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hallId': hallId,
        'number': number,
        'capacity': capacity,
        'status': status.name,
        'currentOrderId': currentOrderId,
        'qrToken': qrToken,
      };

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'] as String,
        hallId: json['hallId'] as String,
        number: json['number'].toString(),
        capacity: parseInt(json['capacity'] ?? 4),
        status: parseEnum(
          json['status'],
          TableStatus.values,
          fallback: TableStatus.free,
        ),
        currentOrderId: json['currentOrderId'] as String?,
        qrToken: json['qrToken'] as String?,
      );
}
