import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/wallet/presentation/screens/receive_method.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_request_flow_screen.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('receive request flow screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      ReceiveRequestFlowScreen(
        wallet: mockWallets.first,
        onChainWallet: true,
        amountBtc: 0.0042,
        method: ReceiveAmountMethod.qrCode,
        enableStatusPolling: false,
        initialStage: ReceiveRequestStage.qr,
        initialAddress: mockWallets.first.address,
        initialPaymentUri: 'bitcoin:${mockWallets.first.address}?amount=0.0042',
      ),
    );
    await screenMatchesGolden(tester, 'receive_request_flow_screen');
  });
}
