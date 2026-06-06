import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'event_bus.dart';
import 'repositories/menu_repository.dart';
import 'repositories/orders_repository.dart';
import 'repositories/tables_repository.dart';
import 'repositories/users_repository.dart';
import 'seed.dart';

/// Глобальный контейнер зависимостей сервера.
/// Инициализируется один раз при старте процесса.
class AppContext {
  AppContext._({
    required this.db,
    required this.menu,
    required this.orders,
    required this.tables,
    required this.users,
    required this.events,
  });

  final Database db;
  final MenuRepository menu;
  final OrdersRepository orders;
  final TablesRepository tables;
  final UsersRepository users;
  final EventBus events;

  static AppContext? _instance;

  static AppContext get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
          'AppContext не инициализирован. Вызовите AppContext.init().');
    }
    return inst;
  }

  static AppContext init() {
    if (_instance != null) return _instance!;

    final dbPath = Platform.environment['DB_PATH'] ?? '.data/restaurant.db';
    final db = openAppDatabase(dbPath);

    final ctx = AppContext._(
      db: db,
      menu: MenuRepository(db),
      orders: OrdersRepository(db),
      tables: TablesRepository(db),
      users: UsersRepository(db),
      events: EventBus.instance,
    );

    seedIfEmpty(ctx);
    _instance = ctx;
    return ctx;
  }
}
