import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../layout/pos_brand_panel.dart';
import '../../layout/pos_page_footer.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/connection_indicator.dart';
import '../auth/auth_providers.dart';
import '../auth/role_labels.dart';

/// Плейсхолдер home для ролей (кроме официанта) в стиле Stitch.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: s.palette.surface,
      body: Stack(
        children: [
          wide
              ? Row(
                  children: [
                    const Expanded(child: PosBrandPanel()),
                    Expanded(
                      flex: 2,
                      child: _HomeBody(
                        role: role,
                        user: user,
                        l10n: l10n,
                      ),
                    ),
                  ],
                )
              : _HomeBody(role: role, user: user, l10n: l10n),
          Positioned(
            top: s.spacing.sm,
            right: s.spacing.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PosPageFooter(),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.role,
    required this.user,
    required this.l10n,
  });

  final UserRole role;
  final User? user;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          s.spacing.xl,
          s.spacing.xxl,
          s.spacing.xl,
          s.spacing.xxl * 2,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 56,
                color: s.palette.primary,
              ),
              SizedBox(height: s.spacing.lg),
              Text(
                _titleForRole(l10n, role),
                style: s.typography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: s.spacing.md),
              Text(
                l10n.homePlaceholderBody(roleDisplayName(context, role)),
                style: s.typography.bodyMedium.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                SizedBox(height: s.spacing.lg),
                Text(
                  l10n.signedInAs(
                    user!.displayName,
                    roleDisplayName(context, user!.role),
                  ),
                  style: s.typography.labelStrong,
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: s.spacing.xl),
              AppButton.fullWidth(
                label: l10n.actionOpenSettings,
                variant: AppButtonVariant.outlined,
                icon: Icons.settings_outlined,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleForRole(AppLocalizations l10n, UserRole role) {
    return switch (role) {
      UserRole.admin => l10n.homeAdminTitle,
      UserRole.director => l10n.homeDirectorTitle,
      UserRole.waiter => l10n.homeWaiterTitle,
      UserRole.cashier => l10n.homeCashierTitle,
      UserRole.cook => l10n.homeKdsTitle,
    };
  }
}
