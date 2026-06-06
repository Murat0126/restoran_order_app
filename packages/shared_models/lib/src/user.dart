/// Пользователи POS (официант / кассир / повар / админ).
library;

import 'enums.dart';
import 'util/json_utils.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.email,
    this.hasPin = false,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final String? email;

  /// Сообщает клиенту, что у пользователя задан PIN для быстрого входа.
  /// Сам PIN-хеш с сервера наружу не отдаётся.
  final bool hasPin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'role': role.name,
        'email': email,
        'hasPin': hasPin,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String? ?? json['username'] as String,
        role: parseEnum(
          json['role'],
          UserRole.values,
          fallback: UserRole.waiter,
        ),
        email: json['email'] as String?,
        hasPin: json['hasPin'] as bool? ?? false,
      );
}

/// Ответ сервера на успешную авторизацию.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
      };

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
