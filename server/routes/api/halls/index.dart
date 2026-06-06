import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';
import 'package:restaurant_server/src/auth.dart';

/// `GET /api/halls` — список залов для табов карты зала.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final guard = requireAuth(context);
  if (guard != null) return guard;

  final ctx = AppContext.instance;
  return Response.json(
    body: {
      'halls': ctx.tables
          .allHalls()
          .map((h) => h.toJson())
          .toList(growable: false),
    },
  );
}
