import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../layout/pos_order_system_footer.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_chip.dart';
import '../../../widgets/app_error_state.dart';
import '../../auth/auth_providers.dart';
import '../order_session.dart';
import '../order_session_provider.dart';
import 'dish_add_sheet.dart';
import 'dish_tile.dart';
import 'order_cart_panel.dart';
import 'order_category_rail.dart';

/// Экран заказа без shell (Stitch `pos_2.3_2`).
class WaiterOrderScreen extends ConsumerWidget {
  const WaiterOrderScreen({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(orderSessionProvider(tableId));
    final l10n = context.l10n;

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: AppErrorState(
          title: l10n.errorStateGenericTitle,
          subtitle: e.toString(),
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(orderSessionProvider(tableId)),
        ),
      ),
      data: (session) => _OrderScaffold(tableId: tableId, session: session),
    );
  }
}

class _OrderScaffold extends ConsumerWidget {
  const _OrderScaffold({required this.tableId, required this.session});

  final String tableId;
  final OrderSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final categories = [...session.menu.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final dishes = session.dishesInCategory();

    return Scaffold(
      backgroundColor: s.palette.surface,
      body: Column(
        children: [
          _OrderTopBar(tableId: tableId, session: session),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < s.layout.orderNarrowBreakpoint) {
                  return _NarrowLayout(
                    tableId: tableId,
                    session: session,
                    categories: categories,
                    dishes: dishes,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OrderCategoryRail(
                      categories: categories,
                      selectedId: session.selectedCategoryId,
                      onSelected: (id) => ref
                          .read(orderSessionProvider(tableId).notifier)
                          .selectCategory(id),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: s.palette.surface,
                        child: _DishGrid(
                          tableId: tableId,
                          dishes: dishes,
                          canEdit: session.canEdit,
                        ),
                      ),
                    ),
                    OrderCartPanel(tableId: tableId),
                  ],
                );
              },
            ),
          ),
          const PosOrderSystemFooter(),
        ],
      ),
    );
  }
}

class _OrderTopBar extends ConsumerWidget {
  const _OrderTopBar({required this.tableId, required this.session});

  final String tableId;
  final OrderSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final c = s.components;
    final layout = s.layout;
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final guests = session.order.guestsCount ?? 2;
    final tableNo = formatTableNumber(session.table.number);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surface,
        border: Border(
          bottom: BorderSide(color: s.palette.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: layout.headerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.headerPaddingH),
          child: Row(
          children: [
            TextButton.icon(
              onPressed: () => context.go('/waiter'),
              icon: Icon(
                Icons.arrow_back,
                size: c.iconLg,
                color: s.palette.onSurfaceVariant,
              ),
              label: Text(
                l10n.waiterBackToHall,
                style: s.typography.labelStrong.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.all(s.spacing.sm),
              ),
            ),
            Container(
              width: c.dividerThickness,
              height: c.headerDividerHeight,
              margin: EdgeInsets.symmetric(horizontal: s.spacing.lg),
              color: s.palette.outlineVariant,
            ),
            Text(
              l10n.waiterOrderTableTitle(tableNo),
              style: s.typography.headlineSmall.copyWith(
                color: s.palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: s.spacing.md),
            _GuestsControl(
              value: guests,
              enabled: session.canEdit,
              onChanged: (v) => ref
                  .read(orderSessionProvider(tableId).notifier)
                  .setGuests(v),
            ),
            const Spacer(),
            if (user != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: s.spacing.md,
                  vertical: s.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: s.palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_circle,
                      size: c.iconLg,
                      color: s.palette.primary,
                    ),
                    SizedBox(width: s.spacing.sm),
                    Text(
                      user.displayName,
                      style: s.typography.labelStrong,
                    ),
                  ],
                ),
              ),
            SizedBox(width: s.spacing.md),
            Icon(
              Icons.sync,
              color: s.palette.onSurfaceVariant,
              size: c.categoryIconSize,
            ),
            SizedBox(width: s.spacing.sm),
            Icon(
              Icons.wifi,
              color: s.palette.primary,
              size: c.categoryIconSize,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _GuestsControl extends StatelessWidget {
  const _GuestsControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(s.spacing.xs),
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(s.radii.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GuestBtn(
            icon: Icons.remove,
            onTap: enabled && value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: s.spacing.md),
            child: Column(
              children: [
                Text(
                  l10n.waiterOrderGuestsCaps,
                  style: s.typography.labelCaps.copyWith(
                    fontSize: c.microFontSize,
                    color: s.palette.onSurfaceVariant,
                  ),
                ),
                Text('$value', style: s.typography.labelStrong),
              ],
            ),
          ),
          _GuestBtn(
            icon: Icons.add,
            onTap: enabled ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _GuestBtn extends StatelessWidget {
  const _GuestBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.components;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appTheme.radii.md),
        child: SizedBox(
          width: c.guestControlSize,
          height: c.guestControlSize,
          child: Icon(icon, size: c.iconMd),
        ),
      ),
    );
  }
}

class _DishGrid extends ConsumerWidget {
  const _DishGrid({
    required this.tableId,
    required this.dishes,
    required this.canEdit,
  });

