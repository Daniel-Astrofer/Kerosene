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
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_activity/presentation/screens/deposits_screen.dart';
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

  testWidgets('statement report is analytics-only and wallet-reactive',
      (tester) async {
    await pumpStatement(tester, wallets: wallets, transactions: transactions);

    expect(find.text('Relatório de movimentação'), findsOneWidget);
    expect(find.text('Volume de movimentação'), findsOneWidget);
    expect(find.text('Distribuição de fundos'), findsOneWidget);
    expect(find.text('Carteira Global'), findsWidgets);
    expect(find.text('Reserva fria'), findsOneWidget);

    expect(find.byIcon(KeroseneIcons.search), findsNothing);
    expect(find.text('Todas'), findsNothing);
    expect(find.text('Recebidas'), findsNothing);
    expect(find.text('Lightning'), findsNothing);
    expect(find.text('Onchain'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statement period selector updates the report in place',
      (tester) async {
    await pumpStatement(tester, wallets: wallets, transactions: transactions);

    expect(find.text('Últimos 6 meses'), findsOneWidget);

    await tester.tap(find.text('Últimos 6 meses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ano atual').last);
    await tester.pumpAndSettle();

    expect(find.text('Ano atual'), findsOneWidget);
    expect(find.text('Relatório de movimentação'), findsOneWidget);
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
