import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// `GET /` — отдаёт стартовую страницу QR-меню (Flutter Web).
///
/// Dart Frog умеет отдавать произвольные статические файлы из `public/`,
/// но индексной маршрутизации для `/` нет — без этого роута браузер
/// получает 404. Здесь мы читаем `public/index.html` и возвращаем его.
///
/// Если сборка ещё не скопирована (фронтенд не собрали) — возвращаем
/// внятный JSON с подсказкой, как это починить, а не глухой 404.
Future<Response> onRequest(RequestContext context) async {
  final indexFile = File('public/index.html');
  if (!await indexFile.exists()) {
    return Response.json(
      statusCode: 503,
      body: {
        'error': 'frontend_not_built',
        'message': 'Сборка Flutter Web не найдена в server/public/.',
        'hint':
            'Запустите ./scripts/build_and_run.ps1 либо `flutter build web` '
            'в client_menu/ и скопируйте build/web/* в server/public/.',
        'api_health': '/api/health',
      },
    );
  }
  final html = await indexFile.readAsBytes();
  return Response.bytes(
    body: html,
    headers: const {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  );
}
