import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../features/auth/auth_providers.dart';
import '../api/api_base_url.dart';

/// `RealtimeChannel` поверх WebSocket Dart Frog сервера.
///
/// Жизненный цикл:
///   - **создаётся, когда** пользователь авторизован (есть user)
///     и есть `baseUrl`;
///   - **dispose-ится автоматически**, если меняется baseUrl
///     (через `ref.watch(apiBaseUrlProvider)`) или происходит signOut
///     (через `ref.watch(authStateProvider)`);
///   - **`null`** для анонимного пользователя — WS-канал держать
///     незачем (на F5 сервер не пропускает анонимов по протоколу,
///     но даже если бы пропускал — событий «для всех» нет).
///
/// Все экраны должны брать канал именно через этот провайдер —
/// тогда переподключение «прозрачное» при смене сервера и логауте.
final realtimeChannelProvider = Provider<RealtimeChannel?>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.isSignedIn) return null;

  final baseUrl = ref.watch(apiBaseUrlProvider);
  final channel = RealtimeChannel.fromApiBase(baseUrl);
  // Connect не ждём — он сам сделает reconnect-цикл при провалах.
  // ignore: discarded_futures
  channel.connect();
  ref.onDispose(() async {
    await channel.dispose();
  });
  return channel;
});

/// Текущий статус (connecting/connected/disconnected) для UI.
final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) async* {
  final channel = ref.watch(realtimeChannelProvider);
  if (channel == null) {
    yield RealtimeStatus.disconnected;
    return;
  }
  yield channel.currentStatus;
  yield* channel.status;
});

/// Поток всех серверных событий (`WsEvent`) — для подписок в feature-screens.
final realtimeEventsProvider = StreamProvider<WsEvent>((ref) async* {
  final channel = ref.watch(realtimeChannelProvider);
  if (channel == null) return;
  yield* channel.events;
});
