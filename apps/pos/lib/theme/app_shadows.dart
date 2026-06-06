import 'package:flutter/material.dart';

/// Уровни elevation для тонального слоения.
///
/// Обе дизайн-системы избегают «жёстких» теней. Используем 3 уровня:
///
/// - **level0** — нет тени, базовый фон.
/// - **level1** — `0 4px 20px rgba(0,0,0,0.04..0.10)` — карточки.
/// - **level2** — `0 10..12px 30..40px rgba(0,0,0,0.08..0.10)` — модалки.
@immutable
class AppShadows {
  const AppShadows({
    required this.level1,
    required this.level2,
    this.level0 = const <BoxShadow>[],
    this.navBar = const <BoxShadow>[],
  });

  /// Базовый фон — теней нет.
  final List<BoxShadow> level0;

  /// Карточки, контейнеры.
  final List<BoxShadow> level1;

  /// Модалки, поповеры.
  final List<BoxShadow> level2;

  /// Боковая панель (лёгкая elevation).
  final List<BoxShadow> navBar;

  AppShadows copyWith({
    List<BoxShadow>? level0,
    List<BoxShadow>? level1,
    List<BoxShadow>? level2,
    List<BoxShadow>? navBar,
  }) {
    return AppShadows(
      level0: level0 ?? this.level0,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      navBar: navBar ?? this.navBar,
    );
  }
}
