import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final ctx = AppContext.instance;
  final body = await context.request.json() as Map<String, dynamic>;
  final username = (body['username'] as String?)?.trim() ?? '';
  final password = (body['password'] as String?) ?? '';

  if (username.isEmpty || password.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'username и password обязательны'},
    );
  }

  final user = ctx.users.findByUsername(username);
  final hash = ctx.users.passwordHash(username);
  if (user == null || hash == null || !verifyPassword(password, hash)) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Неверный логин или пароль'},
    );
  }

  final token = ctx.users.openSession(user.id);
  return Response.json(body: {'token': token, 'user': user.toJson()});
}
