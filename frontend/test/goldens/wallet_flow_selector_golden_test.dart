import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_flow_selector.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('wallet flow selector', (tester) async {
    await pumpFullScreenGolden(
      tester,
      WalletFlowSelector(
        title: 'Enviar',
        subtitle: 'Escolha uma carteira',
        initialWallet: mockWallets.first,
        onContinue: (_) {},
      ),
    );
    await screenMatchesGolden(tester, 'wallet_flow_selector');
  });
}
