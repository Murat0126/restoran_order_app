import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> setUserLoggedIn(bool loggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', loggedIn);
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;  // Если не найдено, возвращаем false
  }
}
