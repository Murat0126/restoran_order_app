import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Нижний системный футер экрана заказа (Stitch `pos_2.3_2`).
class PosOrderSystemFooter extends StatelessWidget {
  const PosOrderSystemFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;
    final online = s.semantic.statusOnline;

    final c = s.components;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.palette.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: s.palette.outlineVariant,
            width: c.dividerThickness,
          ),
        ),
      ),
      child: SizedBox(
        height: c.systemFooterHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.spacing.lg,
            vertical: s.spacing.sm,
          ),
          child: Row(
            children: [
              Container(
              width: c.statusDotSm,
              height: c.statusDotSm,
              decoration: BoxDecoration(
                color: online,
                shape: BoxShape.circle,
              ),
              ),
              SizedBox(width: s.spacing.xs),
              Text(
                l10n.waiterOrderSystemOnline,
                style: s.typography.labelCaps.copyWith(
                  fontSize: c.microFontSize,
                  color: s.palette.secondary,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: s.spacing.md),
                child: Text(
                  '|',
                  style: s.typography.labelCaps.copyWith(
                    fontSize: c.microFontSize,
                    color: s.palette.onTertiaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Text(
                l10n.waiterOrderLocalServer('2.4.1'),
                style: s.typography.labelCaps.copyWith(
                  fontSize: c.microFontSize,
                  color: s.palette.secondary,
                ),
              ),
              const Spacer(),
              _FooterLink(label: l10n.waiterOrderSupport),
              SizedBox(width: s.spacing.lg),
              _FooterLink(label: l10n.waiterOrderHelp),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: s.palette.secondary,
        textStyle: s.typography.labelCaps.copyWith(
          fontSize: s.components.microFontSize,
        ),
      ),
      child: Text(label),
    );
  }
}
