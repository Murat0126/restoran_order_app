/// Базовое исключение клиента API.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.body,
    this.cause,
  });

  /// Сетевая ошибка (нет соединения, таймаут и т.п.).
  /// Сохраняем оригинальное исключение в [cause], чтобы UI мог
  /// диагностировать (DNS, refused, TLS и т.п.).
  factory ApiException.network(Object cause) =>
      ApiException('Сетевая ошибка: $cause', cause: cause);

  /// 401 — нужно перелогиниться.
  factory ApiException.unauthorized([String? detail]) =>
      ApiException(detail ?? 'Требуется авторизация', statusCode: 401);

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? body;

  /// Оригинальная причина (только для сетевых ошибок — `null` для
  /// HTTP-ответов с кодами 4xx/5xx).
  final Object? cause;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  /// `true`, если запрос вообще не дошёл до сервера (DNS, TCP,
  /// таймаут, отказ TLS и т.д.). Полезно отличать «сервер выключен»
  /// от «сервер вернул 4xx/5xx».
  bool get isNetwork => statusCode == null;

  @override
  String toString() =>
      'ApiException(${statusCode ?? 'NET'}: $message)';
}
