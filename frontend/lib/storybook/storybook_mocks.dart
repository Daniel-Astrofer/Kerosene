import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/admin_access.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/domain/entities/passkey_inventory.dart';
import 'package:kerosene/features/security/domain/entities/security_status.dart';
import 'package:kerosene/features/security/domain/entities/kfe_reserve_overview.dart';
import 'package:kerosene/features/transactions/domain/entities/deposit.dart';
import 'package:kerosene/features/transactions/domain/entities/external_transfer.dart';
import 'package:kerosene/features/transactions/domain/entities/fee_estimate.dart';
import 'package:kerosene/features/transactions/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/transactions/domain/entities/payment_link.dart';
import 'package:kerosene/features/transactions/domain/entities/tx_status.dart';
import 'package:kerosene/features/transactions/domain/entities/wallet_network_address.dart';
import 'package:kerosene/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/wallet/presentation/state/wallet_state.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/core/services/price_websocket_service.dart';
import 'package:flutter/foundation.dart';

/// Mock Auth Controller for Storybook.
class MockAuthController extends AuthController {
  final AuthState initialOverride;

  MockAuthController({this.initialOverride = const AuthInitial()});

  @override
  AuthState build() {
    return initialOverride;
  }

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> signup({
    required String username,
    required String password,
    String accountSecurity = 'STANDARD',
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    state = AuthRequiresTotpSetup(
      username: username,
      passphrase: password,
      sessionId: 'storybook_session',
      totpSecret: 'JBSWY3DPEHPK3PXP',
      qrCodeUri:
          'otpauth://totp/Kerosene:$username?secret=JBSWY3DPEHPK3PXP&issuer=Kerosene',
      backupCodes: const ['KERO-1024', 'KERO-2048', 'KERO-4096'],
    );
  }

  @override
  Future<void> loginWithPasskey(
    String username, {
    int remainingChallengeRenewals = 2,
  }) async {}

  @override
  Future<void> verifyTotp(
      {required String username,
      required String passphrase,
      required String totpSecret,
      required String totpCode}) async {}

  @override
  Future<void> verifyLoginTotp(
      {required String username,
      required String passphrase,
      required String totpCode,
      String? preAuthToken}) async {}

  @override
  Future<void> skipTotpSetup() async {
    state = const AuthTotpVerified('storybook_session', 'storybook_user');
  }

  @override
  Future<void> registerPasskey() async {
    state = mockAuthenticatedState;
  }

  @override
  Future<void> registerPasskeyOnboarding(String sessionId) async {
    state = mockAuthenticatedState;
  }

  @override
  Future<void> retrySessionCheck() async {}

  @override
  Future<void> logout() async {
    state = const AuthUnauthenticated();
  }

  @override
  void clearError() {}
}

/// Mock Price WebSocket Service for Storybook.
class MockPriceWebSocketService implements PriceWebSocketService {
  final _priceController = StreamController<double>.broadcast();
  final _tickerController = StreamController<PriceTickerSnapshot>.broadcast();

  @override
  Stream<double> get priceStream => _priceController.stream;

  @override
  Stream<PriceTickerSnapshot> get tickerStream => _tickerController.stream;

  @override
  void connect() {
    debugPrint('>>> MockPriceWebSocket: Connection simulated');
    // Periodically push some mock data to keep it "alive"
    _priceController.add(67234.50);
    _tickerController.add(
      const PriceTickerSnapshot(
        priceUsd: 67234.50,
        dailyChangePercent: 1.2,
      ),
    );
  }

