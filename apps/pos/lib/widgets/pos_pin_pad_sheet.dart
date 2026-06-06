import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Цифровая клавиатура PIN (Stitch 2.1) — UI-заглушка до F7.
Future<void> showPosPinPadSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _PinPadSheet(),
  );
}

class _PinPadSheet extends StatefulWidget {
  const _PinPadSheet();

  @override
  State<_PinPadSheet> createState() => _PinPadSheetState();
}

class _PinPadSheetState extends State<_PinPadSheet> {
  String _pin = '';

  void _tap(String d) {
    if (d == '⌫') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.spacing.lg,
        s.spacing.sm,
        s.spacing.lg,
        s.spacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.loginPinTitle, style: s.typography.headlineSmall),
          SizedBox(height: s.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (i) => Container(
                width: 14,
                height: 14,
                margin: EdgeInsets.symmetric(horizontal: s.spacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length
                      ? s.palette.primary
                      : s.palette.outlineVariant,
                ),
              ),
            ),
          ),
          SizedBox(height: s.spacing.lg),
          _KeyGrid(onTap: _tap),
          SizedBox(height: s.spacing.md),
          Text(
            l10n.loginPinStubMessage,
            style: s.typography.bodySmall.copyWith(
              color: s.palette.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({required this.onTap});

  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', ''];
    final s = context.appTheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return Material(
          color: s.palette.surfaceContainer,
          borderRadius: BorderRadius.circular(s.radii.md),
          child: InkWell(
            onTap: () => onTap(key),
            borderRadius: BorderRadius.circular(s.radii.md),
            child: Center(
              child: Text(
                key,
                style: s.typography.headlineSmall,
              ),
            ),
          ),
        );
      },
    );
  }
}
