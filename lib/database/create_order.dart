import '../data/models/dish.dart';
import '../data/models/order.dart';
import 'daatabase_helper.dart';

Future<void> createOrder(String waiterId, String tableId, List<Dish> orderedDishes) async {
  final newOrder = Order(
    waiterId: waiterId,
    tableId: tableId,
    orderedDishes: orderedDishes,
    orderDateTime: DateTime.now(),
    isPaid: false,
  );

  await DatabaseHelper.insertOrder(newOrder);
}
