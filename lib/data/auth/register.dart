import '../../database/daatabase_helper.dart';
import '../models/user.dart';
import 'auth_helper.dart';

Future<void> register(String name, String email, String password) async {
  // Проверка, существует ли уже пользователь с таким email
  final existingUser = await DatabaseHelper.getUserByEmail(email);
  if (existingUser != null) {
    throw Exception('Пользователь с таким email уже существует.');
  }

  // Хеширование пароля
  final hashedPassword = AuthHelper.hashPassword(password);

  // Создание нового пользователя
  final newUser = User(
    id: email,  // Используем email в качестве уникального ID
    username: name,
    email: email,
    passwordHash: hashedPassword,
    role: 'waiter', // Роль по умолчанию
  );

  // Сохраняем пользователя в базе данных
  await DatabaseHelper.registerUser(newUser);
}
