import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/qr_renderer.dart';

/// `GET /api/qr/<qrToken>[.png]?size=512&margin=32&base=https://...`
///
/// Возвращает PNG с QR-кодом, который ведёт на страницу клиентского
/// меню для указанного столика:
///
///   `<base>/?t=<qrToken>`
///
/// `<base>` определяется так:
///   1. query-параметр `base`, если передан;
///   2. иначе — `scheme://host[:port]` из заголовков запроса
///      (тот же URL, по которому пришёл запрос).
///
/// Это значит: если админ открыл `http://192.168.1.10:8765/api/qr/abc.png`,
/// QR будет указывать на `http://192.168.1.10:8765/?t=abc`. Если зашёл
/// через Cloudflare Tunnel `https://menu.example.com/api/qr/abc.png` —
/// QR будет `https://menu.example.com/?t=abc`.
Future<Response> onRequest(RequestContext context, String token) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // В пути может быть как "abc", так и "abc.png" — второе удобнее
  // для браузеров (правильный MIME из расширения).
  final cleanToken = token.endsWith('.png')
      ? token.substring(0, token.length - 4)
      : token;

  final table = AppContext.instance.tables.byQrToken(cleanToken);
  if (table == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Стол с таким QR-токеном не найден'},
    );
  }

  final query = context.request.uri.queryParameters;
  final overrideBase = query['base']?.trim();
  final baseUrl = (overrideBase != null && overrideBase.isNotEmpty)
      ? overrideBase.replaceFirst(RegExp(r'/+$'), '')
      : _inferPublicBaseUrl(context);

  final menuUrl = '$baseUrl/?t=$cleanToken';

  final size = int.tryParse(query['size'] ?? '') ?? 512;
  final margin = int.tryParse(query['margin'] ?? '') ?? 32;

  final png = renderQrPng(
    data: menuUrl,
    size: size.clamp(128, 2048),
    margin: margin.clamp(0, 200),
  );

  return Response.bytes(
    body: png,
    headers: const {
      'Content-Type': 'image/png',
      'Cache-Control': 'no-store',
    },
  );
}

String _inferPublicBaseUrl(RequestContext context) {
  final request = context.request;
  final headers = request.headers;

  // За reverse-proxy / туннелем приходит X-Forwarded-*.
  final forwardedProto = headers['x-forwarded-proto'];
  final forwardedHost = headers['x-forwarded-host'];
  if (forwardedProto != null && forwardedHost != null) {
    return '$forwardedProto://$forwardedHost';
  }

  final uri = request.uri;
  final host = headers['host'] ?? '${uri.host}:${uri.port}';
  return '${uri.scheme}://$host';
}
