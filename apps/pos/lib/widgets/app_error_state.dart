import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// Состояние ошибки загрузки с опциональным retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  /// Если null — берётся из l10n в месте вызова (передаётся снаружи).
  final String? retryLabel;

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
                Icons.cloud_off_outlined,
                size: c.iconEmpty,
                color: s.palette.error,
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
              if (onRetry != null && retryLabel != null) ...[
                SizedBox(height: s.spacing.lg),
                AppButton(
                  label: retryLabel!,
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  variant: AppButtonVariant.outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
