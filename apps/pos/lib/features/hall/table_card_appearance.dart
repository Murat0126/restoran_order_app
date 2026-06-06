import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_semantic.dart';
import '../../theme/app_theme.dart';

/// Визуальный вариант карточки стола (Stitch `pos_2.2_2`).
enum TableCardVariant {
  standard,
  vacated,
  needsCleaning,
}

enum TableCardFooter {
  none,
  guestAndTotal,
  cleaning,
}

/// Разрешённые цвета бейджа и подпись для карточки стола.
@immutable
class TableCardAppearance {
  const TableCardAppearance({
    required this.variant,
    required this.label,
    required this.badge,
    required this.footer,
    this.mutedNumbers = false,
  });

  final TableCardVariant variant;
  final String label;
  final SemanticColorPair badge;
  final TableCardFooter footer;
  final bool mutedNumbers;

  static TableCardAppearance resolve(
    BuildContext context,
    RestaurantTable table,
    Order? order,
  ) {
    final l10n = context.l10n;
    final sem = context.appTheme.semantic;

    if (table.status == TableStatus.reserved) {
      return TableCardAppearance(
        variant: TableCardVariant.vacated,
        label: l10n.tableStatusVacated,
        badge: sem.tableVacated,
        footer: TableCardFooter.none,
        mutedNumbers: true,
      );
    }

    if (table.status == TableStatus.bill && order == null) {
      return TableCardAppearance(
        variant: TableCardVariant.needsCleaning,
        label: l10n.tableStatusNeedsCleaning,
        badge: sem.tableNeedsCleaning,
        footer: TableCardFooter.cleaning,
      );
    }

    if (order != null) {
      if (order.isPendingQrPreorder) {
        return TableCardAppearance(
          variant: TableCardVariant.standard,
          label: l10n.tableStatusQrPreorder,
          badge: sem.tableQrPreorder,
          footer: TableCardFooter.guestAndTotal,
        );
      }

      if (order.status == OrderStatus.billed ||
          order.status == OrderStatus.ready) {
        return TableCardAppearance(
          variant: TableCardVariant.standard,
          label: l10n.tableStatusPendingPayment,
          badge: sem.tablePendingPayment,
          footer: TableCardFooter.guestAndTotal,
        );
      }

      final sentToKitchen = order.items.any(
        (i) =>
            i.status != OrderItemStatus.draft &&
            i.status != OrderItemStatus.cancelled,
      );

      if (sentToKitchen || order.status == OrderStatus.sent) {
        return TableCardAppearance(
          variant: TableCardVariant.standard,
          label: l10n.tableStatusOrderAccepted,
          badge: sem.tableOrderAccepted,
          footer: TableCardFooter.guestAndTotal,
        );
      }

      final mins = DateTime.now().difference(order.createdAt).inMinutes;
      final display = mins < 1 ? 1 : mins;
      return TableCardAppearance(
        variant: TableCardVariant.standard,
        label: l10n.tableStatusOccupiedMinutes(display),
        badge: sem.tableOccupied,
        footer: TableCardFooter.guestAndTotal,
      );
    }

    if (table.status == TableStatus.bill) {
      return TableCardAppearance(
        variant: TableCardVariant.standard,
        label: l10n.tableStatusPendingPayment,
        badge: sem.tablePendingPayment,
        footer: TableCardFooter.none,
      );
    }

    if (table.status == TableStatus.occupied) {
      return TableCardAppearance(
        variant: TableCardVariant.standard,
        label: l10n.tableStatusOccupied,
        badge: sem.tableOccupied,
        footer: TableCardFooter.none,
      );
    }

    return TableCardAppearance(
      variant: TableCardVariant.standard,
      label: l10n.tableStatusFree,
      badge: sem.tableFree,
      footer: TableCardFooter.none,
    );
  }
}
