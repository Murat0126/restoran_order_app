import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences` как Riverpod-провайдер.
///
/// Инициализируется в `bootstrap()` (`apps/pos/lib/app/bootstrap.dart`)
/// через `overrideWithValue`. До `runApp` ничего не читает —
/// блокирующих await в дереве виджетов не будет.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider должен быть переопределён в ProviderScope '
    '(см. bootstrap()).',
  ),
);
