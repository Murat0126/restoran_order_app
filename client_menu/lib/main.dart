import 'package:flutter/material.dart';

import 'src/api.dart';
import 'src/menu_page.dart';

void main() {
  runApp(const ClientMenuApp());
}

class ClientMenuApp extends StatelessWidget {
  const ClientMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Меню ресторана',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFB8C00),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFB8C00),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: MenuPage(qrToken: _readQrTokenFromUrl()),
    );
  }

  /// Достаёт `?t=<token>` из адреса страницы.
  /// Если не задан — берём `defaultQrToken` (см. api.dart),
  /// чтобы было удобно открывать локально без QR.
  String _readQrTokenFromUrl() {
    final uri = Uri.base;
    return uri.queryParameters['t'] ?? defaultQrToken;
  }
}
