/// Барреллл-экспорт всей системы темизации.
///
/// `import 'package:pos/theme/theme.dart';` — даёт сразу:
///   • [AppTheme] + [AppThemeScope] + extension `context.appTheme`
///   • токены: [AppPalette], [AppTypography] / [AppFontFamilies],
///     [AppSpacing], [AppRadii], [AppShadows]
///
/// JSON-парсер (F3.3) и провайдеры (F3.4) лежат отдельно
/// (`theme_loader.dart`, `theme_providers.dart`).
library;

export 'app_brand.dart';
export 'app_components.dart';
export 'app_layout.dart';
export 'app_palette.dart';
export 'app_semantic.dart';
export 'app_radii.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';
