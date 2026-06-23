import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/financial_activity/domain/entities/payment_link.dart';

void main() {
  group('PaymentLink settlement fields', () {
    test('parses KFE settlement metadata', () {
      final link = PaymentLink.fromJson({
        'id': 'pay_1',
        'userId': 10,
        'amountBtc': 0.0002,
        'description': 'Invoice',
        'depositAddress': 'bc1qexample',
        'status': 'paid',
        'txid': 'tx-1',
        'paymentRail': 'ONCHAIN',
        'settlementStatus': 'SETTLED',
        'settlementReference': 'tx-1',
        'terminal': true,
      });

      expect(link.paymentRail, 'ONCHAIN');
      expect(link.settlementStatus, 'SETTLED');
      expect(link.settlementReference, 'tx-1');
      expect(link.terminal, isTrue);
    });

    test('derives settlement metadata from KFE status', () {
      final link = PaymentLink.fromJson({
        'id': 'pay_2',
        'userId': 10,
        'amountBtc': 0.0002,
        'description': 'Invoice',
        'depositAddress': 'bc1qexample',
        'status': 'cancelled',
      });

      expect(link.paymentRail, 'ONCHAIN');
      expect(link.settlementStatus, 'CANCELED');
      expect(link.terminal, isTrue);
    });
  });
}
