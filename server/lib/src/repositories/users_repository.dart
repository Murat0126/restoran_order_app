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
  }) {
    _db.execute(
      '''INSERT INTO users
          (id, username, display_name, role, email, password_hash)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [id, username, displayName, role.name, email, passwordHash],
    );
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
