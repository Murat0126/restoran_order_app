import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/formatters/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../table_card_appearance.dart';

/// Карточка столика (`pos_2.2_2`).
class TableCard extends StatefulWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final RestaurantTable table;
  final Order? order;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;
    final layout = s.layout;
    final appearance = TableCardAppearance.resolve(
      context,
      widget.table,
      widget.order,
    );

    final bg = switch (appearance.variant) {
      TableCardVariant.vacated => p.surfaceContainerLow,
      _ => p.surfaceContainerLowest,
    };

    final border = appearance.variant == TableCardVariant.vacated
        ? null
        : Border.all(
            color: widget.selected
                ? p.primaryContainer
                : p.outlineVariant.withValues(alpha: 0.3),
            width: widget.selected
                ? layout.tableSelectionOutlineWidth
                : 1,
          );

    final numberColor =
        appearance.mutedNumbers ? p.outline : p.onSurface;
    final seatsColor =
        appearance.mutedNumbers ? p.outline : p.onSurfaceVariant;

    return SizedBox(
      height: layout.tableCardHeight,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(s.radii.lg),
                border: border,
                boxShadow: s.shadows.level1,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  borderRadius: BorderRadius.circular(s.radii.lg),
                  child: Padding(
                    padding: EdgeInsets.all(s.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTableNumber(widget.table.number),
                                    style: s.typography.headlineMedium
                                        .copyWith(
                                      color: numberColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    context.l10n
                                        .tableSeats(widget.table.capacity),
                                    style: s.typography.bodySmall.copyWith(
                                      color: seatsColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(appearance: appearance),
                          ],
                        ),
                        _CardFooter(
                          appearance: appearance,
                          order: widget.order,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (appearance.variant == TableCardVariant.vacated)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: p.outlineVariant,
                      radius: s.radii.lg,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final len = (distance + dash > metric.length)
            ? metric.length - distance
            : dash;
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.appearance});

  final TableCardAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final badge = appearance.badge;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: s.spacing.sm,
        vertical: s.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: badge.background,
        borderRadius: BorderRadius.circular(s.radii.full),
      ),
      child: Text(
        appearance.label,
        style: s.typography.labelCaps.copyWith(
          color: badge.foreground,
          fontSize: s.components.microFontSize,
          height: 1,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.appearance, required this.order});

  final TableCardAppearance appearance;
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    return switch (appearance.footer) {
      TableCardFooter.guestAndTotal when order != null => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.person, size: s.components.iconMd, color: p.onSurfaceVariant),
            Text(
              formatPrice(context, order!.total),
              style: context.appTheme.typography.labelStrong.copyWith(
                color: p.onSurfaceVariant,
                height: 1,
              ),
            ),
          ],
        ),
      TableCardFooter.cleaning => Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.cleaning_services_outlined,
            size: s.components.iconMd,
            color: p.onSurfaceVariant,
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
