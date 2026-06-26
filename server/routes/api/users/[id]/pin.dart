import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

/// Установка / сброс PIN быстрого входа сотрудника админом (Stitch 6.5).
///
/// Тело: `{"pin": "1234"}` — задать; `{"pin": null}` или пустое — сбросить.
/// PIN должен быть уникальным среди сотрудников (вход выполняется по
/// одному PIN, без указания логина).
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
  final pin = (body['pin'] as String?)?.trim();

  if (pin == null || pin.isEmpty) {
    ctx.users.setPin(id, null);
    return Response.json(body: {'ok': true, 'hasPin': false});
  }
  if (pin.length < 4) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'PIN не короче 4 цифр'},
    );
  }
  final owner = ctx.users.userIdByPin(pin);
  if (owner != null && owner != id) {
    return Response.json(
      statusCode: 409,
      body: {'error': 'Такой PIN уже занят'},
    );
  }

  ctx.users.setPin(id, hashPassword(pin));
  return Response.json(body: {'ok': true, 'hasPin': true});
}
