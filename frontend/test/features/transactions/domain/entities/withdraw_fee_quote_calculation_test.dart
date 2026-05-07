import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/transactions/domain/entities/withdraw_fee_quote_calculation.dart';

void main() {
  group('WithdrawFeeQuoteCalculation', () {
    test('adds fees when sender pays', () {
      final quote = WithdrawFeeQuoteCalculation.resolve(
        mode: WithdrawFeeMode.senderPays,
        requestedAmountBtc: 100,
        platformFeeRate: 0.10,
        networkFeeBtc: 10,
      );

      expect(quote.receiverAmountBtc, 100);
      expect(quote.platformFeeBtc, 10);
      expect(quote.totalFeesBtc, 20);
      expect(quote.totalDebitedBtc, 120);
    });

    test('deducts fees when recipient pays', () {
      final quote = WithdrawFeeQuoteCalculation.resolve(
        mode: WithdrawFeeMode.recipientPays,
        requestedAmountBtc: 120,
        platformFeeRate: 0.10,
        networkFeeBtc: 10,
      );

      expect(quote.receiverAmountBtc, closeTo(100, 0.00000001));
      expect(quote.platformFeeBtc, closeTo(10, 0.00000001));
      expect(quote.totalFeesBtc, closeTo(20, 0.00000001));
      expect(quote.totalDebitedBtc, closeTo(120, 0.00000001));
    });

    test('returns zero receiver amount when fees consume the total', () {
      final quote = WithdrawFeeQuoteCalculation.resolve(
        mode: WithdrawFeeMode.recipientPays,
        requestedAmountBtc: 10,
        platformFeeRate: 0.10,
        networkFeeBtc: 10,
      );

      expect(quote.receiverAmountBtc, 0);
      expect(quote.totalDebitedBtc, 0);
    });
  });
}
