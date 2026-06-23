import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/receive/presentation/screens/receive_amount_screen.dart';
import 'package:kerosene/features/receive/presentation/screens/receive_method.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('receive amount screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      ReceiveAmountScreen(
        wallet: mockWallets.first,
        method: ReceiveAmountMethod.qrCode,
        onChainWallet: true,
      ),
    );
    await screenMatchesGolden(tester, 'receive_amount_screen');
  });
}
