import 'package:flutter/foundation.dart';

/// Брендинг продукта (имя POS, не локализуемые метки бренда).
///
/// Задаётся в корне JSON-темы → `brand`.
@immutable
class AppBrand {
  const AppBrand({
    required this.productName,
    required this.loginHeroImageUrl,
  });

  final String productName;
  final String loginHeroImageUrl;
}
