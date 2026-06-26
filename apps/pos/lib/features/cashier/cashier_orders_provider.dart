import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/realtime/realtime_providers.dart';

/// Данные экрана кассы (Stitch 3.2): все активные заказы заведения
/// + столы для номеров.
class CashierOrdersState {
  const CashierOrdersState({
    required this.orders,
    required this.tablesById,
  });

  final List<Order> orders;
  final Map<String, RestaurantTable> tablesById;

  RestaurantTable? tableFor(Order order) => tablesById[order.tableId];
}

/// Все активные заказы (`GET /api/orders`) — касса видит весь зал,
/// в отличие от официанта (`?mine=true`).
final cashierOrdersProvider =
    AsyncNotifierProvider<CashierOrdersNotifier, CashierOrdersState>(
  CashierOrdersNotifier.new,
);

class CashierOrdersNotifier extends AsyncNotifier<CashierOrdersState> {
  @override
  Future<CashierOrdersState> build() async {
    ref.listen<AsyncValue<WsEvent>>(
      realtimeEventsProvider,
      (_, next) => next.whenData(_onWsEvent),
    );
    return _load();
  }

  /// Принимает оплату по заказу. Возвращает обновлённый заказ
  /// (сервер сам освобождает стол, когда баланс закрыт).
  Future<Order> pay(
    String orderId, {
    required PaymentMethod method,
    required double amount,
  }) async {
    final client = ref.read(restaurantApiClientProvider);
    final updated = await client.pay(orderId, method: method, amount: amount);
    state = AsyncData(await _load());
    return updated;
  }

  void _onWsEvent(WsEvent event) {
    final shouldReload = switch (event) {
      OrderUpdated() => true,
      OrderSentToKitchen() => true,
      OrderPaid() => true,
      KitchenItemStatusChanged() => true,
      TableStatusChanged() => true,
      PreorderCreated() => true,
      _ => false,
    };
    if (shouldReload) ref.invalidateSelf();
  }

  Future<CashierOrdersState> _load() async {
    final client = ref.read(restaurantApiClientProvider);
    final results = await Future.wait([
      client.fetchActiveOrders(),
      client.fetchTables(),
    ]);
    final orders = results[0] as List<Order>;
    final tables = results[1] as List<RestaurantTable>;
    return CashierOrdersState(
      orders: orders,
      tablesById: {for (final t in tables) t.id: t},
    );
  }
}
