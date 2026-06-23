import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/data/emergency_recovery_service.dart';

final emergencyRecoveryServiceProvider =
    Provider<EmergencyRecoveryService>((ref) {
  return RemoteEmergencyRecoveryService(ref.watch(authApiClientProvider));
});
