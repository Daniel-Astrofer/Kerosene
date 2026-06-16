import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/transactions/presentation/screens/deposits_screen.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final onchain = Transaction(
    id: 'statement-onchain-001',
    fromAddress: 'bc1qsourceaddress000000000000000000000000000000',
    toAddress: 'bc1qdestination000000000000000000000000000',
    amountSatoshis: 125000,
    feeSatoshis: 900,
    status: TransactionStatus.confirmed,
    type: TransactionType.deposit,
    confirmations: 6,
    timestamp: DateTime(2026, 5, 20, 12),
  );

  final lightning = Transaction(
    id: 'statement-lightning-001',
    fromAddress: 'minha-carteira',
    toAddress: 'lnbc1pjexampleinvoice',
    amountSatoshis: 6400,
    feeSatoshis: 12,
    status: TransactionStatus.pending,
    type: TransactionType.withdrawal,
    confirmations: 0,
    timestamp: DateTime(2026, 5, 21, 12),
    isLightning: true,
  );

  final failedInternal = Transaction(
    id: 'statement-failed-001',
    fromAddress: 'minha-carteira',
    toAddress: 'failed-peer',
    amountSatoshis: 32500,
    feeSatoshis: 0,
    status: TransactionStatus.failed,
    type: TransactionType.send,
    confirmations: 0,
    timestamp: DateTime(2026, 5, 22, 12),
    isInternal: true,
  );

  Future<void> pumpStatement(
    WidgetTester tester,
    List<Transaction> transactions,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionHistoryProvider.overrideWith((ref) async => transactions),
          latestBtcPriceProvider.overrideWith((ref) => 76500),
          btcEurPriceProvider.overrideWith((ref) => 70000),
          btcBrlPriceProvider.overrideWith((ref) => 420000),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TransactionStatementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('statement search matches visible transaction labels',
      (tester) async {
    await pumpStatement(tester, [onchain, lightning]);

    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lightning');
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty statement search can clear filters', (tester) async {
    await pumpStatement(tester, [onchain, lightning]);

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no matching tx');
    await tester.pumpAndSettle();

    expect(find.text('No matching transactions'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.text('Lightning'), findsNothing);
    expect(find.text('Onchain'), findsNothing);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('No matching transactions'), findsNothing);
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement search clear button restores visible rows',
      (tester) async {
    await pumpStatement(tester, [onchain, lightning]);

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lightning');
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsNothing);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(find.byIcon(LucideIcons.x), findsNothing);
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement search closes without preserving stale input',
      (tester) async {
    await pumpStatement(tester, [onchain, lightning]);

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lightning');
    await tester.pumpAndSettle();

    expect(find.text('Onchain'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement status filters isolate pending and failed activity',
      (tester) async {
    await pumpStatement(tester, [onchain, lightning, failedInternal]);

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Onchain'), findsNothing);
    expect(find.textContaining('failed-peer'), findsNothing);

    await tester.ensureVisible(find.text('Failed'));
    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsNothing);
    expect(find.text('Onchain'), findsNothing);
    expect(find.textContaining('failed-peer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
