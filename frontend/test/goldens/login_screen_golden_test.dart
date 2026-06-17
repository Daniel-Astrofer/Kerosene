import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/auth/presentation/screens/login_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('login screen', (tester) async {
    await pumpFullScreenGolden(tester, const LoginScreen());
    await screenMatchesGolden(tester, 'login_screen');
  });
}
