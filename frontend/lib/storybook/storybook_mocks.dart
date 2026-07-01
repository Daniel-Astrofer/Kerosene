import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';
import 'package:kerosene/features/financial_accounts/domain/services/bitcoin_accounts_service.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/admin_access.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/domain/entities/passkey_inventory.dart';
import 'package:kerosene/features/security/domain/entities/security_status.dart';
import 'package:kerosene/features/security/domain/entities/kfe_reserve_overview.dart';
import 'package:kerosene/features/movement/domain/entities/deposit.dart';
import 'package:kerosene/features/movement/domain/entities/external_transfer.dart';
import 'package:kerosene/features/movement/domain/entities/fee_estimate.dart';
import 'package:kerosene/features/movement/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/domain/entities/tx_status.dart';
import 'package:kerosene/features/movement/domain/entities/wallet_network_address.dart';
import 'package:kerosene/features/movement/domain/repositories/transaction_repository.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/core/services/price_websocket_service.dart';
import 'package:flutter/foundation.dart';
import 'storybook_mock_data.dart';
export 'storybook_mock_data.dart';

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
      createdAt: mockNow,
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
      createdAt: mockNow,
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
      expiresAt: mockNow.add(const Duration(hours: 24)).toIso8601String(),
      createdAt: mockNow.toIso8601String(),
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
    String? appPin,
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
    String? appPin,
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
