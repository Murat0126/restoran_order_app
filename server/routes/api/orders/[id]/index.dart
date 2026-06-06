import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final ctx = AppContext.instance;

  switch (context.request.method) {
    case HttpMethod.get:
      final guard = requireAuth(context);
      if (guard != null) return guard;
      final order = ctx.orders.byId(id);
      if (order == null) {
        return Response.json(
          statusCode: 404,
          body: {'error': 'Заказ не найден'},
        );
      }
      return Response.json(body: {'order': order.toJson()});

    case HttpMethod.patch:
      final guard =
          requireAuth(context, roles: {UserRole.waiter, UserRole.admin});
      if (guard != null) return guard;
      final body = await context.request.json() as Map<String, dynamic>;
      final guests = body['guestsCount'] as int?;
      if (guests == null || guests < 1) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'guestsCount обязателен (>= 1)'},
        );
      }
      final updated = ctx.orders.updateGuests(id, guests);
      if (updated == null) {
        return Response.json(
          statusCode: 404,
          body: {'error': 'Заказ не найден или нельзя изменить гостей'},
        );
      }
      ctx.events.emit(OrderUpdated(order: updated));
      return Response.json(body: {'order': updated.toJson()});

    default:
      return Response(statusCode: 405);
  }
}
