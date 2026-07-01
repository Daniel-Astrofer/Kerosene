import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/features/movement/domain/entities/deposit.dart';
import 'package:kerosene/features/movement/domain/entities/external_transfer.dart';
import 'package:kerosene/features/movement/domain/entities/fee_estimate.dart';
import 'package:kerosene/features/movement/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/domain/entities/tx_status.dart';
import 'package:kerosene/features/movement/domain/entities/wallet_network_address.dart';
import 'package:kerosene/features/movement/domain/repositories/transaction_repository.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/screens/movement_amount_screen.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';

void main() {
  testWidgets('shows payment link configuration before generating link',
      (tester) async {
    final repository = _ReceiveAmountRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          paymentLinksProvider.overrideWith((ref) async => const []),
          transactionHistoryProvider.overrideWith((ref) async => const []),
          externalTransfersProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MovementAmountScreen(
            wallet: _wallet(),
            method: ReceiveAmountMethod.paymentLink,
            onChainWallet: false,
          ),
        ),
      ),
    );

    expect(find.text('Link de pagamento'), findsOneWidget);
    expect(find.text('15 Minutos'), findsOneWidget);
    expect(find.text('1 Hora'), findsOneWidget);
    expect(find.text('24 Horas'), findsOneWidget);
    expect(find.text('GERAR LINK DE PAGAMENTO'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('movement-amount-input')),
      '100000000',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('GERAR LINK DE PAGAMENTO'));
    await tester.pump();
    await tester.tap(find.text('GERAR LINK DE PAGAMENTO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    expect(repository.createPaymentLinkCalls, 1);
    expect(repository.lastExpiresInMinutes, 15);
  });

  testWidgets('creates a backend payment link before opening QR receive flow',
      (tester) async {
    final repository = _ReceiveAmountRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          paymentLinksProvider.overrideWith((ref) async => const []),
          transactionHistoryProvider.overrideWith((ref) async => const []),
          externalTransfersProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MovementAmountScreen(
            wallet: _wallet(),
            method: ReceiveAmountMethod.qrCode,
            onChainWallet: false,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('movement-amount-input')),
      '100000000',
    );
    await tester.pump();
    await tester.tap(find.textContaining('350.000,00'));
    await tester.pump();

    expect(find.text('R\$350.000,00'), findsOneWidget);
    expect(find.text('≈ ₿ 1'), findsOneWidget);

    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.pump();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    expect(repository.createPaymentLinkCalls, 1);
    expect(repository.lastAmount, 1);
    expect(repository.lastMetadata?['rail'], 'INTERNAL');
    expect(repository.lastMetadata?['method'], 'qrCode');
    expect(find.text('Receber na Kerosene'), findsOneWidget);
  });
}

Wallet _wallet() {
  return Wallet(
    id: 'wallet-1',
    name: 'Carteira Global',
    address: 'kerosene:wallet-1',
    walletMode: 'KEROSENE',
    balance: 0.1,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

class _ReceiveAmountRepository implements TransactionRepository {
  int createPaymentLinkCalls = 0;
  double? lastAmount;
  Map<String, String>? lastMetadata;
  int? lastExpiresInMinutes;

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
    createPaymentLinkCalls++;
    lastAmount = amount;
    lastMetadata = metadata;
    lastExpiresInMinutes = expiresInMinutes;
    return PaymentLink(
      id: 'receive-link-1',
      userId: 1,
      amountBtc: amount,
      description: description ?? '',
      depositAddress: 'kerosene:wallet-1',
      paymentUri: 'https://kerosene.test/pay/receive-link-1',
      status: 'pending',
      paymentRail: metadata?['rail'] ?? 'INTERNAL',
      createdAt: DateTime(2026, 6, 1),
    );
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    return PaymentLink(
      id: linkId,
      userId: 1,
      amountBtc: lastAmount ?? 1,
      description: 'Recebimento Carteira Global',
      depositAddress: 'kerosene:wallet-1',
      paymentUri: 'https://kerosene.test/pay/$linkId',
      status: 'pending',
      paymentRail: 'INTERNAL',
      createdAt: DateTime(2026, 6, 1),
    );
  }

  @override
  Future<FeeEstimate> estimateFee(double amount) => throw UnimplementedError();

  @override
  Future<TxStatus> getTransactionStatus(String txid) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> getDepositAddress() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Map<String, String>>> getOnrampUrls() =>
      throw UnimplementedError();

  @override
  Future<List<Deposit>> getDeposits() => throw UnimplementedError();

  @override
  Future<double> getDepositBalance() => throw UnimplementedError();

  @override
  Future<Deposit> getDeposit(String txid) => throw UnimplementedError();

  @override
  Future<List<PaymentLink>> getPaymentLinks() => throw UnimplementedError();

  @override
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  }) =>
      throw UnimplementedError();

  @override
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() =>
      throw UnimplementedError();

  @override
  Future<ExternalTransfer> getExternalTransfer(String transferId) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();
}
