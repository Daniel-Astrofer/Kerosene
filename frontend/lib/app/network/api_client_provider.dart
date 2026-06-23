import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/core/providers/tor_providers.dart';
import 'package:kerosene/features/auth/controller/auth_local_provider.dart';
import 'package:kerosene/features/auth/data/interceptors/token_interceptor.dart';

// App-level composition: wires the core API client with auth-specific material.
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(torApiUrlProvider);
  final client = ApiClient(baseUrl: baseUrl, ref: ref);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  client.addInterceptor(
    TokenInterceptor(localDataSource: localDataSource, apiClient: client),
  );

  return client;
});
