import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/order/presentation/dish_add_sheet.dart';
import 'package:pos/l10n/generated/app_localizations.dart';
import 'package:pos/l10n/l10n.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/theme/theme_loader.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  const dish = Dish(
    id: 'd-1',
    categoryId: 'c-1',
    name: 'Test Dish',
    description: 'Desc',
    price: 500,
    available: true,
    images: [],
  );

  late AppTheme theme;

  setUp(() {
    final source = File('assets/themes/default.json').readAsStringSync();
    theme = ThemeLoader.parseFromJson(source).light;
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme.toMaterialThemeData(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: appSupportedLocales(),
        builder: (context, child) =>
            AppThemeScope(theme: theme, child: child!),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('browse dish sheet lays out', (tester) async {
    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDishSheet(
            context,
            dish: dish,
            mode: DishSheetMode.browse,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Test Dish'), findsOneWidget);
  });

  testWidgets('add dish sheet lays out wide', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDishSheet(
            context,
            dish: dish,
            mode: DishSheetMode.addToOrder,
            onAdd: ({required qty, note, courseNo = 1}) async {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Test Dish'), findsOneWidget);
  });
}
