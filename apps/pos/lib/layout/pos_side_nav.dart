import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Вариант боковой панели (Stitch: зал — `primary`, заказы — `surface`).
enum PosSideNavVariant {
  primary,
  surface,
}

/// Пункт боковой навигации POS (Stitch 2.2 / 2.5).
class PosNavDestination {
  const PosNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
}

/// Боковая навигация w-64 (`pos_2.2_2`).
class PosSideNav extends StatelessWidget {
  const PosSideNav({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    this.variant = PosSideNavVariant.primary,
    this.stationLabel,
    this.footer,
  });

  final int selectedIndex;
  final List<PosNavDestination> destinations;
  final PosSideNavVariant variant;
  final String? stationLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final primary = variant == PosSideNavVariant.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary ? s.palette.primaryContainer : s.palette.surface,
        border: primary
            ? null
            : Border(right: BorderSide(color: s.palette.outlineVariant)),
        boxShadow: s.shadows.navBar,
      ),
      child: SizedBox(
        width: s.layout.sideNavWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrandHeader(
              primary: primary,
              stationLabel: stationLabel,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: s.spacing.sm),
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    if (i > 0) SizedBox(height: s.spacing.xs),
                    _NavRow(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      primary: primary,
                    ),
                  ],
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.all(s.spacing.lg),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.primary, this.stationLabel});

  final bool primary;
  final String? stationLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    if (!primary) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          s.spacing.lg,
          s.spacing.xl,
          s.spacing.lg,
          s.spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.appTheme.brand.productName,
              style: s.typography.headlineSmall.copyWith(
                color: p.primary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (stationLabel != null) ...[
              SizedBox(height: s.spacing.xs),
              Text(
                stationLabel!,
                style: s.typography.bodyMedium.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.spacing.md,
        s.spacing.lg,
        s.spacing.md,
        s.spacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: s.components.navBrandSize,
            height: s.components.navBrandSize,
            decoration: BoxDecoration(
              color: p.secondary,
              borderRadius: BorderRadius.circular(s.radii.lg),
            ),
            child: Icon(
              Icons.restaurant,
              color: p.onSecondary,
              size: s.components.navBrandIconSize,
            ),
          ),
          SizedBox(height: s.spacing.sm),
          Text(
            context.appTheme.brand.productName,
            style: s.typography.headlineMedium.copyWith(
              color: p.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (stationLabel != null) ...[
            SizedBox(height: s.spacing.xs),
            Text(
              stationLabel!,
              style: s.typography.bodySmall.copyWith(
                color: p.onPrimaryContainer.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.destination,
    required this.selected,
    required this.primary,
  });

  final PosNavDestination destination;
  final bool selected;
  final bool primary;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final p = s.palette;

    final Color bg;
    final Color fg;
    if (widget.primary) {
      bg = widget.selected ? p.surfaceContainerLowest : Colors.transparent;
      fg = widget.selected ? p.primary : p.onPrimaryContainer;
    } else {
      bg = widget.selected ? p.primaryContainer : Colors.transparent;
      fg = widget.selected
          ? p.onPrimaryContainer
          : p.onSurfaceVariant;
    }

    final row = Material(
        color: bg,
        borderRadius: BorderRadius.circular(s.radii.lg),
        child: InkWell(
          onTap: widget.destination.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(s.radii.lg),
          hoverColor: widget.primary
              ? p.primaryFixedDim.withValues(alpha: 0.2)
              : p.secondaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: EdgeInsets.all(s.spacing.md),
            child: Row(
              children: [
                Icon(
                  widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  color: fg,
                  size: s.components.navItemIconSize,
                ),
                SizedBox(width: s.spacing.md),
                Expanded(
                  child: Text(
                    widget.destination.label,
                    style: s.typography.bodyMedium.copyWith(
                      color: fg,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    final faded = !widget.primary && widget.selected;
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 150),
      child: faded
          ? Opacity(opacity: s.components.navActiveOpacity, child: row)
          : row,
    );
  }
}
