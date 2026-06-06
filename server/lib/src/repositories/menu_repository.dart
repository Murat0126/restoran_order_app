import 'dart:convert';

import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart';

class MenuRepository {
  MenuRepository(this._db);

  final Database _db;

  List<MenuCategory> allCategories() {
    final rows =
        _db.select('SELECT * FROM categories ORDER BY sort_order, name');
    return rows.map(_mapToCategory).toList(growable: false);
  }

  List<Dish> allDishes({bool onlyAvailable = false}) {
    final where = onlyAvailable ? 'WHERE available = 1' : '';
    final rows = _db.select('SELECT * FROM dishes $where ORDER BY name');
    return rows.map(_mapToDish).toList(growable: false);
  }

  Dish? findDish(String id) {
    final r = _db.select('SELECT * FROM dishes WHERE id = ?', [id]);
    if (r.isEmpty) return null;
    return _mapToDish(r.first);
  }

  bool isEmpty() {
    final r = _db.select('SELECT COUNT(*) AS c FROM dishes');
    return (r.first['c'] as int) == 0;
  }

  void insertCategory(MenuCategory c) {
    _db.execute(
      'INSERT INTO categories(id, name, sort_order, station) VALUES (?, ?, ?, ?)',
      [c.id, c.name, c.sortOrder, c.station.name],
    );
  }

  void insertDish(Dish d) {
    _db.execute(
      '''INSERT INTO dishes
        (id, name, description, category_id, price, discount_price,
         station, cooking_time_minutes, images, available)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        d.id,
        d.name,
        d.description,
        d.categoryId,
        d.price,
        d.discountPrice,
        d.station?.name,
        d.cookingTimeMinutes,
        jsonEncode(d.images),
        d.available ? 1 : 0,
      ],
    );
  }

  MenuCategory _mapToCategory(Row r) {
    return MenuCategory(
      id: r['id'] as String,
      name: r['name'] as String,
      sortOrder: r['sort_order'] as int,
      station: Station.values.firstWhere(
        (e) => e.name == r['station'] as String,
        orElse: () => Station.hot,
      ),
    );
  }

  Dish _mapToDish(Row r) {
    return Dish(
      id: r['id'] as String,
      name: r['name'] as String,
      description: r['description'] as String? ?? '',
      categoryId: r['category_id'] as String,
      price: (r['price'] as num).toDouble(),
      discountPrice: r['discount_price'] == null
          ? null
          : (r['discount_price'] as num).toDouble(),
      station: r['station'] == null
          ? null
          : Station.values.firstWhere(
              (e) => e.name == r['station'] as String,
              orElse: () => Station.hot,
            ),
      cookingTimeMinutes: r['cooking_time_minutes'] as int,
      images: (jsonDecode(r['images'] as String) as List<dynamic>)
          .map((e) => e.toString())
          .toList(growable: false),
      available: (r['available'] as int) == 1,
    );
  }
}
