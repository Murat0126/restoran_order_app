import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../theme/app_palette.dart';
import '../../../theme/app_theme.dart';

/// Карточка блюда в сетке (Stitch `pos_2.3_2`).
class DishTile extends StatelessWidget {
  const DishTile({
    super.key,
    required this.dish,
    required this.onOpen,
    this.onQuickAdd,
    this.enabled = true,
    this.showQuickAdd = true,
    this.tag,
  });

  final Dish dish;
  final VoidCallback onOpen;
  final VoidCallback? onQuickAdd;
  final bool enabled;
  final bool showQuickAdd;

  /// Короткий бейдж (Figma: «КЛАССИКА», «ВЕГАН»). Пока нет поля в API —
  /// передаётся с экрана при необходимости.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    final radius = BorderRadius.circular(s.radii.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: p.outlineVariant),
        boxShadow: s.shadows.level1,
      ),
      child: Material(
        color: p.surfaceContainerLowest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onOpen : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: s.layout.dishImageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: p.surfaceContainerHigh,
                      child: dish.images.isNotEmpty
                          ? Image.network(
                              dish.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(
                                p,
                                s.components.quickAddSize,
                              ),
                            )
                          : _placeholder(p, s.components.quickAddSize),
                    ),
                    if (enabled && showQuickAdd)
                      Positioned(
                        right: s.spacing.sm,
                        bottom: s.spacing.sm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.primary,
                            shape: BoxShape.circle,
                            boxShadow: s.shadows.level2,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: enabled
                                  ? (onQuickAdd ?? onOpen)
                                  : null,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: s.components.quickAddSize,
                                height: s.components.quickAddSize,
                                child: Icon(
                                  Icons.add,
                                  color: p.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.spacing.md,
                    vertical: s.spacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          dish.name,
                          style: s.typography.labelStrong,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: s.spacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              formatPrice(context, dish.effectivePrice),
                              style: s.typography.headlineSmall.copyWith(
                                color: p.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tag != null && tag!.isNotEmpty)
                            _DishTag(label: tag!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(AppPalette p, double iconSize) => Center(
        child: Icon(
          Icons.restaurant_menu_outlined,
          size: iconSize,
          color: p.onSurfaceVariant,
        ),
      );
}

class _DishTag extends StatelessWidget {
  const _DishTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: s.spacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: p.secondaryContainer,
        borderRadius: BorderRadius.circular(s.radii.md),
      ),
      child: Text(
        label.toUpperCase(),
        style: s.typography.labelCaps.copyWith(
          fontSize: s.components.microFontSize,
          height: 1.5,
          color: p.onSecondaryContainer,
        ),
      ),
    );
  }
}
