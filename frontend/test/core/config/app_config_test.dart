// ignore_for_file: depend_on_referenced_packages

import 'package:kerosene/core/config/app_config.dart';
import 'package:test/test.dart';

void main() {
  test('activeNodeName tolerates local and custom API URLs', () {
    final previous = AppConfig.activeNodeUrl;
    addTearDown(() => AppConfig.activeNodeUrl = previous);

    AppConfig.activeNodeUrl = 'http://localhost:8080';

    expect(AppConfig.activeNodeName, 'localhost');
  });

  test('active domain endpoints remain mapped to backend contracts', () {
    expect(AppConfig.authLogin, '/auth/login');
    expect(
      AppConfig.authEmergencyRecoveryStart,
      '/auth/recovery/emergency/start',
    );
    expect(
      AppConfig.authEmergencyRecoveryFinish,
      '/auth/recovery/emergency/finish',
    );
    expect(AppConfig.walletAll, '/wallet/all');
    expect(AppConfig.ledgerPaymentRequest, '/ledger/payment-request');
    expect(
        AppConfig.transactionsPaymentLinksList, '/transactions/payment-links');
    expect(
      AppConfig.bitcoinAccountReceiveRequests('account-1'),
      '/bitcoin/accounts/account-1/receive-requests',
    );
    expect(
      AppConfig.bitcoinColdWalletUtxos('cold-1'),
      '/bitcoin/cold-wallets/cold-1/utxos',
    );
    expect(
      AppConfig.bitcoinColdWalletPsbt('cold-1'),
      '/bitcoin/cold-wallets/cold-1/psbt',
    );
    expect(AppConfig.bitcoinPsbt('workflow-1'), '/bitcoin/psbt/workflow-1');
    expect(
      AppConfig.bitcoinPsbtSigned('workflow-1'),
      '/bitcoin/psbt/workflow-1/signed',
    );
    expect(AppConfig.bitcoinTaxEvents, '/bitcoin/tax-events');
    expect(
      AppConfig.bitcoinTaxEventsExport('csv'),
      '/bitcoin/tax-events/export?format=csv',
    );
    expect(
      AppConfig.bitcoinTaxEventClassify('event-1'),
      '/bitcoin/tax-events/event-1/classify',
    );
    expect(AppConfig.notificationsList, '/notifications');
    expect(AppConfig.auditStats, '/v1/audit/stats');
    expect(
      AppConfig.adminOperationsOverview,
      '/api/admin/operations/overview',
    );
  });
}
