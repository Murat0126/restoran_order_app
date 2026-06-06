import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_base_url.dart';
import 'token_storage.dart';

/// Главный `RestaurantApiClient`.
///
/// Зависит от `apiBaseUrlProvider` и `tokenStorageProvider` через
/// `ref.watch` — поэтому при смене base URL в Settings провайдер
/// **автоматически пересоберётся**, старый клиент закроется
/// (через `ref.onDispose`), новый создастся.
///
/// Все экраны, которые делают API-запросы, должны брать клиент
/// именно через этот провайдер — не создавать `RestaurantApiClient`
/// руками.
final restaurantApiClientProvider = Provider<RestaurantApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final storage = ref.watch(tokenStorageProvider);

  final client = RestaurantApiClient(
    baseUrl: baseUrl,
    tokenStorage: storage,
  );

  ref.onDispose(client.close);
  return client;
});
