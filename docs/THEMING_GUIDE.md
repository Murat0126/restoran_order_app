# Темизация (white-label) — гид для разработчика

Файл: `docs/THEMING_GUIDE.md`
Связанные документы: `docs/design/DESIGN.md` (новая дизайн-система от дизайнера), `docs/ARCHITECTURE.md` (общая архитектура).

---

## TL;DR

1. Тема одного клиента — это один JSON-файл (`apps/pos/assets/themes/<id>.json`).
2. Каждый JSON содержит два режима: `light` и `dark`. `dark` может быть полностью описан или сгенерирован из `light` автоматически (`{"derive": "fromSeed"}`).
3. В рантайме активная тема:
   * выбирается через `themeIdProvider` (Riverpod, persist в `SharedPreferences`),
   * загружается через `appThemePairProvider` (FutureProvider, читает asset),
   * скармливается в `MaterialApp.theme` / `darkTheme` и одновременно доставляется до листьев через `AppThemeScope` для кастомных токенов (`spacing`, `radii`, `shadows`).
4. Доступ из виджета:

```dart
final s = context.appTheme;     // полный AppTheme
final p = context.appPalette;   // только AppPalette
final sp = context.appSpacing;  // AppSpacing
final r = context.appRadii;     // AppRadii
```

5. В **production** список доступных тем будет приходить с сервера (`/api/settings/branding`), а админ-панель сможет редактировать JSON. Сейчас это просто статические assets — но контракт уже зафиксирован.

---

## Структура темы (на пальцах)

```
AppTheme
├── id, name                   // метаданные
├── palette: AppPalette        // 44 M3-цвета (primary, on*, *Container, *Fixed, ...)
├── typography: AppTypography  // 9 семантических ролей + AppFontFamilies
├── spacing: AppSpacing        // 8px-rhythm + layout уровни
├── radii: AppRadii            // sm/md/lg/xl/full
└── shadows: AppShadows        // level0/level1/level2
```

Все классы в `apps/pos/lib/theme/`. Барреллл-экспорт: `package:pos/theme/theme.dart`.

### Семантические роли типографики (9 штук)

| Роль                 | Использование                              |
|----------------------|--------------------------------------------|
| `headlineLarge`      | Главные заголовки экранов (desktop / planшет) |
| `headlineLargeMobile`| Главные заголовки на телефоне              |
| `headlineMedium`     | Подзаголовки секций                        |
| `headlineSmall`      | Заголовки карточек                         |
| `bodyLarge`          | Описания, длинные тексты                   |
| `bodyMedium`         | Базовый body, основной                     |
| `bodySmall`          | Сноски, метки                              |
| `labelStrong`        | Кнопки, активные элементы                  |
| `labelCaps`          | Сводки-заглавные («ОЖИДАНИЕ», категории)   |

Маппинг выровнен под Stitch HTML — экраны портируются 1-в-1 без изобретения новых стилей.

---

## Формат JSON-темы

Полный пример: `apps/pos/assets/themes/default.json`. Минимальный шаблон:

```jsonc
{
  "id": "my_client",
  "name": "My Client Theme",
  "fontFamilies": {
    "heading": "Manrope",
    "body": "Inter",
    "fallback": ["Roboto", "sans-serif"]
  },
  "light": {
    "palette": { /* 44 M3-цвета, см. ниже */ },
    "typography": {
      /* минимум 5 ролей:
         headlineLarge, headlineLargeMobile, bodyLarge, bodyMedium, labelStrong */
      "headlineLarge":       { "size": 32, "weight": 500, "height": 1.25 },
      "headlineLargeMobile": { "size": 28, "weight": 500, "height": 1.29 },
      "bodyLarge":           { "size": 18, "weight": 400, "height": 1.56 },
      "bodyMedium":          { "size": 16, "weight": 400, "height": 1.5 },
      "labelStrong":         { "size": 14, "weight": 600, "height": 1.43 }
      /* остальные 4 (headlineMedium/Small, bodySmall, labelCaps)
         сгенерируются из families и rhythm-scale */
    },
    "spacing": {
      "base": 8, "xs": 4, "sm": 8, "md": 16, "lg": 24, "xl": 32, "xxl": 48,
      "gutter": 24,
      "containerPaddingMobile": 16,
      "containerPaddingDesktop": 64,
      "sectionGap": 80
    },
    "radii": { "sm": 2, "md": 4, "lg": 8, "xl": 12, "full": 9999 },
    "shadows": {
      "level1": [{ "x": 0, "y": 4,  "blur": 20, "color": "#000000", "opacity": 0.10 }],
      "level2": [{ "x": 0, "y": 12, "blur": 40, "color": "#000000", "opacity": 0.10 }]
    }
  },
  "dark": { "derive": "fromSeed" }
}
```

### Палитра (обязательные 44 поля)

Все названия в `camelCase`. Hex с `#`, 6 или 8 цифр.

