import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../layout/pos_side_nav.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../auth/auth_providers.dart';

/// Оболочка официанта (Stitch 2.2 / 2.5): боковая навигация 256px.
class WaiterShell extends ConsumerWidget {
  const WaiterShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.path;
    final onOrders = location == AppRoutes.waiterOrders;
    final selectedIndex = onOrders ? 1 : 0;

    final destinations = [
      PosNavDestination(
        icon: Icons.table_bar_outlined,
        selectedIcon: Icons.table_bar,
        label: l10n.waiterNavHallMap,
        onTap: () => context.go(AppRoutes.waiter),
      ),
      PosNavDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: l10n.waiterNavOrders,
        onTap: () => context.go(AppRoutes.waiterOrders),
      ),
      PosNavDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.waiterNavProfile,
        onTap: () => context.push('/settings'),
      ),
    ];

    final stationLabel = l10n.waiterStationLabel('01');

    Widget? navFooter;
    if (onOrders) {
      navFooter = OutlinedButton(
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
        style: OutlinedButton.styleFrom(
          foregroundColor: s.palette.onSurface,
          side: BorderSide(color: s.palette.outline),
          padding: EdgeInsets.symmetric(vertical: s.spacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radii.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: s.components.iconMd),
            SizedBox(width: s.spacing.sm),
            Text(l10n.actionLogout, style: s.typography.labelStrong),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: s.palette.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= s.layout.responsiveWideBreakpoint;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosSideNav(
                  selectedIndex: selectedIndex,
                  destinations: destinations,
                  variant: onOrders
                      ? PosSideNavVariant.surface
                      : PosSideNavVariant.primary,
                  stationLabel: stationLabel,
                  footer: navFooter,
                ),
                if (onOrders)
                  VerticalDivider(
                    width: 1,
                    color: s.palette.outlineVariant,
                  ),
                Expanded(child: child),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: child),
              NavigationBar(
                selectedIndex: selectedIndex.clamp(0, 2),
                onDestinationSelected: (i) => destinations[i].onTap(),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.table_bar_outlined),
                    label: l10n.waiterNavHallMap,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: l10n.waiterNavOrders,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    label: l10n.waiterNavProfile,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
