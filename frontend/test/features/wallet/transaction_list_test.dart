import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/wallet_transaction_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a helpful empty state', (tester) async {
    await _pumpList(tester, const TransactionList());

    expect(find.text('Sem transações ainda'), findsOneWidget);
    expect(
      find.textContaining('o histórico aparece aqui'),
      findsOneWidget,
    );
  });

  testWidgets('shows loading state before transactions arrive', (tester) async {
    await _pumpList(tester, const TransactionList(isLoading: true));

    expect(find.text('Carregando transações'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows retry action after an empty load error', (tester) async {
    var retries = 0;

    await _pumpList(
      tester,
      TransactionList(
        errorMessage: 'Servidor indisponível',
        onRetry: () => retries++,
      ),
    );

    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Servidor indisponível'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('renders transaction rows when history exists', (tester) async {
    await _pumpList(
      tester,
      TransactionList(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        transactions: [
          _transaction(
            id: 'incoming-1',
            amountSatoshis: 150000,
            type: TransactionType.receive,
            toAddress: 'bc1qreceiveaddress',
          ),
          _transaction(
            id: 'outgoing-1',
            amountSatoshis: 70000,
            type: TransactionType.send,
            fromAddress: 'bc1qsendaddress',
          ),
        ],
      ),
    );

    expect(
        find.byKey(const ValueKey('transaction-list-items')), findsOneWidget);
    expect(find.text('Recebimento on-chain'), findsOneWidget);
    expect(find.text('Envio on-chain'), findsOneWidget);
    expect(find.textContaining('+'), findsWidgets);
    expect(find.textContaining('-'), findsWidgets);
  });
}

Future<void> _pumpList(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues(const {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        latestBtcPriceProvider.overrideWith((ref) => 65000),
        btcEurPriceProvider.overrideWith((ref) => 60000),
        btcBrlPriceProvider.overrideWith((ref) => 350000),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: false).copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

Transaction _transaction({
  required String id,
  required int amountSatoshis,
  required TransactionType type,
  String fromAddress = 'bc1qsourceaddress',
  String toAddress = 'bc1qdestinationaddress',
}) {
  return Transaction(
    id: id,
    fromAddress: fromAddress,
    toAddress: toAddress,
    amountSatoshis: amountSatoshis,
    feeSatoshis: 1200,
    status: TransactionStatus.confirmed,
    type: type,
    confirmations: 6,
    timestamp: DateTime(2026, 6, 15, 12),
  );
}
