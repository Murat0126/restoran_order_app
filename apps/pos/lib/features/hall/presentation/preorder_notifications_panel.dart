import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../hall_providers.dart';
import '../preorder_alerts_provider.dart';

/// Боковая панель уведомлений о QR-предзаказах (`pos_2.7_2`).
class PreorderNotificationsPanel extends ConsumerWidget {
  const PreorderNotificationsPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final p = s.palette;
    final l10n = context.l10n;
    final layout = ref.watch(hallLayoutProvider).valueOrNull;
    final alertIds = ref.watch(preorderAlertOrderIdsProvider);
    final panelWidth = s.layout.cartPanelWidth;

    final entries = <_PreorderEntry>[];
    if (layout != null) {
      for (final id in alertIds) {
        final order = layout.ordersById[id];
        if (order == null || !order.isPendingQrPreorder) continue;
        RestaurantTable? table;
        for (final t in layout.tables) {
          if (t.id == order.tableId) {
            table = t;
            break;
          }
        }
        if (table == null) continue;
        final itemCount = order.items
            .where((i) => i.status != OrderItemStatus.cancelled)
            .length;
        entries.add(
          _PreorderEntry(
            order: order,
            tableNumber: table.number,
            itemCount: itemCount,
          ),
        );
      }
      entries.sort((a, b) => b.order.createdAt.compareTo(a.order.createdAt));
    }

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SizedBox(
        width: panelWidth,
        child: ColoredBox(
          color: p.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: s.layout.headerHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: s.spacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.waiterNotificationsTitle,
                          style: s.typography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, color: p.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: s.components.dividerThickness,
                thickness: s.components.dividerThickness,
                color: p.outlineVariant,
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(s.spacing.lg),
                          child: Text(
                            l10n.waiterNotificationsEmpty,
                            textAlign: TextAlign.center,
                            style: s.typography.bodyMedium.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(s.spacing.md),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: s.spacing.sm),
                        itemBuilder: (context, index) {
                          final e = entries[index];
                          return _PreorderTile(
                            entry: e,
                            onOpen: () {
                              onClose();
                              context.push('/waiter/order/${e.order.tableId}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _PreorderEntry {
  const _PreorderEntry({
    required this.order,
    required this.tableNumber,
    required this.itemCount,
  });

  final Order order;
  final String tableNumber;
  final int itemCount;
}

class _PreorderTile extends StatelessWidget {
  const _PreorderTile({
    required this.entry,
    required this.onOpen,
  });

  final _PreorderEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    final sem = s.semantic;
    final l10n = context.l10n;
    final badge = sem.tableQrPreorder;

    return Material(
      color: p.surfaceContainerLow,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(s.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: s.spacing.sm,
                      vertical: s.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: badge.background,
                      borderRadius: BorderRadius.circular(s.radii.sm),
                    ),
                    child: Text(
                      l10n.tableStatusQrPreorder,
                      style: s.typography.labelCaps.copyWith(
                        color: badge.foreground,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(context, entry.order.total),
                    style: s.typography.labelStrong.copyWith(
                      color: p.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.spacing.sm),
              Text(
                l10n.waiterPreorderTableTitle(entry.tableNumber),
                style: s.typography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: s.spacing.xs),
              Text(
                l10n.waiterPreorderItemsCount(entry.itemCount),
                style: s.typography.bodySmall.copyWith(
                  color: p.onSurfaceVariant,
                ),
              ),
              SizedBox(height: s.spacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onOpen,
                  child: Text(l10n.waiterPreorderOpen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
