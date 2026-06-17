import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/providers/appearance_provider.dart';
import 'package:kerosene/core/providers/locale_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/presentation/providers/balance_settings_provider.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

late SharedPreferences goldenSharedPreferences;
late http.Client _goldenFontHttpClient;

Future<void> initializeGoldenHarness() async {
  final fontBytes =
      (await rootBundle.load('assets/google_fonts/Inter-Regular.ttf'))
          .buffer
          .asUint8List();
  _goldenFontHttpClient = _GoldenFontHttpClient(fontBytes);
  GoogleFonts.config.allowRuntimeFetching = true;
  GoogleFonts.config.httpClient = _goldenFontHttpClient;
  SharedPreferences.setMockInitialValues(const {});
  goldenSharedPreferences = await SharedPreferences.getInstance();
}

Future<void> pumpFullScreenGolden(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(430, 6000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrapGolden(child));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Widget wrapGolden(Widget child) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(goldenSharedPreferences),
      appearanceProvider.overrideWith(() => _GoldenAppearanceNotifier()),
      localeProvider.overrideWith(() => _GoldenLocaleNotifier()),
      authControllerProvider.overrideWith(
        () => MockAuthController(initialOverride: mockAuthenticatedState),
      ),
      balanceSettingsProvider.overrideWith(() => _GoldenBalanceSettingsNotifier()),
      walletProvider.overrideWith(() => MockWalletNotifier()),
      sessionNotificationFeedProvider.overrideWith(
        () => _EmptyNotificationFeedNotifier(),
      ),
      transactionHistoryProvider.overrideWith((ref) async => mockTransactions),
      depositsProvider.overrideWith((ref) async => mockDeposits),
      priceWebSocketServiceProvider
          .overrideWithValue(MockPriceWebSocketService()),
      backendBtcRatesProvider.overrideWith(
        (ref) async => const BackendBtcRates(
          btcUsd: 67234.5,
          btcBrl: 336172.5,
          btcEur: 62109.0,
          usdBrl: 5.0,
        ),
      ),
      btcPriceProvider.overrideWith((ref) => Stream.value(67234.5)),
      btcBrlPriceProvider.overrideWithValue(336172.5),
      btcEurPriceProvider.overrideWithValue(62109.0),
      latestBtcPriceProvider.overrideWithValue(67234.5),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _GoldenAppearanceNotifier extends AppearanceNotifier {
  @override
  AppearanceState build() {
    return const AppearanceState(
      themeVariant: AppThemeVariant.dark,
      fontScale: AppFontScale.normal,
    );
  }
}

class _GoldenLocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() {
    return LocaleState(const Locale('pt'));
  }
}

class _GoldenBalanceSettingsNotifier extends BalanceSettingsNotifier {
  @override
  BalanceSettings build() {
    return const BalanceSettings(
      isHidden: false,
      decimalPlaces: 8,
    );
  }
}

class _EmptyNotificationFeedNotifier
    extends SessionNotificationFeedNotifier {
  @override
  List<SessionNotificationItem> build() => const [];
}

class _GoldenFontHttpClient extends http.BaseClient {
  final List<int> _fontBytes;

  _GoldenFontHttpClient(this._fontBytes);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(_fontBytes),
      200,
      request: request,
      headers: const {'content-type': 'font/ttf'},
    );
  }
}
