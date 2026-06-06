import 'package:flutter/material.dart';

/// Размеры и брейкпоинты layout (зал, nav, карточки).
///
/// Задаются в корне JSON-темы → `layout`.
@immutable
class AppLayout {
  const AppLayout({
    required this.sideNavWidth,
    required this.headerHeight,
    required this.selectionFooterHeight,
    required this.tableCardHeight,
    required this.headerPaddingH,
    required this.headerTitleTabsGap,
    required this.hallTabsGap,
    required this.gridPadding,
    required this.gridGap,
    required this.tableSelectionOutlineWidth,
    required this.breakpointMd,
    required this.breakpointLg,
    required this.breakpointXl,
    required this.gridColumnsSm,
    required this.gridColumnsMd,
    required this.gridColumnsLg,
    required this.gridColumnsXl,
    required this.cartPanelWidth,
    required this.categoryRailWidth,
    required this.responsiveWideBreakpoint,
    required this.loginCardMaxWidth,
    required this.orderCardHeight,
    required this.dishCardHeight,
    required this.dishImageHeight,
    required this.dishGridColumns,
    required this.orderNarrowBreakpoint,
  });

  /// Значения по умолчанию (Stitch POS), если в JSON нет секции `layout`.
  static const defaults = AppLayout(
    sideNavWidth: 256,
    headerHeight: 64,
    selectionFooterHeight: 80,
    tableCardHeight: 144,
    headerPaddingH: 24,
    headerTitleTabsGap: 32,
    hallTabsGap: 24,
    gridPadding: 24,
    gridGap: 24,
    tableSelectionOutlineWidth: 2,
    breakpointMd: 768,
    breakpointLg: 1024,
    breakpointXl: 1280,
    gridColumnsSm: 2,
    gridColumnsMd: 3,
    gridColumnsLg: 4,
    gridColumnsXl: 6,
    cartPanelWidth: 384,
    categoryRailWidth: 192,
    responsiveWideBreakpoint: 900,
    loginCardMaxWidth: 400,
    orderCardHeight: 266,
    dishCardHeight: 248,
    dishImageHeight: 160,
    dishGridColumns: 3,
    orderNarrowBreakpoint: 720,
  );

  final double sideNavWidth;
  final double headerHeight;
  final double selectionFooterHeight;
  final double tableCardHeight;
  final double headerPaddingH;
  final double headerTitleTabsGap;
  final double hallTabsGap;
  final double gridPadding;
  final double gridGap;
  final double tableSelectionOutlineWidth;

  final double breakpointMd;
  final double breakpointLg;
  final double breakpointXl;

  final int gridColumnsSm;
  final int gridColumnsMd;
  final int gridColumnsLg;
  final int gridColumnsXl;

  final double cartPanelWidth;
  final double categoryRailWidth;
  final double responsiveWideBreakpoint;
  final double loginCardMaxWidth;
  final double orderCardHeight;
  final double dishCardHeight;
  final double dishImageHeight;
  final int dishGridColumns;
  final double orderNarrowBreakpoint;

  int gridColumnsForWidth(double width) {
    if (width >= breakpointXl) return gridColumnsXl;
    if (width >= breakpointLg) return gridColumnsLg;
    if (width >= breakpointMd) return gridColumnsMd;
    return gridColumnsSm;
  }
}
