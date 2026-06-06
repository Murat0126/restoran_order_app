# POS — Официант (W1–W2)

> Карта зала, экран заказа, realtime. W3+ — в очереди.

## W1 — карта зала

- `GET /api/halls` + `GET /api/tables`, `GET /api/orders`
- `hallLayoutProvider` — загрузка + WS (`TableStatusChanged`, `OrderUpdated`, …)
- `WaiterHallScreen` — сетка столов по залам
- `WaiterShell` — Зал / Заказы (заглушка W4) / Настройки
- Тап по столу → `/waiter/order/:tableId`

## W2 — экран заказа

- Свободный стол: `POST /api/orders` при входе на экран
- Занятый стол: `GET /api/orders/:id` по активному заказу из layout
- Меню: категории + блюда (`menuProvider`), тап «+» → `POST /api/orders/:id/items`
- Корзина: черновые позиции (`status == draft`), удаление → `DELETE /api/orders/:id/items/:itemId`
- Гости: stepper → `PATCH /api/orders/:id` (`guestsCount`)
- Узкий экран (телефон): вкладки **Меню** | **Корзина**
- Широкий (планшет): три колонки — категории | блюда | корзина
- Кнопка «На кухню» — `POST /api/orders/:id/send` (черновые позиции → `pending`)

### API (добавлено в W2)

| Метод | Путь | Назначение |
| ----- | ---- | ---------- |
| GET | `/api/orders/:id` | Заказ с позициями |
| PATCH | `/api/orders/:id` | Обновить `guestsCount` |
| DELETE | `/api/orders/:id/items/:itemId` | Удалить черновую позицию |
| POST | `/api/orders/:id/send` | Отправить черновики на кухню |

## W4 — мои заказы

- `GET /api/orders?mine=true` — только заказы текущего официанта
- POS: `waiterOrdersProvider`, экран `waiter_orders_screen.dart`
- «Подано» — `PATCH` позиций `ready` → `served` для заказа

## W3 — отправка на кухню

- `OrdersRepository.sendToKitchen` — `draft` → `pending`, заказ → `sent`
- WS: `OrderSentToKitchen`, `KitchenItemAdded` (на каждую позицию)
- POS: `OrderSessionNotifier.sendToKitchen()` + кнопка в `order_cart_panel.dart`

## Маршруты

| Путь | Экран |
| ---- | ----- |
| `/waiter` | Карта зала |
| `/waiter/orders` | Мои заказы (`GET /api/orders?mine=true`) |
| `/waiter/menu` | Просмотр меню (без столика) |
| `/waiter/order/:tableId` | Заказ (меню + корзина) |

Доступ только для `UserRole.waiter` (`router.dart` redirect).

## Как проверить

1. Сервер: `dart_frog dev --port 8765`
2. POS: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8765`
3. Войти `waiter1` / `1234`
4. Карта зала — 5 столов «Основной зал»
5. Тап по **свободному** столу → создаётся заказ, открывается экран заказа
6. Добавить блюда «+», изменить гостей, удалить позицию из корзины (только draft)
7. «Отправить на кухню» — черновики уходят в блок «Отправлено», карта зала обновляется
8. В другой вкладке изменить заказ через API — корзина/карта обновятся по WS

## Файлы

```
apps/pos/lib/features/hall/
  hall_layout.dart, hall_providers.dart
  presentation/table_card.dart, waiter_hall_screen.dart
apps/pos/lib/features/order/
  order_session.dart, order_session_provider.dart
  presentation/waiter_order_screen.dart
  presentation/order_cart_panel.dart, dish_tile.dart
apps/pos/lib/features/menu/menu_providers.dart
apps/pos/lib/features/waiter/presentation/waiter_shell.dart
server/routes/api/orders/[id]/index.dart
server/routes/api/orders/[id]/items/[itemId]/index.dart
packages/api_client/ — fetchOrder, updateOrderGuests, removeDraftItem
```

## Дальше

| Этап | Содержание |
| ---- | ---------- |
| W3 | ✅ `POST /api/orders/:id/send` — отправка на кухню |
| W4 | ✅ «Мои заказы» (`?mine=true`, кнопка «Подано») |
| UI | ✅ Модалка блюда `pos_2.4_2`, экран «Меню» |
| W5 | ✅ QR-предзаказы — WS `PreorderCreated`, панель уведомлений, статус на карточке |
| W6–W8 | Офлайн, полировка, 401 interceptor |

## W5 — QR-предзаказы

- Гость: `POST /api/preorders` (client_menu), без авторизации, `qrToken` столика
- Сервер: заказ `source: qrPreorder`, позиции `draft`, стол `occupied`
- WS: `PreorderCreated` + `TableStatusChanged`
- POS: `preorderAlertOrderIdsProvider`, панель на карте зала (колокольчик)
- Карточка стола: бейдж «QR-предзаказ» (`semantic.table.qrPreorder`)
- Подтверждение: открыть заказ → «Отправить на кухню» (`POST /api/orders/:id/send`)
- При отправке официант привязывается к заказу, если `waiterId` был пуст
