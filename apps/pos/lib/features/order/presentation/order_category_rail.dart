import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';

/// Левая колонка категорий (Stitch `pos_2.3_2`, w-48, primary-container).
class OrderCategoryRail extends StatelessWidget {
  const OrderCategoryRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('салат')) return Icons.restaurant_menu;
    if (n.contains('закуск') || n.contains('стартер')) return Icons.tapas;
    if (n.contains('суп')) return Icons.soup_kitchen;
    if (n.contains('горяч') || n.contains('основ')) return Icons.dinner_dining;
    if (n.contains('десерт')) return Icons.icecream;
    if (n.contains('напит') || n.contains('бар')) return Icons.local_bar;
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return SizedBox(
      width: s.layout.categoryRailWidth,
      child: ColoredBox(
        color: s.palette.primaryContainer,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: s.spacing.lg),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                s.spacing.md,
                0,
                s.spacing.md,
                s.spacing.md,
              ),
              child: Text(
                l10n.waiterOrderMenuSection,
                style: s.typography.labelCaps.copyWith(
                  fontSize: s.components.microFontSize,
                  color: s.palette.onPrimaryContainer.withValues(alpha: 0.6),
                  letterSpacing: s.components.categorySectionLetterSpacing,
                ),
              ),
            ),
            for (final c in categories)
              _CategoryTile(
                label: c.name,
                icon: _iconFor(c.name),
                selected: c.id == selectedId,
                onTap: () => onSelected(c.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    return Padding(
      padding: EdgeInsets.only(left: s.spacing.md, bottom: s.spacing.sm),
      child: Material(
        color: selected ? p.surfaceContainerLowest : Colors.transparent,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(999),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(999),
          ),
          child: Padding(
            padding: EdgeInsets.all(s.spacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: s.components.categoryIconSize,
                  color: selected
                      ? p.primary
                      : p.onPrimaryFixedVariant,
                ),
                SizedBox(width: s.spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: s.typography.labelStrong.copyWith(
                      color: selected
                          ? p.primary
                          : p.onPrimaryFixedVariant,
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
