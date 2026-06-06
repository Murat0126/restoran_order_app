import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  Order draftQrOrder() {
    final now = DateTime.utc(2026, 1, 1);
    return Order(
      id: 'o1',
      tableId: 't1',
      status: OrderStatus.open,
      source: OrderSource.qrPreorder,
      createdAt: now,
      items: [
        OrderItem(
          id: 'i1',
          dishId: 'd1',
          dishName: 'Soup',
          qty: 2,
          priceAtMoment: 100,
          station: Station.hot,
          status: OrderItemStatus.draft,
          createdAt: now,
        ),
      ],
    );
  }

  test('isPendingQrPreorder — true for open qr with draft items', () {
    expect(draftQrOrder().isPendingQrPreorder, isTrue);
  });

  test('isPendingQrPreorder — false after send', () {
    final now = DateTime.utc(2026, 1, 1);
    final sent = Order(
      id: 'o1',
      tableId: 't1',
      status: OrderStatus.sent,
      source: OrderSource.qrPreorder,
      createdAt: now,
      items: [
        OrderItem(
          id: 'i1',
          dishId: 'd1',
          dishName: 'Soup',
          qty: 1,
          priceAtMoment: 100,
          station: Station.hot,
          status: OrderItemStatus.pending,
          createdAt: now,
        ),
      ],
    );
    expect(sent.isPendingQrPreorder, isFalse);
  });
}
