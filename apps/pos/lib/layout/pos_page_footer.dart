import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'pos_server_status_badge.dart';

/// Нижняя строка экрана логина: версия + статус сервера (Stitch 2.1).
class PosPageFooter extends ConsumerWidget {
  const PosPageFooter({super.key, this.version = '0.1.0'});

  final String version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.all(s.spacing.lg),
      child: Row(
        children: [
          Text(
            l10n.appVersionLabel(version),
            style: s.typography.bodySmall.copyWith(
              color: s.palette.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          const PosServerStatusBadge(),
        ],
      ),
    );
  }
}
