import 'dart:io';

import 'package:shared_models/shared_models.dart';

import 'app_context.dart';
import 'auth.dart';

/// Наполняет базу тестовыми данными при первом запуске.
void seedIfEmpty(AppContext ctx) {
  // Users — идемпотентно: добавляем только тех, кого ещё нет.
  // Это важно при добавлении новых ролей (например, director)
  // на уже инициализированной БД.
  _seedUsers(ctx);
  if (ctx.tables.isEmpty()) _seedHallsAndTables(ctx);
  if (ctx.menu.isEmpty()) _seedMenu(ctx);
}

void _seedUsers(AppContext ctx) {
  final adminPwd = Platform.environment['ADMIN_PASSWORD'] ?? '1234';

  final seed = <_SeedUser>[
    _SeedUser('u-admin', 'admin', 'Администратор', UserRole.admin, adminPwd),
    _SeedUser(
      'u-director1',
      'director1',
      'Назгуль (директор)',
      UserRole.director,
      '1234',
    ),
    _SeedUser(
      'u-waiter1',
      'waiter1',
      'Айгуль (официант)',
      UserRole.waiter,
      '1234',
    ),
    _SeedUser(
      'u-cashier1',
      'cashier1',
      'Эльдар (касса)',
      UserRole.cashier,
      '1234',
    ),
    _SeedUser('u-cook1', 'cook1', 'Мирлан (повар)', UserRole.cook, '1234'),
  ];

  for (final s in seed) {
    if (ctx.users.findByUsername(s.username) != null) continue;
    ctx.users.create(
      id: s.id,
      username: s.username,
      displayName: s.displayName,
      role: s.role,
      passwordHash: hashPassword(s.password),
    );
  }
}

class _SeedUser {
  const _SeedUser(
    this.id,
    this.username,
    this.displayName,
    this.role,
    this.password,
  );
  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final String password;
}

void _seedHallsAndTables(AppContext ctx) {
  const restaurantId = 'r-main';
  ctx.tables.insertHall(const Hall(
    id: 'hall-main',
    restaurantId: restaurantId,
    name: 'Основной зал',
  ));
  for (var i = 1; i <= 5; i++) {
    ctx.tables.insertTable(RestaurantTable(
      id: 't-$i',
      hallId: 'hall-main',
      number: '$i',
      capacity: i.isEven ? 4 : 2,
      qrToken: generateQrToken(),
    ));
  }
}

void _seedMenu(AppContext ctx) {
  final categories = <MenuCategory>[
    const MenuCategory(
        id: 'c-salad', name: 'Салаты', sortOrder: 1, station: Station.cold),
    const MenuCategory(
        id: 'c-starter', name: 'Закуски', sortOrder: 2, station: Station.cold),
    const MenuCategory(
        id: 'c-soup', name: 'Супы', sortOrder: 3, station: Station.hot),
    const MenuCategory(
        id: 'c-hot', name: 'Горячее', sortOrder: 4, station: Station.hot),
    const MenuCategory(
        id: 'c-grill', name: 'Гриль', sortOrder: 5, station: Station.grill),
    const MenuCategory(
        id: 'c-dessert', name: 'Десерты', sortOrder: 6, station: Station.cold),
    const MenuCategory(
        id: 'c-bar', name: 'Напитки', sortOrder: 7, station: Station.bar),
  ];
  for (final c in categories) {
    ctx.menu.insertCategory(c);
  }

  final dishes = <Dish>[
    const Dish(
        id: 'd-1',
        name: 'Цезарь с курицей',
        price: 580,
        categoryId: 'c-salad',
        cookingTimeMinutes: 7),
    const Dish(
        id: 'd-2',
        name: 'Греческий салат',
        price: 450,
        categoryId: 'c-salad',
        cookingTimeMinutes: 6),
    const Dish(
        id: 'd-9',
        name: 'Салат с лососем',
        price: 720,
        categoryId: 'c-salad',
        cookingTimeMinutes: 8),
    const Dish(
        id: 'd-10',
        name: 'Микс салат',
        price: 320,
        categoryId: 'c-salad',
        cookingTimeMinutes: 5),
    const Dish(
        id: 'd-11',
        name: 'Сельдь под шубой',
        price: 250,
        categoryId: 'c-starter',
        cookingTimeMinutes: 5),
    const Dish(
        id: 'd-3',
        name: 'Борщ с говядиной',
        price: 420,
        categoryId: 'c-soup',
        cookingTimeMinutes: 10),
    const Dish(
        id: 'd-4',
        name: 'Бефстроганов',
        price: 480,
        categoryId: 'c-hot',
        cookingTimeMinutes: 18),
    const Dish(
        id: 'd-5',
        name: 'Стейк рибай',
        description: 'Традиционный стейк из премиальной говядины',
        price: 1200,
        categoryId: 'c-grill',
        cookingTimeMinutes: 20),
    const Dish(
        id: 'd-6',
        name: 'Куриные крылья',
        price: 380,
        categoryId: 'c-grill',
        cookingTimeMinutes: 15),
    const Dish(
        id: 'd-12',
        name: 'Чизкейк',
        price: 280,
        categoryId: 'c-dessert',
        cookingTimeMinutes: 3),
    const Dish(
        id: 'd-7',
        name: 'Чай Ташкентский',
        price: 250,
        categoryId: 'c-bar',
        cookingTimeMinutes: 2),
    const Dish(
        id: 'd-8',
        name: 'Эспрессо',
        price: 100,
        categoryId: 'c-bar',
        cookingTimeMinutes: 3),
  ];
  for (final d in dishes) {
    ctx.menu.insertDish(d);
  }
}
