import 'package:flutter/widgets.dart';
import 'package:shared_models/shared_models.dart';

import 'table_card_appearance.dart';

/// Подпись статуса стола (единая логика с [TableCardAppearance]).
String tableStatusLabel(
  BuildContext context,
  TableStatus status, {
  Order? order,
  RestaurantTable? table,
}) {
  final t = table ??
      RestaurantTable(
        id: '',
        hallId: '',
        number: '',
        status: status,
      );
  return TableCardAppearance.resolve(context, t, order).label;
}
