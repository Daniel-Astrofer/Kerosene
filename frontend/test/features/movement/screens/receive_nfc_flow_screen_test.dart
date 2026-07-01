import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/screens/receive_nfc_flow_screen.dart';

void main() {
  testWidgets('starts NFC receive flow with method selection', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Selecionar método'), findsOneWidget);
    expect(find.text('Direct'), findsWidgets);
    expect(find.text('Lightning'), findsWidgets);
    expect(find.text('On-chain'), findsWidgets);
    expect(find.text('Detectar\nautomaticamente'), findsOneWidget);
  });

  testWidgets('shows detected Lightning transaction with fee details',
      (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Lightning').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.text('Transação Lightning detectada'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.text('Transação reconhecida'), findsOneWidget);
    expect(find.text('Lightning'), findsWidgets);
    expect(find.text('Taxa Lightning'), findsOneWidget);
  });

  testWidgets('shows direct transaction details without network fee',
      (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Direct').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4200));

    expect(find.text('Transação reconhecida'), findsOneWidget);
    expect(find.text('Direct'), findsWidgets);
    expect(find.text('Taxa Lightning'), findsNothing);
    expect(find.text('Taxa de rede'), findsNothing);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false).copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReceiveNfcFlowScreen(
        wallet: _wallet(),
        onChainWallet: false,
        amountBtc: 0.0042,
        supportsNfc: () async => true,
      ),
    ),
  );
  await tester.pump();
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
