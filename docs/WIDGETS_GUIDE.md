# Design-system widgets (F6)

> Базовые UI-компоненты и форматтеры для `apps/pos`. Все виджеты читают токены из `AppThemeScope` (`context.appTheme`), все форматтеры — локаль из `BuildContext`.

## Импорт

```dart
import 'package:pos/widgets/widgets.dart';
import 'package:pos/core/formatters/formatters.dart';
```

---

## Форматтеры (`lib/core/formatters/`)

| Функция | Пример (ru) | Назначение |
| ------- | ------------- | ---------- |
| `formatPrice(ctx, amount)` | `1 240 с` | Цены в KGS, суффикс `с` |
| `formatDate(ctx, dt)` | `04 июн. 2026` | Короткая дата |
| `formatTime(ctx, dt)` | `21:35` | Время |
| `formatDateTime(ctx, dt)` | дата + время | Чеки, логи |
| `formatDuration(ctx, d)` | `1 ч 5 мин` | KDS-таймеры (ARB) |
| `formatOrderNumber(id)` | `#1428` | Номер заказа |
| `formatTableNumber(s)` | trim | Номер стола |

**Правила:**

- Не вызывать `NumberFormat(..., 'ru')` напрямую в feature-коде.
- Дробная часть цены показывается только при ненулевых копейках или `forceDecimals: true` (касса).
- Валюта клиента из админки — позже; сейчас KGS зафиксирован в одном месте (`app_formatters.dart`).

---

## `AppButton`

```dart
AppButton(
  label: l10n.buttonConfirm,
  onPressed: () => submit(),
  variant: AppButtonVariant.primary, // primary | secondary | outlined | text | destructive
  size: AppButtonSize.md,            // sm | md | lg
  icon: Icons.print_outlined,
  isLoading: busy,
)

AppButton.fullWidth(label: l10n.loginSubmit, onPressed: _submit);
```

---

## `AppCard`

```dart
AppCard(
  level: AppCardLevel.elevated, // flat | elevated | raised
  onTap: () => openDetails(),
  child: ...,
)
```

Тени: `level0` / `level1` / `level2` из JSON-темы.

---

## `AppChip`

```dart
AppChip(label: 'ВЕГ');
AppChip(label: 'Горячие', selected: true);
AppChip(label: 'ГОТОВО', variant: AppChipVariant.success);
AppChip(label: 'Фильтр', onDeleted: () => clearFilter());
```

Варианты: `neutral`, `accent`, `success`, `warning`, `error`.

---

## `AppEmptyState` / `AppErrorState`

```dart
AppEmptyState(
  title: l10n.emptyStateNoOrdersTitle,
  subtitle: l10n.emptyStateNoOrdersSubtitle,
  icon: Icons.receipt_long_outlined,
  actionLabel: l10n.actionGoHome,
  onAction: () => context.go(homePath),
);

AppErrorState(
  title: l10n.errorStateGenericTitle,
  subtitle: message,
  retryLabel: l10n.actionRetry,
  onRetry: () => ref.invalidate(ordersProvider),
);
```

Заголовки/подзаголовки — **всегда из ARB**, не хардкод.

---

## Где посмотреть живьём

`Settings` → секции **«Форматирование»**, **«Виджеты design-system»** и превью empty/error внизу.

---

## `AppQuantityStepper`

```dart
AppQuantityStepper(
  value: qty,
  onDecrement: () => decrement(),
  onIncrement: () => increment(),
);
```

Используется в корзине официанта и stepper гостей (Stitch 2.3).

---

## Что дальше (W1+)

- `AppListTile`, `AppBadge` — по мере появления в Stitch-экранах официанта.
- `formatPrice` — подключить валюту с сервера (`GET /api/settings`).
- Скрыть DEV quick-login на release (уже в F5).

---

## Файлы F6

| Путь | Содержимое |
| ---- | ---------- |
| `lib/core/formatters/app_formatters.dart` | formatters |
| `lib/widgets/app_button.dart` | кнопки |
| `lib/widgets/app_card.dart` | карточки |
| `lib/widgets/app_chip.dart` | чипы |
| `lib/widgets/app_empty_state.dart` | пустое состояние |
| `lib/widgets/app_error_state.dart` | ошибка + retry |
| `lib/widgets/widgets.dart` | barrel export |
| `test/core/formatters/app_formatters_test.dart` | тесты |
