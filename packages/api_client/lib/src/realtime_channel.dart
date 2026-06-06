import 'dart:async';
import 'dart:convert';

import 'package:shared_models/shared_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Подключение к серверному WebSocket. Делает автоматический
/// re-connect с экспоненциальной задержкой при разрыве.
class RealtimeChannel {
  RealtimeChannel({required this.url});

  /// Удобный конструктор: получает HTTP base URL клиента (`http://...`
  /// или `https://...`) и сам подставляет правильную схему (`ws`/`wss`)
  /// и путь `/ws`. Это критично за HTTPS-туннелем (Cloudflare Tunnel,
  /// ngrok) — иначе браузер заблокирует mixed-content.
  factory RealtimeChannel.fromApiBase(
    String apiBaseUrl, {
    String path = '/ws',
  }) {
    return RealtimeChannel(url: wsUrlFromApiBase(apiBaseUrl, path: path));
  }

  /// Полный URL вида `ws://192.168.1.10:8765/ws` или `wss://x.example.com/ws`.
  final String url;

  /// Возвращает корректный ws-URL из http base URL.
  static String wsUrlFromApiBase(
    String apiBaseUrl, {
    String path = '/ws',
  }) {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = (uri.scheme == 'https' || uri.scheme == 'wss')
        ? 'wss'
        : 'ws';
    return uri.replace(scheme: scheme, path: path).toString();
  }

  final _eventsController = StreamController<WsEvent>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  bool _disposed = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  RealtimeStatus _status = RealtimeStatus.disconnected;

  Stream<WsEvent> get events => _eventsController.stream;
  Stream<RealtimeStatus> get status => _statusController.stream;
  RealtimeStatus get currentStatus => _status;

  Future<void> connect() async {
    if (_disposed) return;
    _retryTimer?.cancel();
    await _closeCurrent();

    _setStatus(RealtimeStatus.connecting);
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: false,
      );
      _setStatus(RealtimeStatus.connected);
      _retryAttempt = 0;
    } catch (e) {
      _setStatus(RealtimeStatus.disconnected);
      _scheduleReconnect();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _closeCurrent();
    await _eventsController.close();
    await _statusController.close();
  }

  // ----------------------------------------------------------------

  void _onMessage(Object? data) {
    if (data is! String) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    // Технические сообщения сервера (например, hello при коннекте)
    // мы пропускаем — у них тип не сериализуется как WsEvent.
    final type = json['type'] as String?;
    if (type == null || type.startsWith('system.')) return;
    try {
      _eventsController.add(WsEvent.fromJson(json));
    } catch (_) {
      // Игнорируем неизвестные/невалидные события — не валим стрим.
    }
  }

  void _onDone() {
    _setStatus(RealtimeStatus.disconnected);
    _scheduleReconnect();
  }

  void _onError(Object error) {
    _setStatus(RealtimeStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _retryAttempt++;
    final seconds = _retryAttempt > 6 ? 30 : (1 << (_retryAttempt - 1));
    _retryTimer = Timer(Duration(seconds: seconds), connect);
  }

  Future<void> _closeCurrent() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {/* ignore */}
    _channel = null;
  }

  void _setStatus(RealtimeStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }
}

enum RealtimeStatus { disconnected, connecting, connected }
