import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Версия схемы. Поднимать вместе с добавлением миграции в `_migrations`.
const int kSchemaVersion = 1;

/// Открывает (создавая при необходимости) базу данных и прогоняет миграции.
Database openAppDatabase(String path) {
  Directory(File(path).parent.path).createSync(recursive: true);
  final db = sqlite3.open(path);
  db
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA foreign_keys = ON');
  _runMigrations(db);
  return db;
}

void _runMigrations(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS _schema_version (
      version INTEGER PRIMARY KEY
    )
  ''');
  final row = db.select('SELECT version FROM _schema_version LIMIT 1');
  final current = row.isEmpty ? 0 : row.first['version'] as int;

  for (final entry in _migrations.entries) {
    if (entry.key <= current) continue;
    db.execute('BEGIN');
    try {
      for (final stmt in entry.value) {
        db.execute(stmt);
      }
      db.execute('DELETE FROM _schema_version');
      db.execute(
          'INSERT INTO _schema_version(version) VALUES (?)', [entry.key]);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

/// Каждая миграция — список SQL-команд, исполняющихся в одной транзакции.
const Map<int, List<String>> _migrations = {
  1: [
    '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      display_name TEXT NOT NULL,
      role TEXT NOT NULL,
      email TEXT,
      password_hash TEXT NOT NULL,
      pin_hash TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''',
    '''
    CREATE TABLE sessions (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''',
    '''
    CREATE TABLE halls (
      id TEXT PRIMARY KEY,
      restaurant_id TEXT NOT NULL,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE tables (
      id TEXT PRIMARY KEY,
      hall_id TEXT NOT NULL REFERENCES halls(id),
      number TEXT NOT NULL,
      capacity INTEGER NOT NULL DEFAULT 4,
      status TEXT NOT NULL DEFAULT 'free',
      current_order_id TEXT,
      qr_token TEXT UNIQUE
    )''',
    '''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      station TEXT NOT NULL DEFAULT 'hot'
    )''',
    '''
    CREATE TABLE dishes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      category_id TEXT NOT NULL REFERENCES categories(id),
      price REAL NOT NULL,
      discount_price REAL,
      station TEXT,
      cooking_time_minutes INTEGER NOT NULL DEFAULT 10,
      images TEXT NOT NULL DEFAULT '[]',
      available INTEGER NOT NULL DEFAULT 1
    )''',
    '''
    CREATE TABLE modifiers (
      id TEXT PRIMARY KEY,
      dish_id TEXT NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE orders (
      id TEXT PRIMARY KEY,
      table_id TEXT NOT NULL REFERENCES tables(id),
      waiter_id TEXT REFERENCES users(id),
      status TEXT NOT NULL DEFAULT 'open',
      source TEXT NOT NULL DEFAULT 'waiter',
      note TEXT NOT NULL DEFAULT '',
      guests_count INTEGER,
      created_at TEXT NOT NULL,
      sent_at TEXT,
      closed_at TEXT,
      discount_percent REAL NOT NULL DEFAULT 0,
      service_percent REAL NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
      dish_id TEXT NOT NULL,
      dish_name TEXT NOT NULL,
      qty INTEGER NOT NULL,
      price_at_moment REAL NOT NULL,
      modifier_ids TEXT NOT NULL DEFAULT '[]',
      modifiers_total REAL NOT NULL DEFAULT 0,
      note TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'draft',
      station TEXT NOT NULL DEFAULT 'hot',
      course_no INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      sent_at TEXT,
      started_at TEXT,
      ready_at TEXT
    )''',
    '''
    CREATE TABLE payments (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
      method TEXT NOT NULL,
      amount REAL NOT NULL,
      paid_at TEXT NOT NULL,
      by_user_id TEXT REFERENCES users(id)
    )''',
    'CREATE INDEX idx_orders_status ON orders(status)',
    'CREATE INDEX idx_orders_table ON orders(table_id)',
    'CREATE INDEX idx_items_order ON order_items(order_id)',
    'CREATE INDEX idx_items_status ON order_items(status)',
  ],
};