  @override
  void dispose() {
    _priceController.close();
    _tickerController.close();
  }
}

/// Helper for standard mock user
final mockUser = User(
  id: 'sat-001',
  username: 'Satoshi Nakamoto',
  createdAt: DateTime.now(),
);

/// Helper for authenticated state
final mockAuthenticatedState = AuthAuthenticated(mockUser);

/// Shared wallets used by Storybook screens that expect a loaded wallet state.
final mockWallets = [
  Wallet(
    id: 'story-wallet-primary',
    name: 'Reserva principal',
    address: 'bc1qstorybookprimary0000000000000000000000',
    balance: 0.042,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    cardType: WalletCardType.white,
    cardHolderName: 'Satoshi Nakamoto',
    cardMaskedNumber: 'KERO 2048 4096 8192',
    cardNumberSuffix: '8192',
    createdAt: DateTime.now().subtract(const Duration(days: 120)),
    updatedAt: DateTime.now(),
  ),
  Wallet(
    id: 'story-wallet-cold',
    name: 'Cold vault',
    address: 'bc1qstorybookcold000000000000000000000000',
    walletMode: 'COLD_WALLET',
    balance: 0.128,
    derivationPath: "m/84'/0'/1'/0/0",
    type: WalletType.nativeSegwit,
    accountSecurity: 'MULTISIG',
    cardType: WalletCardType.black,
    cardHolderName: 'Kerosene Vault',
    cardMaskedNumber: 'KERO 9000 0000 0420',
    cardNumberSuffix: '0420',
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    updatedAt: DateTime.now(),
  ),
];

final mockTransactions = [
  Transaction(
    id: 'story-tx-receive',
    fromAddress: 'Rede Bitcoin',
    toAddress: mockWallets.first.address,
    amountSatoshis: 420000,
    feeSatoshis: 1200,
    status: TransactionStatus.confirmed,
    type: TransactionType.receive,
    confirmations: 8,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    blockchainTxid: 'storybook-receive-txid',
    description: 'Depósito recebido',
  ),
  Transaction(
    id: 'story-tx-send',
    fromAddress: mockWallets.first.address,
    toAddress: 'bc1qstorybooksent000000000000000000000000',
    amountSatoshis: 180000,
    feeSatoshis: 900,
    status: TransactionStatus.pending,
    type: TransactionType.send,
    confirmations: 0,
    timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    description: 'Envio para carteira externa',
  ),
  Transaction(
    id: 'story-tx-lightning',
    fromAddress: 'Lightning',
    toAddress: mockWallets.first.address,
    amountSatoshis: 95000,
    feeSatoshis: 12,
    status: TransactionStatus.confirmed,
    type: TransactionType.deposit,
    confirmations: 1,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isLightning: true,
    paymentHash: 'storybook-lightning-payment-hash',
    description: 'Invoice Lightning liquidada',
  ),
];

final mockDeposits = [
  Deposit(
    id: 1,
    userId: 1,
    txid: 'storybook-deposit-txid',
    fromAddress: 'bc1qexternalstorybook0000000000000000000',
    toAddress: mockWallets.first.address,
    amountBtc: 0.0125,
    confirmations: 4,
    status: 'credited',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    confirmedAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
  ),
];

PaymentLink mockPaymentLink({
  String id = 'storybook-payment-link',
  String status = 'pending',
  double amountBtc = 0.0042,
  bool internal = true,
}) {
  final createdAt = DateTime.now().subtract(const Duration(minutes: 12));
  return PaymentLink(
    id: id,
    userId: 1,
    amountBtc: amountBtc,
    grossAmountBtc: amountBtc,
    netAmountBtc: amountBtc,
    description: 'Pedido Kerosene Storybook',
    depositAddress: internal
        ? 'kerosene-payment-$id'
        : 'bc1qpaymentlinkstorybook000000000000000000',
    visibility: 'PRIVATE',
    confirmationMode: 'USER_ACTION_REQUIRED',
    amountLocked: true,
    destinationHash: internal ? 'storybook-destination-hash' : null,
    paymentUri: internal
        ? 'kerosene:pay?link=$id&amount=$amountBtc'
        : 'bitcoin:bc1qpaymentlinkstorybook000000000000000000?amount=$amountBtc',
    locked: internal,
    status: status,
    txid: status == 'pending' ? null : 'storybook-payment-link-txid',
    expiresAt: createdAt.add(const Duration(hours: 2)),
    createdAt: createdAt,
    paidAt: status == 'paid' || status == 'completed'
        ? DateTime.now().subtract(const Duration(minutes: 2))
        : null,
    paymentRail: internal ? 'INTERNAL' : 'ONCHAIN',
    settlementStatus:
        status == 'paid' || status == 'completed' ? 'SETTLED' : 'QUOTED',
    terminal: status == 'paid' || status == 'completed',
  );
}

final mockPaymentLinks = [
  mockPaymentLink(),
  mockPaymentLink(
    id: 'storybook-payment-link-paid',
    status: 'paid',
    amountBtc: 0.018,
  ),
];

ExternalTransfer mockExternalTransfer({
  String id = 'storybook-external-transfer',
  String network = 'LIGHTNING',
  String transferType = 'INBOUND_INVOICE',
  String status = 'PENDING',
}) {
  final now = DateTime.now();
  return ExternalTransfer(
    id: id,
    network: network,
    transferType: transferType,
    status: status,
    provider: 'Kerosene',
    walletName: mockWallets.first.name,
    destination: network == 'LIGHTNING'
        ? 'storybook@kerosene.local'
        : mockWallets.first.address,
    amountBtc: 0.0025,
    networkFeeBtc: 0.000001,
    platformFeeBtc: 0.0000005,
    totalDebitedBtc: 0.0025015,
    externalReference: 'storybook-provider-ref',
    invoiceId: 'storybook-invoice',
    blockchainTxid: network == 'ONCHAIN' ? 'storybook-onchain-txid' : '',
    paymentHash: network == 'LIGHTNING' ? 'storybook-payment-hash' : '',
    invoiceData: network == 'LIGHTNING' ? 'lnbc250000n1storybook' : '',
    expectedAmountBtc: 0.0025,
    confirmations: status == 'SETTLED' ? 3 : 0,
    detectedAt:
        status == 'SETTLED' ? now.subtract(const Duration(minutes: 3)) : null,
    settledAt:
        status == 'SETTLED' ? now.subtract(const Duration(minutes: 1)) : null,
    createdAt: now.subtract(const Duration(minutes: 8)),
    updatedAt: now,
    context: network == 'LIGHTNING'
        ? 'Invoice Lightning Storybook'
        : 'Endereço on-chain Storybook',
  );
}

final mockExternalTransfers = [
  mockExternalTransfer(status: 'SETTLED'),
  mockExternalTransfer(
    id: 'storybook-onchain-transfer',
    network: 'ONCHAIN',
    transferType: 'ADDRESS_ISSUE',
  ),
];

final mockBitcoinAccounts = [
  const BitcoinAccount(
    id: 'story-account-card',
    type: 'INTERNAL_CARD',
    custody: 'KEROSENE_CUSTODIAL',
    status: 'ACTIVE',
    label: 'Cartão Kerosene',
    riskTier: 'SILVER',
    cardId: 'card-storybook',
    balanceAvailableSats: 4200000,
    balancePendingSats: 120000,
  ),
  const BitcoinAccount(
    id: 'story-account-cold',
    type: 'WATCH_ONLY_COLD_WALLET',
    custody: 'WATCH_ONLY',
    status: 'ACTIVE',
    label: 'Reserva fria',
    riskTier: 'GOLD',
    coldWalletId: 'cold-storybook',
    observedBalanceSats: 12800000,
    xpubFingerprint: 'F23A91C0',
    derivationPath: "m/84'/0'/0'",
    scriptPolicy: 'wpkh',
  ),
];

final mockReceiveRequests = [
  ReceivingRequestView(
    id: 'receive-storybook-card',
    accountId: 'story-account-card',
    address: mockWallets.first.address,
    bip21: 'kerosene:pay?address=${mockWallets.first.address}&amount=0.025',
    status: 'ACTIVE',
    amountSats: 2500000,
    expiry: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    oneTime: true,
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  ReceivingRequestView(
    id: 'receive-storybook-paid',
    accountId: 'story-account-card',
    address: 'bc1qstorybookpaid000000000000000000000000000000',
    bip21:
        'bitcoin:bc1qstorybookpaid000000000000000000000000000000?amount=0.01000000',
    status: 'PAID',
    amountSats: 1000000,
    expiry: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    oneTime: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  ReceivingRequestView(
    id: 'receive-storybook-expired',
    accountId: 'story-account-card',
    address: 'bc1qstorybookexpired000000000000000000000000000',
    bip21:
        'bitcoin:bc1qstorybookexpired000000000000000000000000000?amount=0.00100000',
    status: 'EXPIRED',
    amountSats: 100000,
    expiry:
        DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
    oneTime: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

final mockColdWalletUtxos = [
  const ColdWalletUtxoView(
    id: 'utxo-storybook-1',
    txidRef: '4f3c0a91...9b12e810',
    vout: 0,
    amountSats: 5200000,
    confirmations: 42,
    status: 'UNSPENT',
  ),
  const ColdWalletUtxoView(
    id: 'utxo-storybook-2',
    txidRef: 'a81021bf...7e0190cc',
    vout: 1,
    amountSats: 7600000,
    confirmations: 8,
    status: 'UNSPENT',
  ),
  const ColdWalletUtxoView(
    id: 'utxo-storybook-locked',
    txidRef: '1010abcd...88ff2200',
    vout: 0,
    amountSats: 2000000,
    confirmations: 3,
    status: 'LOCKED',
  ),
];

final mockPsbtWorkflows = [
  PsbtWorkflowView(
    id: 'psbt-storybook-waiting',
    coldWalletId: 'cold-storybook',
    unsignedPsbt: 'cHNidP8BAHECAAAAARstorybooksignedlater',
    status: 'WAITING_EXTERNAL_SIGNATURE',
    destinationAddress: 'bc1qstorybookrecipient00000000000000000',
    amountSats: 2500000,
    estimatedFeeSats: 1400,
    expiresAt: DateTime.now().add(const Duration(hours: 18)).toIso8601String(),
    createdAt:
        DateTime.now().subtract(const Duration(minutes: 26)).toIso8601String(),
  ),
  PsbtWorkflowView(
    id: 'psbt-storybook-broadcasted',
    coldWalletId: 'cold-storybook',
    unsignedPsbt: 'cHNidP8BAHECAAAAARstorybookbroadcasted',
    status: 'BROADCASTED',
    destinationAddress: 'bc1qstorybookpaidcold0000000000000000',
    amountSats: 1000000,
    estimatedFeeSats: 900,
    broadcastTxid: 'storybook-broadcast-txid',
    broadcastTxidRef: 'storyboo...casttxid',
    expiresAt: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    createdAt:
        DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
  ),
];

final mockTaxEvents = [
  TaxEventView(
    id: 'tax-storybook-1',
    eventType: 'DEPOSIT_INTERNAL',
    asset: 'BTC',
    quantitySats: 1000000,
    classification: 'USER_CLASSIFICATION_PENDING',
    sourceRef: '99aabbcc...00112233',
    createdAt:
        DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
  ),
  TaxEventView(
    id: 'tax-storybook-2',
    eventType: 'FEE',
    asset: 'BTC',
    quantitySats: 900,
    classification: 'FEE',
    sourceRef: '88bbccdd...44556677',
    createdAt:
        DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
  ),
];

final mockNotifications = [
  SessionNotificationItem(
    id: '101',
    title: 'Depósito confirmado',
    body: '0.00420000 BTC foram creditados na Reserva principal.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    kind: SessionNotificationItem.kindDepositConfirmed,
    severity: SessionNotificationItem.severitySuccess,
    entityType: 'transaction',
    entityId: 'storybook-receive-txid',
  ),
  SessionNotificationItem(
    id: '102',
    title: 'Novo acesso detectado',
    body: 'Uma sessão web admin foi autenticada no ambiente Storybook.',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    kind: SessionNotificationItem.kindSecurityLoginDetected,
    severity: SessionNotificationItem.severityWarning,
    entityType: 'security',
    entityId: 'admin-session',
    read: true,
  ),
];

final mockSecurityStatus = SecurityStatus(
  hardwareAttestation: const {
    'status': 'VERIFIED',
    'provider': 'Nitro Enclave',
    'lastCheckedAt': '2026-05-28T12:00:00Z',
  },
  networkConsensus: const {
    'status': 'HEALTHY',
    'nodes': 3,
    'quorum': 2,
  },
  ledgerIntegrity: const {
    'status': 'ANCHORED',
    'merkleRoot': '42b1c9c0storybookmerkle',
    'ledgerCount': 812,
  },
  memoryProtection: const {
    'status': 'ENFORCED',
    'sealedSecrets': true,
  },
  serverUptimeSeconds: 86400 * 18,
);

const mockKfeReserveOverview = KfeReserveOverview(
  totalOnchainBtc: 18.42,
  lightningNodeBtc: 2.18,
  inboundLiquidityBtc: 1.62,
  outboundLiquidityBtc: 0.91,
  reservedOnchainBtc: 3.2,
  reservedLightningBtc: 0.4,
  availableOnchainBtc: 15.22,
  availableLightningBtc: 1.78,
  lightningSendsAllowed: true,
  liquidityState: 'HEALTHY',
);

final mockSecurityAuditStats = {
  'totalEvents': 1842,
  'criticalEvents': 0,
  'warningEvents': 4,
  'lastAnchorAt': '2026-05-28T12:00:00Z',
  'merkleRoot': '42b1c9c0storybookmerkle',
};

final mockAccountSecurityProfile = AccountSecurityProfile(
  mode: AccountSecurityMode.passkey,
  multisigThreshold: 2,
  passkeyAvailable: true,
  passkeyEnabledForTransactions: true,
  appPin: const AppPinStatus(
    enabled: false,
    configured: true,
    remainingAttempts: 5,
    resettableWithTotp: true,
  ),
  requiredFactors: const ['PASSKEY', 'TOTP'],
  passkeys: const PasskeyInventory(
    passkeyRegistered: true,
    compatibleForCurrentLogin: true,
    legacyCredentialsPresent: false,
    currentRelyingPartyId: 'kerosene-device',
    currentHost: 'app.kerosene.local',
    devices: [
      PasskeyDevice(
        credentialRef: '6A31F0B2',
        deviceName: 'Pixel secure enclave',
        brand: 'Google',
        model: 'Pixel 9',
        deviceInstallId: 'storybook-pixel-9',
        platform: 'Android',
        browser: 'Kerosene Mobile',
        status: 'ACTIVE',
        relyingPartyId: 'kerosene-device',
        originHost: 'app.kerosene.local',
        compatibilityStatus: PasskeyCompatibilityStatus.compatible,
        compatibleWithCurrentLogin: true,
      ),
      PasskeyDevice(
        credentialRef: 'F79D4C10',
        deviceName: 'Legacy desktop key',
        deviceInstallId: 'storybook-legacy-desktop',
        platform: 'Linux',
        browser: 'Tor Browser',
        status: 'BLOCKED',
        relyingPartyId: 'legacy.kerosene.local',
        originHost: 'legacy.kerosene.local',
        compatibilityStatus: PasskeyCompatibilityStatus.incompatible,
      ),
    ],
  ),
);

const mockAppPinStatus = AppPinStatus(
  enabled: false,
  configured: true,
  remainingAttempts: 5,
  resettableWithTotp: true,
);

final mockAdminKeyStatus = AdminKeyStatus(
  configured: true,
  status: 'ACTIVE',
  fingerprint: 'F23A91C0',
  createdAt: DateTime.now().subtract(const Duration(days: 45)),
);

final mockAdminAccessAttempts = [
  AdminAccessAttempt(
    attemptId: 'attempt-storybook',
    status: 'PENDING',
    deviceId: 'web-storybook',
    deviceName: 'Storybook Admin Console',
    browser: 'Flutter Linux',
    ipFingerprint: 'ip-storybook',
    requestedAt: DateTime.now().subtract(const Duration(minutes: 7)),
    expiresAt: DateTime.now().add(const Duration(minutes: 8)),
  ),
];

final mockAdminDevices = [
  AdminAuthenticatedDevice(
    deviceId: 'web-storybook',
    deviceName: 'Storybook Admin Console',
    browser: 'Flutter Linux',
    status: 'ACTIVE',
    firstAccessAt: DateTime.now().subtract(const Duration(days: 3)),
    lastAccessAt: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
];

const mockAdminBtcPrice = {
  'btcUsd': 65000.0,
  'btcBrl': 325000.0,
  'usdBrl': 5.0,
};

final mockAdminAuditStats = {
  'totalEvents': 1842,
  'criticalEvents': 0,
  'warningEvents': 4,
  'ledgerCount': 812,
  'lastAnchorAt': '2026-05-28T12:00:00Z',
};

final mockAdminAuditHistory = List<Map<String, dynamic>>.generate(
  6,
  (index) => {
    'merkleRoot': 'storybook-merkle-root-$index',
    'ledgerCount': 812 - index * 7,
    'anchorTxid': 'storybook-anchor-txid-$index',
    'createdAt':
        DateTime.now().subtract(Duration(hours: index * 6)).toIso8601String(),
  },
);

final mockAdminAuditLatestRoot = {
  'merkleRoot': '42b1c9c0storybookmerkle',
  'ledgerCount': 812,
  'anchorTxid': 'storybook-anchor-txid',
  'createdAt': '2026-05-28T12:00:00Z',
};

final mockAdminSovereignty = {
  'hardwareAttestation': {'status': 'VERIFIED'},
  'networkConsensus': {'status': 'HEALTHY'},
  'ledgerIntegrity': {'status': 'ANCHORED'},
  'memoryProtection': {'status': 'ENFORCED'},
  'serverUptimeSeconds': 1555200,
};

final mockAdminCurrentUser = {
  'id': 'admin-storybook',
  'username': 'storybook-admin',
  'role': 'ADMIN',
};

final mockAdminOperationsOverview = {
  'checkedAt': '2026-05-28T12:00:00Z',
  'health': {'status': 'HEALTHY'},
  'blockchain': {'status': 'SYNCED'},
  'lightning': {'status': 'ONLINE'},
  'vaultRaft': {'status': 'QUORUM'},
};

final mockAdminOperationalHealth = {
  'status': 'HEALTHY',
  'service': 'kerosene-core',
  'checkedAt': '2026-05-28T12:00:00Z',
  'checks': {
    'api': {'status': 'HEALTHY', 'message': 'responding'},
    'database': {'status': 'HEALTHY', 'message': 'primary online'},
    'queue': {'status': 'HEALTHY', 'message': 'empty backlog'},
  },
};

final mockAdminBlockchainMonitor = {
  'status': 'SYNCED',
  'primarySource': 'bitcoin-core',
  'network': 'mainnet',
  'indexer': 'electrs',
  'chain': {
    'height': 842000,
    'bestBlockHash': '000000000000000000storybookblock',
    'pruned': false,
    'pruneHeight': 0,
  },
  'mempool': {'transactions': 1842},
  'fees': {'fastestFee': 22, 'halfHourFee': 16},
  'relevantTransactions': [
    {
      'status': 'CONFIRMED',
      'txidRef': 'storybook-receive-txid',
      'confirmations': 8,
    },
  ],
};

final mockAdminLightningMonitor = {
  'status': 'ONLINE',
  'message': 'operational probe',
  'primarySource': 'lnd',
  'checkedAt': '2026-05-28T12:00:00Z',
  'node': {
    'alias': 'kerosene-storybook',
    'version': '0.18.0',
    'identityPubkey': '03storybooknodepubkey',
    'blockHeight': 842000,
    'blockHash': '000000000000000000storybookblock',
    'syncedToChain': true,
    'syncedToGraph': true,
    'numPeers': 12,
    'numActiveChannels': 18,
    'numInactiveChannels': 1,
    'numPendingChannels': 0,
    'localBalanceSats': 95000000,
    'remoteBalanceSats': 125000000,
    'walletConfirmedBalanceSats': 218000000,
  },
};

final mockAdminVaultRaftHealth = {
  'status': 'QUORUM',
  'expectedServers': 3,
  'votingServers': 3,
};

final mockAdminReleaseSnapshot = {
  'authorized': true,
  'reason': 'storybook-release-approved',
  'gitCommit': '978604cstorybook',
  'imageDigest': 'sha256:storybook-image',
  'manifestDigest': 'sha256:storybook-manifest',
  'codeHash': 'sha256:storybook-code',
  'configHash': 'sha256:storybook-config',
};

final mockAdminMobileRelease = {
  'version': '1.0.0-storybook',
  'platform': 'linux',
  'publishedAt': '2026-05-28T12:00:00Z',
};

final mockAdminOperationalMetrics = {
  'totalVolumeBtc': 4.86,
  'totalFeesBtc': 0.018,
  'totalTransactions': 812,
  'confirmedTransactions': 795,
  'pendingTransactions': 15,
  'failedTransactions': 2,
  'avgTicketBtc': 0.006,
  'transfers': {
    'onchainFeesBtc': 0.012,
    'lightningFeesBtc': 0.006,
    'onchainVolumeBtc': 3.4,
    'lightningVolumeBtc': 1.46,
    'onchainCount': 224,
    'lightningCount': 588,
    'inflowBtc': 3.02,
    'outflowBtc': 1.84,
  },
  'paymentLinks': {
    'linksCreated': 240,
    'linksPaid': 198,
    'linksExpired': 18,
    'linksCancelled': 4,
    'linksPending': 20,
  },
};

final mockAdminOperationalLogs = [
  {
    'eventType': 'LEDGER_ANCHOR_CREATED',
    'severity': 'INFO',
    'reference': 'storybook-anchor-txid',
    'userRef': 'system',
    'payloadRef': 'storybook-merkle-root',
    'createdAt': '2026-05-28T12:00:00Z',
  },
  {
    'eventType': 'ADMIN_DEVICE_AUTHENTICATED',
    'severity': 'WARN',
    'reference': 'web-storybook',
    'userRef': 'admin-storybook',
    'payloadRef': 'device-fingerprint',
    'createdAt': '2026-05-28T11:20:00Z',
  },
];

final mockAdminMobileDevices = [
  {
    'deviceId': 'mobile-storybook',
    'deviceName': 'Kerosene Mobile Storybook',
    'status': 'ACTIVE',
    'lastSeenAt': '2026-05-28T11:55:00Z',
  },
];

final mockAdminWebDevices = [
  {
    'deviceId': 'web-storybook',
    'deviceName': 'Storybook Admin Console',
    'status': 'ACTIVE',
    'lastAccessAt': '2026-05-28T11:58:00Z',
  },
];

class MockWalletNotifier extends WalletNotifier {
  @override
  WalletState build() {
    return WalletLoaded(
      wallets: mockWallets,
      selectedWallet: mockWallets.first,
      btcToUsdRate: 65000,
    );
  }

  @override
  Future<void> refresh() async {
    state = WalletLoaded(
      wallets: mockWallets,
      selectedWallet: mockWallets.first,
      btcToUsdRate: 65000,
    );
  }

  @override
  void selectWallet(Wallet wallet) {
    state = WalletLoaded(
      wallets: mockWallets,
      selectedWallet: wallet,
      btcToUsdRate: 65000,
    );
  }

  @override
  Future<void> updateWalletBalance(String walletId) async {}

  @override
  void updateBalanceFromWebSocket(String walletName, double newBalance) {}
}

class MockBitcoinAccountsService implements BitcoinAccountsService {
  final List<BitcoinAccount> _accounts;
  final List<ReceivingRequestView> _requests;
  final List<ColdWalletUtxoView> _utxos;
  final List<PsbtWorkflowView> _psbts;
  final List<TaxEventView> _taxEvents;
  final Exception? listRequestsError;

  MockBitcoinAccountsService({
    List<BitcoinAccount>? accounts,
    List<ReceivingRequestView>? receiveRequests,
    List<ColdWalletUtxoView>? utxos,
    List<PsbtWorkflowView>? psbts,
    List<TaxEventView>? taxEvents,
    this.listRequestsError,
  })  : _accounts = [...(accounts ?? mockBitcoinAccounts)],
        _requests = [...(receiveRequests ?? mockReceiveRequests)],
        _utxos = [...(utxos ?? mockColdWalletUtxos)],
        _psbts = [...(psbts ?? mockPsbtWorkflows)],
        _taxEvents = [...(taxEvents ?? mockTaxEvents)];

  @override
  Future<List<BitcoinAccount>> listAccounts() async => List.of(_accounts);

  @override
  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  }) async {
    final isWatchOnly = custody == BitcoinAccountCustody.watchOnly;
    final account = BitcoinAccount(
      id: 'story-account-${_accounts.length + 1}',
      type: isWatchOnly ? 'WATCH_ONLY_COLD_WALLET' : 'INTERNAL_CARD',
      custody: isWatchOnly ? 'WATCH_ONLY' : 'KEROSENE_CUSTODIAL',
      status: 'ACTIVE',
      label: label,
      riskTier: isWatchOnly ? 'GOLD' : 'BRONZE',
      cardId: isWatchOnly ? null : 'card-storybook-${_accounts.length + 1}',
      coldWalletId:
          isWatchOnly ? 'cold-storybook-${_accounts.length + 1}' : null,
      observedBalanceSats: 0,
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<BitcoinAccount> createInternalCard({
    required String label,
  }) {
    return createWallet(
      label: label,
      custody: BitcoinAccountCustody.internal,
    );
  }

  @override
  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final account = BitcoinAccount(
      id: 'story-cold-${_accounts.length + 1}',
      type: 'WATCH_ONLY_COLD_WALLET',
      custody: 'WATCH_ONLY',
      status: 'ACTIVE',
      label: label,
      riskTier: 'GOLD',
      coldWalletId: 'cold-storybook-${_accounts.length + 1}',
      observedBalanceSats: 0,
      xpubFingerprint: fingerprint,
      derivationPath: derivationPath,
      scriptPolicy: scriptPolicy,
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  }) async {
    final account = _accounts.firstWhere(
      (item) => item.id == accountId,
      orElse: () => _accounts.first,
    );
    final address = account.isWatchOnly
        ? mockWallets.last.address
        : mockWallets.first.address;
    final request = ReceivingRequestView(
      id: 'receive-storybook-${_requests.length + 1}',
      accountId: account.id,
      address: address,
      bip21:
          'bitcoin:$address?amount=${((amountSats ?? 0) / 100000000).toStringAsFixed(8)}',
      status: 'ACTIVE',
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
      createdAt: DateTime.now(),
    );
    _requests.add(request);
    return request;
  }

  @override
  Future<ReceivingRequestView> rotateReceiveAddress(String accountId) async {
    final address = 'bc1qstorybookrotated${_requests.length + 1}';
    final request = ReceivingRequestView.fromKfeActiveAddress(
      accountId: accountId,
      address: address,
      createdAt: DateTime.now(),
    );
    _requests.insert(0, request);
    return request;
  }

  @override
  Future<BitcoinAccount> renameWallet({
    required String accountId,
    required String label,
  }) async {
    final index = _accounts.indexWhere((item) => item.id == accountId);
    if (index < 0) return _accounts.first;
    final updated = _accountWith(_accounts[index], label: label);
    _accounts[index] = updated;
    return updated;
  }

  @override
  Future<BitcoinAccount> archiveWallet(String accountId) async {
    final index = _accounts.indexWhere((item) => item.id == accountId);
    if (index < 0) return _accounts.first;
    final updated = _accountWith(_accounts[index], status: 'ARCHIVED');
    _accounts[index] = updated;
    return updated;
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    final error = listRequestsError;
    if (error != null) {
      throw error;
    }
    return _requests.where((item) => item.accountId == accountId).toList();
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    return _requests.firstWhere(
      (item) => item.id == requestId,
      orElse: () => _requests.first,
    );
  }

  @override
  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(
    String coldWalletId,
  ) async {
    return List.of(_utxos);
  }

  @override
  Future<List<PsbtWorkflowView>> listColdWalletPsbt(String coldWalletId) async {
    return _psbts
        .where((item) => item.coldWalletId == coldWalletId)
        .toList(growable: false);
  }

  @override
  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  }) async {
    final workflow = PsbtWorkflowView(
      id: 'psbt-storybook-${_psbts.length + 1}',
      coldWalletId: coldWalletId,
      unsignedPsbt: 'cHNidP8BAHECAAAAARstorybook${_psbts.length + 1}',
      status: 'WAITING_EXTERNAL_SIGNATURE',
      destinationAddress: destinationAddress,
      amountSats: amountSats,
      estimatedFeeSats: (feeRate ?? 3) * 240,
      expiresAt:
          DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _psbts.insert(0, workflow);
    return workflow;
  }

  @override
  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId) async {
    return _psbts.firstWhere(
      (item) => item.id == workflowId,
      orElse: () => _psbts.first,
    );
  }

  @override
  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  }) async {
    final existing = await getPsbtWorkflow(workflowId);
    final updated = PsbtWorkflowView(
      id: existing.id,
      coldWalletId: existing.coldWalletId,
      unsignedPsbt: existing.unsignedPsbt,
      status: broadcast ? 'BROADCASTED' : 'VALIDATED',
      destinationAddress: existing.destinationAddress,
      amountSats: existing.amountSats,
      estimatedFeeSats: existing.estimatedFeeSats,
      broadcastTxid: broadcast ? 'storybook-signed-broadcast-txid' : null,
      broadcastTxidRef: broadcast ? 'storyboo...dtxid' : null,
      expiresAt: existing.expiresAt,
      createdAt: existing.createdAt,
    );
    final index = _psbts.indexWhere((item) => item.id == workflowId);
    if (index >= 0) {
      _psbts[index] = updated;
    }
    return updated;
  }

  @override
  Future<List<TaxEventView>> listTaxEvents() async => List.of(_taxEvents);

  @override
  Future<TaxEventsExportView> exportTaxEvents({required String format}) async {
    return TaxEventsExportView(
      format: format,
      filename: 'kerosene-tax-events.$format',
      educationalNotice: 'Relatório temporário gerado pelo ambiente Storybook.',
      content: format == 'csv'
          ? 'created_at,event_type,asset,quantity_sats,classification,source_ref\n'
          : null,
      events: List.of(_taxEvents),
    );
  }

  @override
  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    final existing = _taxEvents.firstWhere(
      (item) => item.id == eventId,
      orElse: () => _taxEvents.first,
    );
    final updated = TaxEventView(
      id: existing.id,
      eventType: existing.eventType,
      asset: existing.asset,
      quantitySats: existing.quantitySats,
      classification: classification,
      sourceRef: existing.sourceRef,
      createdAt: existing.createdAt,
      accountId: existing.accountId,
      cardId: existing.cardId,
      walletId: existing.walletId,
      purgeAfter: existing.purgeAfter,
    );
    final index = _taxEvents.indexWhere((item) => item.id == eventId);
    if (index >= 0) {
      _taxEvents[index] = updated;
    }
    return updated;
  }

