import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/security/presentation/screens/settings_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('settings screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      const TickerMode(
        enabled: false,
        child: SettingsScreen(showPrimaryNavigation: true),
      ),
      size: const Size(430, 8000),
    );
    await screenMatchesGolden(tester, 'settings_screen');
  });
}
