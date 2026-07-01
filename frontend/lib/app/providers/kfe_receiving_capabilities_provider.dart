import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/movement/flow/kfe_receiving_capabilities_service.dart';

export 'package:kerosene/features/movement/flow/kfe_receiving_capabilities_service.dart'
    show KfeReceivingCapabilities, KfeReceivingCapabilitiesService;

final kfeReceivingCapabilitiesServiceProvider =
    Provider<KfeReceivingCapabilitiesService>((ref) {
  return RemoteKfeReceivingCapabilitiesService(ref.watch(apiClientProvider));
});
