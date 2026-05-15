import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/theme/app_theme.dart';

import 'package:teste/l10n/app_localizations.dart';
import '../core/providers/appearance_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/session_invalidation_provider.dart';
import '../core/responsive/kerosene_responsive.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_username_screen.dart';
import '../features/auth/presentation/screens/signup/signup_flow_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/home_loading_screen.dart';
import '../features/auth/presentation/screens/server_unavailable_screen.dart';
import '../features/wallet/presentation/screens/create_wallet_screen.dart';
import '../features/wallet/presentation/screens/wallet_card_screen.dart';
import '../features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import '../features/wallet/presentation/screens/receive_hub_screen.dart';
import '../features/wallet/presentation/screens/send_money_screen.dart';
import '../features/security/presentation/providers/security_provider.dart';
import '../features/security/presentation/widgets/app_entry_pin_gate.dart';
import '../features/mining/presentation/screens/mining_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../core/services/background_service.dart';
import '../core/services/notification_service.dart' as local_notifications;
import '../features/transactions/presentation/screens/deposits_screen.dart';
import '../core/services/audio_service.dart';
import '../core/providers/tor_providers.dart';
import '../core/services/tor_service.dart';
import '../core/config/app_config.dart';
import '../core/performance/kerosene_performance_boundary.dart';
import '../core/utils/qr_payment_parser.dart';
import '../features/auth/controller/auth_controller.dart';
import '../shared/widgets/offline_overlay.dart';
import '../core/utils/snackbar_helper.dart';
import '../features/wallet/presentation/providers/balance_websocket_provider.dart';

Future<void> initializeApp(ProviderContainer container) async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 GLOBAL FLUTTER ERROR CAUGHT: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 ASYNC PLATFORM ERROR CAUGHT: $error');
    return true;
  };

  await local_notifications.NotificationService().init();
  await initializeBackgroundService();
  await AudioService.instance.init();

  try {
    debugPrint('🚀 Starting Tor Network Bootstrap...');
    final bool torStarted = await TorService.instance.start();
    AppConfig.isTorEnabled = torStarted;

    if (torStarted) {
      debugPrint('✅ Tor Network Ready.');
      final host = Uri.parse(AppConfig.onionBaseUrl).host;
      final int relayPort = await TorService.instance.startRelay(host, 80);
      final newApiUrl = 'http://127.0.0.1:$relayPort';
      AppConfig.apiUrl = newApiUrl;
      container.read(torApiUrlProvider.notifier).updateUrl(newApiUrl);

      debugPrint(
        '🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> http://$host',
      );
    } else {
      debugPrint('⚠️ Tor is UNAVAILABLE. Backend connection may fail.');
    }
  } catch (e) {
    debugPrint('❌ CRITICAL ERROR: Tor or Relay failed to start: $e');
    AppConfig.isTorEnabled = false;
  }

  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 300;
}

Widget buildApp() => const MyApp();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final appearance = ref.watch(appearanceProvider);
    ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      ref.read(authControllerProvider.notifier).markSessionInvalidated();
    });

    return MaterialApp(
      title: 'Kerosene Bank',
      navigatorKey: SnackbarHelper.navigatorKey,
      scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const KeroseneScrollBehavior(),
      theme: AppTheme.themeFor(appearance.themeVariant),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      builder: (context, child) {
        Widget current = KerosenePerformanceBoundary(
          child: OfflineOverlay(child: child!),
        );
        current = KeroseneResponsiveBoundary(
          requestedTextScale: appearance.fontScale.scaleFactor,
          child: current,
        );
        return _AppRealtimeBootstrap(child: current);
      },
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          if (authState is AuthInitial || authState is AuthLoading) {
            return const Scaffold(backgroundColor: Colors.black);
          }
          if (authState is AuthAuthenticated) {
            return const AppEntryPinGate(child: HomeLoadingScreen());
          }
          if (authState is AuthServerUnavailable) {
            return const ServerUnavailableScreen();
          }
          return const WelcomeScreen();
        },
      ),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginUsernameScreen(),
        '/signup': (context) => const SignupFlowScreen(),
        '/home': (context) => const _PrivateMobileRoute(child: HomeScreen()),
        '/home_loading': (context) =>
            const _PrivateMobileRoute(child: HomeLoadingScreen()),
        '/settings': (context) => const _PrivateMobileRoute(
              child: SettingsScreen(showPrimaryNavigation: true),
            ),
        '/history': (context) => const _PrivateMobileRoute(
              child: DepositsScreen(showPrimaryNavigation: true),
            ),
        '/card': (context) =>
            const _PrivateMobileRoute(child: BitcoinAccountsScreen()),
        '/wallet-cards-legacy': (context) =>
            const _PrivateMobileRoute(child: WalletCardScreen()),
        '/receive': (context) =>
            const _PrivateMobileRoute(child: ReceiveHubScreen()),
        '/mining': (context) =>
            const _PrivateMobileRoute(child: MiningScreen()),
        '/create_wallet': (context) =>
            const _PrivateMobileRoute(child: CreateWalletScreen()),
        '/send-money': (context) =>
            const _PrivateMobileRoute(child: SendMoneyScreen()),
        '/deposits': (context) => const _PrivateMobileRoute(
              child: DepositsScreen(showPrimaryNavigation: true),
            ),
      },
      onGenerateRoute: (settings) {
        final linkId = QrPaymentParser.extractPaymentLinkId(
          settings.name ?? '',
        );
        if (linkId != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => _PrivateMobileRoute(
              child: SendMoneyScreen(
                initialAddress: QrPaymentParser.encodePaymentLink(linkId),
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}

class _PrivateMobileRoute extends ConsumerWidget {
  final Widget child;

  const _PrivateMobileRoute({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    if (authState is AuthAuthenticated) {
      return AppEntryPinGate(child: child);
    }
    if (authState is AuthServerUnavailable) {
      return const ServerUnavailableScreen();
    }
    return const WelcomeScreen();
  }
}

class _AppRealtimeBootstrap extends ConsumerWidget {
  final Widget child;

  const _AppRealtimeBootstrap({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final appPinStatus = ref.watch(appPinStatusProvider);
    final appUnlocked = ref.watch(appEntryPinUnlockedProvider);
    final appPinSatisfied = appPinStatus.maybeWhen(
      data: (status) => !status.enabled || appUnlocked,
      orElse: () => false,
    );
    if (authState is AuthAuthenticated && appPinSatisfied) {
      ref.watch(balanceWebSocketServiceProvider);
    }
    return child;
  }
}

class KeroseneScrollBehavior extends ScrollBehavior {
  const KeroseneScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
