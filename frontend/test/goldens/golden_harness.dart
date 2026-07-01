import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/providers/appearance_provider.dart';
import 'package:kerosene/core/providers/biometric_provider.dart';
import 'package:kerosene/core/providers/locale_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/data/datasources/auth_remote_datasource.dart'
    show AccountSecurityStatusResult, BackupCodesStatusResult;
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/balance_settings_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

late SharedPreferences goldenSharedPreferences;

Future<void> initializeGoldenHarness() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(const {});
  FlutterSecureStorage.setMockInitialValues({});
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

Future<void> pumpGoldenAnimationFrame(WidgetTester tester) {
  return tester.pump(const Duration(milliseconds: 120));
}

Widget wrapGolden(Widget child) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(goldenSharedPreferences),
      sessionStorageScopeProvider.overrideWithValue('golden-session'),
      networkStatusProvider.overrideWith(() => NetworkStatusNotifier()),
      bitcoinAccountsServiceProvider
          .overrideWithValue(MockBitcoinAccountsService()),
      bitcoinAccountsProvider.overrideWith(BitcoinAccountsNotifier.new),
      sovereigntyStatusProvider.overrideWith((ref) async => mockSecurityStatus),
      kfeReserveOverviewProvider
          .overrideWith((ref) async => mockKfeReserveOverview),
      auditStatsProvider.overrideWith((ref) async => mockSecurityAuditStats),
      accountSecurityProfileProvider
          .overrideWith((ref) async => mockAccountSecurityProfile),
      appPinStatusProvider.overrideWith((ref) async => mockAppPinStatus),
      adminKeyStatusProvider.overrideWith((ref) async => mockAdminKeyStatus),
      pendingAdminAccessAttemptsProvider
          .overrideWith((ref) async => mockAdminAccessAttempts),
      adminAuthenticatedDevicesProvider
          .overrideWith((ref) async => mockAdminDevices),
      appearanceProvider.overrideWith(() => _GoldenAppearanceNotifier()),
      localeProvider.overrideWith(() => _GoldenLocaleNotifier()),
      authControllerProvider.overrideWith(
        () => MockAuthController(initialOverride: mockAuthenticatedState),
      ),
      securityStatusProvider.overrideWith(
        (ref) async => const AccountSecurityStatusResult(
          passwordConfigured: true,
          passkeyRegistered: true,
          totpEnabled: true,
          backupCodesRemaining: 8,
          unprotected: false,
          accountActivated: true,
          inboundEnabled: true,
        ),
      ),
      backupCodesStatusProvider.overrideWith(
        (ref) async => const BackupCodesStatusResult(
          enabled: true,
          remainingCodes: 8,
        ),
      ),
      balanceSettingsProvider
          .overrideWith(() => _GoldenBalanceSettingsNotifier()),
      biometricProvider.overrideWith(() => _GoldenBiometricNotifier()),
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

class _EmptyNotificationFeedNotifier extends SessionNotificationFeedNotifier {
  @override
  List<SessionNotificationItem> build() => const [];
}

class _GoldenBiometricNotifier extends BiometricNotifier {
  @override
  BiometricState build() {
    return const BiometricState(
      isEnabled: false,
      isSupported: false,
      isLoading: false,
    );
  }
}
