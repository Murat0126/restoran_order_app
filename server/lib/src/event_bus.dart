import 'dart:async';

import 'package:shared_models/shared_models.dart';

/// Шина серверных событий. Все WebSocket-клиенты слушают этот стрим
/// и рассылают полученные сообщения наружу.
///
/// В рамках процесса — синглтон, потому что у нас один in-memory
/// broadcast, и Dart Frog не форкает процессы.
class EventBus {
  EventBus._();

  static final EventBus instance = EventBus._();

  final _controller = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get stream => _controller.stream;

  void emit(WsEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> close() => _controller.close();
}