  final String tableId;
  final List<Dish> dishes;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    if (dishes.isEmpty) {
      return Center(
        child: Text(
          context.l10n.waiterOrderNoDishes,
          style: s.typography.bodyMedium.copyWith(
            color: s.palette.onSurfaceVariant,
          ),
        ),
      );
    }
    final layout = s.layout;
    return GridView.builder(
      padding: EdgeInsets.all(layout.gridPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.dishGridColumns,
        mainAxisSpacing: layout.gridGap,
        crossAxisSpacing: layout.gridGap,
        mainAxisExtent: layout.dishCardHeight,
      ),
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        final dish = dishes[index];
        return DishTile(
          dish: dish,
          enabled: canEdit,
          onOpen: () => showDishSheet(
            context,
            dish: dish,
            mode: DishSheetMode.addToOrder,
            onAdd: ({required qty, note, courseNo = 1}) => ref
                .read(orderSessionProvider(tableId).notifier)
                .addDish(dish, qty: qty, note: note, courseNo: courseNo),
          ),
          onQuickAdd: canEdit
              ? () => showDishSheet(
                    context,
                    dish: dish,
                    mode: DishSheetMode.addToOrder,
                    onAdd: ({required qty, note, courseNo = 1}) => ref
                        .read(orderSessionProvider(tableId).notifier)
                        .addDish(
                          dish,
                          qty: qty,
                          note: note,
                          courseNo: courseNo,
                        ),
                  )
              : null,
        );
      },
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.tableId,
    required this.session,
    required this.categories,
    required this.dishes,
  });

  final String tableId;
  final OrderSession session;
  final List<MenuCategory> categories;
  final List<Dish> dishes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final c = s.components;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: s.palette.primary,
            tabs: [
              Tab(text: context.l10n.waiterOrderTabMenu),
              Tab(text: context.l10n.waiterOrderTabCart),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: c.buttonHeightMd,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: s.spacing.md,
                          vertical: s.spacing.sm,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final c = categories[index];
                          return Padding(
                            padding: EdgeInsets.only(right: s.spacing.sm),
                            child: AppChip(
                              label: c.name,
                              selected: c.id == session.selectedCategoryId,
                              variant: AppChipVariant.accent,
                              onTap: () => ref
                                  .read(
                                    orderSessionProvider(tableId).notifier,
                                  )
                                  .selectCategory(c.id),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _DishGrid(
                        tableId: tableId,
                        dishes: dishes,
                        canEdit: session.canEdit,
                      ),
                    ),
                  ],
                ),
                OrderCartPanel(tableId: tableId, fixedWidth: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
