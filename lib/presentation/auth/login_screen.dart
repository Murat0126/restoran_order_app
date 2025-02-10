import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth/login.dart';
import '../dishs/dishs_screen.dart';
import 'auth_service.dart';  // Наш сервис для сохранения состояния авторизации
import 'register_screen.dart'; // Экран регистрации

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final success = await login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      // После успешного логина сохраняем состояние
      await AuthService.setUserLoggedIn(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DishesListScreen()), // Переход к экрану с блюдами
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Неверный email или пароль')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Логин')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Пароль')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Войти'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Переход на страницу регистрации
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()), // Экран регистрации
                );
              },
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
