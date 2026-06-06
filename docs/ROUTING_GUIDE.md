# Routing & Auth Gate (F4)

> Документ описывает, как устроена навигация в `apps/pos` после F4: маршруты, защита по ролям (role-based access), точки расширения для F5 (реальный логин через `api_client`).

## TL;DR

- Используем **[`go_router`](https://pub.dev/packages/go_router)** + Riverpod.
- `MaterialApp.router` подключён в `lib/app/app.dart`.
- `lib/app/router.dart` — единственное место, где объявлены пути и `redirect`-логика.
- Аутентификация — `lib/features/auth/auth_providers.dart`. На F4 это **in-memory + persist в SharedPreferences** (DEV-режим). В F5 реализация подменится на реальный `/api/auth/login`, контракт `currentUserProvider` останется.
- Доступ к роутам — по ролям из `shared_models.UserRole`.

---

## Карта маршрутов

| Путь         | Доступ                          | Экран                    |
| ------------ | ------------------------------- | ------------------------ |
| `/`          | любой                           | _никакого_ (redirect)    |
| `/login`     | только анонимный                | `LoginScreen`            |
| `/settings`  | анонимный + любой авторизованный| `SettingsScreen`         |
| `/admin`     | только `UserRole.admin`         | `RoleHomeScreen(admin)`  |
| `/director`  | только `UserRole.director`      | `RoleHomeScreen(director)` |
| `/waiter`    | только `UserRole.waiter`        | `RoleHomeScreen(waiter)` |
| `/cashier`   | только `UserRole.cashier`       | `RoleHomeScreen(cashier)`|
| `/kds`       | только `UserRole.cook`          | `RoleHomeScreen(cook)`   |
| прочее       | —                               | `NotFoundScreen` (404)   |

> Источник истины — `AppRoutes` в `lib/app/router.dart`. **Не пишите магические строки `'/waiter'` напрямую в виджетах** — используйте `AppRoutes.waiter`.

---

## Redirect-логика

`GoRouter.redirect` вызывается на каждом изменении локации и на каждом тике `refreshListenable`. Алгоритм:

```text
1. Если НЕ авторизован:
     /login или /settings  → пропускаем
     прочее                → redirect → /login

2. Если авторизован, role = R, home = homePathForRole(R):
     /login или /          → redirect → home
     /settings             → пропускаем
     home                  → пропускаем
     чужой role-home       → redirect → home  (например, waiter → /admin)
     неизвестный путь      → пропускаем (errorBuilder → NotFoundScreen)
```

Маппинг `role → home` — функция `homePathForRole(role)` в `lib/features/auth/role_labels.dart`. Она же используется в самом redirect и в тестах.

---

## Auth-state

### Контракт (стабильный, не меняется в F5)

```dart
// lib/features/auth/auth_providers.dart

sealed class AuthState {}
class AuthSignedOut extends AuthState {}
class AuthSignedIn extends AuthState {
  final User user; // shared_models.User
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
final currentUserProvider = Provider<User?>(...);

extension AuthStateX on AuthState {
  bool   get isSignedIn;
  User?  get user;
  UserRole? get role;
}
```

### Реализация F4 (DEV)

`AuthNotifier`:

- При создании читает `SharedPreferences[auth.dev_role]`. Если есть — восстанавливает `AuthSignedIn` с фейковым `User(id: 'dev-<role>', ...)`.
- `signInAsRole(role)` — выставляет `AuthSignedIn`, пишет `prefs[auth.dev_role] = role.name`.
- `signOut()` — `AuthSignedOut`, удаляет ключ из prefs.

На `LoginScreen` 5 кнопок «Войти как ...» — по одной на роль. Они вызывают `signInAsRole(...)`. Никакого ввода логина/пароля **сейчас нет** — это режим разработки.

### План F5 (production)

В F5 заменим `AuthNotifier` так:

- `signIn(username, password)` → `restaurantApiClient.login(...)` → `AuthResult(token, user)`.
- Токен сохраняется в `SharedPreferences` (или `flutter_secure_storage`, если поднимем зависимость).
- `User` приходит с сервера (`shared_models.User`).
- `signOut()` — чистит токен, дополнительно уведомляет сервер (опционально).
- `currentUserProvider` отдаёт `User?` ровно так же — **верхний код менять не нужно**, в т.ч. `router.dart`.

> Если в F5 появится «splash до валидации токена», добавится третье состояние `AuthInitial` (или `AuthLoading`). Тогда в `redirect` будет ветка «AuthInitial → не редиректить, показать splash из MaterialApp builder». На F4 этого нет, потому что состояние известно синхронно из prefs.

---

## Splash

Сейчас «splash» — это `_SplashApp` внутри `lib/app/app.dart`, который показывается **только** на время загрузки JSON-темы (`appThemePairProvider`). После того, как тема разрешилась, рендерится `MaterialApp.router`, и `redirect` мгновенно ведёт пользователя в `/login` или в его home.

Отдельного `/splash`-роута **нет**, потому что:
- Auth-state читается синхронно (SharedPreferences через override `sharedPreferencesProvider`).
- Тема нужна **до** `MaterialApp.router` — отдельный роут это не починит, splash должен быть в обёртке.

В F5, если появятся асинхронные операции при старте (валидация токена, тяжёлый seed) — добавим `/splash` как полноценный роут и состояние `AuthInitial`.

---

## Settings и навигация

`SettingsScreen` доступен:

- из `LoginScreen` (anonymous) — иконка `settings` в AppBar → `context.push('/settings')`;
- из любого `RoleHomeScreen` — та же иконка.

Это намеренно: пользователь должен иметь возможность сменить язык/тему **до** логина (особенно важно для тёмных кафе с проектором — переключение языка интерфейса по запросу администратора смены).

---

## Тесты

`apps/pos/test/features/auth/auth_providers_test.dart` покрывает:

- пустые prefs → `AuthSignedOut`;
- `signInAsRole(waiter)` → `AuthSignedIn`, ключ записался;
- перезапуск (новый `ProviderContainer`) видит сохранённую роль;
- `signOut()` чистит prefs;
- `director` (новая роль) корректно сериализуется/десериализуется;
- мусор в prefs (несуществующая роль) → fallback `waiter`, без падения;
- `homePathForRole(...)` — фиксирует контракт `role → /path`.

`flutter analyze` — чистый. `flutter test` — все тесты F2+F3+F4 зелёные.

---

## Чек-лист на расширение

Когда будем добавлять новый защищённый роут (например, `/waiter/orders/:id`):

1. Добавить путь как константу в `AppRoutes` (или вложенный объект `AppRoutes.waiterOrder(id)`).
2. Добавить `GoRoute(path: ..., builder: ...)` в `appRouterProvider`.
3. Подумать, нужен ли `redirect`-кейс. Если путь — поддиректория `/waiter/...`, текущая логика уже его пропустит для официанта и редиректнет для других ролей (надо лишь проверить, что `protectedRoots` это покрывает).
4. Если хочется блокировать другие роли по более сложной логике (например, `cashier` может смотреть `/waiter/orders/:id` в read-only) — выносим в отдельный `policy.dart`, чтобы не разрастался `redirect`.

---

## Файлы, добавленные/изменённые на F4

| Файл                                                | Что                                                |
| --------------------------------------------------- | -------------------------------------------------- |
| `packages/shared_models/lib/src/enums.dart`         | `+ director` в `UserRole`                          |
| `apps/pos/lib/features/auth/auth_providers.dart`    | `AuthState` + `AuthNotifier` + провайдеры          |
| `apps/pos/lib/features/auth/role_labels.dart`       | `roleDisplayName(...)` + `homePathForRole(...)`    |
| `apps/pos/lib/features/auth/login_screen.dart`      | LoginScreen с 5 DEV-кнопками                       |
| `apps/pos/lib/features/home/role_home_screen.dart`  | Универсальный placeholder для всех 5 home-роутов   |
| `apps/pos/lib/features/common/not_found_screen.dart`| 404-страница                                       |
| `apps/pos/lib/app/router.dart`                      | GoRouter + redirect-логика                         |
| `apps/pos/lib/app/app.dart`                         | `MaterialApp.router` (вместо `MaterialApp.home`)   |
| `apps/pos/lib/l10n/arb/app_ru.arb`, `app_ky.arb`    | ARB-ключи F4 (login/role/home/notFound/...)        |
| `apps/pos/lib/l10n/generated/*`                     | Регенерированы из ARB                              |
| `apps/pos/test/features/auth/auth_providers_test.dart` | Unit-тесты на auth state                        |
