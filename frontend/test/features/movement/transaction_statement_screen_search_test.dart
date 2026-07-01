import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/screens/movement_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final wallets = [
    _wallet(
      id: 'wallet-global',
      name: 'Carteira Global',
      address: 'kerosene:global',
      balance: 0.015,
    ),
    _wallet(
      id: 'wallet-cold',
      name: 'Reserva fria',
      address: 'bc1qcoldreserve',
      balance: 0.005,
      walletMode: 'WATCH_ONLY',
    ),
  ];

  final transactions = [
    Transaction(
      id: 'statement-global-in',
      fromAddress: 'external',
      toAddress: 'kerosene:global',
      walletId: 'wallet-global',
      destinationWalletId: 'wallet-global',
      amountSatoshis: 850000,
      feeSatoshis: 0,
      status: TransactionStatus.confirmed,
      type: TransactionType.deposit,
      confirmations: 6,
      timestamp: DateTime(2026, 5, 20, 12),
    ),
    Transaction(
      id: 'statement-cold-out',
      fromAddress: 'bc1qcoldreserve',
      toAddress: 'external',
      walletId: 'wallet-cold',
      sourceWalletId: 'wallet-cold',
      amountSatoshis: 120000,
      feeSatoshis: 900,
      status: TransactionStatus.confirmed,
      type: TransactionType.withdrawal,
      confirmations: 6,
      timestamp: DateTime(2026, 5, 21, 12),
    ),
  ];

  testWidgets('statement opens as searchable bank-style transaction list',
      (tester) async {
    await pumpStatement(tester, wallets: wallets, transactions: transactions);

    expect(find.text('Extrato'), findsWidgets);
    expect(find.byIcon(KeroseneIcons.search), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Recebidos'), findsOneWidget);
    expect(find.text('Enviados'), findsOneWidget);
    expect(find.text('Pendentes'), findsOneWidget);
    expect(find.text('Falhas'), findsOneWidget);
    expect(find.text('On-chain'), findsOneWidget);
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('Internas'), findsOneWidget);
    expect(find.text('20 de mai. de 2026'), findsOneWidget);
    expect(find.text('21 de mai. de 2026'), findsOneWidget);
    expect(find.text('Recebido'), findsOneWidget);
    expect(find.text('Saque on-chain'), findsOneWidget);

    expect(find.text('Volume de movimentação'), findsNothing);
    expect(find.text('Distribuição de fundos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement filters and search narrow visible transactions',
      (tester) async {
    await pumpStatement(tester, wallets: wallets, transactions: transactions);

    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();

    expect(find.text('Saque on-chain'), findsOneWidget);
    expect(find.text('Recebido'), findsNothing);

    await tester.enterText(find.byType(TextField), 'global');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement keeps analytics in the secondary insights tab',
      (tester) async {
    await pumpStatement(tester, wallets: wallets, transactions: transactions);

    expect(find.text('Volume de movimentação'), findsNothing);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Volume de movimentação'), findsOneWidget);
    expect(find.text('Distribuição de fundos'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Base auditada'), findsOneWidget);
    expect(find.text('2 carteiras'), findsOneWidget);
    expect(find.text('2 transações consideradas'), findsOneWidget);
    expect(find.text('0 falhas ignoradas'), findsOneWidget);
    expect(find.text('Maior fatia'), findsOneWidget);
    expect(find.text('0.015000 BTC'), findsOneWidget);
    expect(find.text('Carteira Global'), findsWidgets);
    expect(find.text('Reserva fria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpStatement(
  WidgetTester tester, {
  required List<Wallet> wallets,
  required List<Transaction> transactions,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final sharedPreferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        walletProvider.overrideWith(() => _WalletTestNotifier(wallets)),
        transactionHistoryProvider.overrideWith((ref) async => transactions),
        latestBtcPriceProvider.overrideWith((ref) => 76500),
        btcEurPriceProvider.overrideWith((ref) => 70000),
        btcBrlPriceProvider.overrideWith((ref) => 420000),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TransactionStatementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Wallet _wallet({
  required String id,
  required String name,
  required String address,
  required double balance,
  String walletMode = 'KEROSENE',
}) {
  return Wallet(
    id: id,
    name: name,
    address: address,
    walletMode: walletMode,
    balance: balance,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

class _WalletTestNotifier extends WalletNotifier {
  final List<Wallet> wallets;

  _WalletTestNotifier(this.wallets);

  @override
  WalletState build() {
    return WalletLoaded(
      wallets: wallets,
      selectedWallet: wallets.isEmpty ? null : wallets.first,
      btcToUsdRate: 76500,
    );
  }

  @override
  Future<void> refresh() async {
    state = WalletLoaded(
      wallets: wallets,
      selectedWallet: wallets.isEmpty ? null : wallets.first,
      btcToUsdRate: 76500,
    );
  }
}
