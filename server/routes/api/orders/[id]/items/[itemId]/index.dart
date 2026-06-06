import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String itemId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: 405);
  }
  final guard =
      requireAuth(context, roles: {UserRole.waiter, UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final updated = ctx.orders.removeDraftItem(id, itemId);
  if (updated == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Позиция не найдена или уже отправлена на кухню'},
    );
  }
  ctx.events.emit(OrderUpdated(order: updated));
  return Response.json(body: {'order': updated.toJson()});
}
