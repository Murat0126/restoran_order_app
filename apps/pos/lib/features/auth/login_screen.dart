import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_base_url.dart';
import '../../layout/pos_brand_panel.dart';
import '../../layout/pos_server_status_badge.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pos_pin_pad_sheet.dart';
import 'auth_providers.dart';

/// Экран входа — порт `pos/code.html` (Stitch 2.1).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  Future<void> _submit({String? username, String? password}) async {
    if (_loading) return;
    final u = (username ?? _usernameCtrl.text).trim();
    final p = password ?? _passwordCtrl.text;
    if (username == null && !_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      await ref.read(authStateProvider.notifier).signIn(u, p);
    } on AuthError catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _errorText = switch (e) {
          AuthErrorBadCredentials() => l10n.loginErrorBadCredentials,
          AuthErrorNetwork() =>
            l10n.loginErrorNetwork(ref.read(apiBaseUrlProvider)),
          AuthErrorOther(:final message) => l10n.loginErrorOther(message),
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.appTheme.layout;
    final wide =
        MediaQuery.sizeOf(context).width >= layout.responsiveWideBreakpoint;

    return Scaffold(
      backgroundColor: context.appTheme.palette.surface,
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: PosBrandPanel()),
                Expanded(flex: 2, child: _LoginRightColumn(state: this)),
              ],
            )
          : _LoginRightColumn(state: this),
    );
  }
}