  BitcoinAccount _accountWith(
    BitcoinAccount account, {
    String? label,
    String? status,
  }) {
    return BitcoinAccount(
      id: account.id,
      type: account.type,
      custody: account.custody,
      status: status ?? account.status,
      label: label ?? account.label,
      walletTypeDescription: account.walletTypeDescription,
      riskTier: account.riskTier,
      cardId: account.cardId,
      coldWalletId: account.coldWalletId,
      balanceAvailableSats: account.balanceAvailableSats,
      balancePendingSats: account.balancePendingSats,
      balanceLockedSats: account.balanceLockedSats,
      balanceAutoHoldSats: account.balanceAutoHoldSats,
      observedBalanceSats: account.observedBalanceSats,
      xpubFingerprint: account.xpubFingerprint,
      derivationPath: account.derivationPath,
      scriptPolicy: account.scriptPolicy,
    );
  }
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<Either<Failure, List<SessionNotificationItem>>>
      getNotifications() async {
    return Right(mockNotifications);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DeviceToken>>> activeDeviceTokens() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> revokeDeviceToken(String tokenId) async {
    return const Right(null);
  }
}

class MockTransactionRepository implements TransactionRepository {
  @override
  Future<FeeEstimate> estimateFee(double amount) async {
    return FeeEstimate(
      fastSatPerByte: 22,
      standardSatPerByte: 14,
      slowSatPerByte: 8,
      estimatedFastBtc: 0.000022,
      estimatedStandardBtc: 0.000014,
      estimatedSlowBtc: 0.000008,
      amountReceived: amount,
      totalToSend: amount + 0.000014,
    );
  }

