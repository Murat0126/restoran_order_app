import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(RequestContext context) async {
  final ctx = AppContext.instance;

  switch (context.request.method) {
    case HttpMethod.get:
      final guard = requireAuth(context);
      if (guard != null) return guard;
      final user = currentUser(context)!;
      final mine = context.request.uri.queryParameters['mine'] == 'true';
      final orders = mine
          ? ctx.orders.activeOrdersForWaiter(user.id)
          : ctx.orders.activeOrders();
      return Response.json(
        body: {
          'orders': orders.map((o) => o.toJson()).toList(growable: false),
        },
      );

    case HttpMethod.post:
      final guard =
          requireAuth(context, roles: {UserRole.waiter, UserRole.admin});
      if (guard != null) return guard;

      final body = await context.request.json() as Map<String, dynamic>;
      final tableId = body['tableId'] as String?;
      if (tableId == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'tableId обязателен'},
        );
      }
      final user = currentUser(context)!;
      final guests = body['guestsCount'] as int?;

      final order = ctx.orders.create(
        tableId: tableId,
        waiterId: user.id,
        guestsCount: guests,
      );
      final table = ctx.tables.updateStatus(
        tableId,
        status: TableStatus.occupied,
        currentOrderId: order.id,
      );

      ctx.events
        ..emit(OrderUpdated(order: order))
        ..emit(TableStatusChanged(table: table));

      return Response.json(statusCode: 201, body: {'order': order.toJson()});

    default:
      return Response(statusCode: 405);
  }
}
