import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/financial_activity/presentation/screens/deposits_screen.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';

void main() {
  testWidgets('lists up to three receive wallets from the wallet provider',
      (tester) async {
    await _pumpDepositsScreen(tester, initialWallet: _internalWallet());

    expect(find.text('Gateway de pagamento'), findsOneWidget);
    expect(find.text('P2P'), findsOneWidget);
    expect(find.text('QR Code'), findsOneWidget);
    expect(find.text('Link de pagamento'), findsOneWidget);
    expect(find.text('NFC'), findsOneWidget);
  });

  testWidgets('filters receive methods by selected wallet type',
      (tester) async {
    await _pumpDepositsScreen(tester, initialWallet: _internalWallet());

    expect(find.text('Gateway de pagamento'), findsOneWidget);
    expect(find.text('P2P'), findsOneWidget);

    await _pumpDepositsScreen(tester, initialWallet: _onchainWallet());
    await tester.pumpAndSettle();

    expect(find.text('Gateway de pagamento'), findsNothing);
    expect(find.text('QR Code'), findsOneWidget);
    expect(find.text('Link de pagamento'), findsOneWidget);
    expect(find.text('NFC'), findsNothing);

    await _pumpDepositsScreen(tester, initialWallet: _coldWallet());
    await tester.pumpAndSettle();

    expect(find.text('Gateway de pagamento'), findsNothing);
    expect(find.text('P2P'), findsNothing);
    expect(find.text('QR Code'), findsOneWidget);
    expect(find.text('Link de pagamento'), findsOneWidget);
    expect(find.text('NFC'), findsNothing);
  });
}

Future<void> _pumpDepositsScreen(
  WidgetTester tester, {
  required Wallet initialWallet,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletProvider.overrideWith(
          () => _WalletTestNotifier([initialWallet]),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: false).copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DepositsScreen(initialWallet: initialWallet),
      ),
    ),
  );
}

Wallet _wallet({
  required String id,
  required String name,
  required String mode,
}) {
  return Wallet(
    id: id,
    name: name,
    address: 'bc1q$id',
    walletMode: mode,
    balance: 0.1,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

Wallet _internalWallet() => _wallet(
      id: 'internal-wallet',
      name: 'Carteira Global',
      mode: 'KEROSENE',
    );

Wallet _onchainWallet() => _wallet(
      id: 'custodial-onchain-wallet',
      name: 'On-chain',
      mode: 'CUSTODIAL_ONCHAIN',
    );

Wallet _coldWallet() => _wallet(
      id: 'cold-wallet',
      name: 'Coldwallet',
      mode: 'SELF_CUSTODY',
    );

class _WalletTestNotifier extends WalletNotifier {
  final List<Wallet> wallets;

  _WalletTestNotifier(this.wallets);

  @override
  WalletState build() {
    return WalletLoaded(
      wallets: wallets,
      selectedWallet: wallets.firstOrNull,
      btcToUsdRate: 65000,
    );
  }
}
