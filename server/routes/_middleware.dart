import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';

/// Глобальный middleware.
///
/// * Инициализирует [AppContext] (БД + репозитории) один раз на процесс.
/// * Для статики (всё, что не `/api/*` и не `/ws`) пропускает ответ
///   как есть — это важно для крупных файлов Flutter Web и бинарных
///   PNG/иконок: иначе пришлось бы их буферизовать.
/// * Для API и WebSocket — добавляет CORS-заголовки и корректно
///   отвечает на preflight (`OPTIONS`).
Handler middleware(Handler handler) {
  AppContext.init();

  return (context) async {
    final path = context.request.uri.path;
    final isApi = path.startsWith('/api') || path == '/ws';

    if (!isApi) {
      // Статика — Dart Frog сам отдаст файл из public/.
      return handler(context);
    }

    if (context.request.method == HttpMethod.options) {
      return Response(headers: _corsHeaders);
    }

    final response = await handler(context);

    // 101 Switching Protocols — WebSocket upgrade, его не трогаем.
    if (response.statusCode == 101) return response;

    // Сохраняем тело как байты (универсально для JSON и бинарных PNG).
    final bytes = await response.bytes().fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    return Response.bytes(
      body: bytes,
      statusCode: response.statusCode,
      headers: {...response.headers, ..._corsHeaders},
    );
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods':
      'GET, POST, PATCH, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, If-Match',
  'Access-Control-Expose-Headers': 'ETag',
};
