import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/wallet/presentation/state/wallet_state.dart';
import 'package:kerosene/features/wallet/presentation/widgets/wallet_flow_selector.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wallet flow selector uses full-height two column layout',
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
    expect(
        find.text('Escolha de qual carteira o envio vai sair.'), findsNothing);
    expect(find.text('Reserva\nprincipal'), findsOneWidget);
    expect(find.text('Cold\nvault'), findsOneWidget);
    expect(find.text('SALDO DISPONÍVEL'), findsWidgets);

    final firstTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${mockWallets.first.id}')),
    );
    final secondTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${mockWallets[1].id}')),
    );
    expect(firstTile.top, closeTo(64, 1));
    expect(firstTile.bottom, closeTo(900, 1));
    expect(firstTile.width, closeTo(215, 1));
    expect(secondTile.top, closeTo(firstTile.top, 1));
    expect(secondTile.bottom, closeTo(firstTile.bottom, 1));

    await tester
        .tap(find.byKey(ValueKey('wallet-flow-tile-${mockWallets[1].id}')));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();

    expect(selectedWallet?.id, mockWallets[1].id);
  });

  testWidgets('wallet flow selector uses two column layout for three wallets',
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
    expect(find.text('Travel\nwallet'), findsOneWidget);

    final firstTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets.first.id}')),
    );
    final thirdTile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets[2].id}')),
    );
    expect(firstTile.top, closeTo(64, 1));
    expect(firstTile.bottom, closeTo(900, 1));
    expect(thirdTile.top, closeTo(firstTile.top, 1));

    await tester.tap(find.byKey(ValueKey('wallet-flow-tile-${wallets[2].id}')));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();

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
    expect(find.text('Reserva\nprincipal'), findsOneWidget);

    final tile = tester.getRect(
      find.byKey(ValueKey('wallet-flow-tile-${wallets.first.id}')),
    );
    expect(tile.top, closeTo(64, 1));
    expect(tile.bottom, closeTo(900, 1));
    expect(tile.width, closeTo(430, 1));

    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();

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

    expect(find.text('Reserva\nprincipal'), findsOneWidget);
    expect(find.text('Cold\nvault'), findsOneWidget);
  });

  testWidgets('wallet flow selector shows wallet name and custody label',
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

    expect(find.text('Carteira\nGlobal'), findsOneWidget);
    expect(find.text('Carteira global'), findsOneWidget);
    expect(find.text('Reserva\non-chain'), findsOneWidget);
    expect(find.text('Custodial on-chain'), findsOneWidget);
    expect(find.text('KEROSENE'), findsNothing);
  });
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
