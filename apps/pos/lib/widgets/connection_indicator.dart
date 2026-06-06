import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_base_url.dart';
import '../core/realtime/realtime_providers.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Маленький индикатор realtime-соединения (точка + статус)
/// для размещения в AppBar.
///
/// Цвета берутся из текущей темы — `tertiary` (зелёный), `secondary`
/// (приглушённый — connecting) и `error` (disconnected). Tooltip
/// показывает локализованный статус и текущий base URL.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key, this.compact = true});

  /// `true` — только точка (для AppBar). `false` — точка + текст
  /// (для Settings и больших мест).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final c = s.components;
    final l10n = context.l10n;
    final statusAsync = ref.watch(realtimeStatusProvider);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final status = statusAsync.valueOrNull ?? RealtimeStatus.disconnected;

    final (color, label) = switch (status) {
      RealtimeStatus.connected => (s.palette.tertiary, l10n.connectionConnected),
      RealtimeStatus.connecting => (
          s.palette.secondary,
          l10n.connectionConnecting
        ),
      RealtimeStatus.disconnected => (s.palette.error, l10n.connectionDisconnected),
    };

    final dot = Container(
      width: c.statusDotMd,
      height: c.statusDotMd,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: status == RealtimeStatus.connected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: s.spacing.sm,
                ),
              ]
            : null,
      ),
    );

    final content = compact
        ? dot
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot,
              SizedBox(width: s.spacing.sm),
              Text(label,
                  style: s.typography.labelStrong
                      .copyWith(color: s.palette.onSurface)),
            ],
          );

    return Tooltip(
      message: l10n.connectionTooltip(label, baseUrl),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.spacing.sm),
        child: content,
      ),
    );
  }
}
