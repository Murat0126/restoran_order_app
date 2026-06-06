import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/formatters/app_formatters.dart';
import 'package:pos/l10n/l10n.dart';
import 'package:pos/l10n/generated/app_localizations.dart';

Widget _wrap(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales(),
    home: Builder(builder: (context) => child),
  );
}

void main() {
  group('formatOrderNumber', () {
    test('добавляет #', () {
      expect(formatOrderNumber(42), '#42');
      expect(formatOrderNumber('#42'), '#42');
    });

    test('сокращает UUID', () {
      expect(
        formatOrderNumber('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
        '#7890',
      );
    });
  });

  group('formatPrice', () {
    testWidgets('ru — тысячи и суффикс с', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Locale('ru'),
          Builder(
            builder: (context) {
              final s = formatPrice(context, 1240);
              expect(s, contains('1'));
              expect(s, contains('240'));
              expect(s, contains('с'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('ky — не падает', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Locale('ky'),
          Builder(
            builder: (context) {
              expect(formatPrice(context, 100), isNotEmpty);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('formatDuration', () {
    testWidgets('ru — 65 мин → 1 ч 5 мин', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Locale('ru'),
          Builder(
            builder: (context) {
              final s = formatDuration(
                context,
                const Duration(hours: 1, minutes: 5),
              );
              expect(s, contains('1'));
              expect(s, contains('5'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('ky — 12 мин', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Locale('ky'),
          Builder(
            builder: (context) {
              final s = formatDuration(
                context,
                const Duration(minutes: 12),
              );
              expect(s, contains('12'));
              expect(s.toLowerCase(), contains('мүн'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
