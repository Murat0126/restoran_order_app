import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

/// Сброс пароля сотрудника админом (Stitch 6.5).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context, roles: {UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  if (ctx.users.findById(id) == null) {
    return Response.json(
        statusCode: 404, body: {'error': 'Пользователь не найден'});
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final password = (body['password'] as String?) ?? '';
  if (password.length < 4) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Пароль не короче 4 символов'},
    );
  }

  ctx.users.setPassword(id, hashPassword(password));
  return Response.json(body: {'ok': true});
}
