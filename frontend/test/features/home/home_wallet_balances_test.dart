import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home carousel starts with total balance then wallet card',
      (tester) async {
    await _pumpHome(tester, wallets: [_wallet(name: 'Carteira Global')]);

    expect(find.text('SALDO TOTAL'), findsOneWidget);
    expect(find.text('Carteira Global'), findsNothing);
    expect(find.byKey(const ValueKey('home-balance-carousel')), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('home-balance-carousel')),
        const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Carteira Global'), findsOneWidget);
    expect(find.text('CARTEIRA GLOBAL'), findsOneWidget);
  });

  testWidgets('home carousel lists backend wallets with balances and custody',
      (tester) async {
    await _pumpHome(
      tester,
      wallets: [
        _wallet(name: 'Carteira Global', balance: 0.1),
        _wallet(
          id: 'wallet-cold',
          name: 'Cold vault',
          walletMode: 'WATCH_ONLY',
          balance: 0.2,
        ),
      ],
    );

    expect(find.text('SALDO TOTAL'), findsOneWidget);
    expect(find.text('Carteira Global'), findsNothing);
    expect(find.text('Cold vault'), findsNothing);
    expect(find.byKey(const ValueKey('home-balance-carousel')), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('home-balance-carousel')),
        const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Carteira Global'), findsOneWidget);
    expect(find.text('CARTEIRA GLOBAL'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('home-balance-carousel')),
        const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Cold vault'), findsOneWidget);
    expect(find.text('COLD WALLET'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required List<Wallet> wallets,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final sharedPreferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authControllerProvider.overrideWith(() => _AuthTestController()),
        walletProvider.overrideWith(() => _WalletTestNotifier(wallets)),
        sessionNotificationFeedProvider.overrideWith(
          () => _EmptyNotificationFeedNotifier(),
        ),
        transactionHistoryProvider.overrideWith((ref) async => const []),
        depositsProvider.overrideWith((ref) async => const []),
        depositBalanceProvider.overrideWith((ref) async => 0),
        latestBtcPriceProvider.overrideWith((ref) => 65000),
        btcEurPriceProvider.overrideWith((ref) => 60000),
        btcBrlPriceProvider.overrideWith((ref) => 350000),
        btcDailyChangePercentProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Wallet _wallet({
  String id = 'wallet-global',
  required String name,
  String walletMode = 'INTERNAL',
  double balance = 0.1,
}) {
  return Wallet(
    id: id,
    name: name,
    address: 'kerosene:$id',
    walletMode: walletMode,
    balance: balance,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

class _AuthTestController extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(
        User(
          id: 'user-1',
          username: 'Satoshi Nakamoto',
          createdAt: DateTime(2026, 1, 1),
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
}

class _EmptyNotificationFeedNotifier extends SessionNotificationFeedNotifier {
  @override
  List<SessionNotificationItem> build() => const [];
}
