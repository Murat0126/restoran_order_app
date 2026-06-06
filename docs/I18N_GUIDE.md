# Локализация (i18n) — гид для разработчика

Файл: `docs/I18N_GUIDE.md`
Связанные документы: `docs/THEMING_GUIDE.md`, `docs/ARCHITECTURE.md`.

---

## TL;DR

1. Текст не пишем в коде. Все строки UI — в **ARB-файлах** (`apps/pos/lib/l10n/arb/app_<lang>.arb`).
2. Поддерживаемые языки: **ru** (template / fallback) + **ky** (Кыргызча).
3. Доступ из виджета:

```dart
final l10n = context.l10n;          // AppLocalizations
Text(l10n.settingsTitle);
Text(l10n.splashErrorTheme('FormatException: invalid hex'));
```

4. Пользователь выбирает язык в Settings → `localeProvider` (Riverpod) → persist в `SharedPreferences`. `null` = «следовать системе».
5. Все валюты, числа, даты форматируем через `intl` с правильным `Locale`.

---

## Архитектура

```
apps/pos/
├── l10n.yaml                            ← конфиг gen-l10n
├── lib/
│   └── l10n/
│       ├── arb/
│       │   ├── app_ru.arb              ← TEMPLATE (источник истины)
│       │   └── app_ky.arb              ← перевод
│       ├── generated/                  ← genertated, в .gitignore не попадает
│       │   ├── app_localizations.dart
│       │   ├── app_localizations_ru.dart
│       │   └── app_localizations_ky.dart
│       └── l10n.dart                   ← context.l10n + localeProvider + AppLanguage
```

`pubspec.yaml`:
```yaml
flutter:
  generate: true        # обязательно — без этого код не сгенерится
```

`l10n.yaml`:
```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_ru.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
nullable-getter: false  # AppLocalizations.of(context) гарантированно != null
```

---

## Workflow: добавить новый ключ

1. Открыть `apps/pos/lib/l10n/arb/app_ru.arb`.
2. Добавить ключ + (опционально) `@-метаданные`:
   ```jsonc
   "orderStatusReady": "Готов к выдаче",
   "@orderStatusReady": {
     "description": "Статус заказа на экране официанта — заказ собран, ждёт официанта"
   }
   ```
3. Открыть `app_ky.arb` и добавить перевод (или скопировать русский, если перевод пока неизвестен — обязательно пометить через `@@x-todo`).
4. Запустить `flutter gen-l10n` (либо просто `flutter pub get` — он подхватит автоматически).
5. Использовать в коде:
   ```dart
   Text(context.l10n.orderStatusReady)
   ```

Если генерация падает → проверить JSON-валидность ARB (запятые, кавычки), особенно при копи-пасте.

---

## Параметризованные строки

ARB-плейсхолдеры — для интерполяции:

```jsonc
"orderPlacedAt": "Заказ принят {time}",
"@orderPlacedAt": {
  "placeholders": {
    "time": {
      "type": "DateTime",
      "format": "Hm"
    }
  }
}
```

Использование:
```dart
Text(context.l10n.orderPlacedAt(DateTime.now()));
```

Поддерживаемые типы: `String`, `int`, `double`, `num`, `DateTime`, `Object`. Документация: <https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization>.

---

## Множественное число (plural)

Кыргызский, как и русский — нюансовый язык по числам, но в Flutter `intl` использует CLDR-формы.

```jsonc
"guestsCount": "{count, plural, =0{Нет гостей} =1{1 гость} few{{count} гостя} many{{count} гостей} other{{count} гостя}}",
"@guestsCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

В коде:
```dart
Text(context.l10n.guestsCount(4));   // "4 гостя"
Text(context.l10n.guestsCount(15));  // "15 гостей"
```

---

## Выбор языка в рантайме

`localeProvider` (`lib/l10n/l10n.dart`) хранит:
- `null` → «следовать системе» (Flutter сам подберёт из `supportedLocales`),
- `Locale('ru')` или `Locale('ky')` → явный выбор.

Смена:
```dart
ref.read(localeProvider.notifier).set(const Locale('ky'));  // переключиться на кыргызский
ref.read(localeProvider.notifier).set(null);                // вернуться к системному
```

Persistence через `SharedPreferences` (ключ `locale.code`). Сохраняется автоматически при `.set(...)`.

---

## Стартовые переводы на кыргызский

`app_ky.arb` уже содержит первичные переводы стандартной UI-лексики. **Требуется вычитка носителем** перед релизом. После проверки каждого ключа добавляйте метку:

```jsonc
"@@x-verified-by": "Имя Носителя, дата"
```

(сейчас в файле стоит `"@@x-translator-note"` с предупреждением).

### Куда мы НЕ кладём переводы

- Образцы данных в превью-экранах (имена блюд, номера столов, цены) — это **демо-данные**, не product UI. На реальных экранах эти данные приходят с сервера и переводятся отдельным механизмом (для меню — через `dish_translations` таблицу).
- Технические маркеры (например, метки `HEADLINE LARGE` в превью типографики) — это developer-facing текст, переводу не подлежит.

---

## Форматирование валют, чисел, дат

Не использовать ручную конкатенацию. Через `intl`:

```dart
import 'package:intl/intl.dart';

// Цена в сомах: "1 240 с"
final price = NumberFormat("#,##0 'с'", 'ru').format(1240);

// Дата: "04 июн. 2026"
final date = DateFormat.yMMMd('ru').format(DateTime.now());

// Время короткое: "21:35"
final time = DateFormat.Hm().format(DateTime.now());
```

`'ru'` или `'ky'` — должен совпадать с активным `Locale` (можно брать из `Localizations.localeOf(context).languageCode`).

Помощники форматирования живут в `lib/core/formatters/app_formatters.dart` (F6) и автоматически забирают локаль из `BuildContext`:

```dart
import 'package:pos/core/formatters/formatters.dart';

Text(formatPrice(context, dish.price));
Text(formatDuration(context, elapsed));
```

---

## Server-side контент (планы)

Меню (блюда, описания, категории), названия залов, статичные тексты приветствий — переводимы **per-record**:

```
CREATE TABLE dish_translations (
  dish_id TEXT NOT NULL,
  locale  TEXT NOT NULL,   -- 'ru' | 'ky' | ...
  name    TEXT NOT NULL,
  description TEXT,
  PRIMARY KEY (dish_id, locale)
);
```

API:
```
GET /api/menu?lang=ky
```

Если для блюда нет перевода в `ky` → API возвращает запись из `ru` (fallback). Это **не часть F2** — будет в Этапе 1 (POS Официант + меню).

---

## Тесты

Юнит-тестов локализации сейчас нет. По мере роста добавим виджет-тесты с `tester.pumpWidget` + `Locale('ky')`, проверяющие, что:
- все экраны рендерятся без `MissingTranslationException`,
- длина строк помещается в кнопки/чипы.

---

## Что точно НЕ делать

- ❌ Писать русские строки прямо в `Text('Сохранить')`.
- ❌ Использовать `DateTime.now().toString()` — выдаст `2026-06-04 15:30:12.345` вместо локализованного формата.
- ❌ Хардкодить `'KGS'` или `'с'` в коде форматирования цен — формат должен жить в одном месте (хелпер `formatPrice`).
- ❌ Менять `app_localizations*.dart` руками — это сгенерированный код, перетрётся при следующем `gen-l10n`.
