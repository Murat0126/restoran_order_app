import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences/preferences_provider.dart';

/// Источники базового URL API (по приоритету, сверху вниз):
///
/// 1. `--dart-define=API_BASE_URL=http://host:port` (compile-time).
/// 2. Сохранённое значение из `SharedPreferences[api.base_url]` (runtime).
/// 3. Дефолт для платформы:
///    * Web → текущий origin (`Uri.base.origin`) — мы подаём Flutter Web
///      с того же Dart Frog, что и API.
///    * прочее → `http://localhost:8080`.
const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

const _prefsKeyBaseUrl = 'api.base_url';

/// Текущий base URL без слеша в конце.
class ApiBaseUrlNotifier extends StateNotifier<String> {
  ApiBaseUrlNotifier(this._prefs) : super(_resolveInitial(_prefs));

  final SharedPreferences _prefs;

  static String _resolveInitial(SharedPreferences p) {
    if (_envBaseUrl.isNotEmpty) return _normalize(_envBaseUrl);
    final saved = p.getString(_prefsKeyBaseUrl);
    if (saved != null && saved.isNotEmpty) return _normalize(saved);
    if (kIsWeb) return _normalize(Uri.base.origin);
    return 'http://localhost:8080';
  }

  /// Сохраняет новый URL. Все зависящие провайдеры (api client,
  /// realtime) автоматически пересоберутся через `ref.watch`.
  Future<void> set(String url) async {
    final normalized = _normalize(url);
    if (normalized == state) return;
    state = normalized;
    await _prefs.setString(_prefsKeyBaseUrl, normalized);
  }

  /// Сбросить к дефолту (env / web origin / localhost).
  Future<void> reset() async {
    await _prefs.remove(_prefsKeyBaseUrl);
    state = _resolveInitial(_prefs);
  }

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}

final apiBaseUrlProvider =
    StateNotifierProvider<ApiBaseUrlNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiBaseUrlNotifier(prefs);
});
