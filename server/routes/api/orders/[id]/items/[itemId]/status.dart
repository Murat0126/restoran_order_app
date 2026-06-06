import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String itemId,
) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(
    context,
    roles: {UserRole.cook, UserRole.waiter, UserRole.admin},
  );
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final order = ctx.orders.byId(id);
  if (order == null) {
    return Response.json(statusCode: 404, body: {'error': 'Заказ не найден'});
  }
  final body = await context.request.json() as Map<String, dynamic>;
  final statusName = body['status'] as String?;
  final status = OrderItemStatus.values.firstWhere(
    (s) => s.name == statusName,
    orElse: () => OrderItemStatus.pending,
  );
  if (statusName == null || status.name != statusName) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Невалидный статус',
        'allowed': OrderItemStatus.values.map((e) => e.name).toList()
      },
    );
  }

  final updatedItem = ctx.orders.changeItemStatus(itemId, status);
  ctx.events.emit(KitchenItemStatusChanged(
    orderId: id,
    itemId: itemId,
    item: updatedItem,
  ));

  return Response.json(body: {'item': updatedItem.toJson()});
}
