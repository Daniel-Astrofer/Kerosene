// ignore_for_file: depend_on_referenced_packages

import 'package:kerosene/core/config/app_config.dart';
import 'package:test/test.dart';

void main() {
  test('mobile defaults use the current local-full onion service', () {
    final nodeUri = Uri.parse(AppConfig.nodeIS);

    expect(nodeUri.scheme, 'http');
    expect(nodeUri.host, endsWith('.onion'));
    expect(AppConfig.nodeCH, AppConfig.nodeIS);
    expect(AppConfig.nodeSG, AppConfig.nodeIS);
  });

  test('activeNodeName tolerates local and custom API URLs', () {
    final previous = AppConfig.activeNodeUrl;
    addTearDown(() => AppConfig.activeNodeUrl = previous);

    AppConfig.activeNodeUrl = 'http://localhost:8080';

    expect(AppConfig.activeNodeName, 'localhost');
  });

  test('active domain endpoints remain mapped to KFE backend contracts', () {
    expect(AppConfig.authLogin, '/auth/login');
    expect(
      AppConfig.authEmergencyRecoveryStart,
      '/auth/recovery/emergency/start',
    );
    expect(
      AppConfig.authEmergencyRecoveryFinish,
      '/auth/recovery/emergency/finish',
    );

    expect(AppConfig.kfeDashboard, '/kfe/dashboard');
    expect(AppConfig.kfeWallets, '/kfe/wallets');
    expect(AppConfig.kfeTransactions, '/kfe/transactions');
    expect(AppConfig.kfeTransactionQuote, '/kfe/transactions/quote');
    expect(AppConfig.kfePaymentRequests, '/kfe/payment-requests');
    expect(
      AppConfig.kfePaymentRequest('request-1'),
      '/kfe/payment-requests/request-1',
    );
    expect(
      AppConfig.kfePublicPaymentRequest('public-1'),
      '/api/public/kfe/payment-requests/public-1',
    );
    expect(
      AppConfig.kfeColdWalletUtxos('cold-1'),
      '/kfe/wallets/cold-1/utxos',
    );
    expect(
      AppConfig.kfeColdWalletPsbtCreate('cold-1'),
      '/kfe/wallets/cold-1/cold-wallet/psbt',
    );
    expect(
      AppConfig.kfeColdWalletPsbtWorkflow('workflow-1'),
      '/kfe/cold-wallet/psbts/workflow-1',
    );
    expect(
      AppConfig.kfeColdWalletPsbtSigned('workflow-1'),
      '/kfe/cold-wallet/psbts/workflow-1/signed',
    );
    expect(
      AppConfig.kfeColdWalletPsbtBroadcast('workflow-1'),
      '/kfe/cold-wallet/psbts/workflow-1/broadcast',
    );
    expect(AppConfig.kfeTaxEvents, '/kfe/tax-events');
    expect(
      AppConfig.kfeTaxEventsExport('csv'),
      '/kfe/tax-events/export?format=csv',
    );
    expect(
      AppConfig.kfeTaxEventClassify('event-1'),
      '/kfe/tax-events/event-1/classify',
    );
    expect(AppConfig.kfeReserveOverview, '/api/admin/kfe/reserves/overview');
    expect(
      AppConfig.kfeReceivingCapabilities(' @alice/btc '),
      '/kfe/users/%40alice%2Fbtc/receiving-capabilities',
    );

    expect(AppConfig.notificationsList, '/notifications');
    expect(() => AppConfig.auditStats, throwsUnsupportedError);
    expect(
      AppConfig.auditMerkleLatestRoot,
      '/api/admin/kfe/audit/latest',
    );
    expect(AppConfig.auditMerkleHistory, '/api/admin/kfe/audit/events');
    expect(AppConfig.auditMerkleTrigger, '/api/admin/kfe/audit/root');
    expect(
      AppConfig.adminOperationsBlockchain,
      '/api/admin/operations/blockchain',
    );
    expect(
      () => AppConfig.adminOperationsBlockchainSync,
      throwsUnsupportedError,
    );
    expect(
      AppConfig.adminOperationsLightning,
      '/api/admin/operations/lightning',
    );
    expect(
      AppConfig.adminOperationsOverview,
      '/api/admin/operations/overview',
    );
  });
}
