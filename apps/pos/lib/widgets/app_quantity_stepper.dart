import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppQuantityStepperSize { compact, large }

/// Степпер количества (минус / значение / плюс).
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.value,
    this.onDecrement,
    this.onIncrement,
    this.min = 1,
    this.enabled = true,
    this.size = AppQuantityStepperSize.compact,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final int min;
  final bool enabled;
  final AppQuantityStepperSize size;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final large = size == AppQuantityStepperSize.large;
    final stepSize = large ? c.buttonHeightMd : c.guestControlSize - s.spacing.xs;
    final canDec = enabled && value > min && onDecrement != null;
    final canInc = enabled && onIncrement != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: large ? s.palette.surfaceContainerLow : null,
        border: Border.all(color: s.palette.outlineVariant),
        borderRadius: BorderRadius.circular(large ? s.radii.lg : s.radii.sm),
      ),
      child: Padding(
        padding: large ? EdgeInsets.all(s.spacing.xs) : EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              size: stepSize,
              icon: Icons.remove,
              large: large,
              onPressed: canDec ? onDecrement : null,
            ),
            SizedBox(
              width: large ? s.spacing.xl : stepSize,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: large
                    ? s.typography.headlineSmall
                    : s.typography.labelStrong,
              ),
            ),
            _StepButton(
              size: stepSize,
              icon: Icons.add,
              large: large,
              onPressed: canInc ? onIncrement : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.size,
    required this.icon,
    required this.large,
    this.onPressed,
  });

  final double size;
  final IconData icon;
  final bool large;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final enabled = onPressed != null;

    if (large) {
      return Material(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(s.radii.lg),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: c.iconMd,
              color: enabled ? s.palette.primary : s.palette.outline,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: c.iconSm),
        color: enabled ? s.palette.primary : s.palette.outline,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
