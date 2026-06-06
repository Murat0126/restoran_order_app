import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/theme/theme_loader.dart';

void main() {
  group('ThemeLoader.parseFromJson', () {
    test('default.json — AURA POS (Figma), light + dark palettes', () {
      final source = File('assets/themes/default.json').readAsStringSync();
      final pair = ThemeLoader.parseFromJson(source);

      expect(pair.light.id, 'default');
      expect(pair.light.name, 'AURA POS');
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);

      // Палитра Figma Resto ERP (forest green), светлая.
      expect(pair.light.palette.primary, const Color(0xFF061B0E));
      expect(pair.light.palette.surface, const Color(0xFFFCF9F8));
      expect(pair.light.palette.secondaryContainer, const Color(0xFFDBE2D8));

      // Типография Stitch: Inter для заголовков и body.
      expect(pair.light.typography.families.heading, 'Inter');
      expect(pair.light.typography.families.body, 'Inter');
      expect(pair.light.typography.headlineLarge.fontSize, 32);
      expect(pair.light.typography.headlineLarge.fontWeight, FontWeight.w600);
      expect(pair.light.typography.labelCaps.fontWeight, FontWeight.w700);

      // Spacing / radii.
      expect(pair.light.spacing.md, 16);
      expect(pair.light.shadows.level1, isNotEmpty);
      expect(pair.light.shadows.navBar, isNotEmpty);

      expect(pair.light.brand.productName, 'AURA POS');
      expect(pair.light.brand.loginHeroImageUrl, isNotEmpty);
      expect(pair.light.layout.sideNavWidth, 256);
      expect(pair.light.layout.cartPanelWidth, 384);
      expect(pair.light.layout.categoryRailWidth, 192);
      expect(pair.light.layout.orderCardHeight, 266);
      expect(pair.light.layout.dishCardHeight, 248);
      expect(pair.light.layout.dishImageHeight, 160);
      expect(pair.light.layout.dishGridColumns, 3);
      expect(pair.light.components.buttonHeightMd, 48);
      expect(pair.light.components.navBrandSize, 48);
      expect(pair.light.radii.lg, 12);
      expect(pair.light.radii.md, 8);
      expect(pair.light.shadows.level1.first.blurRadius, 20);
      expect(pair.light.shadows.level2.first.blurRadius, 30);
      expect(pair.light.semantic.statusOnline, const Color(0xFF22C55E));
      expect(pair.light.semantic.orderReady.foreground,
          const Color(0xFF166534));

      // Dark — явная палитра «Evening Lounge».
      expect(pair.dark.spacing.md, pair.light.spacing.md);
      expect(pair.dark.radii.md, pair.light.radii.md);
      expect(pair.dark.palette.surface, const Color(0xFF0F1417));
      expect(pair.dark.palette.onSurface, const Color(0xFFDFE3E7));
      expect(pair.dark.palette.primary, isNot(pair.light.palette.primary));
    });

    test('hushed_luxury.json — Manrope + Inter, частичная типография',
        () {
      final source =
          File('assets/themes/hushed_luxury.json').readAsStringSync();
      final pair = ThemeLoader.parseFromJson(source);

      expect(pair.light.id, 'hushed_luxury');
      expect(pair.light.typography.families.heading, 'Manrope');
      expect(pair.light.typography.families.body, 'Inter');
      // Базовый headlineLarge задан в JSON напрямую.
      expect(pair.light.typography.headlineLarge.fontSize, 32);
      // headlineMedium / Small / bodySmall / labelCaps — производные.
      expect(pair.light.typography.headlineMedium.fontSize, 24);
      expect(pair.light.typography.headlineSmall.fontSize, 20);
      expect(pair.light.typography.bodySmall.fontSize, 14);
      expect(pair.light.typography.labelCaps.fontSize, 12);
      // Радиусы «architectural precision».
      expect(pair.light.radii.md, 4);
      expect(pair.light.radii.lg, 8);
    });

    test('toMaterialThemeData() возвращает валидный ThemeData', () {
      final source = File('assets/themes/default.json').readAsStringSync();
      final pair = ThemeLoader.parseFromJson(source);
      final lightTheme = pair.light.toMaterialThemeData();
      final darkTheme = pair.dark.toMaterialThemeData();

      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.colorScheme.primary,
          pair.light.palette.primary);
    });
  });
}
