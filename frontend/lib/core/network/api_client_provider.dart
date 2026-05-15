import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../../features/auth/controller/auth_local_provider.dart';
import '../../features/auth/data/interceptors/token_interceptor.dart';

import '../providers/tor_providers.dart';

// This provider is shared across the app
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(torApiUrlProvider);
  final client = ApiClient(baseUrl: baseUrl, ref: ref);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  client.addInterceptor(
    TokenInterceptor(localDataSource: localDataSource, apiClient: client),
  );

  ref.onDispose(client.dispose);

  return client;
});
