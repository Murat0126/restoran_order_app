import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/theme_providers.dart';
import 'router.dart';

/// Корневой виджет POS-приложения.
///
/// Что подключено:
///  • темы (`appThemePairProvider`) + `themeMode` (F3);
///  • локали + `AppLocalizations` (F2);
///  • роутинг через `appRouterProvider` (F4) — `MaterialApp.router`;
///  • `AppThemeScope` — доставка spacing/radii/shadows до листьев.
class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themePair = ref.watch(appThemePairProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final pair = themePair.valueOrNull;
    final lightMaterial =
        pair?.light.toMaterialThemeData() ?? ThemeData(useMaterial3: true);
    final darkMaterial =
        pair?.dark.toMaterialThemeData() ?? ThemeData.dark(useMaterial3: true);

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: lightMaterial,
      darkTheme: darkMaterial,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales(),
      routerConfig: router,
      builder: (context, child) {
        return themePair.when(
          loading: () => const _ThemeGate(message: 'Загрузка приложения…'),
          error: (e, _) => _ThemeGate(message: 'Ошибка темы: $e'),
          data: (loaded) {
            final brightness = Theme.of(context).brightness;
            final active = brightness == Brightness.dark
                ? loaded.dark
                : loaded.light;
            return AppThemeScope(theme: active, child: child!);
          },
        );
      },
    );
  }
}

/// Оверлей до загрузки JSON-темы. [MaterialApp.router] уже активен,
/// поэтому URL вроде `/waiter` не ломают Navigator.
class _ThemeGate extends StatelessWidget {
  const _ThemeGate({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
