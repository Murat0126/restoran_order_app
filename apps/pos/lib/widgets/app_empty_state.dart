import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// Пустое состояние списка / экрана.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: s.layout.loginCardMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(s.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: c.iconEmpty,
                color: s.palette.onSurfaceVariant,
              ),
              SizedBox(height: s.spacing.lg),
              Text(
                title,
                style: s.typography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: s.spacing.sm),
                Text(
                  subtitle!,
                  style: s.typography.bodyMedium.copyWith(
                    color: s.palette.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: s.spacing.lg),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
