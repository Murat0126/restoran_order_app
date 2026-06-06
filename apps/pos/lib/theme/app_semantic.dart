import 'package:flutter/material.dart';

/// Пара цветов для бейджа / статуса (фон + текст).
@immutable
class SemanticColorPair {
  const SemanticColorPair({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// Семантические цвета UI (статусы столов, заказов, индикаторы).
///
/// Задаются в `assets/themes/*.json` → `light.semantic` / `dark.semantic`.
@immutable
class AppSemantic {
  const AppSemantic({
    required this.statusOnline,
    required this.orderCookingAccent,
    required this.tableFree,
    required this.tableOccupied,
    required this.tableOrderAccepted,
    required this.tablePendingPayment,
    required this.tableNeedsCleaning,
    required this.tableVacated,
    required this.tableQrPreorder,
    required this.orderCooking,
    required this.orderReady,
    required this.orderPayment,
  });

  final Color statusOnline;
  final Color orderCookingAccent;

  final SemanticColorPair tableFree;
  final SemanticColorPair tableOccupied;
  final SemanticColorPair tableOrderAccepted;
  final SemanticColorPair tablePendingPayment;
  final SemanticColorPair tableNeedsCleaning;
  final SemanticColorPair tableVacated;
  final SemanticColorPair tableQrPreorder;

  final SemanticColorPair orderCooking;
  final SemanticColorPair orderReady;
  final SemanticColorPair orderPayment;
}
