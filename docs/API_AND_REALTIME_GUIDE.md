# API & Realtime (F5)

> Документ описывает контракт между `apps/pos` и Dart Frog сервером после F5: где живёт base URL, как устроен реальный логин, как переподключается WebSocket, и как этим всем пользоваться из feature-экранов.

## TL;DR

- HTTP базовый URL → `apiBaseUrlProvider` (priority: `--dart-define=API_BASE_URL` > `SharedPreferences[api.base_url]` > web origin > `http://localhost:8080`).
- API клиент → `restaurantApiClientProvider`. Один `RestaurantApiClient` на приложение. **Автоматически пересоздаётся** при смене base URL (старый закрывается).
- Токен → `tokenStorageProvider` (поверх `SharedPreferences[api.bearer_token]`). Передаётся как `Authorization: Bearer ...`.
- Логин → `ref.read(authStateProvider.notifier).signIn(username, password)`. Бросает `AuthError` подкласс при ошибке.
- WebSocket → `realtimeChannelProvider` + `realtimeStatusProvider` + `realtimeEventsProvider`. **Авто-connect** при `AuthSignedIn`, **dispose** при `signOut` или смене base URL.
- Индикатор соединения → `ConnectionIndicator()`. Уже подцеплен в `RoleHomeScreen.AppBar` и `Settings → Сервер`.

---

## Источники base URL

`lib/core/api/api_base_url.dart` — `ApiBaseUrlNotifier`. При старте читает по приоритету:

1. **Compile-time:** `--dart-define=API_BASE_URL=http://your-host:port` — переопределяет всё, нельзя поменять в рантайме.
2. **Runtime persist:** `SharedPreferences[api.base_url]` — то, что пользователь сохранил в `Settings → Сервер`.
3. **Web fallback:** `Uri.base.origin` — потому что мы подаём Flutter Web с того же Dart Frog, что API.
4. **Дефолт:** `http://localhost:8080`.

### Как менять

```dart
// В рантайме (например, после ввода в Settings):
await ref.read(apiBaseUrlProvider.notifier).set('http://192.168.1.10:8080');

// Сбросить к дефолту:
await ref.read(apiBaseUrlProvider.notifier).reset();
```

После `set(...)`:
- `restaurantApiClientProvider` инвалидируется → старый клиент закрывается (`ref.onDispose`), новый поднимается.
- `realtimeChannelProvider` инвалидируется → старый WS-канал dispose'ится, новый поднимается (если пользователь авторизован).

---

## REST: `RestaurantApiClient`

Пакет `packages/api_client` — pure-Dart клиент, переиспользуется и POS, и client_menu, и smoke-тестами.

Доступен через `ref.watch(restaurantApiClientProvider)`. Уже умеет:

| Метод                           | Endpoint                            | Auth |
| ------------------------------- | ----------------------------------- | ---- |
| `login(username, password)`     | `POST /api/auth/login`              | —    |
| `logout()`                      | (локально) — чистит токен           | —    |
| `health()` ⭐                   | `GET /api/health`                   | —    |
| `fetchMenu()`                   | `GET /api/menu`                     | —    |
| `fetchTables()`                 | `GET /api/tables`                   | ✓    |
| `fetchTableByQr(token)`         | `GET /api/tables/by-qr/<token>`     | —    |
| `fetchActiveOrders()`           | `GET /api/orders`                   | ✓    |
| `fetchMyOrders()`               | `GET /api/orders?mine=true`         | ✓    |
| `createOrder(...)`              | `POST /api/orders`                  | ✓    |
| `addItemToOrder(...)`           | `POST /api/orders/<id>/items`       | ✓    |
| `sendToKitchen(orderId)`        | `POST /api/orders/<id>/send`        | ✓    |
| `changeItemStatus(...)`         | `PATCH /api/orders/<id>/items/<id>/status` | ✓ |
| `pay(orderId, ...)`             | `POST /api/orders/<id>/pay`         | ✓    |
| `fetchKitchenTickets()`         | `GET /api/kitchen/tickets`          | ✓    |
| `createPreorder(...)`           | `POST /api/preorders`               | —    |

⭐ `health()` добавлен на F5 — возвращает round-trip в мс. Используется кнопкой «Проверить соединение» в Settings.

### Обработка ошибок

`RestaurantApiClient._request` бросает `ApiException` в трёх форматах (поле `statusCode`):

- **`isNetwork == true`** (`statusCode == null`) — DNS / TCP / TLS / таймаут / connection refused. В поле `cause` — оригинальное исключение. Этот случай выделили на F5 — раньше его трудно было отличить от 5xx.
- **`isUnauthorized` (401)** — токен невалиден. Клиент при этом **автоматически вызывает `tokenStorage.clear()`** и бросает наверх. Auth-слой должен поймать это и вернуть пользователя на `/login` (в F5 это делается через UI-обработку в LoginScreen; для остальных экранов нам нужен глобальный interceptor — задача на W1 при первом API-вызове из waiter-экрана).
- **4xx/5xx** — `statusCode` стандартный, `message` берётся из `body.error` или дефолт `HTTP <code>`.

