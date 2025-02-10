class User {
  final String id; // Уникальный ID пользователя
  final String username; // Имя пользователя
  final String passwordHash; // Хешированный пароль
  final String role; // Роль пользователя (например, 'waiter' или 'admin')
  final String email; // Email пользователя

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.email,
  });

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'hashedPassword': passwordHash,
      // 'role': role,
      'email': email,
    };
  }

  // Создание объекта User из Map
  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',  // Если id == null, то поставим пустую строку
      username: map['username'] ?? '',  // Если username == null, то пустую строку
      passwordHash: map['hashedPassword'] ?? '',  // Если passwordHash == null, то пустую строку
      role: map['role'] ?? '',  // Если role == null, то пустую строку
      email: map['email'] ?? '',  // Если email == null, то пустую строку
    );
  }
}
