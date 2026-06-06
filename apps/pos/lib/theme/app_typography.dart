import 'package:flutter/material.dart';

/// Семейство шрифтов в теме.
///
/// В JSON-теме приходят строки-имена (`Inter`, `Manrope`...),
/// здесь — реальные [TextStyle.fontFamily] для Flutter.
/// Подключение шрифтов делается через `flutter/google_fonts` или
/// собственный набор `.ttf` в `assets/fonts/`.
@immutable
class AppFontFamilies {
  const AppFontFamilies({
    required this.heading,
    required this.body,
    this.fallback = const <String>[],
  });

  /// Семейство для заголовков (headline-*).
  final String heading;

  /// Семейство для тела и подписей (body-*, label-*).
  final String body;

  /// Резерв на случай отсутствия шрифта (например при offline).
  final List<String> fallback;

  AppFontFamilies copyWith({
    String? heading,
    String? body,
    List<String>? fallback,
  }) {
    return AppFontFamilies(
      heading: heading ?? this.heading,
      body: body ?? this.body,
      fallback: fallback ?? this.fallback,
    );
  }
}

/// Семантическая типография приложения.
///
/// 9 ролей — выровнены под классы из Stitch HTML, чтобы при
/// портировании экранов был ровно один способ выбрать стиль:
///
/// | Роль              | Старая «Deep Forest» | Новая «Hushed Luxury» |
/// |-------------------|----------------------|------------------------|
/// | headlineLarge     | Inter 32/600         | Manrope 32/500         |
/// | headlineLargeMobile | Inter 28/600       | Manrope 28/500         |
/// | headlineMedium    | Inter 24/600         | Manrope 24/500 (производное) |
/// | headlineSmall     | Inter 20/500         | Manrope 20/500 (производное) |
/// | bodyLarge         | Inter 18/400         | Inter 18/400           |
/// | bodyMedium        | Inter 16/400         | Inter 16/400           |
/// | bodySmall         | Inter 14/400         | Inter 14/400 (производное) |
/// | labelStrong       | Inter 14/600         | Inter 14/600 (= label-md) |
/// | labelCaps         | Inter 12/700 UPPER   | Inter 12/700 UPPER (производное) |
///
/// Если JSON-тема не указывает «производные» роли — они
/// генерятся из базовых правилами в [AppTypography.deriveFromCore].
@immutable
class AppTypography {
  const AppTypography({
    required this.families,
    required this.headlineLarge,
    required this.headlineLargeMobile,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelStrong,
    required this.labelCaps,
  });

  final AppFontFamilies families;

  final TextStyle headlineLarge;
  final TextStyle headlineLargeMobile;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelStrong;
  final TextStyle labelCaps;

  /// Конвертация в Material 3 [TextTheme].
  ///
  /// Маппинг сделан так, чтобы стандартные `Theme.of(context).textTheme.*`
  /// тоже работали — на случай, если где-то используется голый Material
  /// виджет (`ListTile`, `AppBar` и т.п.).
  TextTheme toTextTheme({Color? color}) {
    Color? merge(Color? c) => color;
    return TextTheme(
      displayLarge: headlineLarge.copyWith(color: merge(color)),
      displayMedium: headlineLarge.copyWith(color: merge(color)),
      displaySmall: headlineMedium.copyWith(color: merge(color)),
      headlineLarge: headlineLarge.copyWith(color: merge(color)),
      headlineMedium: headlineMedium.copyWith(color: merge(color)),
      headlineSmall: headlineSmall.copyWith(color: merge(color)),
      titleLarge: headlineSmall.copyWith(color: merge(color)),
      titleMedium: labelStrong.copyWith(
        fontSize: 16,
        height: 1.4,
        color: merge(color),
      ),
      titleSmall: labelStrong.copyWith(color: merge(color)),
      bodyLarge: bodyLarge.copyWith(color: merge(color)),
      bodyMedium: bodyMedium.copyWith(color: merge(color)),
      bodySmall: bodySmall.copyWith(color: merge(color)),
      labelLarge: labelStrong.copyWith(color: merge(color)),
      labelMedium: labelStrong.copyWith(
        fontSize: 12,
        height: 1.2,
        color: merge(color),
      ),
      labelSmall: labelCaps.copyWith(color: merge(color)),
    );
  }

  AppTypography copyWith({
    AppFontFamilies? families,
    TextStyle? headlineLarge,
    TextStyle? headlineLargeMobile,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelStrong,
    TextStyle? labelCaps,
  }) {
    return AppTypography(
      families: families ?? this.families,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineLargeMobile: headlineLargeMobile ?? this.headlineLargeMobile,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelStrong: labelStrong ?? this.labelStrong,
      labelCaps: labelCaps ?? this.labelCaps,
    );
  }

  /// Производит набор «производных» стилей по правилам семейств,
  /// если JSON-тема указала только базовые 6 ролей.
  ///
  /// Используется в JSON-парсере (F3.3) для тем уровня
  /// «Hushed Luxury», где DESIGN.md описывает 6 ролей,
  /// а Stitch HTML использует 9.
  static AppTypography deriveFromCore({
    required AppFontFamilies families,
    required TextStyle headlineLarge,
    required TextStyle headlineLargeMobile,
    required TextStyle bodyLarge,
    required TextStyle bodyMedium,
    required TextStyle labelMd,
  }) {
    final headingFamily = families.heading;
    final bodyFamily = families.body;
    return AppTypography(
      families: families,
      headlineLarge: headlineLarge,
      headlineLargeMobile: headlineLargeMobile,
      headlineMedium: TextStyle(
        fontFamily: headingFamily,
        fontSize: 24,
        fontWeight: headlineLarge.fontWeight ?? FontWeight.w500,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: headingFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelStrong: labelMd,
      labelCaps: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.6, // 0.05em ≈ 0.6 при 12px
      ),
    );
  }
}
