import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_error_state.dart';
import '../waiter_orders_provider.dart';

enum _OrdersFilter { all, cooking, ready, billed }

/// Список «Мои заказы» (Stitch `pos_2.5_2`).
class WaiterOrdersScreen extends ConsumerStatefulWidget {
  const WaiterOrdersScreen({super.key});

  @override
  ConsumerState<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
}

class _WaiterOrdersScreenState extends ConsumerState<WaiterOrdersScreen> {
  _OrdersFilter _filter = _OrdersFilter.all;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(waiterOrdersProvider);
    final l10n = context.l10n;

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        title: l10n.errorStateGenericTitle,
        subtitle: e.toString(),
        retryLabel: l10n.actionRetry,
        onRetry: () => ref.invalidate(waiterOrdersProvider),
      ),
      data: (data) => _OrdersBody(
        data: data,
        filter: _filter,
        onFilterChanged: (f) => setState(() => _filter = f),
        onMarkServed: (order) =>
            ref.read(waiterOrdersProvider.notifier).markOrderServed(order),
      ),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({
    required this.data,
    required this.filter,
    required this.onFilterChanged,
    required this.onMarkServed,
  });

  final WaiterOrdersState data;
  final _OrdersFilter filter;
  final ValueChanged<_OrdersFilter> onFilterChanged;
  final Future<void> Function(Order order) onMarkServed;

  List<Order> _filteredOrders() {
    final all = [...data.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return switch (filter) {
      _OrdersFilter.all => all,
      _OrdersFilter.cooking => all.where((o) {
          return o.status == OrderStatus.sent ||
              o.items.any(
                (i) =>
                    i.status == OrderItemStatus.cooking ||
                    i.status == OrderItemStatus.pending,
              );
        }).toList(),
      _OrdersFilter.ready => all
          .where((o) => o.status == OrderStatus.ready)
          .toList(),
      _OrdersFilter.billed =>
        all.where((o) => o.status == OrderStatus.billed).toList(),
    };
  }

  RestaurantTable? _tableFor(Order order) => data.tableFor(order);

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final orders = _filteredOrders();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrdersHeader(onNewOrder: () => context.go('/waiter')),
        _FilterRow(filter: filter, onFilterChanged: onFilterChanged),
        Expanded(
          child: orders.isEmpty
              ? AppEmptyState(
                  title: l10n.waiterOrdersEmptyTitle,
                  subtitle: l10n.waiterOrdersEmptySubtitle,
                  icon: Icons.restaurant_outlined,
                )
              : ColoredBox(
                  color: s.palette.surface,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCol = constraints.maxWidth >=
                          s.components.ordersTwoColumnBreakpoint;
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          s.spacing.lg,
                          s.spacing.sm,
                          s.spacing.lg,
                          s.spacing.xxl,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: twoCol ? 2 : 1,
                          mainAxisSpacing: s.spacing.lg,
                          crossAxisSpacing: s.spacing.lg,
                          mainAxisExtent: s.layout.orderCardHeight,
                        ),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final table = _tableFor(order);
                          return _OrderCard(
                            order: order,
                            table: table,
                            onOpen: () {
                              if (table != null) {
                                context.push('/waiter/order/${table.id}');
                              }
                            },
                            onMarkServed: () => onMarkServed(order),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.onNewOrder});

  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceBright,
        border: Border(
          bottom: BorderSide(color: s.palette.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: s.layout.headerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.spacing.lg),
          child: Row(
            children: [
              Text(
                l10n.waiterOrdersTitle,
                style: s.typography.headlineSmall.copyWith(
                  color: s.palette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: s.palette.onSurfaceVariant,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: s.palette.onSurfaceVariant,
                ),
                onPressed: () => context.push('/settings'),
              ),
              SizedBox(width: s.spacing.md),
              Material(
                color: s.palette.primaryContainer,
                borderRadius: BorderRadius.circular(s.radii.lg),
                child: InkWell(
                  onTap: onNewOrder,
                  borderRadius: BorderRadius.circular(s.radii.lg),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: s.spacing.lg,
                      vertical: s.spacing.sm,
                    ),
                    child: Text(
                      l10n.waiterNewOrder,
                      style: s.typography.labelStrong.copyWith(
                        color: s.palette.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.onFilterChanged,
  });

  final _OrdersFilter filter;
  final ValueChanged<_OrdersFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    final chips = <(_OrdersFilter, String)>[
      (_OrdersFilter.all, l10n.waiterOrdersFilterAll),
      (_OrdersFilter.cooking, l10n.waiterOrdersFilterCooking),
      (_OrdersFilter.ready, l10n.waiterOrdersFilterReady),
      (_OrdersFilter.billed, l10n.waiterOrdersFilterPayment),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.spacing.lg,
        s.spacing.md,
        s.spacing.lg,
        s.spacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (f, label) in chips) ...[
              _FilterChip(
                label: label,
                selected: filter == f,
                onTap: () => onFilterChanged(f),
              ),
              SizedBox(width: s.spacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return Material(
      color: selected
          ? s.palette.primaryContainer
          : s.palette.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.md,
            vertical: s.spacing.sm,
          ),
          child: Text(
            label,
            style: s.typography.labelStrong.copyWith(
              color: selected
                  ? s.palette.onPrimaryContainer
                  : s.palette.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.table,
    required this.onOpen,
    required this.onMarkServed,
  });

  final Order order;
  final RestaurantTable? table;
  final VoidCallback onOpen;
  final Future<void> Function() onMarkServed;

  bool get _canMarkServed =>
      order.items.any((i) => i.status == OrderItemStatus.ready);

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final tableNo =
        table != null ? formatTableNumber(table!.number) : '—';
    final time = TimeOfDay.fromDateTime(order.createdAt);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final guests = order.guestsCount ?? 0;
    final badge = _statusBadge(context, order.status);

    final items = order.items
        .where((i) => i.status != OrderItemStatus.cancelled)
        .take(4)
        .toList();

    return Material(
      color: s.palette.surfaceContainerLowest,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(s.radii.xl),
      child: Padding(
        padding: EdgeInsets.all(s.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.waiterOrderTableTitle(tableNo),
                        style: s.typography.headlineSmall,
                      ),
                      Text(
                        l10n.waiterOrdersCardMeta(guests, timeStr),
                        style: s.typography.bodySmall.copyWith(
                          color: s.palette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.spacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(s.radii.sm),
                  ),
                  child: Text(
                    badge.label,
                    style: s.typography.labelCaps.copyWith(
                      color: badge.fg,
                      fontSize: s.components.microFontSize,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: s.spacing.md),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: s.palette.outlineVariant.withValues(alpha: 0.2),
                    ),
                    bottom: BorderSide(
                      color: s.palette.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: s.spacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: s.spacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final cooking = item.status == OrderItemStatus.cooking ||
                        item.status == OrderItemStatus.pending;
                    return Row(
                      children: [
                        Icon(
                          cooking
                              ? Icons.local_fire_department
                              : Icons.check_circle_outlined,
                          size: s.components.iconSm,
                          color: cooking
                              ? s.semantic.orderCookingAccent
                              : s.palette.primaryContainer
                                  .withValues(alpha: 0.4),
                        ),
                        SizedBox(width: s.spacing.sm),
                        Expanded(
                          child: Text(
                            item.dishName,
                            style: s.typography.bodyMedium,
                          ),
                        ),
                        Text(
                          '${item.qty}',
                          style: s.typography.labelStrong.copyWith(
                            color: s.palette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: s.spacing.sm),
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    text: '${l10n.waiterOrderSumLabel} ',
                    style: s.typography.labelStrong.copyWith(
                      color: s.palette.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: formatPrice(context, order.total),
                        style: s.typography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: s.palette.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: s.palette.outlineVariant),
                    padding: EdgeInsets.symmetric(
                      horizontal: s.spacing.md,
                      vertical: s.spacing.sm,
                    ),
                  ),
                  child: Text(
                    l10n.waiterOrdersOpen,
                    style: s.typography.labelStrong,
                  ),
                ),
                SizedBox(width: s.spacing.sm),
                _MarkServedButton(
                  enabled: _canMarkServed,
                  label: l10n.waiterOrdersServed,
                  onPressed: onMarkServed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({Color bg, Color fg, String label}) _statusBadge(
    BuildContext context,
    OrderStatus status,
  ) {
    final l10n = context.l10n;
    final sem = context.appTheme.semantic;
    return switch (status) {
      OrderStatus.ready => (
          bg: sem.orderReady.background,
          fg: sem.orderReady.foreground,
          label: l10n.waiterOrdersStatusReady,
        ),
      OrderStatus.billed => (
          bg: sem.orderPayment.background,
          fg: sem.orderPayment.foreground,
          label: l10n.waiterOrdersStatusPayment,
        ),
      _ => (
          bg: sem.orderCooking.background,
          fg: sem.orderCooking.foreground,
          label: l10n.waiterOrdersStatusCooking,
        ),
    };
  }
}

class _MarkServedButton extends StatefulWidget {
  const _MarkServedButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final Future<void> Function() onPressed;

  @override
  State<_MarkServedButton> createState() => _MarkServedButtonState();
}

class _MarkServedButtonState extends State<_MarkServedButton> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final fg = s.palette.onPrimaryContainer;
    return Material(
      color: s.palette.primaryContainer,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: widget.enabled && !_busy ? _tap : null,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: s.spacing.md,
              vertical: s.spacing.sm,
            ),
            child: _busy
                ? SizedBox(
                    width: s.components.iconSm,
                    height: s.components.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Text(
                    widget.label,
                    style: s.typography.labelStrong.copyWith(color: fg),
                  ),
          ),
        ),
      ),
    );
  }
}
