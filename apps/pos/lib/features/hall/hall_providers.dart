import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/realtime/realtime_providers.dart';
import 'hall_layout.dart';

/// Загрузка залов, столов и активных заказов + live-обновления WS.
final hallLayoutProvider =
    AsyncNotifierProvider<HallLayoutNotifier, HallLayout>(
  HallLayoutNotifier.new,
);

/// Выбранный зал (таб). `null` → первый зал из списка.
final selectedHallIdProvider = StateProvider<String?>((ref) => null);

/// Стол, выделенный на карте (для кнопки «Новый заказ»).
final selectedTableIdProvider = StateProvider<String?>((ref) => null);

class HallLayoutNotifier extends AsyncNotifier<HallLayout> {
  @override
  Future<HallLayout> build() async {
    ref.listen<AsyncValue<WsEvent>>(
      realtimeEventsProvider,
      (_, next) => next.whenData(_onWsEvent),
    );
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<HallLayout> _load() async {
    final client = ref.read(restaurantApiClientProvider);
    final results = await Future.wait([
      client.fetchHalls(),
      client.fetchTables(),
      client.fetchActiveOrders(),
    ]);
    final halls = results[0] as List<Hall>;
    final tables = results[1] as List<RestaurantTable>;
    final orders = results[2] as List<Order>;
    return HallLayout(
      halls: halls,
      tables: tables,
      ordersById: {for (final o in orders) o.id: o},
    );
  }

  void _onWsEvent(WsEvent event) {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = switch (event) {
      TableStatusChanged(:final table) => current.copyWithTable(table),
      OrderUpdated(:final order) => current.copyWithOrder(order),
      OrderSentToKitchen(:final order) => current.copyWithOrder(order),
      OrderPaid(:final order) => current.copyWithOrder(order),
      PreorderCreated(:final order) => current.copyWithOrder(order),
      _ => null,
    };
    if (next != null) state = AsyncData(next);
  }
}

/// Id зала для отображения (с fallback на первый).
final effectiveHallIdProvider = Provider<String?>((ref) {
  final layout = ref.watch(hallLayoutProvider).valueOrNull;
  if (layout == null || layout.halls.isEmpty) return null;
  final selected = ref.watch(selectedHallIdProvider);
  if (selected != null && layout.halls.any((h) => h.id == selected)) {
    return selected;
  }
  return layout.halls.first.id;
});
