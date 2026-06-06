import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/preferences/preferences_provider.dart';

/// Состояние аутентификации.
///
/// **F5 (текущая версия):** реальный `/api/auth/login` через
/// `RestaurantApiClient`. Токен и `User` кэшируются в
/// `SharedPreferences`, чтобы при перезапуске сразу попадать в
/// нужный home (без второго логина).
///
/// **Совместимость с F4:** контракт публичный API не менялся.
/// `currentUserProvider` остался тем же, `AuthState` — тот же sealed
/// (`AuthSignedOut` / `AuthSignedIn`). UI экраны (LoginScreen,
/// RoleHomeScreen) переехали на новый метод `signIn(...)` вместо
/// `signInAsRole(...)`.
@immutable
sealed class AuthState {
  const AuthState();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);
  final User user;
}

extension AuthStateX on AuthState {
  bool get isSignedIn => this is AuthSignedIn;

  User? get user => switch (this) {
        AuthSignedIn(:final user) => user,
        AuthSignedOut() => null,
      };

  UserRole? get role => user?.role;
}

/// Ошибка процесса логина — отдельный класс, чтобы UI мог
/// отличать «неверный пароль» от «сервер недоступен».
sealed class AuthError implements Exception {
  const AuthError();
}

class AuthErrorBadCredentials extends AuthError {
  const AuthErrorBadCredentials();
  @override
  String toString() => 'AuthError: bad credentials';
}

class AuthErrorNetwork extends AuthError {
  const AuthErrorNetwork(this.cause);
  final Object cause;
  @override
  String toString() => 'AuthError: network ($cause)';
}

class AuthErrorOther extends AuthError {
  const AuthErrorOther(this.message);
  final String message;
  @override
  String toString() => 'AuthError: $message';
}

const _prefsKeyUser = 'auth.user';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required SharedPreferences prefs,
    required RestaurantApiClient client,
  })  : _prefs = prefs,
        _client = client,
        super(_restoreInitial(prefs));

  final SharedPreferences _prefs;
  final RestaurantApiClient _client;

  static AuthState _restoreInitial(SharedPreferences p) {
    final raw = p.getString(_prefsKeyUser);
    if (raw == null || raw.isEmpty) return const AuthSignedOut();
    try {
      final user = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return AuthSignedIn(user);
    } catch (_) {
      // Битый JSON — лучше начать с чистого состояния.
      p.remove(_prefsKeyUser);
      return const AuthSignedOut();
    }
  }

  /// Реальный логин: POST /api/auth/login. Бросает [AuthError]
  /// если что-то не так. На успех — выставляет `AuthSignedIn`,
  /// сохраняет токен (через `RestaurantApiClient`) и user в prefs.
  Future<void> signIn(String username, String password) async {
    try {
      final res = await _client.login(username.trim(), password);
      await _prefs.setString(_prefsKeyUser, jsonEncode(res.user.toJson()));
      state = AuthSignedIn(res.user);
    } on ApiException catch (e) {
      if (e.statusCode == 401) throw const AuthErrorBadCredentials();
      if (e.isNetwork) throw AuthErrorNetwork(e.cause ?? e);
      throw AuthErrorOther(e.message);
    } catch (e) {
      throw AuthErrorOther(e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AuthSignedOut();
    await _prefs.remove(_prefsKeyUser);
    await _client.logout(); // чистит токен в tokenStorage
  }
}

/// Главный провайдер аутентификации.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(restaurantApiClientProvider);
  return AuthNotifier(prefs: prefs, client: client);
});

/// Сокращённая версия — только текущий пользователь (или null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
