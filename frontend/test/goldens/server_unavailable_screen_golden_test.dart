import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/auth/presentation/screens/server_unavailable_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('server unavailable screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      const ServerUnavailableScreen(
        message: 'Manutenção programada para atualização de infraestrutura.',
      ),
    );
    await screenMatchesGolden(tester, 'server_unavailable_screen');
  });
}
