import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

/// Адрес backend-сервера.
///
/// Логика выбора:
///   1. `--dart-define=API_BASE_URL=...` (если задан) — главный
///      приоритет, удобно для разработки с отдельным портом.
///   2. В Web — **тот же origin**, что и страница (схема + host + порт).
///      То есть когда Dart Frog сам отдаёт собранный Web и API/WS —
///      адрес угадывается автоматически. Это работает и под HTTPS-туннелем.
///   3. Иначе (тесты на desktop) — `http://localhost:8765`.
const _overrideApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_overrideApiBaseUrl.isNotEmpty) return _overrideApiBaseUrl;
  if (kIsWeb) {
    // Uri.base.origin — это "scheme://host[:port]" без пути.
    return Uri.base.origin;
  }
  return 'http://localhost:8765';
}

/// QR-токен, который используется, если в адресной строке
/// нет `?t=...`. Удобно для локальной проверки.
const defaultQrToken = String.fromEnvironment(
  'DEFAULT_QR_TOKEN',
  defaultValue: '',
);

RestaurantApiClient buildClient() => RestaurantApiClient(
      baseUrl: apiBaseUrl,
      tokenStorage: InMemoryAuthTokenStorage(),
    );
