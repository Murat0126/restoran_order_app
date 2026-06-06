import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Семантический вариант чипа.
enum AppChipVariant {
  /// Нейтральный тег (категория, метка блюда).
  neutral,

  /// Акцент / выбранный фильтр.
  accent,

  /// Успех (готово, оплачено).
  success,

  /// Ожидание / в работе.
  warning,

  /// Ошибка / отмена.
  error,
}

/// Чип / тег на токенах темы.
///
/// [selected] — для фильтров меню (акцентная заливка).
/// [onDeleted] — если задан, показывается крестик (фильтр снять).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.neutral,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.icon,
  });

  final String label;
  final AppChipVariant variant;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final (bg, fg) = _colors(s, variant, selected);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(s.radii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radii.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.md,
            vertical: s.spacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: c.iconXs, color: fg),
                SizedBox(width: s.spacing.xs),
              ],
              Text(
                label,
                style: s.typography.labelCaps.copyWith(color: fg),
              ),
              if (onDeleted != null) ...[
                SizedBox(width: s.spacing.xs),
                InkWell(
                  onTap: onDeleted,
                  borderRadius: BorderRadius.circular(s.radii.full),
                  child: Icon(Icons.close, size: c.iconXs, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg) _colors(
    AppTheme s,
    AppChipVariant variant,
    bool selected,
  ) {
    final p = s.palette;
    if (selected) return (p.primaryContainer, p.onPrimaryContainer);
    return switch (variant) {
      AppChipVariant.neutral =>
        (p.surfaceContainerHigh, p.onSurface),
      AppChipVariant.accent =>
        (p.secondaryContainer, p.onSecondaryContainer),
      AppChipVariant.success =>
        (p.tertiaryContainer, p.onTertiaryContainer),
      AppChipVariant.warning =>
        (p.errorContainer.withValues(alpha: 0.6), p.onErrorContainer),
      AppChipVariant.error => (p.errorContainer, p.onErrorContainer),
    };
  }
}