  @override
  Future<TxStatus> getTransactionStatus(String txid) async {
    return TxStatus(
      txid: txid,
      status: 'confirmed',
      feeSatoshis: 1200,
      amountReceived: 0.0042,
      networkFeeBtc: 0.000012,
      receiver: mockWallets.first.address,
    );
  }

  @override
  Future<TxStatus> sendTransaction({
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? fromWalletId,
    String? fromAddress,
    String? context,
    String? passkeyAssertionJson,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
  }) async {
    return TxStatus(
      txid: 'storybook-send-txid',
      status: 'broadcasted',
      feeSatoshis: feeSatoshis,
      amountReceived: amount,
      sender: fromAddress ?? fromWalletId ?? mockWallets.first.name,
      receiver: toAddress,
      context: context,
    );
  }

  @override
  Future<Either<Failure, String>> getDepositAddress() async {
    return Right(mockWallets.first.address);
  }

  @override
  Future<Either<Failure, Map<String, String>>> getOnrampUrls() async {
    return const Right({
      'moonpay': 'https://buy.moonpay.com/storybook',
      'binance': 'https://www.binance.com/storybook',
      'transfero': 'https://transfero.com/storybook',
    });
  }

  @override
  Future<List<Deposit>> getDeposits() async => mockDeposits;

