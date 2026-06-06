import 'package:dart_frog/dart_frog.dart';

import 'package:restaurant_server/src/app_context.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  final ctx = AppContext.instance;
  return Response.json(
    body: {
      'categories': ctx.menu
          .allCategories()
          .map((c) => c.toJson())
          .toList(growable: false),
      'dishes':
          ctx.menu.allDishes().map((d) => d.toJson()).toList(growable: false),
    },
  );
}
