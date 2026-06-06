import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';
import 'package:restaurant_server/src/repositories/orders_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context, roles: {UserRole.waiter, UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final order = ctx.orders.byId(id);
  if (order == null) {
    return Response.json(statusCode: 404, body: {'error': 'Заказ не найден'});
  }
  if (order.status != OrderStatus.open && order.status != OrderStatus.sent) {
    return Response.json(
      statusCode: 409,
      body: {
        'error':
            'Нельзя добавить позиции в заказ со статусом ${order.status.name}'
      },
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final dishId = body['dishId'] as String?;
  final qty = (body['qty'] as int?) ?? 1;
  if (dishId == null) {
    return Response.json(statusCode: 400, body: {'error': 'dishId обязателен'});
  }
  final dish = ctx.menu.findDish(dishId);
  if (dish == null) {
    return Response.json(statusCode: 404, body: {'error': 'Блюдо не найдено'});
  }
  final category = ctx.menu.allCategories().firstWhere(
      (c) => c.id == dish.categoryId,
      orElse: () => const MenuCategory(id: '', name: '', station: Station.hot));

  final item = OrderItem(
    id: newId(),
    dishId: dish.id,
    dishName: dish.name,
    qty: qty,
    priceAtMoment: dish.effectivePrice,
    station: dish.station ?? category.station,
    note: (body['note'] as String?) ?? '',
    courseNo: (body['courseNo'] as int?) ?? 1,
    createdAt: DateTime.now().toUtc(),
  );

  final updated = ctx.orders.addItem(id, item);
  ctx.events.emit(OrderUpdated(order: updated));

  return Response.json(statusCode: 201, body: {
    'order': updated.toJson(),
    'item': item.toJson(),
  });
}
