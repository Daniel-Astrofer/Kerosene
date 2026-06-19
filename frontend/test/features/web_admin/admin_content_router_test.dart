import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/transactions/domain/entities/payment_link.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/web_admin/navigation/admin_content_router.dart';
import 'package:kerosene/features/web_admin/navigation/admin_routes.dart';
import 'package:kerosene/features/web_admin/providers/admin_providers.dart';
import 'package:kerosene/features/web_admin/screens/notifications/notifications_screen.dart';
import 'package:kerosene/features/web_admin/theme/admin_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AdminContentRouter renders every route without placeholders',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final route in AdminRoute.values) {
      final container = _containerFor(route);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdminContentRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Module unavailable in this build.'),
        findsNothing,
        reason: '${route.name} must render a real admin screen.',
      );
      expect(find.byType(AdminContentRouter), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    }
  });
}

ProviderContainer _containerFor(AdminRoute route) {
  final container = ProviderContainer(
    overrides: [
      adminBtcPriceProvider.overrideWith(
        (ref) async => const {
          'btcUsd': 65000.0,
          'btcBrl': 325000.0,
          'usdBrl': 5.0,
        },
      ),
      adminAuditStatsProvider.overrideWith((ref) async => _auditStats),
      adminAuditHistoryProvider.overrideWith((ref) async => _auditHistory),
      adminAuditLatestRootProvider.overrideWith((ref) async => _latestRoot),
      adminSovereigntyProvider.overrideWith((ref) async => _sovereignty),
      adminCurrentUserProvider.overrideWith((ref) async => _currentUser),
      adminOperationsOverviewProvider
          .overrideWith((ref) async => _operationsOverview),
      adminOperationalHealthProvider
          .overrideWith((ref) async => _operationalHealth),
      adminBlockchainMonitorProvider
          .overrideWith((ref) async => _blockchainMonitor),
      adminLightningMonitorProvider
          .overrideWith((ref) async => _lightningMonitor),
      adminVaultRaftHealthProvider.overrideWith((ref) async => _vaultHealth),
      adminReleaseSnapshotProvider
          .overrideWith((ref) async => _releaseSnapshot),
      adminMobileReleaseProvider.overrideWith((ref) async => _mobileRelease),
      adminOperationalMetricsProvider
          .overrideWith((ref) async => _operationalMetrics),
      adminOperationalLogsProvider
          .overrideWith((ref) async => _operationalLogs),
      adminMobileDevicesProvider.overrideWith((ref) async => _mobileDevices),
      adminWebDevicesProvider.overrideWith((ref) async => _webDevices),
      paymentLinksProvider.overrideWith((ref) async => [_paymentLink]),
      notificationsListProvider.overrideWith((ref) async => const []),
    ],
  );

  container.read(adminRouteProvider.notifier).navigate(route);
  return container;
}

final _paymentLink = PaymentLink(
  id: 'test-link',
  userId: 1,
  amountBtc: 0.0042,
  grossAmountBtc: 0.0042,
  netAmountBtc: 0.0042,
  description: 'Admin router test',
  depositAddress: 'bc1qadmintest000000000000000000000000',
  status: 'paid',
  createdAt: DateTime(2026, 5, 29, 12),
  paidAt: DateTime(2026, 5, 29, 12, 4),
  paymentRail: 'ONCHAIN',
  settlementStatus: 'SETTLED',
  terminal: true,
);

const _auditStats = {
  'totalEvents': 120,
  'criticalEvents': 0,
  'warningEvents': 2,
  'ledgerCount': 88,
};

final _auditHistory = [
  {
    'merkleRoot': 'storybook-root',
    'ledgerCount': 88,
    'anchorTxid': 'storybook-anchor',
    'createdAt': '2026-05-29T12:00:00Z',
  },
];

const _latestRoot = {
  'merkleRoot': 'storybook-root',
  'ledgerCount': 88,
  'anchorTxid': 'storybook-anchor',
  'createdAt': '2026-05-29T12:00:00Z',
};

const _sovereignty = {
  'hardwareAttestation': {'status': 'VERIFIED'},
  'networkConsensus': {'status': 'HEALTHY'},
  'ledgerIntegrity': {'status': 'ANCHORED'},
  'memoryProtection': {'status': 'ENFORCED'},
};

