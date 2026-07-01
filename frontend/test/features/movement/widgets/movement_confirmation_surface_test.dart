import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/movement/widgets/movement_confirmation_surface.dart';

void main() {
  testWidgets('renders configurable confirmation title amount and rows',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MovementConfirmationSurface(
            title: 'Transação Confirmada',
            amountLabel: '0.01000000 BTC',
            supportingLabel: 'R\$ 3.000,00',
            rows: [
              MovementConfirmationRow(label: 'Rede', value: 'Kerosene'),
              MovementConfirmationRow(label: 'Carteira', value: 'Principal'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Transação Confirmada'), findsOneWidget);
    expect(find.text('0.01000000 BTC'), findsOneWidget);
    expect(find.text('R\$ 3.000,00'), findsOneWidget);
    expect(find.text('REDE'), findsOneWidget);
    expect(find.text('Kerosene'), findsOneWidget);
    expect(find.text('CARTEIRA'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });
}
