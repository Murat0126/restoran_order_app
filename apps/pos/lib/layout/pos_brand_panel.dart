import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Левая панель логина (Stitch `pos/code.html` — 1/3, primary-container).
class PosBrandPanel extends StatelessWidget {
  const PosBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    final c = s.components;
    final layout = s.layout;
    final heroUrl = s.brand.loginHeroImageUrl;
    final l10n = context.l10n;
    final p = s.palette;

    return ColoredBox(
      color: p.primaryContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _DotPatternPainter(
              color: Colors.white,
              step: c.guestControlSize,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Opacity(
              opacity: 0.2,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.network(
                  heroUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(s.spacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: c.iconEmpty * 2,
                    height: c.iconEmpty * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: c.iconEmpty,
                      color: p.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: s.spacing.lg),
                  Text(
                    l10n.loginBrandHeroTitle,
                    style: s.typography.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: s.spacing.xs),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.categoryRailWidth + s.spacing.xxl,
                    ),
                    child: Text(
                      l10n.loginBrandTagline,
                      style: s.typography.bodyMedium.copyWith(
                        color: p.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter({required this.color, required this.step});

  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.1);
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x + 2, y + 2), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
