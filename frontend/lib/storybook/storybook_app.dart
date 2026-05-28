// Kerosene Storybook — Main Storybook Widget
//
// Aggregates all story files and wraps them with the correct theme,
// ProviderScope, and localization delegates so every screen renders
// exactly as it would in the production app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/providers/shared_preferences_provider.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/core/l10n/app_localizations.dart';

import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/providers/network_status_provider.dart';
import 'storybook_mocks.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';

import 'stories/app_screen_stories.dart';
import 'stories/auth_stories.dart';
import 'stories/wallet_stories.dart';
import 'stories/ui_stories.dart';
import 'stories/shared_stories.dart';

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
        // Wrap every story with ProviderScope + themed MaterialApp

        // KNOB: Language Selection
        final language = context.knobs.options(
          label: 'Language',
          initial: 'pt',
          options: const [
            Option(label: 'Portuguese', value: 'pt'),
            Option(label: 'English', value: 'en'),
          ],
        );

        // KNOB: Auth State
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

        // KNOB: Mobile View Toggle (Fixes unbounded constraints in Storybook)
        final isMobileView =
            context.knobs.boolean(label: 'Mobile Frame', initial: true);

        return ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            // Global overrides for Storybook stability
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
            btcPriceProvider.overrideWith((ref) => Stream.value(65000.0)),
            btcBrlPriceProvider.overrideWithValue(325000.0),
            latestBtcPriceProvider.overrideWithValue(65000.0),
            priceWebSocketServiceProvider
                .overrideWithValue(MockPriceWebSocketService()),
            networkStatusProvider.overrideWith(() => NetworkStatusNotifier()),
            walletProvider.overrideWith(() => MockWalletNotifier()),
            transactionHistoryProvider.overrideWith(
              (ref) async => mockTransactions,
            ),
            pagedTransactionHistoryProvider.overrideWith(
              (ref, request) async =>
                  mockTransactions.take(request.size).toList(),
            ),
            depositsProvider.overrideWith((ref) async => const []),
            paymentLinksProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: isMobileView ? Colors.black : null,
              body: Center(
                child: Container(
                  width: isMobileView ? 390 : null,
                  height: isMobileView ? 844 : null, // iPhone 14-ish dimensions
                  decoration: isMobileView
                      ? BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                            )
                          ],
                        )
                      : null,
                  clipBehavior: Clip.antiAlias,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
      stories: [
        ...appScreenStories(),
        ...authStories(),
        ...walletStories(),
        ...uiStories(),
        ...sharedStories(),
      ],
    );
  }
}
