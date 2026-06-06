import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences/preferences_provider.dart';

const _prefsKeyToken = 'api.bearer_token';

/// `AuthTokenStorage` поверх `SharedPreferences`.
///
/// Используется и для REST (Bearer header), и для восстановления
/// сессии между запусками. На F5 синхронное чтение из prefs — этого
/// достаточно (в Web/Desktop/Mobile это локальный disk-кеш).
///
/// На F6+ может быть заменено на `flutter_secure_storage`
/// (для production-сборок с PIN-входом) — контракт тот же.
class PrefsAuthTokenStorage implements AuthTokenStorage {
  PrefsAuthTokenStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> read() async => _prefs.getString(_prefsKeyToken);

  @override
  Future<void> write(String token) async {
    await _prefs.setString(_prefsKeyToken, token);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_prefsKeyToken);
  }
}

final tokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrefsAuthTokenStorage(prefs);
});
