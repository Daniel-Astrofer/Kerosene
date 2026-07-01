import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/domain/entities/statement_report.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/features/movement/domain/services/statement_report_calculator.dart';

void main() {
  final now = DateTime(2026, 6, 30, 12);

  test('counts external deposit as incoming movement', () {
    final report = StatementReportCalculator.calculate(
      wallets: [_wallet(id: 'wallet-global', name: 'Carteira Global')],
      transactions: [
        _transaction(
          id: 'deposit-1',
          walletId: 'wallet-global',
          destinationWalletId: 'wallet-global',
          amountSatoshis: 100000,
          type: TransactionType.deposit,
          timestamp: DateTime(2026, 6, 10),
        ),
      ],
      period: StatementReportPeriod.monthly,
      now: now,
    );

    expect(report.incomingSats, 100000);
    expect(report.outgoingSats, 0);
    expect(report.feeSats, 0);
    expect(_bucketValue(report, 'jun.', 'wallet-global'), 100000);
  });

  test('counts withdrawal amount and keeps fee separated', () {
    final report = StatementReportCalculator.calculate(
      wallets: [_wallet(id: 'wallet-global', name: 'Carteira Global')],
      transactions: [
        _transaction(
          id: 'withdrawal-1',
          walletId: 'wallet-global',
          sourceWalletId: 'wallet-global',
          amountSatoshis: 50000,
          feeSatoshis: 1000,
          type: TransactionType.withdrawal,
          timestamp: DateTime(2026, 6, 11),
        ),
      ],
      period: StatementReportPeriod.monthly,
      now: now,
    );

    expect(report.incomingSats, 0);
    expect(report.outgoingSats, 50000);
    expect(report.feeSats, 1000);
    expect(_bucketValue(report, 'jun.', 'wallet-global'), 51000);
  });
}

int _bucketValue(StatementReport report, String label, String walletId) {
  final bucket = report.buckets.firstWhere((bucket) => bucket.label == label);
  return bucket.values.firstWhere((value) => value.walletId == walletId).sats;
}

Wallet _wallet({
  required String id,
  required String name,
  String address = 'kerosene:global',
  double balance = 0.01,
}) {
  return Wallet(
    id: id,
    name: name,
    address: address,
    walletMode: 'KEROSENE',
    balance: balance,
    derivationPath: 'test-path',
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

Transaction _transaction({
  required String id,
  String fromAddress = 'external',
  String toAddress = 'external',
  String? walletId,
  String? sourceWalletId,
  String? destinationWalletId,
  required int amountSatoshis,
  int feeSatoshis = 0,
  TransactionStatus status = TransactionStatus.confirmed,
  required TransactionType type,
  required DateTime timestamp,
  bool isInternal = false,
}) {
  return Transaction(
    id: id,
    fromAddress: fromAddress,
    toAddress: toAddress,
    walletId: walletId,
    sourceWalletId: sourceWalletId,
    destinationWalletId: destinationWalletId,
    amountSatoshis: amountSatoshis,
    feeSatoshis: feeSatoshis,
    status: status,
    type: type,
    confirmations: status == TransactionStatus.confirmed ? 6 : 0,
    timestamp: timestamp,
    isInternal: isInternal,
  );
}
