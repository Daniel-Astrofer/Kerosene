import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:kerosene/features/payments/presentation/screens/payment_intent_flow_screen.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeGoldenHarness);

  testGoldens('payment intent flow screen', (tester) async {
    await pumpFullScreenGolden(
      tester,
      const PaymentIntentFlowScreen(
        initialRecipient: 'lojakerosene@bitcoin',
        initialAmountFiat: '1250.00',
      ),
    );
    await screenMatchesGolden(tester, 'payment_intent_flow_screen');
  });
}
