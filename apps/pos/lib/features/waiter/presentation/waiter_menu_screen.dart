import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../app/router.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_error_state.dart';
import '../../menu/menu_providers.dart';
import '../../order/presentation/dish_add_sheet.dart';
import '../../order/presentation/dish_tile.dart';
import '../../order/presentation/order_category_rail.dart';

/// Просмотр меню без привязки к столу (Stitch nav «Меню»).
class WaiterMenuScreen extends ConsumerStatefulWidget {
  const WaiterMenuScreen({super.key});

  @override
  ConsumerState<WaiterMenuScreen> createState() => _WaiterMenuScreenState();
}

class _WaiterMenuScreenState extends ConsumerState<WaiterMenuScreen> {
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final l10n = context.l10n;

    return menuAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        title: l10n.errorStateGenericTitle,
        subtitle: e.toString(),
        retryLabel: l10n.actionRetry,
        onRetry: () => ref.invalidate(menuProvider),
      ),
      data: (menu) {
        final categories = [...menu.categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final selectedId = _categoryId ??
            (categories.isNotEmpty ? categories.first.id : '');
        final dishes = menu.dishes
            .where((d) => d.categoryId == selectedId && d.available)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuHeader(title: l10n.waiterNavMenu),
            Expanded(
              child: categories.isEmpty
                  ? AppEmptyState(
                      title: l10n.waiterOrderNoDishes,
                      icon: Icons.restaurant_menu_outlined,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OrderCategoryRail(
                          categories: categories,
                          selectedId: selectedId,
                          onSelected: (id) =>
                              setState(() => _categoryId = id),
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: context.appTheme.palette.surface,
                            child: _MenuDishGrid(
                              dishes: dishes,
                              onDishTap: (dish) => showDishSheet(
                                context,
                                dish: dish,
                                mode: DishSheetMode.browse,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surface,
        border: Border(bottom: BorderSide(color: s.palette.outlineVariant)),
      ),
      child: SizedBox(
        height: s.layout.headerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.layout.headerPaddingH),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.waiter),
                icon: Icon(
                  Icons.arrow_back,
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
                width: s.components.dividerThickness,
                height: s.components.headerDividerHeight,
                margin: EdgeInsets.symmetric(horizontal: s.spacing.lg),
                color: s.palette.outlineVariant,
              ),
              Text(
                title,
                style: s.typography.headlineSmall.copyWith(
                  color: s.palette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDishGrid extends StatelessWidget {
  const _MenuDishGrid({
    required this.dishes,
    required this.onDishTap,
  });

  final List<Dish> dishes;
  final ValueChanged<Dish> onDishTap;

  @override
  Widget build(BuildContext context) {
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
          enabled: true,
          showQuickAdd: false,
          onOpen: () => onDishTap(dish),
        );
      },
    );
  }
}
