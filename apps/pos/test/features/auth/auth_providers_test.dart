import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pos/core/api/api_client_provider.dart';
import 'package:pos/core/api/token_storage.dart';
import 'package:pos/core/preferences/preferences_provider.dart';
import 'package:pos/features/auth/auth_providers.dart';
import 'package:pos/features/auth/role_labels.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Утилита: ProviderContainer с фейковым http.Client и
/// контролируемыми SharedPreferences.
Future<ProviderContainer> _container({
  Map<String, Object>? seedPrefs,
  required http.Client httpClient,
  String baseUrl = 'http://test.local',
}) async {
  SharedPreferences.setMockInitialValues(seedPrefs ?? {});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    // Переопределяем сам клиент — чтобы внутри использовался mock http.
    restaurantApiClientProvider.overrideWith((ref) {
      final storage = ref.watch(tokenStorageProvider);
      final client = RestaurantApiClient(
        baseUrl: baseUrl,
        tokenStorage: storage,
        httpClient: httpClient,
      );
      ref.onDispose(client.close);
      return client;
    }),
  ]);
}

Map<String, dynamic> _userJson(UserRole role, {String? username}) => {
      'id': 'u-${role.name}',
      'username': username ?? '${role.name}1',
      'displayName': 'Test ${role.name}',
      'role': role.name,
      'hasPin': false,
    };

void main() {
  group('AuthNotifier — restoration', () {
    test('пустые prefs → AuthSignedOut', () async {
      final c = await _container(httpClient: MockClient((_) async {
        throw StateError('Сетевые запросы не должны делаться при старте');
      }));
      addTearDown(c.dispose);
      expect(c.read(authStateProvider), isA<AuthSignedOut>());
      expect(c.read(currentUserProvider), isNull);
    });

    test('валидный auth.user в prefs → SignedIn без сетевых запросов',
        () async {
      final c = await _container(
        seedPrefs: {
          'auth.user': jsonEncode(_userJson(UserRole.director)),
        },
        httpClient: MockClient((_) async {
          throw StateError('Сетевые запросы не должны делаться при старте');
        }),
      );
      addTearDown(c.dispose);
      final auth = c.read(authStateProvider);
      expect(auth, isA<AuthSignedIn>());
      expect(auth.role, UserRole.director);
    });

    test('битый auth.user → SignedOut и ключ очищается', () async {
      final c = await _container(
        seedPrefs: {'auth.user': 'this is not json'},
        httpClient: MockClient((_) async {
          throw StateError('Сетевые запросы не должны делаться при старте');
        }),
      );
      addTearDown(c.dispose);
      expect(c.read(authStateProvider), isA<AuthSignedOut>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('auth.user'), isFalse);
    });
  });

  group('AuthNotifier — signIn', () {
    test('успех (200) → SignedIn, токен и user сохранены в prefs', () async {
      final c = await _container(
        httpClient: MockClient((req) async {
          expect(req.method, 'POST');
          expect(req.url.path, '/api/auth/login');
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['username'], 'waiter1');
          expect(body['password'], '1234');
          return http.Response(
            jsonEncode({
              'token': 'tok-xyz',
              'user': _userJson(UserRole.waiter, username: 'waiter1'),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(c.dispose);

      await c.read(authStateProvider.notifier).signIn('waiter1', '1234');

      expect(c.read(authStateProvider).role, UserRole.waiter);

      final prefs = await SharedPreferences.getInstance();
      // Ключ совпадает с PrefsAuthTokenStorage._prefsKeyToken.
      expect(prefs.getString('api.bearer_token'), 'tok-xyz');
      expect(prefs.containsKey('auth.user'), isTrue);
    });

    test('401 → AuthErrorBadCredentials, состояние остаётся SignedOut',
        () async {
      final c = await _container(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({'error': 'Неверный логин'}),
              401,
              headers: {'content-type': 'application/json'},
            )),
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(authStateProvider.notifier).signIn('x', 'y'),
        throwsA(isA<AuthErrorBadCredentials>()),
      );
      expect(c.read(authStateProvider), isA<AuthSignedOut>());
    });

    test('сетевая ошибка → AuthErrorNetwork', () async {
      final c = await _container(
        httpClient: MockClient((_) async {
          throw Exception('Connection refused');
        }),
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(authStateProvider.notifier).signIn('x', 'y'),
        throwsA(isA<AuthErrorNetwork>()),
      );
    });
  });

  group('AuthNotifier — signOut', () {
    test('очищает state, user и токен', () async {
      final c = await _container(
        seedPrefs: {
          'auth.user': jsonEncode(_userJson(UserRole.admin)),
          'api.bearer_token': 'tok-old',
        },
        httpClient: MockClient((_) async {
          throw StateError('Сетевые запросы не должны делаться при signOut');
        }),
      );
      addTearDown(c.dispose);

      expect(c.read(authStateProvider).role, UserRole.admin);
      await c.read(authStateProvider.notifier).signOut();

      expect(c.read(authStateProvider), isA<AuthSignedOut>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('auth.user'), isFalse);
      expect(prefs.containsKey('api.bearer_token'), isFalse);
    });
  });

  group('homePathForRole', () {
    test('маппинг роль → /path фиксирован', () {
      expect(homePathForRole(UserRole.admin), '/admin');
      expect(homePathForRole(UserRole.director), '/director');
      expect(homePathForRole(UserRole.waiter), '/waiter');
      expect(homePathForRole(UserRole.cashier), '/cashier');
      expect(homePathForRole(UserRole.cook), '/kds');
    });
  });
}
