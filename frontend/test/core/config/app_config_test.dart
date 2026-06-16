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
    expect(AppConfig.walletAll, '/kfe/dashboard');
    expect(AppConfig.ledgerPaymentRequest, '/kfe/transactions');
    expect(
        AppConfig.transactionsPaymentLinksList, '/transactions/payment-links');
    expect(
      AppConfig.bitcoinAccountReceiveRequests('account-1'),
      '/kfe/wallets/account-1/addresses/rotate',
    );
    expect(
      AppConfig.bitcoinColdWalletUtxos('cold-1'),
      '/kfe/wallets',
    );
    expect(
      AppConfig.bitcoinColdWalletPsbt('cold-1'),
      '/kfe/wallets',
    );
    expect(AppConfig.bitcoinPsbt('workflow-1'), '/kfe/transactions');
    expect(
      AppConfig.bitcoinPsbtSigned('workflow-1'),
      '/kfe/transactions',
    );
    expect(AppConfig.bitcoinTaxEvents, '/kfe/dashboard');
    expect(
      AppConfig.bitcoinTaxEventsExport('csv'),
      '/kfe/dashboard',
    );
    expect(
      AppConfig.bitcoinTaxEventClassify('event-1'),
      '/kfe/dashboard',
    );
    expect(AppConfig.notificationsList, '/notifications');
    expect(AppConfig.auditStats, '/v1/audit/stats');
    expect(
      AppConfig.adminOperationsOverview,
      '/api/admin/operations/overview',
    );
  });
}
