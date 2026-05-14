import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';

void main() {
  group('PaymentLink compatibility fields', () {
    test('parses backend PaymentIntent compatibility metadata', () {
      final link = PaymentLink.fromJson({
        'id': 'pay_1',
        'userId': 10,
        'amountBtc': 0.0002,
        'description': 'Invoice',
        'depositAddress': 'bc1qexample',
        'status': 'paid',
        'txid': 'tx-1',
        'paymentRail': 'ONCHAIN',
        'paymentIntentStatus': 'SETTLED',
        'settlementReference': 'tx-1',
        'terminal': true,
      });

      expect(link.paymentRail, 'ONCHAIN');
      expect(link.paymentIntentStatus, 'SETTLED');
      expect(link.settlementReference, 'tx-1');
      expect(link.terminal, isTrue);
    });

    test('derives compatibility metadata for older responses', () {
      final link = PaymentLink.fromJson({
        'id': 'pay_2',
        'userId': 10,
        'amountBtc': 0.0002,
        'description': 'Invoice',
        'depositAddress': 'bc1qexample',
        'status': 'cancelled',
      });

      expect(link.paymentRail, 'ONCHAIN');
      expect(link.paymentIntentStatus, 'CANCELED');
      expect(link.terminal, isTrue);
    });
  });
}
