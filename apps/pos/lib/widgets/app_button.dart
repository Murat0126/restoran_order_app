import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Вариант кнопки design-system.
enum AppButtonVariant {
  /// Primary — `FilledButton`, основное действие.
  primary,

  /// Secondary — `FilledButton.tonal`, вторичное действие.
  secondary,

  /// Outlined — граница, без заливки.
  outlined,

  /// Text — без фона, только текст.
  text,

  /// Destructive — опасное действие (отмена заказа, удаление).
  destructive,
}

enum AppButtonSize { sm, md, lg }

/// Кнопка на токенах [AppTheme]. Оборачивает M3-кнопки с единым
/// API для всех feature-экранов.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  /// Текстовая кнопка на всю ширину (формы, bottom sheets).
  const AppButton.fullWidth({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
  }) : fullWidth = true;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    final c = s.components;
    final enabled = onPressed != null && !isLoading;

    final (height, iconSize) = switch (size) {
      AppButtonSize.sm => (c.buttonHeightSm, c.iconSm),
      AppButtonSize.md => (c.buttonHeightMd, c.iconMd),
      AppButtonSize.lg => (c.buttonHeightLg, c.iconLg),
    };

    final child = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _spinnerColor(variant, p),
            ),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: iconSize),
                  SizedBox(width: s.spacing.sm),
                  Text(label),
                ],
              )
            : Text(label));

    final minSize = Size(fullWidth ? double.infinity : 0, height);

    Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: p.primary,
            foregroundColor: p.onPrimary,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: p.secondaryContainer,
            foregroundColor: p.onSecondaryContainer,
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            foregroundColor: p.primary,
            side: BorderSide(color: p.outlineVariant),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: minSize,
            foregroundColor: p.primary,
          ),
          child: child,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: p.error,
            foregroundColor: p.onError,
          ),
          child: child,
        ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _spinnerColor(AppButtonVariant v, AppPalette p) => switch (v) {
        AppButtonVariant.primary => p.onPrimary,
        AppButtonVariant.secondary => p.onSecondaryContainer,
        AppButtonVariant.destructive => p.onError,
        _ => p.primary,
      };
}
