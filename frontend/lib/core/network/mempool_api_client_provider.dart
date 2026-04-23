import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_client_route_policy.dart';

final mempoolApiClientProvider = Provider<ApiClient>((ref) {
  // Dados de mercado externos devem sair em clearnet.
  // O backend soberano continua separado no fluxo onion/Tor.
  return ApiClient(
    baseUrl: 'https://mempool.space/api',
    ref: ref,
    routePolicy: ApiClientRoutePolicy.clearnet,
  );
});
