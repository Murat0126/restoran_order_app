import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context, roles: {UserRole.waiter, UserRole.admin});
  if (guard != null) return guard;
  final user = currentUser(context)!;

  final ctx = AppContext.instance;
  final existing = ctx.orders.byId(id);
  if (existing == null) {
    return Response.json(statusCode: 404, body: {'error': 'Заказ не найден'});
  }

  final result = ctx.orders.sendToKitchen(
    id,
    assignWaiterId: user.role == UserRole.waiter ? user.id : null,
  );
  final order = result.order;
  final sentItems = result.sentItems;

  final table = ctx.tables.byId(order.tableId);
  final waiter =
      order.waiterId == null ? null : ctx.users.findById(order.waiterId!);

  ctx.events.emit(OrderSentToKitchen(order: order));

  for (final item in sentItems) {
    ctx.events.emit(KitchenItemAdded(
      orderId: order.id,
      tableNumber: table?.number ?? '?',
      item: item,
    ));
  }

  return Response.json(body: {
    'order': order.toJson(),
    'sentCount': sentItems.length,
    'waiter': waiter?.toJson(),
  });
}
