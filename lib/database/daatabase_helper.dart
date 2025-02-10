import 'package:sqflite/sqflite.dart';

import '../data/models/dish.dart';
import '../data/models/order.dart';
import '../data/models/user.dart';

class DatabaseHelper {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      '$dbPath/restaurant.db',
      onCreate: (db, version) {
        // Создаем таблицу для блюд
        db.execute('''CREATE TABLE dishes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          description TEXT,
          cuisineType TEXT,
          dishType TEXT,
          price REAL,
          discountPrice REAL,
          images TEXT
        )''');

        // Создаем таблицу для заказов
        db.execute('''CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          waiterId TEXT,
          tableId TEXT,
          orderedDishes TEXT,  -- Список ID блюд
          orderDateTime TEXT,
          isPaid INTEGER
        )''');

        db.execute('''CREATE TABLE users(
          id TEXT PRIMARY KEY,
          username TEXT,
          email TEXT,
          hashedPassword TEXT
          role TEXT
        )''');
      },
      version: 2,
    );
  }

  // Метод для добавления заказа
  static Future<void> insertOrder(Order order) async {
    final db = await getDatabase();
    await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Метод для получения всех заказов
  static Future<List<Order>> getOrders(List<Dish> allDishes) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i], allDishes);
    });
  }

  // Метод для получения заказов по официанту
  static Future<List<Order>> getOrdersByWaiter(String waiterId, List<Dish> allDishes) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'waiterId = ?',
      whereArgs: [waiterId],
    );
    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i], allDishes);
    });
  }







  // Метод для добавления блюда
  static Future<void> insertDish(Dish dish) async {
    final db = await getDatabase();
    await db.insert(
      'dishes',
      dish.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Метод для обновления блюда
  static Future<void> updateDish(Dish dish) async {
    final db = await getDatabase();
    await db.update(
      'dishes',
      dish.toMap(),
      where: 'id = ?',
      whereArgs: [dish.id],
    );
  }

  // Метод для получения всех блюд
  static Future<List<Dish>> getDishes() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('dishes');
    return List.generate(maps.length, (i) {
      return Dish.fromMap(maps[i]);
    });
  }

  // Метод для получения блюд по типу кухни и типу блюда
  static Future<List<Dish>> getDishesByCuisineAndType(String cuisineType, String dishType) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'dishes',
      where: 'cuisineType = ? AND dishType = ?',
      whereArgs: [cuisineType, dishType],
    );
    return List.generate(maps.length, (i) {
      return Dish.fromMap(maps[i]);
    });
  }



  // Метод для регистрации пользователя
  static Future<void> registerUser(User user) async {
    final db = await getDatabase();
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Метод для поиска пользователя по email
  static Future<User?> getUserByEmail(String email) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
}
