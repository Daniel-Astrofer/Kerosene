// Kerosene Storybook - full app screen coverage.
//
// These stories register the public screen classes that are not already covered
// by the auth/wallet/ui/shared catalogs.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:teste/features/landing/presentation/kerosene_landing_page.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/presentation/screens/mining_contract_screen.dart';
import 'package:teste/features/mining/presentation/screens/mining_screen.dart';
import 'package:teste/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:teste/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:teste/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:teste/features/settings/presentation/screens/settings_screen.dart';
import 'package:teste/features/transactions/presentation/screens/deposits_screen.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/screens/receive_method.dart';
import 'package:teste/features/wallet/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_request_flow_screen.dart';
import 'package:teste/features/web_admin/screens/analytics/analytics_screen.dart';
import 'package:teste/features/web_admin/screens/audit/audit_screen.dart';
import 'package:teste/features/web_admin/screens/checks/checks_screen.dart';
import 'package:teste/features/web_admin/screens/dashboard/dashboard_screen.dart';
import 'package:teste/features/web_admin/screens/lightning/lightning_screen.dart';
import 'package:teste/features/web_admin/screens/login/admin_login_screen.dart';
import 'package:teste/features/web_admin/screens/monitoring/monitoring_screen.dart';
import 'package:teste/features/web_admin/screens/notifications/notifications_screen.dart';
import 'package:teste/features/web_admin/screens/onchain/onchain_screen.dart';
import 'package:teste/features/web_admin/screens/transactions/transactions_screen.dart';
import 'package:teste/features/web_admin/screens/volatility/volatility_screen.dart';
import '../storybook_mocks.dart';

final Wallet _wallet = mockWallets.first;
final Wallet _coldWallet = mockWallets.length > 1 ? mockWallets[1] : _wallet;

final Transaction _miningTransaction = Transaction(
  id: 'storybook-mining-tx',
  fromAddress: _wallet.address,
  toAddress: 'bc1qminingstorybook0000000000000000000000',
  amountSatoshis: 240000,
  feeSatoshis: 1600,
  status: TransactionStatus.pending,
  type: TransactionType.withdrawal,
  confirmations: 0,
  timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
  blockchainTxid: 'storybook-mining-txid',
  description: 'Envio aguardando confirmação',
);

final MempoolMiningDashboardData _miningDashboardData =
    MempoolMiningDashboardData(
  mempool: const MempoolSnapshot(
    count: 132000,
    vsize: 164000000,
    totalFee: 820000000,
    histogram: [
      FeeHistogramBin(feeRate: 45, vsize: 38000000),
      FeeHistogramBin(feeRate: 22, vsize: 52000000),
      FeeHistogramBin(feeRate: 8, vsize: 74000000),
    ],
  ),
  fees: const MempoolFees(
    fastestFee: 54,
    halfHourFee: 42,
    hourFee: 28,
    economyFee: 11,
    minimumFee: 5,
  ),
  feeBlocks: const [
    MempoolFeeBlock(
      blockSize: 1450000,
      blockVSize: 998000,
      txCount: 3120,
      totalFees: 18500000,
      medianFee: 39,
      feeRange: [12, 24, 38, 52, 70],
    ),
  ],
  difficulty: DifficultyAdjustmentInfo(
    progressPercent: 72,
    difficultyChange: 1.8,
    estimatedRetargetDate:
        DateTime.now().add(const Duration(days: 4)).millisecondsSinceEpoch ~/
            1000,
    remainingBlocks: 562,
    remainingTime: 337200,
    previousRetarget: 0.9,
    previousTime: 1209600,
    nextRetargetHeight: 856800,
    timeAvg: 595,
    adjustedTimeAvg: 601,
    expectedBlocks: 1454,
  ),
  blocks: [
    MempoolBlock(
      id: '00000000000000000000storybookblock',
      height: 856238,
      timestamp: DateTime.now()
              .subtract(const Duration(minutes: 7))
              .millisecondsSinceEpoch ~/
          1000,
      txCount: 3680,
      size: 1450000,
      weight: 3990000,
      difficulty: 86.3,
      medianFee: 36,
      totalFees: 18400000,
      reward: 312500000,
      poolName: 'Kerosene Pool',
      poolSlug: 'kerosene',
    ),
  ],
  hashrate: const MiningHashrateSnapshot(
    currentHashrate: 685000000000000000000,
    currentDifficulty: 86.3,
    hashrates: [
      MiningHashratePoint(
          timestamp: 1710000000, avgHashrate: 642000000000000000000),
      MiningHashratePoint(
          timestamp: 1710086400, avgHashrate: 685000000000000000000),
    ],
  ),
  pools: const [
    MiningPool(
      name: 'Foundry USA',
      link: 'https://mempool.space/mining/pool/foundryusa',
      blockCount: 47,
      rank: 1,
      emptyBlocks: 0,
      slug: 'foundryusa',
      avgMatchRate: 99.4,
      avgFeeDelta: '+1.2%',
    ),
  ],
  rewardStats: const MiningRewardStats(
    startBlock: 856100,
    endBlock: 856238,
    totalRewardSat: 43125000000,
    totalFeeSat: 1280000000,
    totalTx: 418000,
  ),
);

