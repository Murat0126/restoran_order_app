import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../features/auth/auth_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/role_labels.dart';
import '../features/common/not_found_screen.dart';
import '../features/hall/presentation/waiter_hall_screen.dart';
import '../features/home/role_home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/order/presentation/waiter_order_screen.dart';
import '../features/waiter/presentation/waiter_menu_screen.dart';
import '../features/waiter/presentation/waiter_orders_screen.dart';
import '../features/waiter/presentation/waiter_shell.dart';

/// Карта роутов в одном месте — чтобы не вводить «магических строк»
/// в виджетах.
class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const settings = '/settings';

  static const admin = '/admin';
  static const director = '/director';
  static const waiter = '/waiter';
  static const waiterOrders = '/waiter/orders';
  static const waiterMenu = '/waiter/menu';
  static String waiterOrder(String tableId) => '/waiter/order/$tableId';
  static const cashier = '/cashier';
  static const kds = '/kds';

  /// Все защищённые «домашние» пути — по ним проверяется,
  /// что пользователь авторизован.
  static const protectedRoots = <String>{
    admin,
    director,
    waiter,
    cashier,
    kds,
    settings,
  };
}

/// Главный `GoRouter`, реагирующий на изменения `authStateProvider`.
///
/// Логика redirect:
///   1. Не авторизован и пытается зайти на защищённый роут → `/login`.
///   2. Авторизован и пытается зайти на `/login` → его home по роли.
///   3. Авторизован и пытается зайти в чужую роль (например, официант
///      на `/admin`) → его свой home по роли. `/settings` доступен
///      всем авторизованным.
///   4. Корень `/` → `/login` (если не авторизован) или home (если да).
final appRouterProvider = Provider<GoRouter>((ref) {
  // `Listenable` для refreshListenable — чтобы GoRouter сам
  // перевычислял redirect при каждом изменении auth-state.
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isLogin = loc == AppRoutes.login;
      final isSettings = loc == AppRoutes.settings;

      // Анонимный пользователь.
      if (!auth.isSignedIn) {
        // Разрешаем только /login и /settings (для смены языка/темы
        // до входа).
        if (isLogin || isSettings) return null;
        return AppRoutes.login;
      }

      // Авторизованный.
      final role = auth.role!;
      final home = homePathForRole(role);

      // С /login или с / — на свой home.
      if (isLogin || loc == '/') {
        return home;
      }

      // /settings — пропускаем.
      if (isSettings) return null;

      // Маршруты официанта — только для waiter.
      if (loc == AppRoutes.waiter ||
          loc.startsWith('${AppRoutes.waiter}/')) {
        if (role != UserRole.waiter) return home;
        return null;
      }

      // Свой home (точное совпадение).
      if (loc == home) return null;

      // Чужой role-home (/admin, /cashier, …).
      if (AppRoutes.protectedRoots.contains(loc)) {
        return home;
      }

      return null;
    },
    routes: [
      // Корень — формально пустой, redirect обработает.
      GoRoute(
        path: '/',
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      // 5 ролей × home.
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const RoleHomeScreen(role: UserRole.admin),
      ),
      GoRoute(
        path: AppRoutes.director,
        builder: (_, __) => const RoleHomeScreen(role: UserRole.director),
      ),
      GoRoute(
        path: AppRoutes.waiter,
        builder: (_, __) =>
            const WaiterShell(child: WaiterHallScreen()),
      ),
      GoRoute(
        path: AppRoutes.waiterOrders,
        builder: (_, __) =>
            const WaiterShell(child: WaiterOrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.waiterMenu,
        builder: (_, __) => const WaiterShell(child: WaiterMenuScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.waiter}/order/:tableId',
        builder: (_, state) => WaiterOrderScreen(
          tableId: state.pathParameters['tableId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.cashier,
        builder: (_, __) => const RoleHomeScreen(role: UserRole.cashier),
      ),
      GoRoute(
        path: AppRoutes.kds,
        builder: (_, __) => const RoleHomeScreen(role: UserRole.cook),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(path: state.uri.toString()),
  );
});

/// `Listenable`-обёртка над Riverpod `authStateProvider`,
/// чтобы GoRouter мог `refreshListenable: ...` подцепиться.
///
/// Слушает изменения и нотифит подписчиков (GoRouter).
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen<dynamic>(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