  @override
  Future<double> getDepositBalance() async => 0.0545;

  @override
  Future<Deposit> getDeposit(String txid) async {
    return mockDeposits.firstWhere(
      (item) => item.txid == txid,
      orElse: () => mockDeposits.first,
    );
  }

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    String? description,
    int? expiresInMinutes,
    String? visibility,
    String? confirmationMode,
    bool amountLocked = true,
    String? referenceLabel,
    Map<String, String>? metadata,
  }) async {
    return mockPaymentLink(
      id: 'storybook-payment-link-created',
      amountBtc: amount,
    );
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    return mockPaymentLinks.firstWhere(
      (item) => item.id == linkId,
      orElse: () => mockPaymentLinks.first,
    );
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async => mockPaymentLinks;

  @override
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  }) async {
    return WalletNetworkAddress(
      walletName: walletName,
      onchainAddress: mockWallets.first.address,
      lightningAddress: 'storybook@kerosene.local',
      network: 'mainnet',
      provider: 'Kerosene',
      externalWalletReference: 'storybook-wallet-ref',
      walletMode: 'KEROSENE',
      lightningEnabled: true,
      lightningUnavailableReason: '',
    );
  }

  @override
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  }) async {
    return OnchainAddressAllocation(
      walletName: walletName,
      onchainAddress: mockWallets.first.address,
      expectedAmountBtc: expectedAmountBtc,
      network: 'mainnet',
      provider: 'Kerosene',
      externalWalletReference: 'storybook-onchain-ref',
      walletMode: 'KEROSENE',
      transferId: 'storybook-onchain-transfer',
      transferStatus: 'PENDING',
      confirmations: 0,
      requiredConfirmations: 3,
      blockchainTxid: '',
    );
  }

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() async {
    return mockExternalTransfers;
  }

  @override
  Future<ExternalTransfer> getExternalTransfer(String transferId) async {
    return mockExternalTransfers.firstWhere(
      (item) => item.id == transferId,
      orElse: () => mockExternalTransfers.first,
    );
  }

  @override
  Future<TxStatus> withdraw({
    required String fromWalletName,
    String? toAddress,
    String? paymentRequest,
    required double amount,
    String? totpCode,
    bool isLightning = false,
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
  }) async {
    return TxStatus(
      txid: isLightning
          ? 'storybook-lightning-withdrawal'
          : 'storybook-onchain-withdrawal',
      status: 'broadcasted',
      feeSatoshis: isLightning ? 120 : 1200,
      amountReceived: amount,
      networkFeeBtc: isLightning ? maxRoutingFeeBtc : 0.000012,
      sender: fromWalletName,
      receiver: paymentRequest ?? toAddress ?? '',
      context: description,
    );
  }
}
