import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

/// Локализованное форматирование цен, дат и длительностей.
///
/// Все функции берут локаль из [BuildContext] — не хардкодим `'ru'`.
/// Валюта по умолчанию — **KGS (сом)**, суффикс `с` (см. TZ).
/// Смена валюты на клиента — через админку (будущий API); пока
/// фиксированный шаблон в одном месте.
String localeTag(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// Цена в сомах: `1 240 с` (ru) / `1 240 с` (ky — тот же суффикс).
///
/// [amount] — целое или с копейками (касса). Дробная часть
/// показывается только если она ненулевая или [forceDecimals].
String formatPrice(
  BuildContext context,
  num amount, {
  bool forceDecimals = false,
}) {
  final locale = localeTag(context);
  final hasFraction =
      forceDecimals || (amount is double && amount.truncateToDouble() != amount);
  final pattern = hasFraction ? "#,##0.00 'с'" : "#,##0 'с'";
  return NumberFormat(pattern, locale).format(amount);
}

/// Короткая дата: `04 июн. 2026` (зависит от локали).
String formatDate(BuildContext context, DateTime dateTime) {
  return DateFormat.yMMMd(localeTag(context)).format(dateTime);
}

/// Время: `21:35`.
String formatTime(BuildContext context, DateTime dateTime) {
  return DateFormat.Hm(localeTag(context)).format(dateTime);
}

/// Дата + время в одной строке.
String formatDateTime(BuildContext context, DateTime dateTime) {
  final locale = localeTag(context);
  return DateFormat.yMMMd(locale).add_Hm().format(dateTime);
}

/// Длительность для KDS / таймеров заказа.
///
/// Примеры (ru): `12 мин`, `1 ч`, `1 ч 5 мин`.
/// Использует ARB — не хардкодим единицы в виджетах.
String formatDuration(BuildContext context, Duration duration) {
  final l10n = context.l10n;
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return l10n.formatDurationLessThanMinute;
  if (totalMinutes < 60) {
    return l10n.formatDurationMinutes(totalMinutes);
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) return l10n.formatDurationHours(hours);
  return l10n.formatDurationHoursMinutes(hours, minutes);
}

/// Компактный номер столика / заказа (без локали — цифры универсальны).
String formatTableNumber(String number) => number.trim();

/// Номер заказа с префиксом `#` для UI.
///
/// Длинные UUID сокращаются до последних 4 символов (как в макетах Stitch).
String formatOrderNumber(Object id) {
  final raw = id is int ? id.toString() : id as String;
  if (raw.startsWith('#')) return raw;
  final compact = raw.replaceAll('-', '');
  if (compact.length > 6 && int.tryParse(compact) == null) {
    final tail = compact.substring(compact.length - 4).toUpperCase();
    return '#$tail';
  }
  return '#$raw';
}
