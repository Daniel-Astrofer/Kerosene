import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/auth/presentation/screens/welcome_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('welcome screen', (tester) async {
    await pumpFullScreenGolden(tester, const WelcomeScreen());
    await screenMatchesGolden(tester, 'welcome_screen');
  });
}
