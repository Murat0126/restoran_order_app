/// Утилиты для безопасной работы с `Map<String, dynamic>` из JSON.
library;

DateTime parseDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Не удалось распарсить DateTime из $value');
}

DateTime? parseDateTimeOrNull(Object? value) {
  if (value == null) return null;
  return parseDateTime(value);
}

double parseDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Не удалось распарсить double из $value');
}

int parseInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Не удалось распарсить int из $value');
}

T parseEnum<T extends Enum>(Object? value, List<T> values, {T? fallback}) {
  if (value == null) {
    if (fallback != null) return fallback;
    throw const FormatException('enum значение равно null');
  }
  final name = value.toString();
  for (final v in values) {
    if (v.name == name) return v;
  }
  if (fallback != null) return fallback;
  throw FormatException(
    'Не удалось распарсить enum: $name, ожидалось одно из '
    '${values.map((e) => e.name).join(', ')}',
  );
}
