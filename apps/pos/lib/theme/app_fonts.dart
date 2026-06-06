import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';

/// Подключает [Manrope] / [Inter] через `google_fonts` (как в Stitch DESIGN.md).
TextStyle bundleGoogleFont(TextStyle style, AppFontFamilies families) {
  final family = style.fontFamily ?? families.body;
  final resolved = style.copyWith(
    fontFamilyFallback: families.fallback,
  );
  if (family == families.heading) {
    return switch (families.heading) {
      'Manrope' => GoogleFonts.manrope(textStyle: resolved),
      _ => resolved,
    };
  }
  return switch (families.body) {
    'Inter' => GoogleFonts.inter(textStyle: resolved),
    _ => resolved,
  };
}

/// Все 9 ролей типографики с загруженными веб-шрифтами.
AppTypography typographyWithGoogleFonts(AppTypography typography) {
  TextStyle h(TextStyle s) => bundleGoogleFont(s, typography.families);
  final f = typography.families;
  return typography.copyWith(
    headlineLarge: h(typography.headlineLarge),
    headlineLargeMobile: h(typography.headlineLargeMobile),
    headlineMedium: h(typography.headlineMedium),
    headlineSmall: h(typography.headlineSmall),
    bodyLarge: bundleGoogleFont(
      typography.bodyLarge,
      f,
    ),
    bodyMedium: bundleGoogleFont(
      typography.bodyMedium,
      f,
    ),
    bodySmall: bundleGoogleFont(
      typography.bodySmall,
      f,
    ),
    labelStrong: bundleGoogleFont(
      typography.labelStrong,
      f,
    ),
    labelCaps: bundleGoogleFont(
      typography.labelCaps,
      f,
    ),
  );
}
