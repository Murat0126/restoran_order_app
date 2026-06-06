import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/preferences/preferences_provider.dart';
import 'app_fonts.dart';
import 'app_theme.dart';
import 'theme_loader.dart';

// ───────────────────────────────────────────────────────────────────────
// Реестр доступных тем.
// ───────────────────────────────────────────────────────────────────────

/// Одна запись в реестре тем — id + человекочитаемое имя + путь к assets.
@immutable
class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.displayName,
    required this.assetPath,
  });

  final String id;
  final String displayName;
  final String assetPath;
}

/// Список доступных тем. Пока хардкод — в проде придёт с сервера.
///
/// Чтобы добавить новую тему:
/// 1. Создать `apps/pos/assets/themes/<id>.json`
/// 2. Добавить запись сюда.
/// 3. (Опционально) показать переключатель в админке.
final availableThemesProvider = Provider<List<ThemeOption>>(
  (ref) => const <ThemeOption>[
    ThemeOption(
      id: 'default',
      displayName: 'AURA POS',
      assetPath: 'assets/themes/default.json',
    ),
    ThemeOption(
      id: 'hushed_luxury',
      displayName: 'Hushed Luxury',
      assetPath: 'assets/themes/hushed_luxury.json',
    ),
  ],
);

// ───────────────────────────────────────────────────────────────────────
// Выбранный id темы (StateNotifier + persist).
// ───────────────────────────────────────────────────────────────────────

const _prefsKeyThemeId = 'theme.id';
const _prefsKeyThemeMode = 'theme.mode';
const _defaultThemeId = 'default';

class ThemeIdNotifier extends StateNotifier<String> {
  ThemeIdNotifier(this._prefs)
      : super(_prefs.getString(_prefsKeyThemeId) ?? _defaultThemeId);

  final SharedPreferences _prefs;

  Future<void> set(String id) async {
    state = id;
    await _prefs.setString(_prefsKeyThemeId, id);
  }
}

final themeIdProvider =
    StateNotifierProvider<ThemeIdNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeIdNotifier(prefs);
});

// ───────────────────────────────────────────────────────────────────────
// Режим (light / dark / system).
// ───────────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences p) {
    final raw = p.getString(_prefsKeyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_prefsKeyThemeMode, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

// ───────────────────────────────────────────────────────────────────────
// Загрузка JSON-темы по выбранному id.
// ───────────────────────────────────────────────────────────────────────

typedef AppThemePair = ({AppTheme light, AppTheme dark});

/// `FutureProvider`, читающий JSON выбранной темы из assets.
/// При смене [themeIdProvider] — автоматически перезагружается.
final appThemePairProvider = FutureProvider<AppThemePair>((ref) async {
  final id = ref.watch(themeIdProvider);
  final available = ref.watch(availableThemesProvider);
  final option = available.firstWhere(
    (o) => o.id == id,
    orElse: () => available.first,
  );
  final pair = await ThemeLoader.loadFromAsset(option.assetPath);
  return (
    light: _withFonts(pair.light),
    dark: _withFonts(pair.dark),
  );
});

AppTheme _withFonts(AppTheme theme) {
  return theme.copyWith(
    typography: typographyWithGoogleFonts(theme.typography),
  );
}
