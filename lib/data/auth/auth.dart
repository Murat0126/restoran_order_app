import 'package:flutter/material.dart';
import 'package:restaurant_menu/data/auth/register.dart';

import '../models/user.dart';
import 'login.dart';

Future<void> navigateToHomeScreen(User user) async {
  if (user.role == 'waiter') {
    // Переход на экран для официанта
    // Navigator.pushReplacement(
      // context,
      // MaterialPageRoute(builder: (context) => WaiterHomeScreen()),
    // );
  } else if (user.role == 'admin') {
    // Переход на экран администратора
    // Navigator.pushReplacement(
      // context,
      // MaterialPageRoute(builder: (context) => AdminHomeScreen()),
    // );
  }
}

// Регистрация
void onRegister(String username, String password, String role) async {
  await register(username, password, role);
  // Перенаправление на экран логина
}

// Логин
void onLogin(String username, String password) async {
  final user = await login(username, password);
  if (user != null) {
    // Логин успешен
    navigateToHomeScreen(user as User);
  } else {
    // Ошибка логина
    print('Invalid credentials');
  }
}

