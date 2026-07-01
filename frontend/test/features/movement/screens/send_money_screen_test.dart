import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/movement/domain/repositories/transaction_repository.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart'
    as transaction_providers;
import 'package:kerosene/app/providers/kfe_receiving_capabilities_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import 'package:kerosene/features/movement/screens/send_money_screen.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';

void main() {
  testWidgets('shows transfer destination screen with frequent contacts',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(() => _WalletTestNotifier([_wallet()])),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          recentTransactionDestinationsProvider.overrideWith(
            () => _RecentDestinationsNotifier([
              RecentTransactionDestination(
                address: 'edinaldo_bezerra',
                label: 'Edinaldo Bezerra',
                kind: RecentTransactionDestinationKind.internal,
                lastUsedAt: DateTime(2026, 6, 16),
              ),
              RecentTransactionDestination(
                address: 'willyan_miranda',
                label: 'Willyan Miranda',
                kind: RecentTransactionDestinationKind.internal,
                lastUsedAt: DateTime(2026, 6, 15),
              ),
              RecentTransactionDestination(
                address: 'mateus_franco',
                label: 'Mateus Franco Bezerra',
                kind: RecentTransactionDestinationKind.internal,
                lastUsedAt: DateTime(2026, 6, 14),
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: false).copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendMoneyScreen(walletId: _wallet().id),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Para quem deseja enviar?'), findsOneWidget);
    expect(find.text('Usuário, endereço Bitcoin ou link'), findsWidgets);
    expect(find.text('Destinos frequentes'), findsOneWidget);
    expect(find.text('Todos os destinos'), findsOneWidget);
    expect(find.text('Edinaldo Bezerra'), findsWidgets);
    expect(find.text('Willyan Miranda'), findsWidgets);
    expect(find.text('Mateus Franco Bezerra'), findsWidgets);
    expect(find.text('QR Code'), findsNothing);
    expect(find.text('NFC'), findsNothing);
    expect(find.text('CONTINUAR'), findsOneWidget);

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.textAlign, TextAlign.left);
    expect(input.decoration?.hintText, 'Usuário, endereço Bitcoin ou link');
  });

  testWidgets('shows transfer destination screen with empty contacts state',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(() => _WalletTestNotifier([_wallet()])),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          recentTransactionDestinationsProvider.overrideWith(
            () => _EmptyRecentDestinationsNotifier(),
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: false).copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendMoneyScreen(walletId: _wallet().id),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Para quem deseja enviar?'), findsOneWidget);
    expect(find.text('Usuário, endereço Bitcoin ou link'), findsWidgets);
    expect(find.text('Nenhum destino recente ainda.'), findsOneWidget);
    expect(
      find.text(
          'Informe um usuário, endereço ou link para iniciar seu primeiro envio.'),
      findsOneWidget,
    );
    expect(find.text('QR Code'), findsNothing);
    expect(find.text('NFC'), findsNothing);
    expect(find.text('CONTINUAR'), findsOneWidget);

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.textAlign, TextAlign.left);
    expect(input.decoration?.hintText, 'Usuário, endereço Bitcoin ou link');
  });

  testWidgets('amount step native field updates the send amount',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(() => _WalletTestNotifier([_wallet()])),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          recentTransactionDestinationsProvider.overrideWith(
            () => _RecentDestinationsNotifier([
              RecentTransactionDestination(
                address: '34b5cc23-e18e-4f32-8414-9844e7300c25',
                label: 'Minecraft',
                kind: RecentTransactionDestinationKind.internal,
                lastUsedAt: DateTime(2026, 6, 19),
              ),
            ]),
          ),
          kfeReceivingCapabilitiesServiceProvider.overrideWithValue(
            const _ReadyKfeReceivingCapabilitiesService(),
          ),
          transaction_providers.transactionRepositoryProvider.overrideWithValue(
            const _UnusedTransactionRepository(),
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: false).copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendMoneyScreen(walletId: _wallet().id),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Minecraft').first);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    final amountInput = find.byKey(const ValueKey('movement-amount-input'));
    await tester.ensureVisible(amountInput);
    await tester.enterText(amountInput, '100000000');
    await tester.pump();

    expect(find.textContaining('350.000,00'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'CONTINUAR'),
    );
    expect(continueButton.onPressed, isNotNull);
  });

  testWidgets('blocks internal wallet UUID when KFE verification rejects it',
      (tester) async {
    const missingWalletId = '34b5cc23-e18e-4f32-8414-9844e7300c25';
    final capabilitiesService = _NotReadyKfeReceivingCapabilitiesService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(() => _WalletTestNotifier([_wallet()])),
          latestBtcPriceProvider.overrideWith((ref) => 65000),
          btcEurPriceProvider.overrideWith((ref) => 60000),
          btcBrlPriceProvider.overrideWith((ref) => 350000),
          recentTransactionDestinationsProvider.overrideWith(
            () => _EmptyRecentDestinationsNotifier(),
          ),
          kfeReceivingCapabilitiesServiceProvider.overrideWithValue(
            capabilitiesService,
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: false).copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendMoneyScreen(walletId: _wallet().id),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField).first, missingWalletId);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(capabilitiesService.calls, 1);
    expect(capabilitiesService.lastReceiverIdentifier, missingWalletId);
    expect(find.byKey(const ValueKey('movement-amount-input')), findsNothing);

    await tester.pump(const Duration(seconds: 4));
  });
}

Wallet _wallet() {
  return Wallet(
    id: '61a8bb23-e18e-4f32-8414-9844e7300c14',
    name: 'Carteira Global',
    address: '61a8bb23-e18e-4f32-8414-9844e7300c14',
    walletMode: 'KEROSENE',
    balance: 0.1,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
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
      selectedWallet: wallets.firstOrNull,
      btcToUsdRate: 65000,
    );
  }
}

class _EmptyRecentDestinationsNotifier
    extends RecentTransactionDestinationsNotifier {
  @override
  List<RecentTransactionDestination> build() {
    return const [];
  }
}

class _RecentDestinationsNotifier
    extends RecentTransactionDestinationsNotifier {
  final List<RecentTransactionDestination> destinations;

  _RecentDestinationsNotifier(this.destinations);

  @override
  List<RecentTransactionDestination> build() {
    return destinations;
  }
}

class _ReadyKfeReceivingCapabilitiesService
    implements KfeReceivingCapabilitiesService {
  const _ReadyKfeReceivingCapabilitiesService();

  @override
  Future<KfeReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  ) async {
    return const KfeReceivingCapabilities(
      canReceiveInternal: true,
      canReceiveLightning: false,
      canReceiveOnchain: false,
      preferredRail: 'INTERNAL',
      missingRequirements: [],
      receiverDisplayName: '@minecraft',
      internalWalletId: '8ad5c8f0-7b7a-4f44-82f8-f916f49bd54f',
      availableRails: ['INTERNAL'],
    );
  }
}

class _NotReadyKfeReceivingCapabilitiesService
    implements KfeReceivingCapabilitiesService {
  int calls = 0;
  String? lastReceiverIdentifier;

  @override
  Future<KfeReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  ) async {
    calls++;
    lastReceiverIdentifier = receiverIdentifier;
    return const KfeReceivingCapabilities(
      canReceiveInternal: false,
      canReceiveLightning: false,
      canReceiveOnchain: false,
      preferredRail: '',
      missingRequirements: ['KFE_INTERNAL_WALLET_NOT_FOUND'],
      receiverDisplayName: '@missing',
      availableRails: [],
    );
  }
}

class _UnusedTransactionRepository implements TransactionRepository {
  const _UnusedTransactionRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
