import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

import 'api.dart';
import 'cart.dart';
import 'cart_sheet.dart';

final _money = NumberFormat.currency(
  locale: 'ru',
  symbol: '₽',
  decimalDigits: 0,
);

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.qrToken});

  final String qrToken;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final RestaurantApiClient _client = buildClient();
  final Cart _cart = Cart();

  Future<_MenuData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _client.close();
    _cart.dispose();
    super.dispose();
  }

  Future<_MenuData> _load() async {
    if (widget.qrToken.isEmpty) {
      throw const _UserMessage(
        'QR-токен столика отсутствует.\n'
        'Откройте страницу со ссылкой ?t=<токен>.',
      );
    }
    final menu = await _client.fetchMenu();
    final table = await _client.fetchTableByQr(widget.qrToken);
    return _MenuData(menu: menu, table: table);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _openCart(_MenuData data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartSheet(
        cart: _cart,
        money: _money,
        onSubmit: (note) => _submitPreorder(data, note),
      ),
    );
  }

  Future<void> _submitPreorder(_MenuData data, String note) async {
    try {
      final order = await _client.createPreorder(
        qrToken: data.table.qrToken!,
        items: _cart.items
            .map((c) => PreorderItem(
                  dishId: c.dish.id,
                  qty: c.qty,
                  note: c.note,
                ))
            .toList(growable: false),
        note: note,
      );
      if (!mounted) return;
      _cart.clear();
      Navigator.of(context).pop();
      _showSuccess(order, data.table);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить: ${e.message}')),
      );
    }
  }

  void _showSuccess(Order order, RestaurantTable table) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Заказ принят'),
        content: Text(
          'Спасибо! Ваш заказ № ${order.id.substring(0, 6)} '
          'отправлен официанту стола №${table.number}.\n\n'
          'Сумма: ${_money.format(order.subtotal)}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refresh();
            },
            child: const Text('Ок'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MenuData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _ErrorScreen(
            error: snapshot.error!,
            onRetry: _refresh,
          );
        }
        return _MenuScaffold(
          data: snapshot.data!,
          cart: _cart,
          money: _money,
          onOpenCart: () => _openCart(snapshot.data!),
        );
      },
    );
  }
}

class _MenuData {
  _MenuData({required this.menu, required this.table});
  final MenuSnapshot menu;
  final RestaurantTable table;
}

class _UserMessage implements Exception {
  const _UserMessage(this.text);
  final String text;
  @override
  String toString() => text;
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = error is _UserMessage
        ? (error as _UserMessage).text
        : (error is ApiException
            ? (error as ApiException).message
            : 'Ошибка: $error');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuScaffold extends StatelessWidget {
  const _MenuScaffold({
    required this.data,
    required this.cart,
    required this.money,
    required this.onOpenCart,
  });

  final _MenuData data;
  final Cart cart;
  final NumberFormat money;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Dish>>{};
    for (final dish in data.menu.dishes.where((d) => d.available)) {
      grouped.putIfAbsent(dish.categoryId, () => []).add(dish);
    }
    final orderedCategories = [...data.menu.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Меню', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
            Text(
              'Стол №${data.table.number}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: CustomScrollView(
        slivers: [
          for (final cat in orderedCategories)
            if (grouped[cat.id]?.isNotEmpty ?? false) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: grouped[cat.id]!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DishTile(
                    dish: grouped[cat.id]![i],
                    cart: cart,
                    money: money,
                  ),
                ),
              ),
            ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: cart,
        builder: (_, __) {
          if (cart.totalCount == 0) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: onOpenCart,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Корзина · ${cart.totalCount} поз.'),
                    Text(money.format(cart.totalAmount)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.dish,
    required this.cart,
    required this.money,
  });

  final Dish dish;
  final Cart cart;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dish.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dish.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        money.format(dish.effectivePrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFB8C00),
                        ),
                      ),
                      if (dish.discountPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          money.format(dish.price),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _QtyStepper(dish: dish, cart: cart),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.dish, required this.cart});
  final Dish dish;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (_, __) {
        final qty = cart.qtyOf(dish.id);
        if (qty == 0) {
          return IconButton.filled(
            onPressed: () => cart.add(dish),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              foregroundColor: Colors.white,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E0),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => cart.add(dish, -1),
                icon: const Icon(Icons.remove, color: Color(0xFFFB8C00)),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFB8C00),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => cart.add(dish),
                icon: const Icon(Icons.add, color: Color(0xFFFB8C00)),
              ),
            ],
          ),
        );
      },
    );
  }
}
