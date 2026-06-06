/// Меню: категории, блюда, модификаторы.
library;

import 'enums.dart';
import 'util/json_utils.dart';

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.station = Station.hot,
  });

  final String id;
  final String name;
  final int sortOrder;

  /// Станция по умолчанию для блюд этой категории.
  final Station station;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
        'station': station.name,
      };

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        sortOrder: parseInt(json['sortOrder'] ?? 0),
        station: parseEnum(
          json['station'],
          Station.values,
          fallback: Station.hot,
        ),
      );
}

class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description = '',
    this.discountPrice,
    this.station,
    this.cookingTimeMinutes = 10,
    this.images = const [],
    this.available = true,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double price;

  /// Цена со скидкой; если задана — используется при расчёте суммы заказа.
  final double? discountPrice;

  /// На какую станцию печатать чек для повара. Если `null` — берётся
  /// `station` из категории.
  final Station? station;
  final int cookingTimeMinutes;
  final List<String> images;
  final bool available;

  double get effectivePrice => discountPrice ?? price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'price': price,
        'discountPrice': discountPrice,
        'station': station?.name,
        'cookingTimeMinutes': cookingTimeMinutes,
        'images': images,
        'available': available,
      };

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        categoryId: json['categoryId'] as String,
        price: parseDouble(json['price']),
        discountPrice: json['discountPrice'] == null
            ? null
            : parseDouble(json['discountPrice']),
        station: json['station'] == null
            ? null
            : parseEnum(json['station'], Station.values),
        cookingTimeMinutes: parseInt(json['cookingTimeMinutes'] ?? 10),
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        available: json['available'] as bool? ?? true,
      );
}

class Modifier {
  const Modifier({
    required this.id,
    required this.dishId,
    required this.name,
    this.price = 0,
  });

  final String id;
  final String dishId;
  final String name;
  final double price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dishId': dishId,
        'name': name,
        'price': price,
      };

  factory Modifier.fromJson(Map<String, dynamic> json) => Modifier(
        id: json['id'] as String,
        dishId: json['dishId'] as String,
        name: json['name'] as String,
        price: parseDouble(json['price'] ?? 0),
      );
}
