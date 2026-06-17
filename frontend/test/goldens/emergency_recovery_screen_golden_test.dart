import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/auth/presentation/screens/emergency_recovery_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('emergency recovery screen', (tester) async {
    await pumpFullScreenGolden(tester, const EmergencyRecoveryScreen());
    await screenMatchesGolden(tester, 'emergency_recovery_screen');
  });
}
