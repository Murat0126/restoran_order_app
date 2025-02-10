class Order {
  final int? id;
  final String waiterId; // ID официанта
  final String tableId; // ID столика
  final List<String> orderedItems; // Список заказанных блюд
  final DateTime dateTime;

  Order({
    this.id,
    required this.waiterId, // Идентификатор официанта
    required this.tableId,
    required this.orderedItems,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waiterId': waiterId, // Добавляем в map
      'tableId': tableId,
      'orderedItems': orderedItems.join(','),
      'dateTime': dateTime.toIso8601String(),
    };
  }

  static Order fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      waiterId: map['waiterId'], // Читаем ID официанта
      tableId: map['tableId'],
      orderedItems: List<String>.from(map['orderedItems'].split(',')),
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