/// Правая 2/3: форма по центру + футер внизу.
class _LoginRightColumn extends StatelessWidget {
  const _LoginRightColumn({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.appTheme.spacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.appTheme.layout.loginCardMaxWidth,
                ),
                child: _LoginCard(state: state),
              ),
            ),
          ),
        ),
        const _LoginFooter(),
        if (kDebugMode) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.appTheme.spacing.lg,
              0,
              context.appTheme.spacing.lg,
              context.appTheme.spacing.sm,
            ),
            child: _QuickDevBlock(
              enabled: !state._loading,
              onTap: (u, p) => state._submit(username: u, password: p),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: s.shadows.level1,
      ),
      child: Padding(
        padding: EdgeInsets.all(s.spacing.xl),
        child: Form(
          key: state._formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.loginTitle,
                style: s.typography.headlineLarge.copyWith(
                  color: s.palette.primary,
                ),
              ),
              SizedBox(height: s.spacing.xs),
              Text(
                l10n.loginFormSubtitle,
                style: s.typography.bodySmall.copyWith(
                  color: s.palette.onSurfaceVariant,
                ),
              ),
              SizedBox(height: s.spacing.lg),
              _LoginField(
                label: l10n.loginUsernameLabel,
                hint: l10n.loginUsernameHint,
                controller: state._usernameCtrl,
                enabled: !state._loading,
                icon: Icons.account_circle_outlined,
                onSubmitted: () => state._submit(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.loginFieldRequired : null,
              ),
              SizedBox(height: s.spacing.md),
              _LoginField(
                label: l10n.loginPasswordLabel,
                hint: l10n.loginPasswordHint,
                controller: state._passwordCtrl,
                enabled: !state._loading,
                obscure: state._obscure,
                icon: Icons.lock_outline,
                onSubmitted: () => state._submit(),
                suffix: IconButton(
                  icon: Icon(
                    state._obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: s.palette.outline,
                  ),
                  onPressed: state._toggleObscure,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.loginFieldRequired : null,
              ),
              if (state._errorText != null) ...[
                SizedBox(height: s.spacing.md),
                _LoginErrorBanner(message: state._errorText!),
              ],
              SizedBox(height: s.spacing.sm),
              _LoginPrimaryButton(
                label: state._loading ? l10n.loginSigningIn : l10n.loginSubmit,
                loading: state._loading,
                onPressed: state._loading ? null : () => state._submit(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: s.spacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: s.palette.outlineVariant),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s.spacing.md),
                      child: Text(
                        l10n.loginOrDivider,
                        style: s.typography.labelCaps.copyWith(
                          color: s.palette.outline,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: s.palette.outlineVariant),
                    ),
                  ],
                ),
              ),
              _LoginPinButton(
                label: l10n.loginPinButton,
                onPressed: state._loading
                    ? null
                    : () => showPosPinPadSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.enabled = true,
    this.suffix,
    this.onSubmitted,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final Widget? suffix;
  final VoidCallback? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: s.typography.labelStrong.copyWith(
            color: s.palette.onSurfaceVariant,
          ),
        ),
        SizedBox(height: s.spacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          autofillHints: obscure
              ? const [AutofillHints.password]
              : const [AutofillHints.username],
          style: s.typography.bodyMedium,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: s.typography.bodyMedium.copyWith(
              color: s.palette.outline,
            ),
            filled: true,
            fillColor: s.palette.surfaceBright,
            prefixIcon: Icon(
              icon,
              color: s.palette.outline,
              size: c.categoryIconSize,
            ),
            suffixIcon: suffix,
            contentPadding: EdgeInsets.symmetric(
              horizontal: s.spacing.md,
              vertical: s.spacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s.radii.lg),
              borderSide: BorderSide(color: s.palette.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s.radii.lg),
              borderSide: BorderSide(color: s.palette.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s.radii.lg),
              borderSide: BorderSide(
                color: s.palette.primary,
                width: s.layout.tableSelectionOutlineWidth,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s.radii.lg),
              borderSide: BorderSide(color: s.palette.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.primary,
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: s.shadows.level2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(s.radii.lg),
          child: SizedBox(
            width: double.infinity,
            height: c.buttonHeightMd,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: c.iconMd,
                      height: c.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: s.layout.tableSelectionOutlineWidth,
                        color: s.palette.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: s.typography.labelStrong.copyWith(
                        color: s.palette.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPinButton extends StatelessWidget {
  const _LoginPinButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: s.palette.onSurface,
        backgroundColor: s.palette.surfaceBright,
        side: BorderSide(color: s.palette.outlineVariant),
        padding: EdgeInsets.symmetric(vertical: s.spacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.radii.lg),
        ),
        textStyle: s.typography.labelStrong,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dialpad, size: c.iconMd, color: s.palette.onSurface),
          SizedBox(width: s.spacing.sm),
          Text(label),
        ],
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    return Container(
      padding: EdgeInsets.all(s.spacing.sm),
      decoration: BoxDecoration(
        color: s.palette.errorContainer,
        borderRadius: BorderRadius.circular(s.radii.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: c.iconSm,
            color: s.palette.onErrorContainer,
          ),
          SizedBox(width: s.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: s.typography.bodySmall.copyWith(
                color: s.palette.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFooter extends ConsumerWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.appTheme;
    final c = s.components;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: s.palette.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(s.spacing.lg),
        child: Row(
          children: [
            Text(
              l10n.loginFooterVersion('1.0'),
              style: s.typography.labelCaps.copyWith(
                color: s.palette.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(width: s.spacing.md),
            Container(
              width: c.dividerThickness,
              height: c.iconXs,
              color: s.palette.outlineVariant,
            ),
            SizedBox(width: s.spacing.md),
            Container(
              width: c.statusDotSm,
              height: c.statusDotSm,
              decoration: BoxDecoration(
                color: context.appTheme.semantic.statusOnline,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: s.spacing.xs),
            const PosServerStatusBadge(hideIndicator: true, compactText: true),
            const Spacer(),
            Icon(Icons.wifi, size: c.iconSm, color: s.palette.outline),
            SizedBox(width: s.spacing.sm),
            Icon(Icons.sync, size: c.iconSm, color: s.palette.outline),
            SizedBox(width: s.spacing.sm),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.settings_outlined,
                size: c.iconSm,
                color: s.palette.outline,
              ),
              tooltip: l10n.actionOpenSettings,
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDevBlock extends StatelessWidget {
  const _QuickDevBlock({required this.enabled, required this.onTap});

  final bool enabled;
  final void Function(String username, String password) onTap;

  static const _users = ['waiter1', 'cashier1', 'cook1', 'director1', 'admin'];

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.all(s.spacing.md),
      decoration: BoxDecoration(
        color: s.palette.surfaceContainer,
        borderRadius: BorderRadius.circular(s.radii.md),
        border: Border.all(color: s.palette.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loginQuickDevTitle, style: s.typography.labelStrong),
          SizedBox(height: s.spacing.sm),
          Wrap(
            spacing: s.spacing.sm,
            runSpacing: s.spacing.sm,
            children: [
              for (final u in _users)
                ActionChip(
                  label: Text(u),
                  onPressed: enabled ? () => onTap(u, '1234') : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
