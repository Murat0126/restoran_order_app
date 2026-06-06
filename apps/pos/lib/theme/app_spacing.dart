import 'package:flutter/foundation.dart';

/// 8px-rhythm spacing scale + layout-уровни.
///
/// Слиты обе дизайн-системы:
/// — «Deep Forest»: xs/sm/md/lg/xl/xxl + container-padding + gutter
/// — «Hushed Luxury»: base / gutter / margin-mobile / margin-desktop / section-gap
///
/// Все значения в логических пикселях Flutter. Тип `double`,
/// чтобы можно было использовать напрямую в `EdgeInsets.all(s.md)`
/// и аналогах без приведения.
@immutable
class AppSpacing {
  const AppSpacing({
    required this.base,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.gutter,
    required this.containerPaddingMobile,
    required this.containerPaddingDesktop,
    required this.sectionGap,
  });

  /// Базовая единица rhythm-scale (обычно 4 или 8).
  final double base;

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Промежуток между колонками в гриде.
  final double gutter;

  /// Боковые отступы контейнера на мобильных устройствах.
  final double containerPaddingMobile;

  /// Боковые отступы контейнера на desktop / широкий планшет.
  final double containerPaddingDesktop;

  /// Большой вертикальный разрыв между секциями (для admin/director).
  final double sectionGap;

  AppSpacing copyWith({
    double? base,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? gutter,
    double? containerPaddingMobile,
    double? containerPaddingDesktop,
    double? sectionGap,
  }) {
    return AppSpacing(
      base: base ?? this.base,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      gutter: gutter ?? this.gutter,
      containerPaddingMobile:
          containerPaddingMobile ?? this.containerPaddingMobile,
      containerPaddingDesktop:
          containerPaddingDesktop ?? this.containerPaddingDesktop,
      sectionGap: sectionGap ?? this.sectionGap,
    );
  }
}
