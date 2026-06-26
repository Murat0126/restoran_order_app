import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';
import 'package:restaurant_server/src/repositories/orders_repository.dart' show newId;

/// Управление сотрудниками — только для админа (Stitch 6.5).
Future<Response> onRequest(RequestContext context) async {
  final guard = requireAuth(context, roles: {UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;

  switch (context.request.method) {
    case HttpMethod.get:
      final users = ctx.users.allUsers();
      return Response.json(
        body: {
          'users': users.map((u) => u.toJson()).toList(growable: false),
        },
      );

    case HttpMethod.post:
      final body = await context.request.json() as Map<String, dynamic>;
      final username = (body['username'] as String?)?.trim() ?? '';
      final displayName = (body['displayName'] as String?)?.trim() ?? '';
      final roleName = body['role'] as String?;
      final password = (body['password'] as String?) ?? '';
      final pin = (body['pin'] as String?)?.trim();
      final email = (body['email'] as String?)?.trim();

      if (username.isEmpty || displayName.isEmpty || roleName == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'username, displayName и role обязательны'},
        );
      }
      if (password.length < 4) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Пароль не короче 4 символов'},
        );
      }
      final role = UserRole.values
          .where((r) => r.name == roleName)
          .cast<UserRole?>()
          .firstWhere((r) => r != null, orElse: () => null);
      if (role == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Неизвестная роль: $roleName'},
        );
      }
      if (ctx.users.findByUsername(username) != null) {
        return Response.json(
          statusCode: 409,
          body: {'error': 'Пользователь с таким логином уже есть'},
        );
      }
      // PIN, если задан, должен быть уникальным (вход по одному PIN).
      String? pinHash;
      if (pin != null && pin.isNotEmpty) {
        if (pin.length < 4) {
          return Response.json(
            statusCode: 400,
            body: {'error': 'PIN не короче 4 цифр'},
          );
        }
        if (ctx.users.userIdByPin(pin) != null) {
          return Response.json(
            statusCode: 409,
            body: {'error': 'Такой PIN уже занят'},
          );
        }
        pinHash = hashPassword(pin);
      }

      final id = newId();
      ctx.users.create(
        id: id,
        username: username,
        displayName: displayName,
        role: role,
        passwordHash: hashPassword(password),
        email: (email == null || email.isEmpty) ? null : email,
        pinHash: pinHash,
      );

      return Response.json(
        statusCode: 201,
        body: {'user': ctx.users.findById(id)!.toJson()},
      );

    default:
      return Response(statusCode: 405);
  }
}
