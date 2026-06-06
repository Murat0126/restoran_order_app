/// Перечисления, используемые во всём домене.
library;

/// Роль пользователя POS-системы.
///
/// **Иерархия прав** (от высоких к низким):
///   admin > director > cashier ≈ cook ≈ waiter
///
/// `director` — отчётно-наблюдательная роль: видит дашборды, отчёты,
/// рейтинги официантов и алерты, но не редактирует справочники
/// (этим занимается admin).
enum UserRole {
  admin,
  director,
  waiter,
  cashier,
  cook,
}

/// Жизненный цикл заказа целиком.
enum OrderStatus {
  /// Открыт официантом, в стадии добавления позиций.
  open,

  /// Хотя бы одна позиция отправлена на кухню.
  sent,

  /// Все позиции готовы / поданы, ждёт оплаты.
  ready,

  /// Счёт сформирован и распечатан, ожидает оплаты.
  billed,

  /// Оплачен.
  paid,

  /// Отменён целиком.
  cancelled,
}

/// Статус отдельной позиции заказа.
enum OrderItemStatus {
  /// Только что добавлена официантом, ещё не отправлена.
  draft,

  /// Отправлена на кухню, ждёт повара.
  pending,

  /// Повар принял в работу.
  cooking,

  /// Готово, ждёт официанта.
  ready,

  /// Подано клиенту.
  served,

  /// Отменено.
  cancelled,
}

/// Статус столика.
enum TableStatus {
  free,
  occupied,
  reserved,
  bill,
}

/// Цех / станция на кухне.
enum Station {
  hot,
  cold,
  bar,
  grill,
  dessert,
  other,
}

/// Способ оплаты.
enum PaymentMethod {
  cash,
  card,
  transfer,
}

/// Источник заказа.
enum OrderSource {
  waiter,
  qrPreorder,
}
