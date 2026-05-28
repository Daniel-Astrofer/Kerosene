import 'dart:async';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/domain/entities/user.dart';
import 'package:teste/core/services/price_websocket_service.dart';
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
