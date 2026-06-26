import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart';

import '../auth.dart';

class UsersRepository {
  UsersRepository(this._db);

  final Database _db;

  User? findByUsername(String username) {
    final r = _db.select(
      'SELECT * FROM users WHERE username = ?',
      [username],
    );
    if (r.isEmpty) return null;
    return _mapToUser(r.first);
  }

  User? findById(String id) {
    final r = _db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (r.isEmpty) return null;
    return _mapToUser(r.first);
  }

  String? passwordHash(String username) {
    final r = _db.select(
      'SELECT password_hash FROM users WHERE username = ?',
      [username],
    );
    if (r.isEmpty) return null;
    return r.first['password_hash'] as String;
  }

  void create({
    required String id,
    required String username,
    required String displayName,
    required UserRole role,
    required String passwordHash,
    String? email,
    String? pinHash,
  }) {
    _db.execute(
      '''INSERT INTO users
          (id, username, display_name, role, email, password_hash, pin_hash)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [id, username, displayName, role.name, email, passwordHash, pinHash],
    );
  }

  /// Все пользователи (для админки). Сортировка: по роли, затем по имени.
  List<User> allUsers() {
    final rows =
        _db.select('SELECT * FROM users ORDER BY role, display_name');
    return rows.map(_mapToUser).toList(growable: false);
  }

  /// Частичное обновление профиля. Пустой [email] трактуется как `NULL`.
  void updateProfile({
    required String id,
    String? displayName,
    UserRole? role,
    String? email,
  }) {
    final sets = <String>[];
    final args = <Object?>[];
    if (displayName != null) {
      sets.add('display_name = ?');
      args.add(displayName);
    }
    if (role != null) {
      sets.add('role = ?');
      args.add(role.name);
    }
    if (email != null) {
      sets.add('email = ?');
      args.add(email.isEmpty ? null : email);
    }
    if (sets.isEmpty) return;
    args.add(id);
    _db.execute('UPDATE users SET ${sets.join(', ')} WHERE id = ?', args);
  }

  void setPassword(String id, String passwordHash) {
    _db.execute(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [passwordHash, id],
    );
  }

  /// Устанавливает или (при `null`) сбрасывает PIN быстрого входа.
  void setPin(String id, String? pinHash) {
    _db.execute('UPDATE users SET pin_hash = ? WHERE id = ?', [pinHash, id]);
  }

  void deleteUser(String id) {
    _db.execute('DELETE FROM users WHERE id = ?', [id]);
  }

  int countByRole(UserRole role) {
    final r = _db.select(
      'SELECT COUNT(*) AS c FROM users WHERE role = ?',
      [role.name],
    );
    return r.first['c'] as int;
  }

  /// PIN-вход: возвращает id пользователя, чей PIN совпадает, иначе `null`.
  /// Перебираем только тех, у кого PIN задан (их единицы — это нормально).
  String? userIdByPin(String pin) {
    final rows =
        _db.select('SELECT id, pin_hash FROM users WHERE pin_hash IS NOT NULL');
    for (final row in rows) {
      final hash = row['pin_hash'] as String?;
      if (hash != null && verifyPassword(pin, hash)) {
        return row['id'] as String;
      }
    }
    return null;
  }

  bool isEmpty() {
    final r = _db.select('SELECT COUNT(*) AS c FROM users');
    return (r.first['c'] as int) == 0;
  }

  /// Создаёт сессионный токен и возвращает его.
  String openSession(String userId) {
    final token = generateToken();
    _db.execute(
      'INSERT INTO sessions(token, user_id) VALUES (?, ?)',
      [token, userId],
    );
    return token;
  }

  void closeSession(String token) {
    _db.execute('DELETE FROM sessions WHERE token = ?', [token]);
  }

  User? userByToken(String token) {
    final r = _db.select(
      '''SELECT u.* FROM users u
         JOIN sessions s ON s.user_id = u.id
         WHERE s.token = ?''',
      [token],
    );
    if (r.isEmpty) return null;
    return _mapToUser(r.first);
  }

  User _mapToUser(Row r) {
    return User(
      id: r['id'] as String,
      username: r['username'] as String,
      displayName: r['display_name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == r['role'] as String,
        orElse: () => UserRole.waiter,
      ),
      email: r['email'] as String?,
      hasPin: r['pin_hash'] != null,
    );
  }
}
