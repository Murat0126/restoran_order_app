import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/realtime/realtime_providers.dart';
import '../hall/hall_providers.dart';

/// Данные экрана «Мои заказы».
class WaiterOrdersState {
  const WaiterOrdersState({
    required this.orders,
    required this.tablesById,
  });

  final List<Order> orders;
  final Map<String, RestaurantTable> tablesById;

  RestaurantTable? tableFor(Order order) => tablesById[order.tableId];
}

/// Заказы текущего официанта + столы для номеров (`GET /api/orders?mine=true`).
final waiterOrdersProvider =
    AsyncNotifierProvider<WaiterOrdersNotifier, WaiterOrdersState>(
  WaiterOrdersNotifier.new,
);

class WaiterOrdersNotifier extends AsyncNotifier<WaiterOrdersState> {
  @override
  Future<WaiterOrdersState> build() async {
    ref.listen<AsyncValue<WsEvent>>(
      realtimeEventsProvider,
      (_, next) => next.whenData(_onWsEvent),
    );
    return _load();
  }

  /// Помечает все готовые позиции заказа как поданные (`served`).
  Future<void> markOrderServed(Order order) async {
    final ready = order.items
        .where((i) => i.status == OrderItemStatus.ready)
        .toList(growable: false);
    if (ready.isEmpty) return;

    final client = ref.read(restaurantApiClientProvider);
    for (final item in ready) {
      await client.changeItemStatus(
        order.id,
        item.id,
        OrderItemStatus.served,
      );
    }
    ref.invalidate(hallLayoutProvider);
    state = AsyncData(await _load());
  }

  void _onWsEvent(WsEvent event) {
    final shouldReload = switch (event) {
      OrderUpdated() => true,
      OrderSentToKitchen() => true,
      OrderPaid() => true,
      KitchenItemStatusChanged() => true,
      _ => false,
    };
    if (shouldReload) {
      ref.invalidateSelf();
    }
  }

  Future<WaiterOrdersState> _load() async {
    final client = ref.read(restaurantApiClientProvider);
    final results = await Future.wait([
      client.fetchMyOrders(),
      client.fetchTables(),
    ]);
    final orders = results[0] as List<Order>;
    final tables = results[1] as List<RestaurantTable>;
    return WaiterOrdersState(
      orders: orders,
      tablesById: {for (final t in tables) t.id: t},
    );
  }
}
