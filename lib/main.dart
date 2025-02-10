import 'package:flutter/material.dart';

import 'presentation/auth/auth_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/dishs/dishs_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: AuthService.isUserLoggedIn(),
        builder: (context, snapshot) {
          // Если загрузка завершена
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              return DishesListScreen();  // Если пользователь авторизован
            } else {
              return LoginScreen();  // Если не авторизован, показываем экран логина
            }
          } else {
            return Center(child: CircularProgressIndicator());  // Пока загружаем состояние
          }
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),  // Экран логина
        '/register': (context) => RegisterScreen(),  // Экран регистрации
        '/dishesList': (context) => DishesListScreen(),  // Экран с блюдами
      },
    );
  }
}
