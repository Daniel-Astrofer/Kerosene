import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/profile/presentation/screens/security_settings_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('security settings screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      const SecuritySettingsScreen(),
      size: const Size(430, 7600),
    );
    await screenMatchesGolden(tester, 'security_settings_screen');
  });
}
