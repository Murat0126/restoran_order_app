import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

/// Редактирование / удаление сотрудника (admin). Защита от самоблокировки:
/// нельзя удалить себя и нельзя убрать последнего админа.
Future<Response> onRequest(RequestContext context, String id) async {
  final guard = requireAuth(context, roles: {UserRole.admin});
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  final target = ctx.users.findById(id);
  if (target == null) {
    return Response.json(
        statusCode: 404, body: {'error': 'Пользователь не найден'});
  }
  final me = currentUser(context)!;

  switch (context.request.method) {
    case HttpMethod.patch:
      final body = await context.request.json() as Map<String, dynamic>;
      UserRole? role;
      if (body['role'] != null) {
        role = UserRole.values
            .where((r) => r.name == body['role'])
            .cast<UserRole?>()
            .firstWhere((r) => r != null, orElse: () => null);
        if (role == null) {
          return Response.json(
            statusCode: 400,
            body: {'error': 'Неизвестная роль: ${body['role']}'},
          );
        }
        // Нельзя снять роль admin с последнего администратора.
        if (target.role == UserRole.admin &&
            role != UserRole.admin &&
            ctx.users.countByRole(UserRole.admin) <= 1) {
          return Response.json(
            statusCode: 409,
            body: {'error': 'Нельзя понизить последнего администратора'},
          );
        }
      }
      ctx.users.updateProfile(
        id: id,
        displayName: (body['displayName'] as String?)?.trim(),
        role: role,
        email: (body['email'] as String?)?.trim(),
      );
      return Response.json(body: {'user': ctx.users.findById(id)!.toJson()});

    case HttpMethod.delete:
      if (id == me.id) {
        return Response.json(
          statusCode: 409,
          body: {'error': 'Нельзя удалить собственную учётную запись'},
        );
      }
      if (target.role == UserRole.admin &&
          ctx.users.countByRole(UserRole.admin) <= 1) {
        return Response.json(
          statusCode: 409,
          body: {'error': 'Нельзя удалить последнего администратора'},
        );
      }
      ctx.users.deleteUser(id);
      return Response.json(body: {'ok': true});

    default:
      return Response(statusCode: 405);
  }
}
