import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/realtime/realtime_providers.dart';
import '../hall/hall_providers.dart';
import '../menu/menu_providers.dart';
import 'order_session.dart';

/// Сессия заказа для столика [tableId]: открывает/создаёт заказ,
/// держит меню и выбранную категорию.
final orderSessionProvider =
    AsyncNotifierProvider.family<OrderSessionNotifier, OrderSession, String>(
  OrderSessionNotifier.new,
);

class OrderSessionNotifier
    extends FamilyAsyncNotifier<OrderSession, String> {
  @override
  Future<OrderSession> build(String tableId) async {
    ref.listen<AsyncValue<WsEvent>>(
      realtimeEventsProvider,
      (_, next) => next.whenData(_onWsEvent),
    );
    return _load(tableId);
  }

  void selectCategory(String categoryId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCategoryId: categoryId));
  }

  Future<void> setGuests(int guestsCount) async {
    final current = state.requireValue;
    if (!current.canEdit) return;
    final client = ref.read(restaurantApiClientProvider);
    final order =
        await client.updateOrderGuests(current.order.id, guestsCount);
    state = AsyncData(current.copyWith(order: order));
    ref.invalidate(hallLayoutProvider);
  }

  Future<void> addDish(
    Dish dish, {
    int qty = 1,
    String? note,
    int courseNo = 1,
  }) async {
    final current = state.requireValue;
    if (!current.canEdit) return;
    final client = ref.read(restaurantApiClientProvider);
    final result = await client.addItemToOrder(
      current.order.id,
      dishId: dish.id,
      qty: qty,
      note: note,
      courseNo: courseNo,
    );
    state = AsyncData(current.copyWith(order: result.order));
    ref.invalidate(hallLayoutProvider);
  }

  Future<void> removeItem(OrderItem item) async {
    final current = state.requireValue;
    if (!current.canEdit || item.status != OrderItemStatus.draft) return;
    final client = ref.read(restaurantApiClientProvider);
    final order = await client.removeDraftItem(current.order.id, item.id);
    state = AsyncData(current.copyWith(order: order));
    ref.invalidate(hallLayoutProvider);
  }

  Future<void> changeDraftQty(OrderItem item, int delta) async {
    final current = state.requireValue;
    if (!current.canEdit || item.status != OrderItemStatus.draft) return;
    final newQty = item.qty + delta;
    if (newQty < 1) {
      await removeItem(item);
      return;
    }
    final client = ref.read(restaurantApiClientProvider);
    await client.removeDraftItem(current.order.id, item.id);
    final result = await client.addItemToOrder(
      current.order.id,
      dishId: item.dishId,
      qty: newQty,
      note: item.note,
      courseNo: item.courseNo,
    );
    state = AsyncData(current.copyWith(order: result.order));
    ref.invalidate(hallLayoutProvider);
  }

  Future<void> incrementDraft(OrderItem item) async {
    final menu = await ref.read(menuProvider.future);
    final dish = menu.dishes.firstWhereOrNull((d) => d.id == item.dishId);
    if (dish == null) return;
    await addDish(
      dish,
      qty: 1,
      note: item.note,
      courseNo: item.courseNo,
    );
  }

  /// Отправляет черновые позиции на кухню (`POST /api/orders/:id/send`).
  ///
  /// Возвращает число отправленных позиций; `0` — нечего отправлять.
  Future<int> sendToKitchen() async {
    final current = state.requireValue;
    if (!current.canEdit) return 0;
    if (current.draftItems().isEmpty) return 0;

    final client = ref.read(restaurantApiClientProvider);
    final result = await client.sendToKitchen(current.order.id);
    state = AsyncData(current.copyWith(order: result.order));
    ref.invalidate(hallLayoutProvider);
    return result.sentCount;
  }

  void _onWsEvent(WsEvent event) {
    final current = state.valueOrNull;
    if (current == null) return;
    final orderId = current.order.id;

    final Order? updated = switch (event) {
      OrderUpdated(:final order) when order.id == orderId => order,
      OrderSentToKitchen(:final order) when order.id == orderId => order,
      PreorderCreated(:final order) when order.id == orderId => order,
      _ => null,
    };
    if (updated != null) {
      state = AsyncData(current.copyWith(order: updated));
    }
  }

  Future<OrderSession> _load(String tableId) async {
    final client = ref.read(restaurantApiClientProvider);
    final menu = await ref.read(menuProvider.future);
    final layout = await ref.read(hallLayoutProvider.future);

    final table = layout.tables.firstWhere((t) => t.id == tableId);
    Order? order = layout.orderForTable(table);

    if (order == null && table.currentOrderId != null) {
      order = await client.fetchOrder(table.currentOrderId!);
    }
    if (order == null) {
      final active = await client.fetchActiveOrders();
      order = active.where((o) => o.tableId == tableId).firstOrNull;
    }
    if (order == null) {
      order = await client.createOrder(
        tableId: tableId,
        guestsCount: 2,
      );
      ref.invalidate(hallLayoutProvider);
    }

    final sortedCategories = [...menu.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final categoryId =
        sortedCategories.isNotEmpty ? sortedCategories.first.id : '';

    return OrderSession(
      table: table,
      order: order,
      menu: menu,
      selectedCategoryId: categoryId,
    );
  }
}
