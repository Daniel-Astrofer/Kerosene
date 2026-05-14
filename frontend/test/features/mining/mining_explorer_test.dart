import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/presentation/mining_explorer.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

void main() {
  group('MiningExplorerDescriptor', () {
    test('detects lightning payloads from invoice addresses', () {
      final transaction = Transaction(
        id: 'ln-payment',
        fromAddress: 'Minha carteira',
        toAddress: 'lnbc1pjexampleinvoicepayload',
        amountSatoshis: 1200,
        feeSatoshis: 0,
        status: TransactionStatus.pending,
        type: TransactionType.withdrawal,
        confirmations: 0,
        timestamp: DateTime(2026, 4, 14),
      );

      final descriptor = MiningExplorerDescriptor.fromTransaction(transaction);

      expect(descriptor.rail, MiningExplorerRail.lightning);
      expect(descriptor.buttonLabel, 'Lightning');
      expect(descriptor.canLookupOnchain, isFalse);
    });

    test('keeps blockchain txids only when they look public', () {
      final transaction = Transaction(
        id: 'internal-reference',
        fromAddress: 'Rede Bitcoin',
        toAddress: 'bc1qexampledestination',
        amountSatoshis: 150000,
        feeSatoshis: 1200,
        status: TransactionStatus.confirming,
        type: TransactionType.deposit,
        confirmations: 1,
        timestamp: DateTime(2026, 4, 14),
        blockchainTxid:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      final descriptor = MiningExplorerDescriptor.fromTransaction(transaction);

      expect(descriptor.rail, MiningExplorerRail.blockchain);
      expect(
        descriptor.txid,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(descriptor.canLookupOnchain, isTrue);
    });
  });

  group('estimateProjectedBlockIndex', () {
    test('uses the minimum fee in each projected block range', () {
      final blocks = [
        const MempoolFeeBlock(
          blockSize: 1,
          blockVSize: 0.98,
          txCount: 1000,
          totalFees: 100000,
          medianFee: 56,
          feeRange: [72, 61, 54],
        ),
        const MempoolFeeBlock(
          blockSize: 1,
          blockVSize: 0.95,
          txCount: 900,
          totalFees: 90000,
          medianFee: 24,
          feeRange: [39, 28, 18],
        ),
      ];

      expect(estimateProjectedBlockIndex(blocks, 55), 0);
      expect(estimateProjectedBlockIndex(blocks, 22), 1);
      expect(estimateProjectedBlockIndex(blocks, 4), 1);
    });
  });
}
