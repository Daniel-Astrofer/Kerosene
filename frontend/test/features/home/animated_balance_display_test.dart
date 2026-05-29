import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/home/presentation/widgets/animated_balance_display.dart';

void main() {
  testWidgets('AnimatedBalanceDisplay updates rolling digits without errors',
      (tester) async {
    Widget buildSubject(double balance) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedBalanceDisplay(
              balance: balance,
              prefix: '₿ ',
              decimalPlaces: 2,
              locale: 'en_US',
              enableFlash: true,
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSubject(1234.56));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(AnimatedBalanceDisplay), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildSubject(1299.42));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(AnimatedBalanceDisplay), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
