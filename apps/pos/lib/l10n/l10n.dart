import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/preferences/preferences_provider.dart';
import 'generated/app_localizations.dart';

/// Краткий доступ к локализации из любого виджета:
///
/// ```dart
/// final l10n = context.l10n;
/// Text(l10n.settingsTitle);
/// ```
extension L10nContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ───────────────────────────────────────────────────────────────────────
// Список поддерживаемых языков.
// ───────────────────────────────────────────────────────────────────────

/// Один поддерживаемый язык + человекочитаемое имя на родном языке.
@immutable
class AppLanguage {
  const AppLanguage({required this.locale, required this.displayName});

  final Locale locale;
  final String displayName;
}

const _supportedLanguages = <AppLanguage>[
  AppLanguage(locale: Locale('ru'), displayName: 'Русский'),
  AppLanguage(locale: Locale('ky'), displayName: 'Кыргызча'),
];

const _defaultLocale = Locale('ru');

/// Реестр доступных языков. Сейчас хардкод — позже придёт с сервера
/// (для админов, которые управляют переводами клиентского меню).
final supportedLanguagesProvider = Provider<List<AppLanguage>>(
  (ref) => _supportedLanguages,
);

// ───────────────────────────────────────────────────────────────────────
// Выбранная локаль (null = «системная», иначе явный выбор пользователя).
// ───────────────────────────────────────────────────────────────────────

const _prefsKeyLocale = 'locale.code';

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences p) {
    final raw = p.getString(_prefsKeyLocale);
    if (raw == null || raw.isEmpty || raw == 'system') return null;
    return Locale(raw);
  }

  /// `null` → «следовать системной» (Flutter возьмёт первый совпадающий
  /// из `supportedLocales`, иначе fallback на ru).
  Future<void> set(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.setString(_prefsKeyLocale, 'system');
    } else {
      await _prefs.setString(_prefsKeyLocale, locale.languageCode);
    }
  }
}

/// Выбранная пользователем локаль. `null` означает «системная».
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

// ───────────────────────────────────────────────────────────────────────
// Фабрика supportedLocales для MaterialApp.
// ───────────────────────────────────────────────────────────────────────

/// Возвращает в порядке приоритета: сначала [_defaultLocale] (ru),
/// затем все остальные. Это нужно, чтобы Flutter при отсутствии
/// перевода брал именно русский, а не первый по алфавиту.
List<Locale> appSupportedLocales() {
  final list = <Locale>[
    _defaultLocale,
    ..._supportedLanguages
        .map((l) => l.locale)
        .where((l) => l != _defaultLocale),
  ];
  return List<Locale>.unmodifiable(list);
}
