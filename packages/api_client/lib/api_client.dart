/// Типизированный клиент REST-API и WebSocket-канала сервера ресторана.
///
/// Один и тот же пакет используется и POS-приложением,
/// и Flutter Web QR-меню. Поэтому не зависит от Flutter.
library api_client;

export 'src/api_exception.dart';
export 'src/auth_token_storage.dart';
export 'src/realtime_channel.dart';
export 'src/restaurant_api_client.dart';
