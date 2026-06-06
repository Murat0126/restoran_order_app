import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'app_context.dart';

const _headerAuth = 'authorization';

String hashPassword(String plain) {
  if (plain.isEmpty) throw ArgumentError('Пароль не может быть пустым');
  return BCrypt.hashpw(plain, BCrypt.gensalt());
}

bool verifyPassword(String plain, String hash) {
  if (plain.isEmpty || hash.isEmpty) return false;
  return BCrypt.checkpw(plain, hash);
}

String generateToken() {
  final r = Random.secure();
  final bytes = List<int>.generate(32, (_) => r.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String generateQrToken() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Достаёт текущего пользователя из заголовка `Authorization: Bearer <token>`.
/// Возвращает `null`, если токена нет или он невалиден.
User? currentUser(RequestContext context) {
  final raw = context.request.headers[_headerAuth];
  if (raw == null) return null;
  final parts = raw.split(' ');
  if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') return null;
  final token = parts[1].trim();
  if (token.isEmpty) return null;
  return AppContext.instance.users.userByToken(token);
}

/// Возвращает ответ 401, если пользователь не залогинен.
/// Используется в начале обработчиков, требующих авторизацию.
Response? requireAuth(RequestContext context, {Set<UserRole>? roles}) {
  final user = currentUser(context);
  if (user == null) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'unauthorized'},
    );
  }
  if (roles != null && !roles.contains(user.role)) {
    return Response.json(
      statusCode: 403,
      body: {
        'error': 'forbidden',
        'requiredRoles': roles.map((e) => e.name).toList()
      },
    );
  }
  return null;
}
