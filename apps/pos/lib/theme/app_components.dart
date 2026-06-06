import 'package:flutter/material.dart';

/// Размеры UI-компонентов (иконки, кнопки, бейджи) — корень JSON `components`.
@immutable
class AppComponents {
  const AppComponents({
    required this.iconXs,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
    required this.icon2xl,
    required this.iconEmpty,
    required this.navBrandSize,
    required this.navBrandIconSize,
    required this.navItemIconSize,
    required this.quickAddSize,
    required this.guestControlSize,
    required this.headerDividerHeight,
    required this.dividerThickness,
    required this.statusDotSm,
    required this.statusDotMd,
    required this.microFontSize,
    required this.categoryIconSize,
    required this.categorySectionLetterSpacing,
    required this.systemFooterHeight,
    required this.buttonHeightSm,
    required this.buttonHeightMd,
    required this.buttonHeightLg,
    required this.dishSheetImageSize,
    required this.dishSheetImageHeightNarrow,
    required this.notificationBadgeFontSize,
    required this.ordersTwoColumnBreakpoint,
    required this.navActiveOpacity,
    required this.emptyStateIconSize,
  });

  static const defaults = AppComponents(
    iconXs: 16,
    iconSm: 18,
    iconMd: 20,
    iconLg: 24,
    iconXl: 28,
    icon2xl: 40,
    iconEmpty: 64,
    navBrandSize: 48,
    navBrandIconSize: 28,
    navItemIconSize: 24,
    quickAddSize: 40,
    guestControlSize: 40,
    headerDividerHeight: 32,
    dividerThickness: 1,
    statusDotSm: 8,
    statusDotMd: 10,
    microFontSize: 10,
    categoryIconSize: 22,
    categorySectionLetterSpacing: 2,
    systemFooterHeight: 28,
    buttonHeightSm: 40,
    buttonHeightMd: 48,
    buttonHeightLg: 56,
    dishSheetImageSize: 280,
    dishSheetImageHeightNarrow: 200,
    notificationBadgeFontSize: 9,
    ordersTwoColumnBreakpoint: 1100,
    navActiveOpacity: 0.8,
    emptyStateIconSize: 48,
  );

  final double iconXs;
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double icon2xl;
  final double iconEmpty;
  final double navBrandSize;
  final double navBrandIconSize;
  final double navItemIconSize;
  final double quickAddSize;
  final double guestControlSize;
  final double headerDividerHeight;
  final double dividerThickness;
  final double statusDotSm;
  final double statusDotMd;
  final double microFontSize;
  final double categoryIconSize;
  final double categorySectionLetterSpacing;
  final double systemFooterHeight;
  final double buttonHeightSm;
  final double buttonHeightMd;
  final double buttonHeightLg;
  final double dishSheetImageSize;
  final double dishSheetImageHeightNarrow;
  final double notificationBadgeFontSize;
  final double ordersTwoColumnBreakpoint;
  final double navActiveOpacity;
  final double emptyStateIconSize;
}
