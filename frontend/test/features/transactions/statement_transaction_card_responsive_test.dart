import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:teste/features/transactions/presentation/widgets/statement_transaction_card.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compactPortrait = Size(320, 568);
  const compactLandscape = Size(568, 320);
  const regularPortrait = Size(390, 844);

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
    configureViewport(tester, size);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [latestBtcPriceProvider.overrideWith((ref) => 76500)],
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
