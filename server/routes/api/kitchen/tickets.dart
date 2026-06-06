import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context,
      roles: {UserRole.cook, UserRole.admin, UserRole.waiter});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final tickets = ctx.orders.kitchenTickets();
  return Response.json(
    body: {'tickets': tickets.map((t) => t.toJson()).toList(growable: false)},
  );
}
