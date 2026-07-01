import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/movement/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('receive nfc flow screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      ReceiveNfcFlowScreen(
        wallet: mockWallets.first,
        onChainWallet: true,
        amountBtc: 0.0042,
        supportsNfc: () async => true,
      ),
    );
    await screenMatchesGolden(
      tester,
      'receive_nfc_flow_screen',
      finder: find.byType(ReceiveNfcFlowScreen),
      customPump: pumpGoldenAnimationFrame,
    );
  });
}
