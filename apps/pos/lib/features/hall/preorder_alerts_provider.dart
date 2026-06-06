import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/realtime/realtime_providers.dart';
import 'hall_layout.dart';
import 'hall_providers.dart';

/// Id заказов с неподтверждённым QR-предзаказом (для колокольчика и панели).
final preorderAlertOrderIdsProvider =
    NotifierProvider<PreorderAlertsNotifier, Set<String>>(
  PreorderAlertsNotifier.new,
);

class PreorderAlertsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen<AsyncValue<WsEvent>>(
      realtimeEventsProvider,
      (_, next) => next.whenData(_onWsEvent),
    );
    ref.listen<AsyncValue<HallLayout>>(
      hallLayoutProvider,
      (_, next) => next.whenData(_syncFromHall),
    );
    return {};
  }

  void dismiss(String orderId) {
    if (!state.contains(orderId)) return;
    state = {...state}..remove(orderId);
  }

  void _onWsEvent(WsEvent event) {
    switch (event) {
      case PreorderCreated(:final order):
        if (order.isPendingQrPreorder) {
          state = {...state, order.id};
        }
      case OrderSentToKitchen(:final order):
        _removeIfNotPending(order);
      case OrderUpdated(:final order):
        _removeIfNotPending(order);
      default:
        break;
    }
  }

  void _removeIfNotPending(Order order) {
    if (order.isPendingQrPreorder) return;
    if (!state.contains(order.id)) return;
    state = {...state}..remove(order.id);
  }

  void _syncFromHall(HallLayout layout) {
    final pending = layout.ordersById.values
        .where((o) => o.isPendingQrPreorder)
        .map((o) => o.id);
    if (pending.isEmpty && state.isEmpty) return;
    state = {...state, ...pending};
  }
}