List<Story> appScreenStories() {
  return [
    Story(
      name: 'Current/Mobile/Settings',
      builder: (_) => const SettingsScreen(),
    ),
    Story(
      name: 'Current/Mobile/Bitcoin Accounts',
      builder: (_) => const BitcoinAccountsScreen(),
    ),
    Story(
      name: 'Current/Receive/Selection',
      builder: (_) => DepositsScreen(initialWallet: _wallet),
    ),
    Story(
      name: 'Current/Receive/Provedores',
      builder: (_) => ReceiveGatewayProvidersScreen(wallet: _wallet),
    ),
    Story(
      name: 'Current/Receive/QR Code e Dados',
      builder: (_) => ReceiveRequestFlowScreen(
        wallet: _wallet,
        onChainWallet: false,
        amountBtc: 0.025,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.qr,
        enableStatusPolling: false,
        initialAddress: _wallet.address,
        initialPaymentUri:
            'kerosene:pay?address=${_wallet.address}&amount=0.02500000',
      ),
    ),
    Story(
      name: 'Current/Receive/Confirmações de Rede',
      builder: (_) => ReceiveRequestFlowScreen(
        wallet: _coldWallet,
        onChainWallet: true,
        amountBtc: 0.045,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.confirmations,
        enableStatusPolling: false,
        initialAddress: _coldWallet.address,
        initialPaymentUri: 'bitcoin:${_coldWallet.address}?amount=0.04500000',
        initialTxid: 'storybook-onchain-txid',
        initialConfirmations: 0,
        requiredConfirmations: 3,
      ),
    ),
    Story(
      name: 'Current/Receive/Pagamento Identificado',
      builder: (_) => ReceiveRequestFlowScreen(
        wallet: _coldWallet,
        onChainWallet: true,
        amountBtc: 0.045,
        method: ReceiveAmountMethod.qrCode,
        initialStage: ReceiveRequestStage.identified,
        enableStatusPolling: false,
        initialAddress: _coldWallet.address,
        initialPaymentUri: 'bitcoin:${_coldWallet.address}?amount=0.04500000',
        initialTxid: 'storybook-onchain-txid',
        initialConfirmations: 3,
        requiredConfirmations: 3,
        identifiedAt: DateTime(2023, 10, 24, 14, 32),
      ),
    ),
    Story(
      name: 'Current/Receive/NFC Kerosene',
      builder: (_) => ReceiveNfcFlowScreen(
        wallet: _wallet,
        onChainWallet: false,
        amountBtc: 0.00125,
      ),
    ),
    Story(
      name: 'Current/Receive/NFC On-chain',
      builder: (_) => ReceiveNfcFlowScreen(
        wallet: _wallet.copyWith(
          name: 'Carteira Fria',
          walletMode: 'ONCHAIN',
        ),
        onChainWallet: true,
        amountBtc: 0.00125,
      ),
    ),
    Story(
      name: 'Current/Transactions/Statement',
      builder: (_) => const TransactionStatementScreen(),
    ),
    Story(
      name: 'Current/Mobile/Mining Dashboard',
      builder: (_) => MiningScreen(initialTransaction: _miningTransaction),
    ),
    Story(
      name: 'Current/Mobile/Mining Contract',
      builder: (_) => MiningContractScreen(dashboardData: _miningDashboardData),
    ),
    Story(
      name: 'Current/Account/Notification Settings',
      builder: (_) => const NotificationSettingsScreen(),
    ),
    Story(
      name: 'Current/Account/Security Settings',
      builder: (_) => const SecuritySettingsScreen(),
    ),
    Story(
      name: 'Current/Notifications/Notification Center',
      builder: (_) => const NotificationCenterScreen(),
    ),
    Story(
      name: 'Current/Web/Public Landing',
      builder: (_) => const KeroseneLandingPage(),
    ),
    Story(
      name: 'Current/Web/Download Landing',
      builder: (_) => const KeroseneLandingPage(focusDownload: true),
    ),
    Story(
      name: 'Current/Web/Public Status',
      builder: (_) => const KerosenePublicStatusPage(),
    ),
    Story(
      name: 'Current/Web Admin/Login',
      builder: (_) => const AdminLoginScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Dashboard',
      builder: (_) => const DashboardScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Monitoring',
      builder: (_) => const MonitoringScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Transactions',
      builder: (_) => const TransactionsScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Lightning',
      builder: (_) => const LightningScreen(),
    ),
    Story(
      name: 'Current/Web Admin/On-chain',
      builder: (_) => const OnchainScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Checks',
      builder: (_) => const ChecksScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Analytics',
      builder: (_) => const AnalyticsScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Volatility',
      builder: (_) => const VolatilityScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Audit',
      builder: (_) => const AuditScreen(),
    ),
    Story(
      name: 'Current/Web Admin/Notifications',
      builder: (_) => const NotificationsScreen(),
    ),
  ];
}
