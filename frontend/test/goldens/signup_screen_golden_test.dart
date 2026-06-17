import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/auth/presentation/screens/signup/signup_flow_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('signup screen', (tester) async {
    await pumpFullScreenGolden(tester, const SignupFlowScreen());
    await screenMatchesGolden(tester, 'signup_screen');
  });
}
