import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/transactions/domain/entities/external_transfer.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

void main() {
  group('TransactionVisualSpec', () {
    test('classifies on-chain sends as outgoing on-chain', () {
      final transaction = Transaction(
        id: 'tx-onchain-send',
        fromAddress: 'minha-carteira',
        toAddress: 'bc1qdestination',
        amountSatoshis: 125000,
        feeSatoshis: 1200,
        status: TransactionStatus.pending,
        type: TransactionType.withdrawal,
        confirmations: 0,
        timestamp: DateTime(2026, 4, 22),
      );

      final visual = TransactionVisualSpec.fromTransaction(transaction);

      expect(visual.family, TransactionVisualFamily.onChain);
      expect(visual.direction, TransactionVisualDirection.outgoing);
      expect(visual.labelKey, TransactionVisualLabel.onChainSend);
      expect(visual.prefix, '-');
    });

    test('classifies internal receives as incoming internal transfers', () {
      final transaction = Transaction(
        id: 'tx-internal',
        fromAddress: 'alice',
        toAddress: 'bob',
        amountSatoshis: 50000,
        feeSatoshis: 0,
        status: TransactionStatus.confirmed,
        type: TransactionType.receive,
        confirmations: 6,
        timestamp: DateTime(2026, 4, 22),
        isInternal: true,
      );

      final visual = TransactionVisualSpec.fromTransaction(transaction);

      expect(visual.family, TransactionVisualFamily.internalTransfer);
      expect(visual.direction, TransactionVisualDirection.incoming);
      expect(visual.labelKey, TransactionVisualLabel.internalReceive);
      expect(visual.prefix, '+');
    });

    test('classifies qr descriptions before generic payment link heuristics',
        () {
      final transaction = Transaction(
        id: 'pl_123',
        fromAddress: 'Rede Bitcoin',
        toAddress: 'bc1qwallet',
        amountSatoshis: 21000,
        feeSatoshis: 0,
        status: TransactionStatus.pending,
        type: TransactionType.receive,
        confirmations: 0,
        timestamp: DateTime(2026, 4, 22),
        description: 'Recebimento via QR',
      );

      final visual = TransactionVisualSpec.fromTransaction(transaction);

      expect(visual.family, TransactionVisualFamily.qrCode);
      expect(visual.direction, TransactionVisualDirection.incoming);
      expect(visual.labelKey, TransactionVisualLabel.qrReceive);
    });

    test('classifies lightning transactions from the explicit flag', () {
      final transaction = Transaction(
        id: 'tx-lightning',
        fromAddress: 'minha-carteira',
        toAddress: 'lnbc1pjexampleinvoice',
        amountSatoshis: 6400,
        feeSatoshis: 10,
        status: TransactionStatus.pending,
        type: TransactionType.withdrawal,
        confirmations: 0,
        timestamp: DateTime(2026, 4, 22),
        isLightning: true,
      );

      final visual = TransactionVisualSpec.fromTransaction(transaction);

      expect(visual.family, TransactionVisualFamily.lightning);
      expect(visual.direction, TransactionVisualDirection.outgoing);
      expect(visual.labelKey, TransactionVisualLabel.lightningPayment);
    });

    test('keeps deposits in the dedicated deposit family', () {
      final transaction = Transaction(
        id: 'tx-deposit',
        fromAddress: 'Rede Bitcoin',
        toAddress: 'bc1qwallet',
        amountSatoshis: 90000,
        feeSatoshis: 0,
        status: TransactionStatus.confirming,
        type: TransactionType.deposit,
        confirmations: 1,
        timestamp: DateTime(2026, 4, 22),
      );

      final visual = TransactionVisualSpec.fromTransaction(transaction);

      expect(visual.family, TransactionVisualFamily.deposit);
      expect(visual.direction, TransactionVisualDirection.incoming);
      expect(visual.labelKey, TransactionVisualLabel.deposit);
    });
  });

  group('ExternalTransfer.toTransaction', () {
    test('preserves the lightning flag for merged transaction history', () {
      final transfer = ExternalTransfer(
        id: 'transfer-1',
        network: 'LIGHTNING',
        transferType: 'OUTBOUND_PAYMENT',
        status: 'PENDING',
        provider: 'mock',
        walletName: 'MAIN',
        destination: 'lnbc1pjexampleinvoice',
        amountBtc: 0.0002,
        networkFeeBtc: 0.000001,
        platformFeeBtc: 0,
        totalDebitedBtc: 0.000201,
        externalReference: 'ln-ref',
        invoiceId: '',
        blockchainTxid: '',
        paymentHash: 'payment-hash-1',
        invoiceData: 'lnbc1pjexampleinvoice',
        expectedAmountBtc: 0,
        confirmations: 0,
        detectedAt: null,
        settledAt: null,
        createdAt: DateTime(2026, 4, 22),
        updatedAt: DateTime(2026, 4, 22),
        context: 'Pagamento Lightning',
      );

      final transaction = transfer.toTransaction();

      expect(transaction.isLightning, isTrue);
      expect(transaction.type, TransactionType.withdrawal);
    });
  });
}
