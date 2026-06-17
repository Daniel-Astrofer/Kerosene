import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/wallet/presentation/screens/receive_payment_link_screen.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('receive payment link screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      ReceivePaymentLinkScreen(
        initialLink: mockPaymentLink(
          amountBtc: 0.0042,
          internal: false,
        ),
        requestedAmountLabel: r'R$ 1.250,00',
        btcAmountLabel: '0.00420000 BTC',
        walletLabel: mockWallets.first.name,
        cardTypeLabel: 'Carteira principal',
        depositFeeLabel: 'Taxa de depósito: 0.00000012 BTC',
        netAmountLabel: 'Líquido: 0.00419988 BTC',
      ),
    );
    await screenMatchesGolden(tester, 'receive_payment_link_screen');
  });
}
