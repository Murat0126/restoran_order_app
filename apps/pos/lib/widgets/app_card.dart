import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Уровень «подъёма» карточки — соответствует `AppShadows.level*`.
enum AppCardLevel {
  /// Без тени — плоская панель.
  flat,

  /// Стандартная карточка (level1).
  elevated,

  /// Модальные / важные блоки (level2).
  raised,
}

/// Карточка на токенах темы: surface + радиус + тень.
///
/// Используйте вместо ручного `Container` + `BoxDecoration` в
/// feature-экранах — так white-label тени и радиусы подтянутся
/// из JSON автоматически.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.level = AppCardLevel.elevated,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final AppCardLevel level;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    final shadows = switch (level) {
      AppCardLevel.flat => s.shadows.level0,
      AppCardLevel.elevated => s.shadows.level1,
      AppCardLevel.raised => s.shadows.level2,
    };

    final content = Padding(
      padding: padding ?? EdgeInsets.all(s.spacing.lg),
      child: child,
    );

    final box = Container(
      decoration: BoxDecoration(
        color: color ?? p.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: shadows,
        border: border,
      ),
      child: content,
    );

    if (onTap == null) return box;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: box,
      ),
    );
  }
}
