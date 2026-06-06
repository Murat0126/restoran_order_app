// Прогоняет полный сценарий через api_client + WebSocket.
// Запуск: dart run packages/api_client/bin/smoke.dart [http://host:port]

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:shared_models/shared_models.dart';

Future<void> main(List<String> args) async {
  final baseUrl = args.isEmpty ? 'http://localhost:8765' : args[0];

  print('=== Smoke test против $baseUrl ===\n');

  final client = RestaurantApiClient(
    baseUrl: baseUrl,
    tokenStorage: InMemoryAuthTokenStorage(),
  );
  final realtime = RealtimeChannel.fromApiBase(baseUrl);

  final received = <WsEvent>[];
  realtime.events.listen((e) {
    received.add(e);
    print('  WS << ${e.type}');
  });
  realtime.status.listen((s) => print('  WS status: ${s.name}'));

  await realtime.connect();
  await Future<void>.delayed(const Duration(milliseconds: 300));

  print('\n[1] login waiter1/1234');
  final auth = await client.login('waiter1', '1234');
  print('    user: ${auth.user.displayName} (${auth.user.role.name})');

  print('\n[2] fetch menu');
  final menu = await client.fetchMenu();
  print('    ${menu.categories.length} категорий, ${menu.dishes.length} блюд');

  print('\n[3] fetch tables');
  final tables = await client.fetchTables();
  print('    ${tables.length} столиков');
  final firstFree = tables.firstWhere(
    (t) => t.status == TableStatus.free,
    orElse: () => tables.first,
  );

  print('\n[4] создать заказ на стол ${firstFree.number}');
  final order = await client.createOrder(tableId: firstFree.id);
  print('    orderId = ${order.id}');

  print('\n[5] добавить позиции (борщ ×1, эспрессо ×2)');
  await client.addItemToOrder(order.id, dishId: 'd-3', qty: 1);
  await client.addItemToOrder(order.id, dishId: 'd-8', qty: 2);

  print('\n[6] отправить на кухню');
  final sent = await client.sendToKitchen(order.id);
  print('    sentCount=${sent.sentCount}, status=${sent.order.status.name}');

  print('\n[7] кухня видит тикет');
  final tickets = await client.fetchKitchenTickets();
  for (final t in tickets) {
    print('    tкт: table=${t.tableNumber}, items=${t.items.length}, station=${t.station.name}');
  }

  print('\n[8] QR-предзаказ от клиента на другой столик');
  final qrTable = tables.firstWhere(
    (t) => t.qrToken != null && t.id != firstFree.id,
  );
  final preorder = await client.createPreorder(
    qrToken: qrTable.qrToken!,
    items: const [
      PreorderItem(dishId: 'd-1', qty: 1),
      PreorderItem(dishId: 'd-5', qty: 1, note: 'medium rare'),
    ],
    note: 'Через QR',
  );
  print('    предзаказ id=${preorder.id}, source=${preorder.source.name}');

  print('\n[9] ждём ещё немного, чтобы все WS-события прилетели...');
  await Future<void>.delayed(const Duration(milliseconds: 500));

  print('\n=== Получено WS-событий: ${received.length} ===');
  for (final e in received) {
    print('  - ${e.type}');
  }

  await realtime.dispose();
  client.close();
  print('\nOK');
}
