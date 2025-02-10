
import '../../database/daatabase_helper.dart';
import 'auth_helper.dart';

Future<bool> login(String email, String password) async {
  // Получаем пользователя из базы данных по email
  final user = await DatabaseHelper.getUserByEmail(email);

  if (user != null) {
    // Проверяем пароль
    return AuthHelper.verifyPassword(password, user.passwordHash);
  }

  return false;  // Пользователь не найден
}

