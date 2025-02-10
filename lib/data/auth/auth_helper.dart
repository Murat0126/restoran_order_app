import 'package:bcrypt/bcrypt.dart';

class AuthHelper {
  // Хеширование пароля
  static String hashPassword(String password) {
    if (password.isEmpty) {
      throw Exception("====================Пароль не может быть пустым");
    }
    String salt = BCrypt.gensalt();
    print("-------------------Генерируемая соль: $salt");  // Логирование соли
    return BCrypt.hashpw(password, salt);
  }

  // Проверка пароля
  static bool verifyPassword(String password, String hashedPassword) {
    if (password.isEmpty || hashedPassword.isEmpty) {
      throw Exception("!!!!!!!!!!!!!!!!!!!Пароль или хешированный пароль не может быть пустым");
    }
    print("+++++++++++++++++++++Проверка пароля: $password против хешированного: $hashedPassword");  // Логирование
    return BCrypt.checkpw(password, hashedPassword);
  }
}
