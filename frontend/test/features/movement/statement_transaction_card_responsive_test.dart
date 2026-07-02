import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/features/movement/widgets/transaction_list_item.dart';
import 'package:kerosene/features/movement/widgets/statement_transaction_card.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compactPortrait = Size(320, 568);
  const compactLandscape = Size(568, 320);
  const regularPortrait = Size(390, 844);

  String? clipboardText;

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final arguments = call.arguments;
          if (arguments is Map) {
            clipboardText = arguments['text']?.toString();
          }
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

  final transaction = Transaction(
    id: 'tx-responsive-001',
    fromAddress: 'bc1qsourceaddresswithaverylongvalue00000000000000000000',
    toAddress: 'bc1qdestinationaddresswithaverylongvalue1111111111111111',
    amountSatoshis: 987654321,
    feeSatoshis: 3210,
    status: TransactionStatus.confirming,
    type: TransactionType.withdrawal,
    confirmations: 1,
    timestamp: DateTime(2026, 5, 19, 22, 30),
    blockchainTxid:
        '82b6f7a1f0d1f1422c3378e4a66de62c2bb91df1a8d2de8f9c11c2a6e3123456',
    description:
        'Long transaction description used only for responsive widget tests',
  );

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }
    return exceptions;
  }

  void configureViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    final sharedPreferences = await SharedPreferences.getInstance();
    configureViewport(tester, size);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          backendBtcRatesProvider.overrideWith(
            (ref) async => const BackendBtcRates(
              btcUsd: 76500,
              btcBrl: 382500,
              btcEur: 70380,
              usdBrl: 5,
            ),
          ),
          latestBtcPriceProvider.overrideWithValue(76500),
          btcBrlPriceProvider.overrideWithValue(382500),
          btcEurPriceProvider.overrideWithValue(70380),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('StatementTransactionCard responsiveness', () {
    testWidgets('stacked card fits its fixed stack extent', (tester) async {
      for (final size in [compactPortrait, compactLandscape, regularPortrait]) {
        await pumpCard(
          tester,
          size: size,
          child: SizedBox(
            width: 340,
            height: 174,
            child: StatementTransactionCard(transaction: transaction),
          ),
        );

        expect(
          takeAllExceptions(tester),
          isEmpty,
          reason: 'Stacked transaction card overflowed at $size',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('expanded separated card remains scrollable on short screens', (
      tester,
    ) async {
      await pumpCard(
        tester,
        size: compactLandscape,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: StatementTransactionCard(
              transaction: transaction,
              expanded: true,
              mode: StatementTransactionCardMode.separated,
            ),
          ),
        ),
      );

      expect(takeAllExceptions(tester), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('failed outgoing cards keep the debit sign', (tester) async {
      final failedOutgoing = Transaction(
        id: 'tx-failed-outgoing',
        fromAddress: 'minha-carteira',
        toAddress: 'bc1qdestination',
        amountSatoshis: 50000,
        feeSatoshis: 1200,
        status: TransactionStatus.failed,
        type: TransactionType.withdrawal,
        confirmations: 0,
        timestamp: DateTime(2026, 5, 20, 12),
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SizedBox(
          width: 340,
          height: 174,
          child: StatementTransactionCard(transaction: failedOutgoing),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && (widget.data?.startsWith('-') ?? false),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('expanded detail rows copy exact transaction identifiers', (
      tester,
    ) async {
      const paymentHash = 'payment-hash-fallback-00000000000000000000000001';
      final transactionWithFallbackReference = Transaction(
        id: 'tx-copyable-detail-001',
        fromAddress: 'bc1qsourceaddresswithaverylongvalue00000000000000000000',
        toAddress: 'bc1qdestinationaddresswithaverylongvalue1111111111111111',
        amountSatoshis: 210000,
        feeSatoshis: 1200,
        status: TransactionStatus.confirmed,
        type: TransactionType.withdrawal,
        confirmations: 6,
        timestamp: DateTime(2026, 5, 21, 9, 45),
        blockchainTxid: '',
        paymentHash: paymentHash,
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 340,
            child: StatementTransactionCard(
              transaction: transactionWithFallbackReference,
              expanded: true,
              mode: StatementTransactionCardMode.separated,
            ),
          ),
        ),
      );

      final referenceCopy = find.byKey(
        const ValueKey('statement-detail-copy-reference'),
      );
      await tester.ensureVisible(referenceCopy);
      await tester.tap(referenceCopy);
      await tester.pump();

      final referenceClipboard = await Clipboard.getData('text/plain');
      expect(referenceClipboard?.text, paymentHash);
      expect(find.text('Transaction detail copied.'), findsOneWidget);

      final idCopy = find.byKey(const ValueKey('statement-detail-copy-id'));
      await tester.ensureVisible(idCopy);
      await tester.tap(idCopy);
      await tester.pump();

      final idClipboard = await Clipboard.getData('text/plain');
      expect(idClipboard?.text, transactionWithFallbackReference.id);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('expanded on-chain card shows blockchain data only', (
      tester,
    ) async {
      final onChain = Transaction(
        id: 'ledger-onchain-001',
        fromAddress: 'bc1qsourceaddresswithaverylongvalue00000000000000000000',
        toAddress: 'bc1qdestinationaddresswithaverylongvalue1111111111111111',
        amountSatoshis: 300000,
        feeSatoshis: 900,
        status: TransactionStatus.confirming,
        type: TransactionType.deposit,
        confirmations: 3,
        timestamp: DateTime(2026, 5, 22, 8, 30),
        blockchainTxid:
            '82b6f7a1f0d1f1422c3378e4a66de62c2bb91df1a8d2de8f9c11c2a6e3123456',
        blockHeight: 845123,
        blockHash:
            '00000000000000000003f6a9b9db9e1e53f1db0f56bbf6b9f7c2d6f000000001',
        hasNetworkFee: true,
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 340,
            child: StatementTransactionCard(
              transaction: onChain,
              expanded: true,
            ),
          ),
        ),
      );

      expect(find.text('Confirmations'), findsOneWidget);
      expect(find.text('TXID'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Payment hash'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('expanded lightning card shows payment data without chain rows',
        (
      tester,
    ) async {
      final lightning = Transaction(
        id: 'ln-ledger-001',
        fromAddress: 'alice@kerosene.test',
        toAddress: 'bob@kerosene.test',
        amountSatoshis: 42000,
        feeSatoshis: 12,
        status: TransactionStatus.confirmed,
        type: TransactionType.receive,
        confirmations: 0,
        timestamp: DateTime(2026, 5, 22, 9),
        invoiceId: 'invoice-0001',
        lightningInvoice: 'lnbcrt420n1ptestinvoice',
        paymentHash: 'payment-hash-00000000000000000000000000000001',
        isLightning: true,
        hasNetworkFee: true,
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 340,
            child: StatementTransactionCard(
              transaction: lightning,
              expanded: true,
            ),
          ),
        ),
      );

      expect(find.text('Settlement'), findsOneWidget);
      expect(find.text('Payment hash'), findsOneWidget);
      expect(find.text('Invoice'), findsOneWidget);
      expect(find.text('BOLT11'), findsOneWidget);
      expect(find.text('Confirmations'), findsNothing);
      expect(find.text('TXID'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('expanded internal card shows wallet movement without txid', (
      tester,
    ) async {
      final internal = Transaction(
        id: 'internal-ledger-001',
        fromAddress: 'wallet-main',
        toAddress: 'wallet-reserve',
        walletId: 'wallet-main',
        sourceWalletId: 'wallet-main',
        destinationWalletId: 'wallet-reserve',
        senderDisplayName: 'Conta principal',
        receiverDisplayName: 'Reserva',
        amountSatoshis: 120000,
        feeSatoshis: 0,
        status: TransactionStatus.confirmed,
        type: TransactionType.send,
        confirmations: 0,
        timestamp: DateTime(2026, 5, 22, 10),
        isInternal: true,
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 340,
            child: StatementTransactionCard(
              transaction: internal,
              expanded: true,
            ),
          ),
        ),
      );

      expect(find.text('Internal status'), findsOneWidget);
      expect(find.text('Source wallet'), findsOneWidget);
      expect(find.text('Destination wallet'), findsOneWidget);
      expect(find.text('TXID'), findsNothing);
      expect(find.text('Confirmations'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('transaction list item keeps the debit sign for outgoing rows',
        (tester) async {
      final outgoing = Transaction(
        id: 'tx-list-outgoing',
        fromAddress: 'minha-carteira',
        toAddress: 'bc1qdestination',
        amountSatoshis: 50000,
        feeSatoshis: 1200,
        status: TransactionStatus.confirmed,
        type: TransactionType.send,
        confirmations: 6,
        timestamp: DateTime(2026, 5, 20, 12),
      );

      await pumpCard(
        tester,
        size: regularPortrait,
        child: SizedBox(
          width: 340,
          child: TransactionListItem(transaction: outgoing),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && (widget.data?.startsWith('-') ?? false),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