---

## Auth: `AuthNotifier` (F5)

`lib/features/auth/auth_providers.dart`. Контракт **не изменился** относительно F4 — тот же `AuthState` sealed (`AuthSignedOut`/`AuthSignedIn`), тот же `currentUserProvider`. Изменилась только реализация: вместо `signInAsRole(role)` теперь `signIn(username, password)`, и она реально ходит на сервер.

### Что хранится в `SharedPreferences`

| Ключ                  | Что                                | Кто пишет/читает                   |
| --------------------- | ---------------------------------- | ---------------------------------- |
| `api.base_url`        | сохранённый base URL               | `ApiBaseUrlNotifier`               |
| `api.bearer_token`    | bearer-токен                       | `PrefsAuthTokenStorage`            |
| `auth.user`           | сериализованный `User` JSON        | `AuthNotifier`                     |
| `app.theme_id`, ...   | F2/F3 настройки                    | theme/locale notifiers             |

Сохранение `User` отдельно нужно, чтобы при перезапуске не делать второй вызов `/api/auth/me` (которого пока нет) — токен + кешированный user полностью восстанавливают сессию.

### Ошибки логина — sealed `AuthError`

```dart
sealed class AuthError implements Exception {}
class AuthErrorBadCredentials extends AuthError {}    // 401
class AuthErrorNetwork extends AuthError {            // _request бросил isNetwork
  final Object cause;
}
class AuthErrorOther extends AuthError {              // прочее (500, 403, ...)
  final String message;
}
```

LoginScreen маппит их на локализованные сообщения (`l10n.loginErrorBadCredentials` и т.п.) — это правильный путь и для всех будущих обработчиков ошибок.

### Restore при старте

```dart
SharedPreferences[auth.user] == null → AuthSignedOut
SharedPreferences[auth.user] == <valid JSON> → AuthSignedIn(User.fromJson(...))
SharedPreferences[auth.user] == <garbage> → AuthSignedOut + ключ удаляется
```

Все три ветки покрыты тестами (`test/features/auth/auth_providers_test.dart`, group `restoration`).

---

## Seed-пользователи (DEV)

`server/lib/src/seed.dart` сидит идемпотентно (добавляет только тех, кого нет в БД). После каждого `dart_frog dev` доступны:

| Username     | Пароль                | Роль         | Display name           |
| ------------ | --------------------- | ------------ | ---------------------- |
| `admin`      | `1234` (или `$env:ADMIN_PASSWORD`) | `admin`      | Администратор          |
| `director1`  | `1234`                | `director`   | Назгуль (директор)     |
| `waiter1`    | `1234`                | `waiter`     | Айгуль (официант)      |
| `cashier1`   | `1234`                | `cashier`    | Эльдар (касса)         |
| `cook1`      | `1234`                | `cook`       | Мирлан (повар)         |

LoginScreen → блок «Быстрый вход (DEV)» рендерит чипы для каждого. На проде блок скрывается по флагу (см. `_QuickDevBlock` — на F5 показан всегда, на M1 завернём в `kDebugMode || kProfileMode`).

---

## Realtime: `RealtimeChannel` (auto-managed)

`lib/core/realtime/realtime_providers.dart`. Три провайдера:

```dart
realtimeChannelProvider   // Provider<RealtimeChannel?>
realtimeStatusProvider    // StreamProvider<RealtimeStatus>
realtimeEventsProvider    // StreamProvider<WsEvent>
```

### Жизненный цикл

`realtimeChannelProvider` watch'ит `authStateProvider` и `apiBaseUrlProvider`:

- `AuthSignedIn` + `baseUrl` есть → канал создаётся, `connect()` вызывается (он сам сделает reconnect-loop при провалах — экспоненциальный backoff до 30с).
- `AuthSignedOut` → канал `dispose`-ится через `ref.onDispose`.
- `baseUrl` изменился → провайдер инвалидируется → старый `dispose`-ится, новый создаётся.

WS-URL выводится автоматически из `baseUrl` через `RealtimeChannel.fromApiBase(...)`:
- `http://host:port` → `ws://host:port/ws`
- `https://host` → `wss://host/ws` (важно для Cloudflare Tunnel — иначе mixed-content).

### Как подписаться на события

```dart
class WaiterOrdersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<WsEvent>>(realtimeEventsProvider, (prev, next) {
      next.whenData((event) {
        switch (event) {
          case OrderUpdated(:final order): /* refresh local cache */
          case PreorderCreated(:final order): /* show notification */
          // ...
        }
      });
    });
    // ...
  }
}
```

