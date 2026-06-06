import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context, roles: {UserRole.cashier, UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final order = ctx.orders.byId(id);
  if (order == null) {
    return Response.json(statusCode: 404, body: {'error': 'Заказ не найден'});
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final methodName = body['method'] as String?;
  final amount = (body['amount'] as num?)?.toDouble();
  if (methodName == null || amount == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'method и amount обязательны'},
    );
  }
  final method = PaymentMethod.values.firstWhere(
    (m) => m.name == methodName,
    orElse: () => PaymentMethod.cash,
  );

  final user = currentUser(context)!;
  ctx.orders.addPayment(
    orderId: id,
    method: method,
    amount: amount,
    byUserId: user.id,
  );

  final updated = ctx.orders.byId(id)!;
  if (updated.status == OrderStatus.paid) {
    final table = ctx.tables.updateStatus(
      updated.tableId,
      status: TableStatus.free,
      clearCurrentOrderId: true,
    );
    ctx.events
      ..emit(OrderPaid(order: updated))
      ..emit(TableStatusChanged(table: table));
  } else {
    ctx.events.emit(OrderUpdated(order: updated));
  }

  return Response.json(body: {'order': updated.toJson()});
}
