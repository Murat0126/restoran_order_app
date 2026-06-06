import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

/// Состояние корзины QR-клиента: множество позиций с количеством и заметкой.
class Cart extends ChangeNotifier {
  final Map<String, _Line> _lines = {};

  Iterable<CartItem> get items =>
      _lines.values.map((l) => CartItem(dish: l.dish, qty: l.qty, note: l.note));

  int get totalCount =>
      _lines.values.fold(0, (sum, l) => sum + l.qty);

  double get totalAmount => _lines.values.fold(
      0, (sum, l) => sum + l.dish.effectivePrice * l.qty);

  int qtyOf(String dishId) => _lines[dishId]?.qty ?? 0;

  void add(Dish dish, [int delta = 1]) {
    final line = _lines.putIfAbsent(dish.id, () => _Line(dish: dish));
    line.qty += delta;
    if (line.qty <= 0) {
      _lines.remove(dish.id);
    }
    notifyListeners();
  }

  void setNote(String dishId, String note) {
    final line = _lines[dishId];
    if (line == null) return;
    line.note = note;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

class CartItem {
  CartItem({required this.dish, required this.qty, required this.note});
  final Dish dish;
  final int qty;
  final String note;
}

class _Line {
  _Line({required this.dish});
  final Dish dish;
  int qty = 0;
  String note = '';
}
