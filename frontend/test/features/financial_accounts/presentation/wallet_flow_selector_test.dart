import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_hold_selection_tile.dart';
import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_flow_selector.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wallet flow selector uses centered vertical hold layout',
      (tester) async {
    Wallet? selectedWallet;

    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      wallets: mockWallets,
      onContinue: (wallet) => selectedWallet = wallet,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GridView), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.text('Enviar'), findsNothing);
    expect(find.text('CONTINUAR'), findsNothing);
    expect(find.text('Reserva principal'), findsOneWidget);
    expect(find.text('Cold vault'), findsOneWidget);
    expect(find.textContaining('BTC'), findsWidgets);

    final firstTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${mockWallets.first.id}')),
    );
    final secondTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${mockWallets[1].id}')),
    );
    expect(firstTile.top, lessThan(secondTile.top));
    expect(firstTile.width, greaterThan(secondTile.width));
    expect(firstTile.center.dx, closeTo(215, 1));
    expect(secondTile.center.dx, closeTo(215, 1));

    final holdGesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(ValueKey('wallet-flow-tile-${mockWallets[1].id}')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final expandedSecondTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${mockWallets[1].id}')),
    );
    expect(expandedSecondTile.width, greaterThan(secondTile.width));

    await tester.pump(kWalletHoldSelectionDuration);
    await holdGesture.up();
    await tester.pumpAndSettle();

    expect(selectedWallet?.id, mockWallets[1].id);
  });

  testWidgets('wallet flow selector keeps three wallets vertical and fitted',
      (tester) async {
    Wallet? selectedWallet;
    final wallets = [
      ...mockWallets,
      mockWallets.first.copyWith(
        id: 'story-wallet-travel',
        name: 'Travel wallet',
        address: 'bc1qstorybooktravel000000000000000000000',
        balance: 0.011,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      wallets: wallets,
      onContinue: (wallet) => selectedWallet = wallet,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ListView), findsNothing);
    expect(find.text('Travel wallet'), findsOneWidget);

    final firstTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets.first.id}')),
    );
    final thirdTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets[2].id}')),
    );
    final secondTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets[1].id}')),
    );
    expect(firstTile.top, lessThan(secondTile.top));
    expect(secondTile.top, lessThan(thirdTile.top));
    expect(thirdTile.bottom, lessThanOrEqualTo(900));

    await _holdWallet(tester, wallets[2].id);

    expect(selectedWallet?.id, wallets[2].id);
  });

  testWidgets('wallet flow selector uses full-height layout for one wallet',
      (tester) async {
    Wallet? selectedWallet;
    final wallets = [mockWallets.first];

    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      wallets: wallets,
      onContinue: (wallet) => selectedWallet = wallet,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GridView), findsNothing);
    expect(find.text('Reserva principal'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsNothing);

    final tile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets.first.id}')),
    );
    expect(tile.center.dx, closeTo(215, 1));
    expect(tile.width, greaterThan(390));

    await _holdWallet(tester, wallets.first.id);

    expect(selectedWallet?.id, wallets.first.id);
  });

  testWidgets('wallet flow selector keeps inactive wallets visible',
      (tester) async {
    final wallets = [
      mockWallets.first.copyWith(isActive: false),
      mockWallets[1],
    ];

    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      wallets: wallets,
      onContinue: (_) {},
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reserva principal'), findsOneWidget);
    expect(find.text('Cold vault'), findsOneWidget);
  });

  testWidgets('wallet flow selector shows wallet name and BTC balance',
      (tester) async {
    final wallets = [
      Wallet(
        id: 'wallet-global',
        name: 'Carteira Global',
        address: 'kerosene:global',
        walletMode: 'INTERNAL',
        balance: 0.01,
        derivationPath: "m/84'/0'/0'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      ),
      Wallet(
        id: 'wallet-custodial',
        name: 'Reserva on-chain',
        address: 'bc1qcustodial',
        walletMode: 'CUSTODIAL_ONCHAIN',
        balance: 0.02,
        derivationPath: "m/84'/0'/1'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      wallets: wallets,
      onContinue: (_) {},
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Carteira Global'), findsOneWidget);
    expect(find.text('Reserva on-chain'), findsOneWidget);
    expect(find.textContaining('BTC'), findsNWidgets(2));
    expect(find.text('Carteira global'), findsNothing);
    expect(find.text('Custodial on-chain'), findsNothing);
    expect(find.text('KEROSENE'), findsNothing);
  });
}

Future<void> _holdWallet(WidgetTester tester, String walletId) async {
  final finder = find.byKey(ValueKey('wallet-flow-tile-$walletId'));
  final gesture = await tester.startGesture(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump(kWalletHoldSelectionDuration);
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _pumpSelector(
  WidgetTester tester, {
  required List<Wallet> wallets,
  required ValueChanged<Wallet> onContinue,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletProvider.overrideWith(() => _WalletTestNotifier(wallets)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: false).copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WalletFlowSelector(
          title: 'Enviar',
          subtitle: 'Escolha de qual carteira o envio vai sair.',
          initialWallet: wallets.first,
          onContinue: onContinue,
        ),
      ),
    ),
  );
}

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

  @override
  Future<void> refresh() async {
    state = WalletLoaded(
      wallets: wallets,
      selectedWallet: wallets.firstOrNull,
      btcToUsdRate: 65000,
    );
  }

  @override
  void selectWallet(Wallet wallet) {
    state = WalletLoaded(
      wallets: wallets,
      selectedWallet: wallet,
      btcToUsdRate: 65000,
    );
  }
}
