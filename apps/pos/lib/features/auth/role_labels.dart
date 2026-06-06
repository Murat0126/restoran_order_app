import 'package:flutter/widgets.dart';
import 'package:shared_models/shared_models.dart';

import '../../l10n/l10n.dart';

/// Локализованные подписи ролей.
///
/// Не делаем это методом самого `UserRole`, чтобы не тянуть Flutter
/// и l10n в shared_models (это pure-Dart package).
String roleDisplayName(BuildContext context, UserRole role) {
  final l10n = context.l10n;
  return switch (role) {
    UserRole.admin => l10n.roleAdmin,
    UserRole.director => l10n.roleDirector,
    UserRole.waiter => l10n.roleWaiter,
    UserRole.cashier => l10n.roleCashier,
    UserRole.cook => l10n.roleKds,
  };
}

/// Маршрут home-экрана, на котором эта роль работает по умолчанию.
String homePathForRole(UserRole role) {
  return switch (role) {
    UserRole.admin => '/admin',
    UserRole.director => '/director',
    UserRole.waiter => '/waiter',
    UserRole.cashier => '/cashier',
    UserRole.cook => '/kds',
  };
}
