import 'package:flutter/material.dart';
import 'auth/auth_service.dart';

class UserProfileScreen extends StatelessWidget {
  // Метод для выхода из аккаунта
  Future<void> _logout(BuildContext context) async {
    // При выходе очищаем состояние авторизации
    await AuthService.setUserLoggedIn(false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль пользователя'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _logout(context), // Выход из аккаунта
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Здесь будет информация о пользователе'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context), // Кнопка выхода из аккаунта
              child: Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
