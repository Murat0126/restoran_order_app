import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/repositories/orders_repository.dart';

/// Эндпоинт для QR-меню: клиент со своего телефона отправляет
/// предзаказ. **Не** требует авторизации, но требует валидный
/// `qrToken` столика — иначе любой желающий мог бы создавать заказы.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final ctx = AppContext.instance;
  final body = await context.request.json() as Map<String, dynamic>;
  final qrToken = body['qrToken'] as String?;
  final cart = body['items'] as List<dynamic>?;
  if (qrToken == null || cart == null || cart.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'qrToken и непустой items обязательны'},
    );
  }

  final table = ctx.tables.byQrToken(qrToken);
  if (table == null) {
    return Response.json(statusCode: 404, body: {'error': 'Стол не найден'});
  }

  final categories = ctx.menu.allCategories();
  final initialItems = <OrderItem>[];
  for (final raw in cart) {
    final m = raw as Map<String, dynamic>;
    final dishId = m['dishId'] as String?;
    final qty = (m['qty'] as int?) ?? 1;
    if (dishId == null) continue;
    final dish = ctx.menu.findDish(dishId);
    if (dish == null) continue;
    final category = categories.firstWhere(
      (c) => c.id == dish.categoryId,
      orElse: () => const MenuCategory(id: '', name: '', station: Station.hot),
    );
    initialItems.add(OrderItem(
      id: newId(),
      dishId: dish.id,
      dishName: dish.name,
      qty: qty,
      priceAtMoment: dish.effectivePrice,
      station: dish.station ?? category.station,
      note: (m['note'] as String?) ?? '',
      createdAt: DateTime.now().toUtc(),
    ));
  }
  if (initialItems.isEmpty) {
    return Response.json(
        statusCode: 400, body: {'error': 'Нет валидных позиций'});
  }

  final order = ctx.orders.create(
    tableId: table.id,
    source: OrderSource.qrPreorder,
    guestsCount: body['guestsCount'] as int?,
    note: body['note'] as String? ?? '',
    initialItems: initialItems,
  );
  final updatedTable = ctx.tables.updateStatus(
    table.id,
    status: TableStatus.occupied,
    currentOrderId: order.id,
  );

  ctx.events
    ..emit(PreorderCreated(order: order))
    ..emit(TableStatusChanged(table: updatedTable));

  return Response.json(statusCode: 201, body: {'order': order.toJson()});
}
