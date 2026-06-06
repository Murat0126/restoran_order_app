// ignore_for_file: file_names

import 'package:dart_frog/dart_frog.dart';
import 'package:restaurant_server/src/app_context.dart';

Response onRequest(RequestContext context, String token) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final ctx = AppContext.instance;
  final table = ctx.tables.byQrToken(token);
  if (table == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Стол по такому QR-коду не найден'},
    );
  }
  return Response.json(body: {'table': table.toJson()});
}
