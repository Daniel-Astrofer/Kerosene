import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final mempoolApiClientProvider = Provider<ApiClient>((ref) {
  // Use mempool.space as the base URL
  // We force Tor proxying if it's available, as requested
  return ApiClient(
    baseUrl: 'https://mempool.space/api',
    ref: ref,
    forceTor: true,
  );
});
