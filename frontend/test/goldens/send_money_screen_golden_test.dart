import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('send money screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      SendMoneyScreen(walletId: mockWallets.first.id),
    );
    await screenMatchesGolden(tester, 'send_money_screen');
  });
}
