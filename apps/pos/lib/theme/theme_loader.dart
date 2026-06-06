import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_brand.dart';
import 'app_components.dart';
import 'app_layout.dart';
import 'app_palette.dart';
import 'app_radii.dart';
import 'app_semantic.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_theme.dart';
import 'app_typography.dart';

/// Загружает [AppTheme] из JSON-файла в assets.
///
/// Формат JSON документирован в `docs/THEMING_GUIDE.md`. В двух словах:
/// корень содержит метаданные + `fontFamilies` + блоки `light` и `dark`.
/// Каждый блок описывает одну палитру + типографию + spacing + radii +
/// shadows. Если в `dark` указан `{ "derive": "fromSeed" }`, тёмная
/// палитра генерится из светлой через [ColorScheme.fromSeed].
class ThemeLoader {
  const ThemeLoader._();

  /// Загружает обе версии темы (light + dark) из одного JSON-файла.
  static Future<({AppTheme light, AppTheme dark})> loadFromAsset(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    return parseFromJson(raw);
  }

  /// Парсит JSON-строку. Выделен отдельно, чтобы можно было покрыть
  /// тестами без участия Flutter binding.
  static ({AppTheme light, AppTheme dark}) parseFromJson(String source) {
    final dynamic decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Корень JSON-темы должен быть объектом.',
      );
    }
    final root = decoded;

    final id = _requireString(root, 'id');
    final name = _requireString(root, 'name');

    final families = _parseFontFamilies(
      _requireMap(root, 'fontFamilies'),
    );

    final brand = _parseBrandRoot(root);
    final layout = _parseLayoutRoot(root);
    final components = _parseComponentsRoot(root);

    final lightMap = _requireMap(root, 'light');
    final darkMap = _requireMap(root, 'dark');

    final light = _buildTheme(
      id: id,
      name: name,
      brand: brand,
      layout: layout,
      components: components,
      families: families,
      block: lightMap,
      brightness: Brightness.light,
    );

    final AppTheme dark;
    if (_isDerived(darkMap)) {
      dark = _deriveDarkFromLight(
        light: light,
        directive: darkMap,
      );
    } else {
      dark = _buildTheme(
        id: id,
        name: name,
        brand: brand,
        layout: layout,
        components: components,
        families: families,
        block: darkMap,
        brightness: Brightness.dark,
      );
    }

    return (light: light, dark: dark);
  }

  // ────────────────────────────────────────────────────────────────────
  // Сборка темы из «полного» блока (light или dark с явной палитрой).
  // ────────────────────────────────────────────────────────────────────

  static AppTheme _buildTheme({
    required String id,
    required String name,
    required AppBrand brand,
    required AppLayout layout,
    required AppComponents components,
    required AppFontFamilies families,
    required Map<String, dynamic> block,
    required Brightness brightness,
  }) {
    final palette = _parsePalette(
      _requireMap(block, 'palette'),
      brightness: brightness,
    );
    final semantic = _parseSemantic(_requireMap(block, 'semantic'));
    final typography = _parseTypography(
      _requireMap(block, 'typography'),
      families: families,
    );
    final spacing = _parseSpacing(_requireMap(block, 'spacing'));
    final radii = _parseRadii(_requireMap(block, 'radii'));
    final shadows = _parseShadows(_requireMap(block, 'shadows'));

    return AppTheme(
      id: id,
      name: name,
      brand: brand,
      layout: layout,
      components: components,
      semantic: semantic,
      palette: palette,
      typography: typography,
      spacing: spacing,
      radii: radii,
      shadows: shadows,
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Авто-генерация dark из light через M3 fromSeed.
  // Радиусы / типография / spacing — наследуются от light без изменений.
  // ────────────────────────────────────────────────────────────────────

  static AppTheme _deriveDarkFromLight({
    required AppTheme light,
    required Map<String, dynamic> directive,
  }) {
    final strategy = (directive['derive'] as String?)?.trim() ?? 'fromSeed';
    if (strategy != 'fromSeed') {
      throw FormatException(
        'Неизвестная стратегия derive в dark: $strategy. '
        'Поддерживается только "fromSeed" или явная палитра.',
      );
    }
    final seed = light.palette.primary;
    final dark = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final palette = AppPalette(
      brightness: Brightness.dark,
      primary: dark.primary,
      onPrimary: dark.onPrimary,
      primaryContainer: dark.primaryContainer,
      onPrimaryContainer: dark.onPrimaryContainer,
      secondary: dark.secondary,
      onSecondary: dark.onSecondary,
      secondaryContainer: dark.secondaryContainer,
      onSecondaryContainer: dark.onSecondaryContainer,
      tertiary: dark.tertiary,
      onTertiary: dark.onTertiary,
      tertiaryContainer: dark.tertiaryContainer,
      onTertiaryContainer: dark.onTertiaryContainer,
      error: dark.error,
      onError: dark.onError,
      errorContainer: dark.errorContainer,
      onErrorContainer: dark.onErrorContainer,
      surface: dark.surface,
      onSurface: dark.onSurface,
      onSurfaceVariant: dark.onSurfaceVariant,
      surfaceDim: dark.surfaceDim,
      surfaceBright: dark.surfaceBright,
      surfaceContainerLowest: dark.surfaceContainerLowest,
      surfaceContainerLow: dark.surfaceContainerLow,
      surfaceContainer: dark.surfaceContainer,
      surfaceContainerHigh: dark.surfaceContainerHigh,
      surfaceContainerHighest: dark.surfaceContainerHighest,
      outline: dark.outline,
      outlineVariant: dark.outlineVariant,
      inverseSurface: dark.inverseSurface,
      onInverseSurface: dark.onInverseSurface,
      inversePrimary: dark.inversePrimary,
      surfaceTint: dark.surfaceTint,
      primaryFixed: dark.primaryFixed,
      primaryFixedDim: dark.primaryFixedDim,
      onPrimaryFixed: dark.onPrimaryFixed,
      onPrimaryFixedVariant: dark.onPrimaryFixedVariant,
      secondaryFixed: dark.secondaryFixed,
      secondaryFixedDim: dark.secondaryFixedDim,
      onSecondaryFixed: dark.onSecondaryFixed,
      onSecondaryFixedVariant: dark.onSecondaryFixedVariant,
      tertiaryFixed: dark.tertiaryFixed,
      tertiaryFixedDim: dark.tertiaryFixedDim,
      onTertiaryFixed: dark.onTertiaryFixed,
      onTertiaryFixedVariant: dark.onTertiaryFixedVariant,
      shadow: dark.shadow,
      scrim: dark.scrim,
    );
    return light.copyWith(palette: palette);
  }

  static bool _isDerived(Map<String, dynamic> block) =>
      block.containsKey('derive');

  // ────────────────────────────────────────────────────────────────────
  // Парсеры отдельных секций.
  // ────────────────────────────────────────────────────────────────────

  static AppFontFamilies _parseFontFamilies(Map<String, dynamic> m) {
    return AppFontFamilies(
      heading: _requireString(m, 'heading'),
      body: _requireString(m, 'body'),
      fallback: (m['fallback'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }

  static AppPalette _parsePalette(
    Map<String, dynamic> m, {
    required Brightness brightness,
  }) {
    Color c(String key) => _requireHex(m, key);
    return AppPalette(
      brightness: brightness,
      primary: c('primary'),
      onPrimary: c('onPrimary'),
      primaryContainer: c('primaryContainer'),
      onPrimaryContainer: c('onPrimaryContainer'),
      secondary: c('secondary'),
      onSecondary: c('onSecondary'),
      secondaryContainer: c('secondaryContainer'),
      onSecondaryContainer: c('onSecondaryContainer'),
      tertiary: c('tertiary'),
      onTertiary: c('onTertiary'),
      tertiaryContainer: c('tertiaryContainer'),
      onTertiaryContainer: c('onTertiaryContainer'),
      error: c('error'),
      onError: c('onError'),
      errorContainer: c('errorContainer'),
      onErrorContainer: c('onErrorContainer'),
      surface: c('surface'),
      onSurface: c('onSurface'),
      onSurfaceVariant: c('onSurfaceVariant'),
      surfaceDim: c('surfaceDim'),
      surfaceBright: c('surfaceBright'),
      surfaceContainerLowest: c('surfaceContainerLowest'),
      surfaceContainerLow: c('surfaceContainerLow'),
      surfaceContainer: c('surfaceContainer'),
      surfaceContainerHigh: c('surfaceContainerHigh'),
      surfaceContainerHighest: c('surfaceContainerHighest'),
      outline: c('outline'),
      outlineVariant: c('outlineVariant'),
      inverseSurface: c('inverseSurface'),
      onInverseSurface: c('onInverseSurface'),
      inversePrimary: c('inversePrimary'),
      surfaceTint: c('surfaceTint'),
      primaryFixed: c('primaryFixed'),
      primaryFixedDim: c('primaryFixedDim'),
      onPrimaryFixed: c('onPrimaryFixed'),
      onPrimaryFixedVariant: c('onPrimaryFixedVariant'),
      secondaryFixed: c('secondaryFixed'),
      secondaryFixedDim: c('secondaryFixedDim'),
      onSecondaryFixed: c('onSecondaryFixed'),
      onSecondaryFixedVariant: c('onSecondaryFixedVariant'),
      tertiaryFixed: c('tertiaryFixed'),
      tertiaryFixedDim: c('tertiaryFixedDim'),
      onTertiaryFixed: c('onTertiaryFixed'),
      onTertiaryFixedVariant: c('onTertiaryFixedVariant'),
      shadow: _optionalHex(m, 'shadow') ?? const Color(0xFF000000),
      scrim: _optionalHex(m, 'scrim') ?? const Color(0xFF000000),
    );
  }

  static AppTypography _parseTypography(
    Map<String, dynamic> m, {
    required AppFontFamilies families,
  }) {
    // Базовые 6 ролей всегда обязательны (это пересечение обеих
    // дизайн-систем). Остальные 3 — производные либо явные.
    final headlineLarge = _parseTextStyle(
      _requireMap(m, 'headlineLarge'),
      family: families.heading,
    );
    final headlineLargeMobile = _parseTextStyle(
      _requireMap(m, 'headlineLargeMobile'),
      family: families.heading,
    );
    final bodyLarge = _parseTextStyle(
      _requireMap(m, 'bodyLarge'),
      family: families.body,
    );
    final bodyMedium = _parseTextStyle(
      _requireMap(m, 'bodyMedium'),
      family: families.body,
    );
    final labelMd = _parseTextStyle(
      _requireMap(m, 'labelStrong'),
      family: families.body,
    );

    final headlineMedium = m['headlineMedium'] is Map<String, dynamic>
        ? _parseTextStyle(
            m['headlineMedium'] as Map<String, dynamic>,
            family: families.heading,
          )
        : null;
    final headlineSmall = m['headlineSmall'] is Map<String, dynamic>
        ? _parseTextStyle(
            m['headlineSmall'] as Map<String, dynamic>,
            family: families.heading,
          )
        : null;
    final bodySmall = m['bodySmall'] is Map<String, dynamic>
        ? _parseTextStyle(
            m['bodySmall'] as Map<String, dynamic>,
            family: families.body,
          )
        : null;
    final labelCaps = m['labelCaps'] is Map<String, dynamic>
        ? _parseTextStyle(
            m['labelCaps'] as Map<String, dynamic>,
            family: families.body,
          )
        : null;

    final derived = AppTypography.deriveFromCore(
      families: families,
      headlineLarge: headlineLarge,
      headlineLargeMobile: headlineLargeMobile,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelMd: labelMd,
    );

    return derived.copyWith(
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodySmall: bodySmall,
      labelCaps: labelCaps,
    );
  }

  static TextStyle _parseTextStyle(
    Map<String, dynamic> m, {
    required String family,
  }) {
    final fontSize = _requireDouble(m, 'size');
    final weight = _parseFontWeight(m['weight']);
    final height = m['height'] is num ? (m['height'] as num).toDouble() : null;
    final letterSpacing = m['letterSpacing'] is num
        ? (m['letterSpacing'] as num).toDouble()
        : null;
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static FontWeight _parseFontWeight(dynamic v) {
    if (v is num) {
      return FontWeight.values.firstWhere(
        (w) => w.value == v.toInt(),
        orElse: () => FontWeight.w400,
      );
    }
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return _parseFontWeight(n);
    }
    return FontWeight.w400;
  }

  static AppSpacing _parseSpacing(Map<String, dynamic> m) {
    double d(String k, {double? fallback}) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (fallback != null) return fallback;
      throw FormatException('spacing.$k обязателен.');
    }

    final base = d('base', fallback: 8);
    return AppSpacing(
      base: base,
      xs: d('xs', fallback: base / 2),
      sm: d('sm', fallback: base),
      md: d('md', fallback: base * 2),
      lg: d('lg', fallback: base * 3),
      xl: d('xl', fallback: base * 4),
      xxl: d('xxl', fallback: base * 6),
      gutter: d('gutter', fallback: base * 2),
      containerPaddingMobile: d('containerPaddingMobile', fallback: 16),
      containerPaddingDesktop: d('containerPaddingDesktop', fallback: 64),
      sectionGap: d('sectionGap', fallback: 80),
    );
  }

  static AppRadii _parseRadii(Map<String, dynamic> m) {
    double d(String k, double fallback) {
      final v = m[k];
      if (v is num) return v.toDouble();
      return fallback;
    }

    return AppRadii(
      sm: d('sm', 4),
      md: d('md', 8),
      lg: d('lg', 12),
      xl: d('xl', 16),
      full: d('full', 9999),
    );
  }

  static AppShadows _parseShadows(Map<String, dynamic> m) {
    List<BoxShadow> list(String key) {
      final raw = m[key];
      if (raw is! List) return const <BoxShadow>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(_parseShadow)
          .toList(growable: false);
    }

    return AppShadows(
      level0: list('level0'),
      level1: list('level1'),
      level2: list('level2'),
      navBar: list('navBar'),
    );
  }

  /// Корневой `brand`: объект или legacy-строка (только имя продукта).
  static AppBrand _parseBrandRoot(Map<String, dynamic> root) {
    final v = root['brand'];
    if (v is String && v.isNotEmpty) {
      return AppBrand(productName: v, loginHeroImageUrl: '');
    }
    if (v is Map) {
      return _parseBrand(Map<String, dynamic>.from(v));
    }
    throw const FormatException(
      'Поле "brand" обязательно (object или string).',
    );
  }

  static AppBrand _parseBrand(Map<String, dynamic> m) {
    final hero = m['loginHeroImageUrl'];
    return AppBrand(
      productName: _requireString(m, 'productName'),
      loginHeroImageUrl: hero is String ? hero : '',
    );
  }

  static AppComponents _parseComponentsRoot(Map<String, dynamic> root) {
    final v = root['components'];
    if (v is Map) {
      return _parseComponents(Map<String, dynamic>.from(v));
    }
    return AppComponents.defaults;
  }

  static AppComponents _parseComponents(Map<String, dynamic> m) {
    double d(String key, double fallback) =>
        m.containsKey(key) ? _requireDouble(m, key) : fallback;
    final dflt = AppComponents.defaults;
    return AppComponents(
      iconXs: d('iconXs', dflt.iconXs),
      iconSm: d('iconSm', dflt.iconSm),
      iconMd: d('iconMd', dflt.iconMd),
      iconLg: d('iconLg', dflt.iconLg),
      iconXl: d('iconXl', dflt.iconXl),
      icon2xl: d('icon2xl', dflt.icon2xl),
      iconEmpty: d('iconEmpty', dflt.iconEmpty),
      navBrandSize: d('navBrandSize', dflt.navBrandSize),
      navBrandIconSize: d('navBrandIconSize', dflt.navBrandIconSize),
      navItemIconSize: d('navItemIconSize', dflt.navItemIconSize),
      quickAddSize: d('quickAddSize', dflt.quickAddSize),
      guestControlSize: d('guestControlSize', dflt.guestControlSize),
      headerDividerHeight: d('headerDividerHeight', dflt.headerDividerHeight),
      dividerThickness: d('dividerThickness', dflt.dividerThickness),
      statusDotSm: d('statusDotSm', dflt.statusDotSm),
      statusDotMd: d('statusDotMd', dflt.statusDotMd),
      microFontSize: d('microFontSize', dflt.microFontSize),
      categoryIconSize: d('categoryIconSize', dflt.categoryIconSize),
      categorySectionLetterSpacing: d(
        'categorySectionLetterSpacing',
        dflt.categorySectionLetterSpacing,
      ),
      systemFooterHeight: d('systemFooterHeight', dflt.systemFooterHeight),
      buttonHeightSm: d('buttonHeightSm', dflt.buttonHeightSm),
      buttonHeightMd: d('buttonHeightMd', dflt.buttonHeightMd),
      buttonHeightLg: d('buttonHeightLg', dflt.buttonHeightLg),
      dishSheetImageSize: d('dishSheetImageSize', dflt.dishSheetImageSize),
      dishSheetImageHeightNarrow: d(
        'dishSheetImageHeightNarrow',
        dflt.dishSheetImageHeightNarrow,
      ),
      notificationBadgeFontSize: d(
        'notificationBadgeFontSize',
        dflt.notificationBadgeFontSize,
      ),
      ordersTwoColumnBreakpoint: d(
        'ordersTwoColumnBreakpoint',
        dflt.ordersTwoColumnBreakpoint,
      ),
      navActiveOpacity: d('navActiveOpacity', dflt.navActiveOpacity),
      emptyStateIconSize: d('emptyStateIconSize', dflt.emptyStateIconSize),
    );
  }

  static AppLayout _parseLayoutRoot(Map<String, dynamic> root) {
    final v = root['layout'];
    if (v is Map) {
      return _parseLayout(Map<String, dynamic>.from(v));
    }
    return AppLayout.defaults;
  }

  static AppLayout _parseLayout(Map<String, dynamic> m) {
    final cols = _requireMap(m, 'gridColumns');
    final bp = _requireMap(m, 'breakpoints');
    double d(String key) => _requireDouble(m, key);
    int i(String key) => _requireDouble(cols, key).round();

    return AppLayout(
      sideNavWidth: d('sideNavWidth'),
      headerHeight: d('headerHeight'),
      selectionFooterHeight: d('selectionFooterHeight'),
      tableCardHeight: d('tableCardHeight'),
      headerPaddingH: d('headerPaddingH'),
      headerTitleTabsGap: d('headerTitleTabsGap'),
      hallTabsGap: d('hallTabsGap'),
      gridPadding: d('gridPadding'),
      gridGap: d('gridGap'),
      tableSelectionOutlineWidth: d('tableSelectionOutlineWidth'),
      breakpointMd: _requireDouble(bp, 'md'),
      breakpointLg: _requireDouble(bp, 'lg'),
      breakpointXl: _requireDouble(bp, 'xl'),
      gridColumnsSm: i('sm'),
      gridColumnsMd: i('md'),
      gridColumnsLg: i('lg'),
      gridColumnsXl: i('xl'),
      cartPanelWidth: d('cartPanelWidth'),
      categoryRailWidth: d('categoryRailWidth'),
      responsiveWideBreakpoint: d('responsiveWideBreakpoint'),
      loginCardMaxWidth: d('loginCardMaxWidth'),
      orderCardHeight: m.containsKey('orderCardHeight')
          ? d('orderCardHeight')
          : AppLayout.defaults.orderCardHeight,
      dishCardHeight: m.containsKey('dishCardHeight')
          ? d('dishCardHeight')
          : AppLayout.defaults.dishCardHeight,
      dishImageHeight: m.containsKey('dishImageHeight')
          ? d('dishImageHeight')
          : AppLayout.defaults.dishImageHeight,
      dishGridColumns: m.containsKey('dishGridColumns')
          ? d('dishGridColumns').round()
          : AppLayout.defaults.dishGridColumns,
      orderNarrowBreakpoint: m.containsKey('orderNarrowBreakpoint')
          ? d('orderNarrowBreakpoint')
          : AppLayout.defaults.orderNarrowBreakpoint,
    );
  }

  static SemanticColorPair _parsePair(Map<String, dynamic> m, String key) {
    final map = _requireMap(m, key);
    return SemanticColorPair(
      background: _requireHex(map, 'background'),
      foreground: _requireHex(map, 'foreground'),
    );
  }

  static AppSemantic _parseSemantic(Map<String, dynamic> m) {
    final table = _requireMap(m, 'table');
    final order = _requireMap(m, 'order');
    return AppSemantic(
      statusOnline: _requireHex(m, 'statusOnline'),
      orderCookingAccent: _requireHex(m, 'orderCookingAccent'),
      tableFree: _parsePair(table, 'free'),
      tableOccupied: _parsePair(table, 'occupied'),
      tableOrderAccepted: _parsePair(table, 'orderAccepted'),
      tablePendingPayment: _parsePair(table, 'pendingPayment'),
      tableNeedsCleaning: _parsePair(table, 'needsCleaning'),
      tableVacated: _parsePair(table, 'vacated'),
      tableQrPreorder: _parsePair(table, 'qrPreorder'),
      orderCooking: _parsePair(order, 'cooking'),
      orderReady: _parsePair(order, 'ready'),
      orderPayment: _parsePair(order, 'payment'),
    );
  }

  static BoxShadow _parseShadow(Map<String, dynamic> m) {
    final color = _optionalHex(m, 'color') ?? const Color(0xFF000000);
    final opacity = m['opacity'] is num
        ? (m['opacity'] as num).toDouble().clamp(0.0, 1.0)
        : 1.0;
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: Offset(
        m['x'] is num ? (m['x'] as num).toDouble() : 0,
        m['y'] is num ? (m['y'] as num).toDouble() : 0,
      ),
      blurRadius:
          m['blur'] is num ? (m['blur'] as num).toDouble() : 0,
      spreadRadius:
          m['spread'] is num ? (m['spread'] as num).toDouble() : 0,
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Низкоуровневые helpers.
  // ────────────────────────────────────────────────────────────────────

  static String _requireString(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('Поле "$key" обязательно (string).');
  }

  static Map<String, dynamic> _requireMap(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is Map) return Map<String, dynamic>.from(v);
    throw FormatException('Поле "$key" обязательно (object).');
  }

  static double _requireDouble(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    throw FormatException('Поле "$key" обязательно (number).');
  }

  static Color _requireHex(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String) return _hexToColor(v);
    throw FormatException('Поле "$key" должно быть hex-строкой (#rrggbb).');
  }

  static Color? _optionalHex(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String) return _hexToColor(v);
    return null;
  }

  static Color _hexToColor(String hex) {
    var clean = hex.trim();
    if (clean.startsWith('#')) clean = clean.substring(1);
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) {
      throw FormatException('Невалидный hex-цвет: "$hex".');
    }
    final value = int.tryParse(clean, radix: 16);
    if (value == null) {
      throw FormatException('Невалидный hex-цвет: "$hex".');
    }
    return Color(value);
  }
}
