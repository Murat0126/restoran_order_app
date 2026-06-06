import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

/// 404 — попали на несуществующий маршрут.
///
/// Используется как `errorBuilder` в GoRouter.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: s.palette.surface,
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(s.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.signpost_outlined,
                size: c.iconEmpty,
                color: s.palette.onSurfaceVariant,
              ),
              SizedBox(height: s.spacing.lg),
              Text(
                l10n.notFoundTitle,
                style: s.typography.headlineMedium,
              ),
              SizedBox(height: s.spacing.sm),
              Text(
                l10n.notFoundBody(path),
                style: s.typography.bodyMedium.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: s.spacing.lg),
              AppButton.fullWidth(
                label: l10n.actionGoHome,
                icon: Icons.home_outlined,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
