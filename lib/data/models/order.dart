import 'dish.dart';

class Order {
  final int? id;
  final String waiterId; // ID официанта
  final String tableId; // Столик, к которому привязан заказ
  final List<Dish> orderedDishes; // Список заказанных блюд
  final DateTime orderDateTime; // Время оформления заказа
  final bool isPaid; // Статус оплаты

  Order({
    this.id,
    required this.waiterId,
    required this.tableId,
    required this.orderedDishes,
    required this.orderDateTime,
    required this.isPaid,
  });

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waiterId': waiterId,
      'tableId': tableId,
      'orderedDishes': orderedDishes.map((dish) => dish.id).join(','), // Храним ID блюд
      'orderDateTime': orderDateTime.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
    };
  }

  // Создание объекта Order из Map
  static Order fromMap(Map<String, dynamic> map, List<Dish> allDishes) {
    List<Dish> orderedDishes = [];
    for (var dishId in map['orderedDishes'].split(',')) {
      orderedDishes.add(allDishes.firstWhere((dish) => dish.id.toString() == dishId));
    }

    return Order(
      id: map['id'],
      waiterId: map['waiterId'],
      tableId: map['tableId'],
      orderedDishes: orderedDishes,
      orderDateTime: DateTime.parse(map['orderDateTime']),
      isPaid: map['isPaid'] == 1,
    );
  }
}
