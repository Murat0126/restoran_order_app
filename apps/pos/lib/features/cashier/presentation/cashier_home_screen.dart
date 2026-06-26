import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_error_state.dart';
import '../../../widgets/connection_indicator.dart';
import '../../auth/auth_providers.dart';
import '../cashier_orders_provider.dart';
import 'payment_sheet.dart';

enum _CashierFilter { all, awaitingPayment }

/// Главный экран кассира (Stitch 3.2): список активных заказов зала
/// с быстрым переходом к оплате.
class CashierHomeScreen extends ConsumerStatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  ConsumerState<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends ConsumerState<CashierHomeScreen> {
  _CashierFilter _filter = _CashierFilter.all;
  String _query = '';

  /// Заказ «ждёт оплаты»: помечен готовым/в счёте, либо все активные
  /// позиции уже поданы (а позиции есть).
  static bool isAwaitingPayment(Order order) {
    if (order.status == OrderStatus.ready ||
        order.status == OrderStatus.billed) {
      return true;
    }
    final active =
        order.items.where((i) => i.status != OrderItemStatus.cancelled);
    if (active.isEmpty) return false;
    return active.every((i) => i.status == OrderItemStatus.served);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final async = ref.watch(cashierOrdersProvider);

    return Scaffold(
      backgroundColor: s.palette.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              query: _query,
              onQueryChanged: (v) => setState(() => _query = v),
            ),
            _FilterRow(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppErrorState(
                  title: l10n.errorStateGenericTitle,
                  subtitle: e.toString(),
                  retryLabel: l10n.actionRetry,
                  onRetry: () => ref.invalidate(cashierOrdersProvider),
                ),
                data: (data) => _OrdersGrid(
                  orders: _visibleOrders(data),
                  data: data,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Order> _visibleOrders(CashierOrdersState data) {
    final all = [...data.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    Iterable<Order> filtered = switch (_filter) {
      _CashierFilter.all => all,
      _CashierFilter.awaitingPayment => all.where(isAwaitingPayment),
    };
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((o) {
        final table = data.tableFor(o);
        final number = table?.number.toLowerCase() ?? '';
        return number.contains(q);
      });
    }
    return filtered.toList(growable: false);
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.query, required this.onQueryChanged});

  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceBright,
        border: Border(bottom: BorderSide(color: s.palette.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: s.spacing.lg,
          vertical: s.spacing.sm,
        ),
        child: Row(
          children: [
            Text(
              l10n.cashierTitle,
              style: s.typography.headlineSmall.copyWith(
                color: s.palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: s.spacing.lg),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: onQueryChanged,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: s.palette.surfaceContainer,
                      hintText: l10n.cashierSearchHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: s.palette.onSurfaceVariant,
                        size: s.components.iconMd,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(s.radii.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: s.spacing.md),
            const ConnectionIndicator(),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.actionOpenSettings,
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: l10n.actionLogout,
              onPressed: () =>
                  ref.read(authStateProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final _CashierFilter filter;
  final ValueChanged<_CashierFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    final chips = <(_CashierFilter, String)>[
      (_CashierFilter.all, l10n.cashierFilterAll),
      (_CashierFilter.awaitingPayment, l10n.cashierFilterAwaitingPayment),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.spacing.lg,
        s.spacing.md,
        s.spacing.lg,
        s.spacing.sm,
      ),
      child: Row(
        children: [
          for (final (f, label) in chips) ...[
            _Chip(
              label: label,
              selected: filter == f,
              onTap: () => onChanged(f),
            ),
            SizedBox(width: s.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
          : s.palette.surfaceContainerHigh,
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
                  : s.palette.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersGrid extends StatelessWidget {
  const _OrdersGrid({required this.orders, required this.data});

  final List<Order> orders;
  final CashierOrdersState data;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    if (orders.isEmpty) {
      return AppEmptyState(
        title: l10n.cashierEmptyTitle,
        subtitle: l10n.cashierEmptySubtitle,
        icon: Icons.point_of_sale_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1100
            ? 3
            : w >= 700
                ? 2
                : 1;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            s.spacing.lg,
            s.spacing.sm,
            s.spacing.lg,
            s.spacing.xxl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: s.spacing.lg,
            crossAxisSpacing: s.spacing.lg,
            mainAxisExtent: 184,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(
              order: order,
              table: data.tableFor(order),
              awaitingPayment:
                  _CashierHomeScreenState.isAwaitingPayment(order),
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({
    required this.order,
    required this.table,
    required this.awaitingPayment,
  });

  final Order order;
  final RestaurantTable? table;
  final bool awaitingPayment;

  Future<void> _openPayment(BuildContext context) {
    return showPaymentSheet(context, order: order, table: table);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final sem = s.semantic;

    final tableNo = table != null ? formatTableNumber(table!.number) : '—';
    final guests = order.guestsCount ?? 0;
    final timeStr = formatTime(context, order.createdAt);

    final activeItems = order.items
        .where((i) => i.status != OrderItemStatus.cancelled)
        .length;

    final badge = awaitingPayment
        ? (
            bg: sem.orderPayment.background,
            fg: sem.orderPayment.foreground,
            label: l10n.cashierStatusAwaitingPayment,
          )
        : (
            bg: sem.orderCooking.background,
            fg: sem.orderCooking.foreground,
            label: l10n.cashierStatusServing,
          );

    return Material(
      color: s.palette.surfaceContainerLowest,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(s.radii.xl),
      child: InkWell(
        onTap: () => _openPayment(context),
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
                          l10n.cashierTableTitle(tableNo),
                          style: s.typography.headlineSmall,
                        ),
                        Text(
                          l10n.cashierCardMeta(guests, timeStr),
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
              SizedBox(height: s.spacing.sm),
              Padding(
                padding: EdgeInsets.symmetric(vertical: s.spacing.sm),
                child: Row(
                  children: [
                    Icon(
                      order.source == OrderSource.qrPreorder
                          ? Icons.qr_code_2
                          : Icons.receipt_long_outlined,
                      size: s.components.iconSm,
                      color: s.palette.onSurfaceVariant,
                    ),
                    SizedBox(width: s.spacing.sm),
                    Text(
                      '$activeItems',
                      style: s.typography.labelStrong.copyWith(
                        color: s.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      formatPrice(context, order.balance),
                      style: s.typography.headlineSmall.copyWith(
                        color: s.palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.spacing.sm),
                  _ActionButton(
                    label: awaitingPayment
                        ? l10n.cashierActionPay
                        : l10n.cashierActionDetails,
                    primary: awaitingPayment,
                    onTap: () => _openPayment(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final bg = primary ? s.palette.primary : s.palette.surfaceContainerHigh;
    final fg = primary ? s.palette.onPrimary : s.palette.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(s.radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.lg,
            vertical: s.spacing.sm,
          ),
          child: Text(
            label,
            style: s.typography.labelStrong.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
