/// Абстракция над хранилищем bearer-токена.
///
/// Конкретная реализация подаётся снаружи: Flutter-приложение может
/// использовать `shared_preferences` / `flutter_secure_storage`,
/// Web-клиент — `window.localStorage`, тесты — in-memory.
abstract class AuthTokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Простое in-memory хранилище — подходит для тестов и QR-страницы,
/// где токен не нужен между перезагрузками.
class InMemoryAuthTokenStorage implements AuthTokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
