import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime/realtime_providers.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Бейдж «Сервер: онлайн / офлайн» (Stitch 2.1).
class PosServerStatusBadge extends ConsumerWidget {
  const PosServerStatusBadge({
    super.key,
    this.compact = false,
    this.hideIndicator = false,
    this.compactText = false,
  });

  final bool compact;
  final bool hideIndicator;
  /// Текст 12px label-strong (Stitch login footer).
  final bool compactText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final status = ref.watch(realtimeStatusProvider).valueOrNull ??
        RealtimeStatus.disconnected;

    final online = status == RealtimeStatus.connected;
    final color = online ? s.palette.tertiary : s.palette.error;
    final label = l10n.loginServerStatus(online ? l10n.connectionConnected : l10n.connectionDisconnected);

    final textStyle = compactText
        ? s.typography.labelCaps.copyWith(
            fontSize: s.components.microFontSize,
            color: s.palette.onSurfaceVariant,
          )
        : s.typography.bodySmall.copyWith(
            color: s.palette.onSurfaceVariant,
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hideIndicator)
          Container(
            width: s.components.statusDotMd,
            height: s.components.statusDotMd,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: online
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        if (!compact) ...[
          if (!hideIndicator) SizedBox(width: s.spacing.sm),
          Text(label, style: textStyle),
        ],
      ],
    );
  }
}
