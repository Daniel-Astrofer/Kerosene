import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/domain/entities/deposit.dart';
import 'package:kerosene/features/movement/domain/entities/external_transfer.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/admin_access.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/domain/entities/kfe_reserve_overview.dart';
import 'package:kerosene/features/security/domain/entities/passkey_inventory.dart';
import 'package:kerosene/features/security/domain/entities/security_status.dart';

final mockNow = DateTime.utc(2026, 5, 28, 12);

final mockUser = User(
  id: 'sat-001',
  username: 'Satoshi Nakamoto',
  createdAt: mockNow,
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
    createdAt: mockNow.subtract(const Duration(days: 120)),
    updatedAt: mockNow,
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
    createdAt: mockNow.subtract(const Duration(days: 45)),
    updatedAt: mockNow,
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
    timestamp: mockNow.subtract(const Duration(hours: 2)),
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
    timestamp: mockNow.subtract(const Duration(minutes: 18)),
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
    timestamp: mockNow.subtract(const Duration(days: 1)),
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
    createdAt: mockNow.subtract(const Duration(days: 2)),
    confirmedAt: mockNow.subtract(const Duration(days: 2, hours: -1)),
  ),
];

PaymentLink mockPaymentLink({
  String id = 'storybook-payment-link',
  String status = 'pending',
  double amountBtc = 0.0042,
  bool internal = true,
}) {
  final createdAt = mockNow.subtract(const Duration(minutes: 12));
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
        ? mockNow.subtract(const Duration(minutes: 2))
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
  final now = mockNow;
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
    expiry: mockNow.add(const Duration(hours: 2)).toIso8601String(),
    oneTime: true,
    createdAt: mockNow.subtract(const Duration(minutes: 10)),
  ),
  ReceivingRequestView(
    id: 'receive-storybook-paid',
    accountId: 'story-account-card',
    address: 'bc1qstorybookpaid000000000000000000000000000000',
    bip21:
        'bitcoin:bc1qstorybookpaid000000000000000000000000000000?amount=0.01000000',
    status: 'PAID',
    amountSats: 1000000,
    expiry: mockNow.add(const Duration(hours: 1)).toIso8601String(),
    oneTime: true,
    createdAt: mockNow.subtract(const Duration(hours: 1)),
  ),
  ReceivingRequestView(
    id: 'receive-storybook-expired',
    accountId: 'story-account-card',
    address: 'bc1qstorybookexpired000000000000000000000000000',
    bip21:
        'bitcoin:bc1qstorybookexpired000000000000000000000000000?amount=0.00100000',
    status: 'EXPIRED',
    amountSats: 100000,
    expiry: mockNow.subtract(const Duration(minutes: 20)).toIso8601String(),
    oneTime: true,
    createdAt: mockNow.subtract(const Duration(hours: 2)),
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
    expiresAt: mockNow.add(const Duration(hours: 18)).toIso8601String(),
    createdAt: mockNow.subtract(const Duration(minutes: 26)).toIso8601String(),
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
    expiresAt: mockNow.add(const Duration(hours: 1)).toIso8601String(),
    createdAt: mockNow.subtract(const Duration(hours: 3)).toIso8601String(),
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
    createdAt: mockNow.subtract(const Duration(minutes: 40)).toIso8601String(),
  ),
  TaxEventView(
    id: 'tax-storybook-2',
    eventType: 'FEE',
    asset: 'BTC',
    quantitySats: 900,
    classification: 'FEE',
    sourceRef: '88bbccdd...44556677',
    createdAt: mockNow.subtract(const Duration(hours: 3)).toIso8601String(),
  ),
];

final mockNotifications = [
  SessionNotificationItem(
    id: '101',
    title: 'Depósito confirmado',
    body: '0.00420000 BTC foram creditados na Reserva principal.',
    timestamp: mockNow.subtract(const Duration(minutes: 4)),
    kind: SessionNotificationItem.kindDepositConfirmed,
    severity: SessionNotificationItem.severitySuccess,
    entityType: 'transaction',
    entityId: 'storybook-receive-txid',
  ),
  SessionNotificationItem(
    id: '102',
    title: 'Novo acesso detectado',
    body: 'Uma sessão web admin foi autenticada no ambiente Storybook.',
    timestamp: mockNow.subtract(const Duration(hours: 1)),
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
  createdAt: mockNow.subtract(const Duration(days: 45)),
);

final mockAdminAccessAttempts = [
  AdminAccessAttempt(
    attemptId: 'attempt-storybook',
    status: 'PENDING',
    deviceId: 'web-storybook',
    deviceName: 'Storybook Admin Console',
    browser: 'Flutter Linux',
    ipFingerprint: 'ip-storybook',
    requestedAt: mockNow.subtract(const Duration(minutes: 7)),
    expiresAt: mockNow.add(const Duration(minutes: 8)),
  ),
];

final mockAdminDevices = [
  AdminAuthenticatedDevice(
    deviceId: 'web-storybook',
    deviceName: 'Storybook Admin Console',
    browser: 'Flutter Linux',
    status: 'ACTIVE',
    firstAccessAt: mockNow.subtract(const Duration(days: 3)),
    lastAccessAt: mockNow.subtract(const Duration(minutes: 2)),
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
    'createdAt': mockNow.subtract(Duration(hours: index * 6)).toIso8601String(),
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
