import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_error_state.dart';
import '../hall_providers.dart';
import '../preorder_alerts_provider.dart';
import '../table_card_appearance.dart';
import 'preorder_notifications_panel.dart';
import 'table_card.dart';

/// Карта зала — pixel-perfect `pos_2.2_2`.
class WaiterHallScreen extends ConsumerStatefulWidget {
  const WaiterHallScreen({super.key});

  @override
  ConsumerState<WaiterHallScreen> createState() => _WaiterHallScreenState();
}

class _WaiterHallScreenState extends ConsumerState<WaiterHallScreen> {
  final _focusNode = FocusNode();
  bool _notificationsOpen = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSelection() {
    ref.read(selectedTableIdProvider.notifier).state = null;
  }

  void _onEscape() {
    if (_notificationsOpen) {
      setState(() => _notificationsOpen = false);
      return;
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(hallLayoutProvider);
    final hallId = ref.watch(effectiveHallIdProvider);
    final selectedTableId = ref.watch(selectedTableIdProvider);
    final alertCount = ref.watch(preorderAlertOrderIdsProvider).length;
    final l10n = context.l10n;

    return layoutAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        title: l10n.errorStateGenericTitle,
        subtitle: e.toString(),
        retryLabel: l10n.actionRetry,
        onRetry: () => ref.invalidate(hallLayoutProvider),
      ),
      data: (layout) {
        if (layout.halls.isEmpty) {
          return AppEmptyState(
            title: l10n.waiterHallEmptyTitle,
            subtitle: l10n.waiterHallEmptySubtitle,
            icon: Icons.table_restaurant_outlined,
          );
        }

        final effectiveId = hallId ?? layout.halls.first.id;
        final currentHall =
            layout.halls.firstWhere((h) => h.id == effectiveId);
        final tables = layout.tablesInHall(effectiveId);

        RestaurantTable? selectedTable;
        Order? selectedOrder;
        if (selectedTableId != null) {
          for (final t in tables) {
            if (t.id == selectedTableId) {
              selectedTable = t;
              selectedOrder = layout.orderForTable(t);
              break;
            }
          }
        }

        final hasActiveTables = tables.any((t) {
          final o = layout.orderForTable(t);
          return o != null ||
              t.status == TableStatus.occupied ||
              t.status == TableStatus.bill ||
              t.status == TableStatus.reserved;
        });
        final showInactiveHall = tables.isNotEmpty && !hasActiveTables;

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
          },
          child: Focus(
            autofocus: true,
            focusNode: _focusNode,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HallHeader(
                  hallName: currentHall.name,
                  halls: layout.halls,
                  selectedHallId: effectiveId,
                  onHallSelected: (id) {
                    ref.read(selectedHallIdProvider.notifier).state = id;
                    _clearSelection();
                  },
                  notificationCount: alertCount,
                  onNotificationsTap: () =>
                      setState(() => _notificationsOpen = true),
                  newOrderEnabled: selectedTableId != null,
                  onNewOrder: selectedTableId == null
                      ? null
                      : () =>
                          context.push('/waiter/order/$selectedTableId'),
                ),
                Expanded(
                  child: tables.isEmpty
                      ? AppEmptyState(
                          title: l10n.waiterHallNoTablesTitle,
                          subtitle: l10n.waiterHallNoTablesSubtitle,
                          icon: Icons.table_bar_outlined,
                        )
                      : showInactiveHall
                          ? _EmptyHallState()
                          : ColoredBox(
                              color: context.appTheme.palette.surfaceBright,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final grid = context.appTheme.layout;
                                  final cols = grid.gridColumnsForWidth(
                                    constraints.maxWidth,
                                  );
                                  return GridView.builder(
                                    padding: EdgeInsets.all(grid.gridPadding),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: grid.gridGap,
                                      crossAxisSpacing: grid.gridGap,
                                      mainAxisExtent: grid.tableCardHeight,
                                    ),
                                    itemCount: tables.length,
                                    itemBuilder: (context, index) {
                                      final table = tables[index];
                                      final order =
                                          layout.orderForTable(table);
                                      return TableCard(
                                        table: table,
                                        order: order,
                                        selected:
                                            table.id == selectedTableId,
                                        onTap: () {
                                          ref
                                              .read(
                                                selectedTableIdProvider
                                                    .notifier,
                                              )
                                              .state = table.id;
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                ),
                _TableSelectionFooter(
                  visible: selectedTable != null,
                  table: selectedTable,
                  order: selectedOrder,
                  onOpenOrder: selectedTable == null
                      ? null
                      : () => context.push(
                            '/waiter/order/${selectedTable!.id}',
                          ),
                ),
              ],
            ),
                if (_notificationsOpen)
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _notificationsOpen = false),
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.32),
                            ),
                          ),
                        ),
                        PreorderNotificationsPanel(
                          onClose: () =>
                              setState(() => _notificationsOpen = false),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyHallState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(s.spacing.xl),
              decoration: BoxDecoration(
                color: s.palette.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: s.components.emptyStateIconSize,
                color: s.palette.outline,
              ),
            ),
            SizedBox(height: s.spacing.lg),
            Text(
              l10n.waiterHallInactiveTitle,
              style: s.typography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.spacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                l10n.waiterHallInactiveSubtitle,
                style: s.typography.bodyMedium.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HallHeader extends StatelessWidget {
  const _HallHeader({
    required this.hallName,
    required this.halls,
    required this.selectedHallId,
    required this.onHallSelected,
    required this.notificationCount,
    required this.onNotificationsTap,
    required this.newOrderEnabled,
    this.onNewOrder,
  });

  final String hallName;
  final List<Hall> halls;
  final String selectedHallId;
  final ValueChanged<String> onHallSelected;
  final int notificationCount;
  final VoidCallback onNotificationsTap;
  final bool newOrderEnabled;
  final VoidCallback? onNewOrder;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final p = s.palette;

    final layout = s.layout;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.outlineVariant)),
      ),
      child: SizedBox(
        height: layout.headerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.headerPaddingH,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  hallName,
                  style: s.typography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(width: layout.headerTitleTabsGap),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < halls.length; i++) ...[
                          if (i > 0)
                            SizedBox(width: layout.hallTabsGap),
                          _HallTab(
                            label: halls[i].name,
                            selected: halls[i].id == selectedHallId,
                            onTap: () => onHallSelected(halls[i].id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: _NotificationButton(
                  tooltip: l10n.waiterNotifications,
                  count: notificationCount,
                  onTap: onNotificationsTap,
                ),
              ),
              SizedBox(width: s.spacing.md),
              Center(
                child: _NewOrderButton(
                  enabled: newOrderEnabled,
                  onPressed: onNewOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HallTab extends StatelessWidget {
  const _HallTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(bottom: s.spacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? p.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: s.spacing.sm),
          child: Text(
            label,
            style: s.typography.labelStrong.copyWith(
              color: selected ? p.primary : p.onSurfaceVariant,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.tooltip,
    required this.count,
    required this.onTap,
  });

  final String tooltip;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    final showBadge = count > 0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(s.spacing.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: s.components.iconLg,
                  color: p.onSurfaceVariant,
                ),
                if (showBadge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: p.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: s.typography.labelCaps.copyWith(
                          color: p.onError,
                          fontSize: s.components.notificationBadgeFontSize,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewOrderButton extends StatefulWidget {
  const _NewOrderButton({required this.enabled, this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<_NewOrderButton> createState() => _NewOrderButtonState();
}

class _NewOrderButtonState extends State<_NewOrderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final p = s.palette;

    return AnimatedScale(
      scale: _pressed && widget.enabled ? 0.95 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: p.primaryContainer,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(s.radii.lg),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s.spacing.lg,
                vertical: s.spacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: s.components.iconSm, color: p.onPrimary),
                  SizedBox(width: s.spacing.sm),
                  Text(
                    l10n.waiterNewOrder,
                    style: s.typography.labelStrong.copyWith(
                      color: p.onPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableSelectionFooter extends StatelessWidget {
  const _TableSelectionFooter({
    required this.visible,
    required this.table,
    required this.order,
    this.onOpenOrder,
  });

  final bool visible;
  final RestaurantTable? table;
  final Order? order;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final p = s.palette;

    final layout = s.layout;
    final statusLabel = table != null
        ? TableCardAppearance.resolve(context, table!, order).label
        : '—';

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceContainerLow,
              border: Border(top: BorderSide(color: p.outlineVariant)),
            ),
            child: SizedBox(
              height: layout.selectionFooterHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.headerPaddingH,
                ),
                child: Row(
                  children: [
                    _FooterField(
                      label: l10n.waiterHallSelectedTableLabel,
                      value: table != null
                          ? l10n.waiterHallSelectedTable(
                              formatTableNumber(table!.number),
                            )
                          : '—',
                    ),
                    SizedBox(width: s.spacing.lg),
                    Container(
                      width: s.components.dividerThickness,
                      height: s.components.headerDividerHeight,
                      color: p.outlineVariant,
                    ),
                    SizedBox(width: s.spacing.lg),
                    _FooterField(
                      label: l10n.waiterHallSelectedStatusLabel,
                      value: statusLabel,
                      valueStyle: s.typography.bodyMedium,
                    ),
                    const Spacer(),
                    _AssignWaiterButton(
                      label: l10n.waiterHallAssignWaiter,
                      onPressed: () {},
                    ),
                    SizedBox(width: s.spacing.md),
                    _OpenOrderButton(
                      label: l10n.waiterHallOpenOrder,
                      onPressed: onOpenOrder,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterField extends StatelessWidget {
  const _FooterField({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: s.typography.labelCaps.copyWith(
            color: s.palette.onSurfaceVariant.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              s.typography.headlineSmall.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _AssignWaiterButton extends StatelessWidget {
  const _AssignWaiterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Material(
      color: s.palette.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.lg,
            vertical: s.spacing.sm,
          ),
          child: Text(label, style: s.typography.labelStrong.copyWith(height: 1)),
        ),
      ),
    );
  }
}

class _OpenOrderButton extends StatefulWidget {
  const _OpenOrderButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_OpenOrderButton> createState() => _OpenOrderButtonState();
}

class _OpenOrderButtonState extends State<_OpenOrderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: p.primaryContainer,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(s.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
            horizontal: s.spacing.xl,
            vertical: s.spacing.sm,
          ),
            child: Text(
              widget.label,
              style: s.typography.labelStrong.copyWith(
                color: p.onPrimary,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
