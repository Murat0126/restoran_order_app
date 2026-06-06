import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client_provider.dart';

/// Кэш меню на сессию официанта. Инвалидируйте вручную при
/// изменении меню в админке (позже — push-событие с сервера).
final menuProvider = FutureProvider<MenuSnapshot>((ref) async {
  final client = ref.watch(restaurantApiClientProvider);
  return client.fetchMenu();
});
