import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import 'api_exception.dart';
import 'auth_token_storage.dart';

/// Снимок меню — то, что отдаёт `GET /api/menu`.
class MenuSnapshot {
  const MenuSnapshot({required this.categories, required this.dishes});

  final List<MenuCategory> categories;
  final List<Dish> dishes;
}

/// Корзина для QR-предзаказа.
class PreorderItem {
  const PreorderItem({required this.dishId, this.qty = 1, this.note = ''});
  final String dishId;
  final int qty;
  final String note;

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'qty': qty,
        if (note.isNotEmpty) 'note': note,
      };
}

/// Главный клиент сервера. Один экземпляр на приложение.
class RestaurantApiClient {
  RestaurantApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Адрес сервера без слеша в конце, например `http://192.168.1.10:8765`.
  final String baseUrl;
  final AuthTokenStorage tokenStorage;
  final http.Client _http;

  void close() => _http.close();

  // ----------------------------- diagnostics --------------------------

  /// Лёгкая проверка доступности сервера через `GET /api/health`.
  /// Возвращает round-trip в миллисекундах. Бросает [ApiException]
  /// с `isNetwork == true`, если запрос вообще не дошёл.
  Future<int> health() async {
    final sw = Stopwatch()..start();
    await _request('GET', '/api/health', auth: false);
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  /// WS-URL, выведенный из [baseUrl]: `http→ws`, `https→wss`,
  /// тот же host/port, путь `/ws`. Используется при создании
  /// `RealtimeChannel`.
  String get wsUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = (uri.scheme == 'https' || uri.scheme == 'wss')
        ? 'wss'
        : 'ws';
    return uri.replace(scheme: scheme, path: '/ws').toString();
  }

  // ------------------------------- auth -------------------------------

  Future<AuthResult> login(String username, String password) async {
    final res = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
    );
    final auth = AuthResult.fromJson(res);
    await tokenStorage.write(auth.token);
    return auth;
  }

  Future<void> logout() async => tokenStorage.clear();

  // ------------------------------- menu -------------------------------

  Future<MenuSnapshot> fetchMenu() async {
    final json = await _request('GET', '/api/menu', auth: false);
    return MenuSnapshot(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      dishes: (json['dishes'] as List<dynamic>)
          .map((e) => Dish.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  // ------------------------------ halls -------------------------------

  Future<List<Hall>> fetchHalls() async {
    final json = await _request('GET', '/api/halls');
    return (json['halls'] as List<dynamic>)
        .map((e) => Hall.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ------------------------------ tables ------------------------------

  Future<List<RestaurantTable>> fetchTables() async {
    final json = await _request('GET', '/api/tables');
    return (json['tables'] as List<dynamic>)
        .map((e) => RestaurantTable.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Получить столик по QR-токену. Не требует авторизации
  /// (используется на странице QR-меню до создания заказа).
  Future<RestaurantTable> fetchTableByQr(String qrToken) async {
    final json = await _request(
      'GET',
      '/api/tables/by-qr/$qrToken',
      auth: false,
    );
    return RestaurantTable.fromJson(
      json['table'] as Map<String, dynamic>,
    );
  }

  // ------------------------------ orders ------------------------------

  Future<List<Order>> fetchActiveOrders() async {
    final json = await _request('GET', '/api/orders');
    return _parseOrdersList(json);
  }

  /// Активные заказы текущего официанта (`GET /api/orders?mine=true`).
  Future<List<Order>> fetchMyOrders() async {
    final json = await _request(
      'GET',
      '/api/orders',
      queryParameters: {'mine': 'true'},
    );
    return _parseOrdersList(json);
  }

  List<Order> _parseOrdersList(Map<String, dynamic> json) {
    return (json['orders'] as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Order> fetchOrder(String orderId) async {
    final json = await _request('GET', '/api/orders/$orderId');
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<Order> createOrder({
    required String tableId,
    int? guestsCount,
  }) async {
    final json = await _request(
      'POST',
      '/api/orders',
      body: {
        'tableId': tableId,
        if (guestsCount != null) 'guestsCount': guestsCount,
      },
    );
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<Order> updateOrderGuests(String orderId, int guestsCount) async {
    final json = await _request(
      'PATCH',
      '/api/orders/$orderId',
      body: {'guestsCount': guestsCount},
    );
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<Order> removeDraftItem(String orderId, String itemId) async {
    final json = await _request(
      'DELETE',
      '/api/orders/$orderId/items/$itemId',
    );
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<({Order order, OrderItem item})> addItemToOrder(
    String orderId, {
    required String dishId,
    int qty = 1,
    int courseNo = 1,
    String? note,
  }) async {
    final json = await _request(
      'POST',
      '/api/orders/$orderId/items',
      body: {
        'dishId': dishId,
        'qty': qty,
        'courseNo': courseNo,
        if (note != null) 'note': note,
      },
    );
    return (
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      item: OrderItem.fromJson(json['item'] as Map<String, dynamic>),
    );
  }

  Future<({Order order, int sentCount})> sendToKitchen(String orderId) async {
    final json = await _request('POST', '/api/orders/$orderId/send');
    return (
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      sentCount: (json['sentCount'] as num).toInt(),
    );
  }

  Future<OrderItem> changeItemStatus(
    String orderId,
    String itemId,
    OrderItemStatus status,
  ) async {
    final json = await _request(
      'PATCH',
      '/api/orders/$orderId/items/$itemId/status',
      body: {'status': status.name},
    );
    return OrderItem.fromJson(json['item'] as Map<String, dynamic>);
  }

  Future<Order> pay(
    String orderId, {
    required PaymentMethod method,
    required double amount,
  }) async {
    final json = await _request(
      'POST',
      '/api/orders/$orderId/pay',
      body: {'method': method.name, 'amount': amount},
    );
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  // ---------------------------- kitchen -------------------------------

  Future<List<KitchenTicket>> fetchKitchenTickets() async {
    final json = await _request('GET', '/api/kitchen/tickets');
    return (json['tickets'] as List<dynamic>)
        .map((e) => KitchenTicket.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // -------------------------- preorder (QR) ---------------------------

  Future<Order> createPreorder({
    required String qrToken,
    required List<PreorderItem> items,
    String? note,
    int? guestsCount,
  }) async {
    final json = await _request(
      'POST',
      '/api/preorders',
      body: {
        'qrToken': qrToken,
        'items': items.map((e) => e.toJson()).toList(growable: false),
        if (note != null) 'note': note,
        if (guestsCount != null) 'guestsCount': guestsCount,
      },
      auth: false,
    );
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  // ---------------------------- internals -----------------------------

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await tokenStorage.read();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final http.Response res;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..encoding = utf8;
      if (body != null) request.body = jsonEncode(body);
      final stream = await _http.send(request);
      res = await http.Response.fromStream(stream);
    } catch (e) {
      throw ApiException.network(e);
    }

    if (res.statusCode == 401) {
      await tokenStorage.clear();
      throw ApiException.unauthorized();
    }

    final decoded = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw ApiException(
        (decoded['error'] as String?) ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
        body: decoded,
      );
    }
    return decoded;
  }
}
