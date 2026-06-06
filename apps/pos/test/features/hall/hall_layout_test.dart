import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/hall/hall_layout.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  const hall = Hall(id: 'h1', restaurantId: 'r1', name: 'Main');
  final tables = [
    const RestaurantTable(
      id: 't1',
      hallId: 'h1',
      number: '1',
      status: TableStatus.free,
    ),
    const RestaurantTable(
      id: 't2',
      hallId: 'h1',
      number: '2',
      status: TableStatus.occupied,
      currentOrderId: 'o1',
    ),
  ];

  test('tablesInHall фильтрует по hallId', () {
    final layout = HallLayout(
      halls: const [hall],
      tables: tables,
      ordersById: const {},
    );
    expect(layout.tablesInHall('h1'), hasLength(2));
    expect(layout.tablesInHall('other'), isEmpty);
  });

  test('copyWithTable заменяет стол', () {
    final layout = HallLayout(
      halls: const [hall],
      tables: tables,
      ordersById: const {},
    );
    final updated = tables[0].copyWith(status: TableStatus.occupied);
    final next = layout.copyWithTable(updated);
    expect(next.tables.first.status, TableStatus.occupied);
    expect(next.tables[1].status, TableStatus.occupied);
  });

  test('copyWithOrder удаляет оплаченный заказ из карты', () {
    final order = Order(
      id: 'o1',
      tableId: 't2',
      waiterId: 'w1',
      status: OrderStatus.paid,
      source: OrderSource.waiter,
      createdAt: DateTime(2026, 6, 4),
      items: const [],
    );
    final layout = HallLayout(
      halls: const [hall],
      tables: tables,
      ordersById: {'o1': order},
    );
    final next = layout.copyWithOrder(order);
    expect(next.ordersById.containsKey('o1'), isFalse);
  });
}
