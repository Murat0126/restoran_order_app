/// Общая модельная библиотека для сервера, POS и клиентского QR-меню.
///
/// Все DTO неизменяемы (immutable), имеют `fromJson` / `toJson`
/// и не зависят от Flutter — могут жить в чистом Dart-коде на сервере.
library shared_models;

export 'src/enums.dart';
export 'src/events.dart';
export 'src/menu.dart';
export 'src/order.dart';
export 'src/restaurant.dart';
export 'src/user.dart';
export 'src/util/json_utils.dart';
