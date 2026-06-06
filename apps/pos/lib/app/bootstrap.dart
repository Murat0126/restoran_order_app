import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Универсальный bootstrap: запускает приложение и навешивает
/// обработчики ошибок.
///
/// На этом этапе [bootstrap] минимален — он только настраивает
/// логирование и ловит ошибки фреймворка. По мере роста (F2..F5)
/// здесь же будут инициализироваться: локализация, темы, БД,
/// разогрев SharedPreferences и т.п.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _setupLogging();

      FlutterError.onError = (FlutterErrorDetails details) {
        Logger('flutter').severe(
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
      };

      final widget = await builder();
      runApp(widget);
    },
    (error, stack) {
      Logger('zone').severe('Uncaught', error, stack);
    },
  );
}

void _setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((rec) {
    // Используем debugPrint, чтобы не валить телеметрию через тяжёлый print.
    debugPrint('[${rec.level.name}] ${rec.loggerName}: ${rec.message}');
    if (rec.error != null) debugPrint('  err: ${rec.error}');
    if (rec.stackTrace != null) debugPrint(rec.stackTrace.toString());
  });
}
