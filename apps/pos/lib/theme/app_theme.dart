import 'package:flutter/material.dart';

import 'app_brand.dart';
import 'app_components.dart';
import 'app_layout.dart';
import 'app_palette.dart';
import 'app_radii.dart';
import 'app_semantic.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Полный пакет токенов одной темы клиента в одном из режимов.
///
/// Создаётся из JSON-файла (`assets/themes/<id>.json`) на этапе F3.3.
/// Конвертируется в [ThemeData] методом [toMaterialThemeData].
@immutable
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.brand,
    required this.layout,
    required this.components,
    required this.semantic,
    required this.palette,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.shadows,
  });

  /// Машинный id (`default`, `hushed_luxury`...). Используется
  /// в SharedPreferences и API-вызовах брендирования.
  final String id;

  /// Человекочитаемое имя из JSON-темы.
  final String name;

  final AppBrand brand;
  final AppLayout layout;
  final AppComponents components;
  final AppSemantic semantic;

  final AppPalette palette;
  final AppTypography typography;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppShadows shadows;

  Brightness get brightness => palette.brightness;

  /// Конвертация в Material 3 [ThemeData].
  ///
  /// Используется в `MaterialApp.theme` / `darkTheme`. Все остальные
  /// токены, которые не покрываются [ThemeData] (`spacing`, `shadows`),
  /// доставляются через `InheritedWidget` (`AppThemeScope`).
  ThemeData toMaterialThemeData() {
    final scheme = palette.toColorScheme();
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      // Используем `Theme.of(context).textTheme` для голых
      // Material-виджетов; цвет — onSurface.
      textTheme: typography.toTextTheme(color: scheme.onSurface),
      primaryTextTheme:
          typography.toTextTheme(color: scheme.onPrimary),
      fontFamily: typography.families.body,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headlineSmall.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: typography.labelStrong,
          minimumSize: Size.fromHeight(components.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: typography.labelStrong,
          minimumSize: Size.fromHeight(components.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: typography.labelStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle:
            typography.labelStrong.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: typography.bodyMedium.copyWith(color: scheme.outline),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondaryContainer,
        labelStyle: typography.labelCaps.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm),
        ),
        padding:
            EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            typography.bodyMedium.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
        ),
      ),
    );
  }

  AppTheme copyWith({
    String? id,
    String? name,
    AppBrand? brand,
    AppLayout? layout,
    AppComponents? components,
    AppSemantic? semantic,
    AppPalette? palette,
    AppTypography? typography,
    AppSpacing? spacing,
    AppRadii? radii,
    AppShadows? shadows,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      layout: layout ?? this.layout,
      components: components ?? this.components,
      semantic: semantic ?? this.semantic,
      palette: palette ?? this.palette,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      shadows: shadows ?? this.shadows,
    );
  }
}

/// `InheritedWidget` для доставки [AppTheme] до любого виджета
/// без необходимости таскать его через конструкторы.
///
/// В виджете:
/// ```dart
/// final theme = AppThemeScope.of(context);
/// Container(padding: EdgeInsets.all(theme.spacing.md), ...);
/// ```
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final AppTheme theme;

  static AppTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in widget tree');
    return scope!.theme;
  }

  /// Не-listening вариант — для одноразовых чтений без подписки.
  static AppTheme read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in widget tree');
    return scope!.theme;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      !identical(theme, oldWidget.theme);
}

/// Удобный extension для `context.appTheme` / `context.appSpacing`.
extension AppThemeContextX on BuildContext {
  AppTheme get appTheme => AppThemeScope.of(this);
  AppSpacing get appSpacing => appTheme.spacing;
  AppRadii get appRadii => appTheme.radii;
  AppShadows get appShadows => appTheme.shadows;
  AppTypography get appType => appTheme.typography;
  AppPalette get appPalette => appTheme.palette;
  AppBrand get appBrand => appTheme.brand;
  AppLayout get appLayout => appTheme.layout;
  AppComponents get appComponents => appTheme.components;
  AppSemantic get appSemantic => appTheme.semantic;
}
