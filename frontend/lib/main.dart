import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/core/theme/app_theme.dart';

import 'package:teste/l10n/app_localizations.dart';
import 'core/providers/appearance_provider.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_username_screen.dart';
import 'features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/home_loading_screen.dart';
import 'features/auth/presentation/screens/server_unavailable_screen.dart';
import 'features/wallet/presentation/screens/create_wallet_screen.dart';
import 'features/wallet/presentation/screens/send_money_screen.dart';
import 'features/mining/presentation/screens/mining_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart'
    as local_notifications; // Alias for local notification service
import 'features/transactions/presentation/screens/deposits_screen.dart';
import 'core/services/audio_service.dart';
import 'core/providers/tor_providers.dart';
import 'core/services/tor_service.dart';
import 'core/config/app_config.dart';
import 'core/utils/qr_payment_parser.dart';

import 'features/auth/controller/auth_controller.dart';
import 'shared/widgets/offline_overlay.dart';
import 'core/utils/snackbar_helper.dart';
import 'features/wallet/presentation/providers/balance_websocket_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. GLobal Error Handling (Production Crash Defenders)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 GLOBAL FLUTTER ERROR CAUGHT: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 ASYNC PLATFORM ERROR CAUGHT: $error');
    return true; // Prevent default crash behavior
  };

  // Initialize Local Notifications (for foreground handling)
  await local_notifications.NotificationService().init();

  // Initialize Background Service (WebSocket/Balance Monitor)
  await initializeBackgroundService();

  // Initialize Audio Service (Pre-cache synth sounds)
  await AudioService.instance.init();

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // 🧅 INITIALIZE TOR MANDATORY (Only Network Layer)
  try {
    debugPrint('🚀 Starting Tor Network Bootstrap...');
    final bool torStarted = await TorService.instance.start();
    AppConfig.isTorEnabled = torStarted;

    if (torStarted) {
      debugPrint('✅ Tor Network Ready.');
      // Start local relay to the .onion backend
      final host = Uri.parse(AppConfig.onionBaseUrl).host;
      final int relayPort = await TorService.instance.startRelay(host, 80);
      final newApiUrl = 'http://127.0.0.1:$relayPort';
      AppConfig.apiUrl = newApiUrl;

      // Update the reactive provider so ApiClient and WebSocket rebuild
      container.read(torApiUrlProvider.notifier).updateUrl(newApiUrl);

      debugPrint(
          '🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> http://$host');
    } else {
      debugPrint('⚠️ Tor is UNAVAILABLE. Backend connection may fail.');
    }
  } catch (e) {
    debugPrint('❌ CRITICAL ERROR: Tor or Relay failed to start: $e');
    AppConfig.isTorEnabled = false;
  }

  // Aumentar o limite do cachê de imagens para acomodar texturas premium
  // 500MB de cache e 300 imagens simultâneas
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 300;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final appearance = ref.watch(appearanceProvider);

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
        return supportedLocales.first; // Retorna EN por padrão se não suportado
      },
      builder: (context, child) {
        final mediaQuery = MediaQuery.maybeOf(context);
        Widget current = OfflineOverlay(child: child!);
        if (mediaQuery != null) {
          current = MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(appearance.fontScale.scaleFactor),
            ),
            child: current,
          );
        }
        return _AppRealtimeBootstrap(child: current);
      },
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          if (authState is AuthInitial || authState is AuthLoading) {
            // Se ainda não determinou se tem sessão ou não,
            // fica numa tela preta vazia para não piscar o WelcomeScreen.
            return const Scaffold(backgroundColor: Colors.black);
          }
          if (authState is AuthAuthenticated) {
            return const HomeLoadingScreen();
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
        '/home': (context) => const HomeScreen(),
        '/home_loading': (context) => const HomeLoadingScreen(),
        '/settings': (context) =>
            const SettingsScreen(showPrimaryNavigation: true),
        '/history': (context) =>
            const DepositsScreen(showPrimaryNavigation: true),
        '/mining': (context) => const MiningScreen(),
        '/create_wallet': (context) => const CreateWalletScreen(),
        '/send-money': (context) => const SendMoneyScreen(),
        '/deposits': (context) =>
            const DepositsScreen(showPrimaryNavigation: true),
      },
      onGenerateRoute: (settings) {
        final linkId =
            QrPaymentParser.extractPaymentLinkId(settings.name ?? '');
        if (linkId != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => SendMoneyScreen(
              initialAddress: QrPaymentParser.encodePaymentLink(linkId),
            ),
          );
        }
        return null;
      },
    );
  }
}

class _AppRealtimeBootstrap extends ConsumerWidget {
  final Widget child;

  const _AppRealtimeBootstrap({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is AuthAuthenticated) {
      ref.watch(balanceWebSocketServiceProvider);
    }
    return child;
  }
}

// Comportamento de scroll suavizado global
class KeroseneScrollBehavior extends ScrollBehavior {
  const KeroseneScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Retorna BouncingScrollPhysics em todas as plataformas para um feeling mais elástico e fluido
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Podemos customizar o scrollbar se necessário, mas o padrão do Material 3 já é bom
    return super.buildScrollbar(context, child, details);
  }
}

// Criar um provider para o SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