`realtimeStatusProvider` — для UI-индикатора (см. `ConnectionIndicator`).

---

## UI: `ConnectionIndicator`

`lib/widgets/connection_indicator.dart`. Маленькая цветная точка:

- 🟢 `tertiary` (зелёный из текущей темы) — connected.
- 🟡 `secondary` — connecting.
- 🔴 `error` — disconnected.

Tooltip: `<status> · <baseUrl>`. Кладётся в `AppBar.actions` (compact-режим) или в Settings раздел «Сервер» (полный режим с подписью).

---

## Cheatsheet: новый feature-экран

```dart
class WaiterDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Текущий пользователь
    final user = ref.watch(currentUserProvider);
    
    // 2. API клиент (вызывайте методы внутри FutureProvider/AsyncNotifier)
    final api = ref.watch(restaurantApiClientProvider);
    
    // 3. Realtime подписка
    ref.listen<AsyncValue<WsEvent>>(realtimeEventsProvider, (_, next) {
      next.whenData(_handleEvent);
    });
    
    // 4. Статус соединения — в AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text('Официант'),
        actions: const [ConnectionIndicator()],
      ),
      // ...
    );
  }
}
```

---

## Тесты

`apps/pos/test/features/auth/auth_providers_test.dart` (11 тестов в файле, 8 из них — F5):

- restoration: пустые prefs, валидный user JSON, битый JSON;
- signIn: 200 (success), 401 (bad credentials), сетевая ошибка;
- signOut: чистит state + user + token;
- `homePathForRole` фиксирует role→/path.

Mock-http через `package:http/testing.dart` (добавлен в `dev_dependencies`).

`flutter analyze` — чисто. `flutter test` — 11/11 зелёных. `dart analyze server` — чисто.

---

## Что **не сделано** на F5 (намеренно, под следующие задачи)

- **Глобальный 401-interceptor.** Сейчас 401 в auth обрабатывается в LoginScreen. Для прочих экранов (waiter, cashier...) при просрочке токена нужно либо явно ловить `ApiException.isUnauthorized`, либо добавить общий interceptor, который пушит `authStateProvider` в `SignedOut`. Эту задачу взято в W1 (первый реальный экран официанта).
- **PIN-вход.** В `User` есть поле `hasPin`, но endpoint и UI ещё не реализованы. План: F5.x в будущем или встроим как часть W1.
- **Secure storage.** Сейчас токен в `SharedPreferences`. Для прода (особенно мобильные сборки) перейдём на `flutter_secure_storage`. Контракт `AuthTokenStorage` уже под это готов.
- **`/api/auth/me`** — текущий пользователь по токену. Не нужен, пока сидим на cached `User`. Понадобится, если данные пользователя могут меняться без нашего ведома (например, admin сменил displayName).
- **Скрывать DEV-блок** на проде. Лёгкая правка: `if (!kDebugMode && !kProfileMode) return SizedBox.shrink()`. Сделаем при первом release-билде.

---

## Файлы, добавленные/изменённые на F5

| Файл                                                       | Что                                                    |
| ---------------------------------------------------------- | ------------------------------------------------------ |
| `server/lib/src/seed.dart`                                  | Идемпотентный seed + `director1`                       |
| `packages/api_client/lib/src/api_exception.dart`            | `isNetwork` getter + `cause` поле                      |
| `packages/api_client/lib/src/restaurant_api_client.dart`    | `health()` метод                                        |
| `apps/pos/lib/core/api/api_base_url.dart`                   | `apiBaseUrlProvider` (env / prefs / web / default)     |
| `apps/pos/lib/core/api/token_storage.dart`                  | `PrefsAuthTokenStorage` + provider                     |
| `apps/pos/lib/core/api/api_client_provider.dart`            | `restaurantApiClientProvider`                          |
| `apps/pos/lib/core/realtime/realtime_providers.dart`        | channel + status + events providers                    |
| `apps/pos/lib/features/auth/auth_providers.dart`            | переписан под реальный `signIn(...)` + `AuthError`     |
| `apps/pos/lib/features/auth/login_screen.dart`              | форма username/password + Quick DEV блок               |
| `apps/pos/lib/features/home/role_home_screen.dart`          | + `ConnectionIndicator` в AppBar                       |
| `apps/pos/lib/features/settings/settings_screen.dart`       | + `_ServerCard` (URL / Save / Reset / Test)            |
| `apps/pos/lib/widgets/connection_indicator.dart`            | новый виджет                                            |
| `apps/pos/lib/l10n/arb/app_{ru,ky}.arb` + `generated/*`     | +28 новых ключей                                       |
| `apps/pos/test/features/auth/auth_providers_test.dart`      | переписан под mock http (8 новых проверок)             |
| `apps/pos/pubspec.yaml`                                     | + `http: ^1.2.0` в `dev_dependencies`                  |
