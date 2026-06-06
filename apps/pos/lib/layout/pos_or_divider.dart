import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Разделитель «или» между блоками формы (Stitch 2.1).
class PosOrDivider extends StatelessWidget {
  const PosOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Row(
      children: [
        Expanded(child: Divider(color: s.palette.outlineVariant)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.spacing.md),
          child: Text(
            label,
            style: s.typography.bodySmall.copyWith(
              color: s.palette.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: s.palette.outlineVariant)),
      ],
    );
  }
}
