# POS (Flutter)

Единое приложение для **внутренних** пользователей ресторана:
официант, кассир, повар, директор, администратор. Роль определяется
после входа, дальше — соответствующий набор экранов.

Адаптив: **планшет (10–12") в первом приоритете**, смартфон —
обязательная поддержка для официантов «с телефоном в кармане».

## Стек

| Слой | Технология |
|---|---|
| State management | `flutter_riverpod` 2.x (+ `riverpod_generator`) |
| Роутинг | `go_router` 14.x |
| Локализация | `flutter_localizations` + `intl` + `flutter gen-l10n` |
| Хранилище (KV) | `shared_preferences` |
| Хранилище (DB / offline outbox) | `sqflite` |
| Сетевой клиент | `api_client` (path-зависимость из монорепо) |
| Модели | `shared_models` (path-зависимость из монорепо) |
| Логирование | `logging` |
| Линты | `flutter_lints` + `riverpod_lint` + `custom_lint` |

## Запуск (этап F1)

```powershell
cd apps\pos
flutter pub get
flutter run            # запустится плоская заглушка
```

После F2 (локализация) и F3 (темизация) появятся переключатель языка
и темы в Settings — это будет первая визуальная проверка, что
i18n и theming работают.

## Структура каталогов

```
apps/pos/
├── assets/
│   ├── icons/                 — кастомные SVG/PNG иконки
│   └── themes/                — JSON-темы для white-label (F3)
├── lib/
│   ├── app/                   — корневой App, router, bootstrap
│   ├── core/
│   │   ├── errors/            — типы ошибок, mapping API → UI
│   │   ├── network/           — провайдеры api_client, realtime
│   │   ├── storage/           — обёртки над SharedPreferences и sqflite
│   │   └── utils/             — мелкие хелперы (formatters, extensions)
│   ├── features/              — фичи по ролям/доменам
│   │   ├── auth/              — логин, текущая сессия
│   │   ├── hall/              — карта зала (waiter)
│   │   ├── order/             — экраны заказа (waiter)
│   │   ├── menu/              — каталог блюд (общий read-only)
│   │   ├── kitchen/           — KDS (cook)
│   │   ├── cashier/           — экраны кассы
│   │   ├── director/          — дашборд + отчёты
│   │   ├── admin/             — управление пользователями/меню
│   │   └── settings/          — настройки (язык, тема, принтеры)
│   ├── l10n/
│   │   ├── arb/               — app_ru.arb, app_ky.arb (F2)
│   │   ├── generated/         — авто-генерация AppLocalizations (F2)
│   │   └── l10n.dart          — supportedLocales, delegates, provider
│   ├── theme/                 — AppPalette, AppTheme, JSON-loader (F3)
│   ├── widgets/               — общие виджеты (AppButton, AppCard…)
│   └── main.dart              — entrypoint
└── test/                      — unit + widget тесты
```

## Принципы

- **Никаких хардкод-строк в UI** — все тексты через `context.l10n`.
- **Никаких хардкод-цветов** — только `Theme.of(context)` или
  `context.theme.palette`. Менять стиль клиенту = подменить JSON.
- **`pubspec.lock` коммитим** (это application, не библиотека).
- **`features/` плоская**: одна фича = `features/<name>/` со своим
  `data/`, `presentation/`, `providers.dart`.
- **Один экран — один файл** в `presentation/`, разделяемые виджеты
  выносятся в `widgets/`.

## Сборка

```powershell
# Android (для планшета):
flutter build apk --release

# Windows (для моноблока кассы):
flutter build windows --release
```
