import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/movement/domain/entities/external_transfer.dart';
import 'package:kerosene/features/movement/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/movement/domain/repositories/transaction_repository.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'package:kerosene/features/movement/screens/receive_request_flow_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboardText;

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final arguments = call.arguments as Map<dynamic, dynamic>;
          clipboardText = arguments['text']?.toString();
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboardText};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'updates on-chain receive confirmation progress while polling',
    (tester) async {
      _setMobileViewport(tester);
      final repository = _PollingReceiveRepository(
        updates: [
          _externalTransfer(status: 'DETECTED', confirmations: 1),
          _externalTransfer(status: 'CONFIRMED', confirmations: 2),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(repository),
            transactionHistoryProvider.overrideWith((ref) async => const []),
            externalTransfersProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReceiveRequestFlowScreen(
              wallet: _wallet(),
              onChainWallet: true,
              amountBtc: 0.0015,
              method: ReceiveAmountMethod.qrCode,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Receber Bitcoin'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.text('Aguardando confirmações (1/3)'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.text('Aguardando confirmações (2/3)'), findsOneWidget);
      expect(repository.getExternalTransferCalls, 2);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('copies raw receive address from the QR address pill', (
    tester,
  ) async {
    _setMobileViewport(tester);
    final wallet = _wallet();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionHistoryProvider.overrideWith((ref) async => const []),
          externalTransfersProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReceiveRequestFlowScreen(
            wallet: wallet,
            onChainWallet: true,
            amountBtc: 0.0015,
            method: ReceiveAmountMethod.qrCode,
            enableStatusPolling: false,
            initialAddress: wallet.address,
          ),
        ),
      ),
    );

    await tester.pump();
    final copyPill = find.byKey(const ValueKey('receive-address-pill-copy'));
    await tester.ensureVisible(copyPill);
    await tester.tap(copyPill);
    await tester.pump();

    final clipboardData = await Clipboard.getData('text/plain');
    expect(clipboardData?.text, wallet.address);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows payment details before sharing the receive request', (
    tester,
  ) async {
    _setMobileViewport(tester);
    final wallet = _wallet();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionHistoryProvider.overrideWith((ref) async => const []),
          externalTransfersProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReceiveRequestFlowScreen(
            wallet: wallet,
            onChainWallet: true,
            amountBtc: 0.0015,
            method: ReceiveAmountMethod.qrCode,
            enableStatusPolling: false,
            initialAddress: wallet.address,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Carteira'), findsOneWidget);
    expect(find.text(wallet.name), findsOneWidget);
    expect(find.text('Rede'), findsOneWidget);
    expect(find.text('Bitcoin (BTC)'), findsOneWidget);
    expect(find.text('Solicitado'), findsOneWidget);
    expect(find.text('0.001500 BTC'), findsOneWidget);
    expect(find.text('Endereço'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Wallet _wallet() {
  return Wallet(
    id: 'wallet-1',
    name: 'Reserva principal',
    address: 'bc1qreceiveflow000000000000000000000000000000',
    walletMode: 'SELF_CUSTODY',
    balance: 0.05,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

ExternalTransfer _externalTransfer({
  required String status,
  required int confirmations,
}) {
  return ExternalTransfer(
    id: 'transfer-1',
    network: 'ONCHAIN',
    transferType: 'ADDRESS_ISSUE',
    status: status,
    provider: 'KFE',
    walletName: 'Reserva principal',
    destination: 'bc1qreceiveflow000000000000000000000000000000',
    amountBtc: 0,
    networkFeeBtc: 0,
    platformFeeBtc: 0,
    totalDebitedBtc: 0,
    externalReference: 'bc1qreceiveflow000000000000000000000000000000',
    invoiceId: '',
    blockchainTxid: 'txid-receive-flow',
    paymentHash: '',
    invoiceData: '',
    expectedAmountBtc: 0.0015,
    confirmations: confirmations,
    detectedAt: DateTime(2026, 6, 1, 12),
    settledAt: null,
    createdAt: DateTime(2026, 6, 1, 11, 58),
    updatedAt: DateTime(2026, 6, 1, 12, confirmations),
    context: 'Recebimento via QR',
  );
}

class _PollingReceiveRepository implements TransactionRepository {
  final List<ExternalTransfer> updates;
  int getExternalTransferCalls = 0;

  _PollingReceiveRepository({required this.updates});

  @override
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  }) async {
    return OnchainAddressAllocation(
      walletName: walletName,
      onchainAddress: 'bc1qreceiveflow000000000000000000000000000000',
      expectedAmountBtc: expectedAmountBtc,
      network: 'ONCHAIN',
      provider: 'KFE',
      externalWalletReference: walletName,
      walletMode: 'SELF_CUSTODY',
      transferId: 'transfer-1',
      transferStatus: 'PENDING',
      confirmations: 0,
      requiredConfirmations: 3,
      blockchainTxid: '',
    );
  }

  @override
  Future<ExternalTransfer> getExternalTransfer(String transferId) async {
    final index = getExternalTransferCalls;
    getExternalTransferCalls++;
    if (index >= updates.length) {
      return updates.last;
    }
    return updates[index];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