```
primary               onPrimary             primaryContainer       onPrimaryContainer
secondary             onSecondary           secondaryContainer     onSecondaryContainer
tertiary              onTertiary            tertiaryContainer      onTertiaryContainer
error                 onError               errorContainer         onErrorContainer
surface               onSurface             onSurfaceVariant
surfaceDim            surfaceBright
surfaceContainerLowest surfaceContainerLow  surfaceContainer
surfaceContainerHigh   surfaceContainerHighest
outline               outlineVariant
inverseSurface        onInverseSurface      inversePrimary         surfaceTint
primaryFixed          primaryFixedDim       onPrimaryFixed         onPrimaryFixedVariant
secondaryFixed        secondaryFixedDim     onSecondaryFixed       onSecondaryFixedVariant
tertiaryFixed         tertiaryFixedDim      onTertiaryFixed        onTertiaryFixedVariant
```

Опциональные (по умолчанию `#000000`): `shadow`, `scrim`.

### Тёмная тема — два варианта

**A. Автогенерация** — для старта:

```json
"dark": { "derive": "fromSeed" }
```

Парсер вызовет `ColorScheme.fromSeed(seedColor: light.primary, brightness: dark)`. `spacing`, `radii`, `shadows`, `typography` — наследуются от `light` без изменений.

**B. Явная палитра** — когда дизайнер пришлёт точные hex:

```json
"dark": {
  "palette": { /* те же 44 поля */ },
  "typography": { /* можно повторить или скопировать light */ },
  "spacing": { /* ... */ },
  "radii": { /* ... */ },
  "shadows": { /* ... */ }
}
```

---

## Как добавить тему нового клиента

1. Создать `apps/pos/assets/themes/<id>.json` (см. шаблон выше).
2. Добавить запись в `availableThemesProvider` (`lib/theme/theme_providers.dart`):

   ```dart
   ThemeOption(
     id: 'my_client',
     displayName: 'My Client',
     assetPath: 'assets/themes/my_client.json',
   ),
   ```

3. (Не обязательно сейчас) Пересобрать тесты — `theme_loader_test.dart` рекомендуется расширить кейсом на новую тему.
4. Перезапустить приложение — тема появится в Settings.

---

## Доступ в коде

### Из виджета

```dart
class DishCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.appTheme;
    return Container(
      padding: EdgeInsets.all(s.spacing.md),
      decoration: BoxDecoration(
        color: s.palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(s.radii.lg),
        boxShadow: s.shadows.level1,
      ),
      child: Text('Цезарь', style: s.typography.headlineSmall),
    );
  }
}
```

### Внутри Material-виджетов

Стандартные `Theme.of(context).textTheme.headlineSmall`, `Theme.of(context).colorScheme.primary` тоже работают — `AppTypography.toTextTheme()` мапит наши 9 ролей в стандартные слоты Material 3, чтобы не было визуальных провалов при использовании `ListTile`, `AppBar`, `SnackBar` и т.п.

---

## Server-side overrides (план)

В `docs/ARCHITECTURE.md` уже зафиксировано, что брендинг — поле в БД `restaurant_settings`. Когда дойдём до Админки (раздел 6.x), добавится:

```
GET  /api/settings/branding         → JSON-тема + meta (logo URL, brand name)
POST /api/settings/branding         → перезаписать (только admin)
WS event "branding.updated"         → пуш на всех клиентов
```

Клиент:
1. На старте читает `default.json` из assets (мгновенный UI).
2. Параллельно тянет `GET /api/settings/branding`. Если ответ непустой и `etag` отличается от закэшированного → подменяет тему через `themeIdProvider.set('server')` или прямой override `appThemePairProvider`.
3. При получении `branding.updated` по WebSocket — повторяет шаг 2.

Это даёт «лёгкое и быстрое» поведение, которое вы просили: первый paint всегда мгновенный, кастомизация подхватывается без блокировки.

---

## Тестирование

Юнит-тесты парсера: `apps/pos/test/theme/theme_loader_test.dart` (3 кейса: default, hushed_luxury, ThemeData).

Запуск:

```powershell
cd apps\pos
flutter test
```

Визуальная проверка темы — экран Settings (`SettingsScreen`):

```powershell
cd apps\pos
flutter run -d windows   # или -d chrome / -d <device-id>
```

Внутри экрана:
- блок «Тема клиента» — переключение между Modern Gastronomy и Hushed Luxury,
- блок «Режим» — Light / Dark / System,
- три превью-секции: типография (9 ролей), палитра (8 swatches), surface-уровни (8 swatches),
- блок «Компоненты»: кнопки, чипы, инпуты, тонально-elevated card.

Любая смена темы или режима **мгновенно** перерисовывает весь экран — это и есть white-label.

---

## Что точно НЕ делать

- ❌ Хардкодить hex в виджетах. Всегда через `context.appPalette`.
- ❌ Использовать `Colors.*` из Flutter SDK (`Colors.red`, `Colors.grey[300]` и т.п.).
- ❌ Прописывать `fontSize: 16` без `fontFamily` — он сломает консистентность шрифтов между темами с разными `families.body`.
- ❌ Создавать новые семантические роли «на ходу». Если нужна новая роль — обсуждение → правка `AppPalette`/`AppTypography` → правка обоих JSON-пресетов → правка теста.
