import 'dart:async';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/domain/entities/user.dart';
import 'package:teste/core/services/price_websocket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/features/security/domain/entities/security_status.dart';
import 'package:teste/features/security/domain/entities/treasury_overview.dart';
import 'package:teste/features/transactions/domain/entities/deposit.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/domain/entities/wallet_network_address.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

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
  void clearError() {}
}

/// Mock Price WebSocket Service for Storybook.
class MockPriceWebSocketService implements PriceWebSocketService {
  final _priceController = StreamController<double>.broadcast();

  @override
  Stream<double> get priceStream => _priceController.stream;

  @override
  void connect() {
    debugPrint('>>> MockPriceWebSocket: Connection simulated');
    // Periodically push some mock data to keep it "alive"
    _priceController.add(67234.50);
  }

  @override
  void dispose() {
    _priceController.close();
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

final mockWallets = [
  Wallet(
    id: 'story_wallet_001',
    name: 'Satoshi Vault',
    address: 'bc1qstorybook0vault0address000000000000000000',
    balance: 0.042,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 4, 2),
    updatedAt: DateTime(2026, 5, 5),
    cardHolderName: 'SATOSHI NAKAMOTO',
    cardMaskedNumber: '**** **** **** 2109',
    cardNumberSuffix: '2109',
    cardType: WalletCardType.black,
  ),
  Wallet(
    id: 'story_wallet_002',
    name: 'Lightning Daily',
    address: 'bc1qstorybook0daily0address000000000000000000',
    balance: 0.0085,
    derivationPath: "m/84'/0'/0'/0/1",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 4, 18),
    updatedAt: DateTime(2026, 5, 4),
    cardHolderName: 'SATOSHI NAKAMOTO',
    cardMaskedNumber: '**** **** **** 9021',
    cardNumberSuffix: '9021',
    cardType: WalletCardType.white,
  ),
];

final mockTransactions = [
  Transaction(
    id: 'storybook_tx_confirmed_receive',
    fromAddress: 'Rede Bitcoin',
    toAddress: mockWallets.first.address,
    amountSatoshis: 1250000,
    feeSatoshis: 0,
    status: TransactionStatus.confirmed,
    type: TransactionType.receive,
    confirmations: 12,
    timestamp: DateTime(2026, 5, 5, 14, 20),
    description: 'Deposito on-chain confirmado',
    blockchainTxid:
        '6f1a9f2e44f1c9d3d0a98b9fdb3f39e5de5d24b48d44f81dd0fb4e23b956f010',
  ),
  Transaction(
    id: 'storybook_tx_pending_lightning',
    fromAddress: 'lnbc...',
    toAddress: mockWallets.last.address,
    amountSatoshis: 420000,
    feeSatoshis: 120,
    status: TransactionStatus.pending,
    type: TransactionType.deposit,
    confirmations: 0,
    timestamp: DateTime(2026, 5, 6, 9, 5),
    description: 'Invoice Lightning aguardando liquidacao',
    isLightning: true,
    paymentHash: 'storybook_payment_hash',
  ),
  Transaction(
    id: 'storybook_tx_send',
    fromAddress: mockWallets.first.address,
    toAddress: 'bc1qexternal0receiver0address000000000000000',
    amountSatoshis: 275000,
    feeSatoshis: 1800,
    status: TransactionStatus.confirmed,
    type: TransactionType.send,
    confirmations: 8,
    timestamp: DateTime(2026, 5, 3, 17, 42),
    description: 'Envio externo',
  ),
];

final mockWalletNetworkAddress = WalletNetworkAddress(
  walletName: mockWallets.first.name,
  onchainAddress: mockWallets.first.address,
  lightningAddress: 'satoshi.storybook@kerosene.local',
  network: 'signet',
  provider: 'storybook',
  externalWalletReference: 'story-ext-wallet-001',
  walletMode: 'KEROSENE',
  lightningEnabled: true,
  lightningUnavailableReason: '',
);

final mockPaymentLinks = [
  PaymentLink(
    id: 'pl_story_001',
    userId: 1,
    amountBtc: 0.0021,
    grossAmountBtc: 0.0021,
    netAmountBtc: 0.0020811,
    depositFeeBtc: 0.0000189,
    description: 'Pagamento do pedido #4821',
    depositAddress: mockWallets.first.address,
    status: 'pending',
    createdAt: DateTime(2026, 5, 6, 8, 30),
    expiresAt: DateTime(2026, 5, 7, 8, 30),
    paymentUri: 'bitcoin:${mockWallets.first.address}?amount=0.0021',
  ),
];

final mockDeposits = [
  Deposit(
    id: 1,
    userId: 1,
    txid: 'storybook_deposit_001',
    fromAddress: 'Rede Bitcoin',
    toAddress: mockWallets.first.address,
    amountBtc: 0.0125,
    confirmations: 12,
    status: 'credited',
    createdAt: DateTime(2026, 5, 5, 14, 20),
    confirmedAt: DateTime(2026, 5, 5, 15, 4),
  ),
];

const mockSecurityStatus = SecurityStatus(
  hardwareAttestation: {'status': 'verified', 'score': 92},
  networkConsensus: {'status': 'healthy', 'peers': 7},
  ledgerIntegrity: {'status': 'sealed', 'latestRoot': 'story-root'},
  memoryProtection: {'status': 'active', 'locked': true},
  serverUptimeSeconds: 248400,
);

const mockTreasuryOverview = TreasuryOverview(
  totalOnchainBtc: 4.82,
  lightningNodeBtc: 0.74,
  inboundLiquidityBtc: 0.41,
  outboundLiquidityBtc: 0.33,
  reservedOnchainBtc: 0.52,
  reservedLightningBtc: 0.08,
  availableOnchainBtc: 4.3,
  availableLightningBtc: 0.66,
  lightningSendsAllowed: true,
  liquidityState: 'HEALTHY',
);

class MockWalletNotifier extends WalletNotifier {
  final WalletState initialOverride;

  MockWalletNotifier({WalletState? initialOverride})
      : initialOverride = initialOverride ??
            WalletLoaded(
              wallets: mockWallets,
              selectedWallet: mockWallets.first,
              btcToUsdRate: 65000,
            );

  @override
  WalletState build() => initialOverride;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> updateWalletBalance(String walletId) async {}
}
