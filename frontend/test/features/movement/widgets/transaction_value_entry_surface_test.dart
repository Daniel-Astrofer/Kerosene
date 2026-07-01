import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/movement/widgets/transaction_value_entry_surface.dart';

void main() {
  testWidgets('uses centered native amount input contract', (tester) async {
    String? latestAmount;
    var continued = false;
    var quoteTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionValueEntrySurface(
            onBack: () {},
            amountLabel: '0',
            fiatReference: '≈ R\$ 350.000,00',
            onAmountChanged: (value) => latestAmount = value,
            onFiatReferenceTap: () => quoteTapped = true,
            ctaLabel: 'Continuar',
            ctaEnabled: true,
            isBusy: false,
            onCta: () => continued = true,
          ),
        ),
      ),
    );

    expect(find.text('Inserir valor'), findsNothing);
    expect(find.text('₿0.00000000'), findsOneWidget);

    final input = find.byKey(const ValueKey('movement-amount-input'));
    await tester.enterText(input, '1');
    await tester.pump();

    expect(latestAmount, '0.00000001');

    await tester.enterText(input, '100000000');
    await tester.pump();
    expect(latestAmount, '1.00000000');

    await tester.enterText(input, '1.2.3');
    await tester.pump();
    expect(latestAmount, '0.00000123');

    await tester.tap(find.text('≈ R\$ 350.000,00'));
    await tester.pump();
    expect(quoteTapped, isTrue);

    await tester.showKeyboard(input);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(continued, isTrue);
  });
}
