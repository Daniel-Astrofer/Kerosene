import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';

import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'storybook_mocks.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    show walletProvider;
import 'package:kerosene/features/web/providers/admin_providers.dart';
import 'package:kerosene/features/web/screens/notifications/notifications_screen.dart';

import 'stories/admin_stories.dart';
import 'stories/app_flow_story.dart';
import 'stories/bitcoin_advanced_stories.dart';
import 'stories/receive_stories.dart';

/// The root Storybook widget for Kerosene.
class KeroseneStorybook extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const KeroseneStorybook({
    super.key,
    required this.sharedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return Storybook(
      wrapperBuilder: (context, child) {
        final language = context.knobs.options(
          label: 'Language',
          initial: 'pt',
          options: const [
            Option(label: 'Portuguese', value: 'pt'),
            Option(label: 'English', value: 'en'),
          ],
        );

        final authStateLabel = context.knobs.options(
          label: 'Auth State',
          initial: 'Initial',
          options: const [
            Option(label: 'Initial', value: 'initial'),
            Option(label: 'Authenticated', value: 'auth'),
            Option(label: 'Unauthenticated', value: 'unauth'),
            Option(label: 'Error', value: 'error'),
          ],
        );

        return ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            authControllerProvider.overrideWith(() {
              if (authStateLabel == 'auth') {
                return MockAuthController(
                    initialOverride: mockAuthenticatedState);
              }
              if (authStateLabel == 'unauth') {
                return MockAuthController(
                    initialOverride: const AuthUnauthenticated());
              }
              if (authStateLabel == 'error') {
                return MockAuthController(
                    initialOverride: const AuthError('MOCK ERROR'));
              }
              return MockAuthController();
            }),
            backendBtcRatesProvider.overrideWith(
              (ref) async => const BackendBtcRates(
                btcUsd: 65000,
                btcBrl: 325000,
                btcEur: 60000,
                usdBrl: 5,
              ),
            ),
            btcPriceProvider.overrideWith((ref) => Stream.value(65000.0)),
            btcBrlPriceProvider.overrideWithValue(325000.0),
            btcEurPriceProvider.overrideWithValue(60000.0),
            latestBtcPriceProvider.overrideWithValue(65000.0),
            priceWebSocketServiceProvider
                .overrideWithValue(MockPriceWebSocketService()),
            networkStatusProvider.overrideWith(() => NetworkStatusNotifier()),
            walletProvider.overrideWith(() => MockWalletNotifier()),
            bitcoinAccountsServiceProvider
                .overrideWithValue(MockBitcoinAccountsService()),
            transactionRepositoryProvider
                .overrideWithValue(MockTransactionRepository()),
            transactionHistoryProvider.overrideWith(
              (ref) async => mockTransactions,
            ),
            pagedTransactionHistoryProvider.overrideWith(
              (ref, request) async =>
                  mockTransactions.take(request.size).toList(),
            ),
            depositsProvider.overrideWith((ref) async => mockDeposits),
            paymentLinksProvider.overrideWith((ref) async => mockPaymentLinks),
            externalTransfersProvider
                .overrideWith((ref) async => mockExternalTransfers),
            notificationRepositoryProvider
                .overrideWithValue(MockNotificationRepository()),
            sovereigntyStatusProvider
                .overrideWith((ref) async => mockSecurityStatus),
            kfeReserveOverviewProvider
                .overrideWith((ref) async => mockKfeReserveOverview),
            auditStatsProvider
                .overrideWith((ref) async => mockSecurityAuditStats),
            accountSecurityProfileProvider
                .overrideWith((ref) async => mockAccountSecurityProfile),
            appPinStatusProvider.overrideWith((ref) async => mockAppPinStatus),
            adminKeyStatusProvider
                .overrideWith((ref) async => mockAdminKeyStatus),
            pendingAdminAccessAttemptsProvider
                .overrideWith((ref) async => mockAdminAccessAttempts),
            adminAuthenticatedDevicesProvider
                .overrideWith((ref) async => mockAdminDevices),
            adminBtcPriceProvider
                .overrideWith((ref) async => mockAdminBtcPrice),
            adminAuditStatsProvider
                .overrideWith((ref) async => mockAdminAuditStats),
            adminAuditHistoryProvider
                .overrideWith((ref) async => mockAdminAuditHistory),
            adminAuditLatestRootProvider
                .overrideWith((ref) async => mockAdminAuditLatestRoot),
            adminSovereigntyProvider
                .overrideWith((ref) async => mockAdminSovereignty),
            adminCurrentUserProvider
                .overrideWith((ref) async => mockAdminCurrentUser),
            adminOperationsOverviewProvider
                .overrideWith((ref) async => mockAdminOperationsOverview),
            adminOperationalHealthProvider
                .overrideWith((ref) async => mockAdminOperationalHealth),
            adminBlockchainMonitorProvider
                .overrideWith((ref) async => mockAdminBlockchainMonitor),
            adminLightningMonitorProvider
                .overrideWith((ref) async => mockAdminLightningMonitor),
            adminVaultRaftHealthProvider
                .overrideWith((ref) async => mockAdminVaultRaftHealth),
            adminReleaseSnapshotProvider
                .overrideWith((ref) async => mockAdminReleaseSnapshot),
            adminMobileReleaseProvider
                .overrideWith((ref) async => mockAdminMobileRelease),
            adminOperationalMetricsProvider
                .overrideWith((ref) async => mockAdminOperationalMetrics),
            adminOperationalLogsProvider
                .overrideWith((ref) async => mockAdminOperationalLogs),
            adminMobileDevicesProvider
                .overrideWith((ref) async => mockAdminMobileDevices),
            adminWebDevicesProvider
                .overrideWith((ref) async => mockAdminWebDevices),
            notificationsListProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: KeroseneBrandTokens.background,
              body: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      stories: [
        appFlowStory(),
        ...bitcoinAdvancedStories(),
        ...receiveStories(),
        ...adminStories(),
      ],
    );
  }
}
