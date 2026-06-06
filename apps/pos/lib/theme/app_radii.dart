import 'package:flutter/widgets.dart';

/// Радиусы скругления.
///
/// «Deep Forest»: 4 / 8 / 12 / 16 / 24 / full (мягкие, friendly)
/// «Hushed Luxury»: 2 / 4 / 6 / 8 / 12 / full (architectural precision)
///
/// Использовать как `BorderRadius.circular(r.lg)` либо
/// напрямую `r.lg` в `Radius.circular(...)`.
@immutable
class AppRadii {
  const AppRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    this.full = 9999,
  });

  /// Маленькие чипы, статусы.
  final double sm;

  /// Кнопки, инпуты — основа интерфейса.
  final double md;

  /// Карточки, контейнеры.
  final double lg;

  /// Модальные окна, акцентные блоки.
  final double xl;

  /// Pill / круг.
  final double full;

  AppRadii copyWith({double? sm, double? md, double? lg, double? xl, double? full}) {
    return AppRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }
}
