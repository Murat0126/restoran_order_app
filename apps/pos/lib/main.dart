import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/preferences/preferences_provider.dart';

/// Точка входа POS-приложения.
///
/// Внутри [bootstrap] выполняется только настройка логирования и
/// перехвата ошибок. Платформенные асинхронные инициализации
/// (`SharedPreferences`, в дальнейшем `sqflite`, `path_provider`)
/// выполняются здесь и пробрасываются в `ProviderScope` через
/// `overrides`, чтобы провайдеры не делали блокирующих await
/// в дереве виджетов.
Future<void> main() async {
  await bootstrap(() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PosApp(),
    );
  });
}