const _currentUser = {
  'id': 'admin-test',
  'username': 'admin-test',
  'role': 'ADMIN',
};

const _operationsOverview = {
  'checkedAt': '2026-05-29T12:00:00Z',
  'health': {'status': 'HEALTHY'},
  'blockchain': {'status': 'SYNCED'},
  'lightning': {'status': 'ONLINE'},
  'vaultRaft': {'status': 'QUORUM'},
};

const _operationalHealth = {
  'status': 'HEALTHY',
  'service': 'kerosene-core',
  'checks': {
    'api': {'status': 'HEALTHY', 'message': 'responding'},
  },
};

const _blockchainMonitor = {
  'status': 'SYNCED',
  'primarySource': 'bitcoin-core',
  'network': 'mainnet',
  'indexer': 'electrs',
  'chain': {
    'height': 842000,
    'bestBlockHash': '000000000000000000test',
    'pruned': false,
    'pruneHeight': 0,
  },
  'mempool': {'transactions': 8},
  'fees': {'fastestFee': 22, 'halfHourFee': 16},
  'relevantTransactions': [
    {'status': 'CONFIRMED', 'txidRef': 'tx-test', 'confirmations': 6},
  ],
};

const _lightningMonitor = {
  'status': 'ONLINE',
  'message': 'operational probe',
  'primarySource': 'lnd',
  'checkedAt': '2026-05-29T12:00:00Z',
  'node': {
    'alias': 'kerosene-test',
    'version': '0.18.0',
    'identityPubkey': '03test',
    'blockHeight': 842000,
    'blockHash': '000000000000000000test',
    'syncedToChain': true,
    'syncedToGraph': true,
    'numPeers': 4,
    'numActiveChannels': 6,
    'numInactiveChannels': 0,
    'numPendingChannels': 0,
    'localBalanceSats': 1000000,
    'remoteBalanceSats': 2000000,
    'walletConfirmedBalanceSats': 3000000,
  },
};

const _vaultHealth = {
  'status': 'QUORUM',
  'expectedServers': 3,
  'votingServers': 3,
};

const _releaseSnapshot = {
  'authorized': true,
  'reason': 'test-release',
  'gitCommit': 'abcdef123456',
  'imageDigest': 'sha256:test',
  'manifestDigest': 'sha256:manifest',
  'codeHash': 'sha256:code',
  'configHash': 'sha256:config',
};

const _mobileRelease = {
  'version': '1.0.0-test',
  'platform': 'linux',
};

const _operationalMetrics = {
  'totalVolumeBtc': 1.2,
  'totalFeesBtc': 0.01,
  'totalTransactions': 100,
  'confirmedTransactions': 97,
  'pendingTransactions': 2,
  'failedTransactions': 1,
  'avgTicketBtc': 0.012,
  'transfers': {
    'onchainFeesBtc': 0.007,
    'lightningFeesBtc': 0.003,
    'onchainVolumeBtc': 0.8,
    'lightningVolumeBtc': 0.4,
    'onchainCount': 35,
    'lightningCount': 65,
    'inflowBtc': 0.9,
    'outflowBtc': 0.3,
  },
  'paymentLinks': {
    'linksCreated': 24,
    'linksPaid': 20,
    'linksExpired': 2,
    'linksCancelled': 1,
    'linksPending': 1,
  },
};

const _operationalLogs = [
  {
    'eventType': 'LEDGER_ANCHOR_CREATED',
    'severity': 'INFO',
    'reference': 'test-anchor',
    'userRef': 'system',
    'payloadRef': 'test-root',
    'createdAt': '2026-05-29T12:00:00Z',
  },
];

const _mobileDevices = [
  {
    'deviceId': 'mobile-test',
    'deviceName': 'Kerosene Mobile',
    'platform': 'Android',
    'status': 'ACTIVE',
    'lastSeenAt': '2026-05-29T12:00:00Z',
  },
];

const _webDevices = [
  {
    'deviceId': 'web-test',
    'deviceName': 'Admin Console',
    'browser': 'Flutter Test',
    'status': 'ACTIVE',
    'lastAccessAt': '2026-05-29T12:00:00Z',
  },
];
