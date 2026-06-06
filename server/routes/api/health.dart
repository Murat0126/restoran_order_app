import 'package:dart_frog/dart_frog.dart';

/// `GET /api/health` — простой healthcheck, удобно для мониторинга/балансера
/// и быстрой проверки «жив ли сервер» из консоли. Возвращает список
/// основных endpoint'ов как подсказку.
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'app': 'restaurant_server',
      'status': 'ok',
      'endpoints': [
        'POST /api/auth/login',
        'GET  /api/menu',
        'GET  /api/tables',
        'GET  /api/orders',
        'POST /api/orders',
        'POST /api/orders/:id/send',
        'POST /api/preorders',
        'GET  /api/qr/<token>.png',
        'GET  /api/admin/qr-poster',
        'WS   /ws',
      ],
    },
  );
}
