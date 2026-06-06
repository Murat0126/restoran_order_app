import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

import 'package:restaurant_server/src/event_bus.dart';

/// WebSocket-эндпоинт. Любой клиент, подключившийся к `/ws`,
/// получает все события из `EventBus` в JSON-формате.
Future<Response> onRequest(RequestContext context) async {
  final handler = webSocketHandler((channel, protocol) {
    late StreamSubscription<dynamic> sub;
    sub = EventBus.instance.stream.listen(
      (event) {
        channel.sink.add(jsonEncode(event.toJson()));
      },
      onError: (Object _) {},
    );

    channel.sink.add(jsonEncode({'type': 'system.hello'}));

    channel.stream.listen(
      (_) {},
      onDone: () => sub.cancel(),
      onError: (Object _) => sub.cancel(),
    );
  });

  return handler(context);
}
