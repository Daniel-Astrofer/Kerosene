import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/core/theme/app_theme.dart';

import 'package:teste/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_username_screen.dart';
import 'features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/home_loading_screen.dart';
import 'features/auth/presentation/screens/server_unavailable_screen.dart';
import 'features/wallet/presentation/screens/create_wallet_screen.dart';
import 'features/wallet/presentation/screens/send_money_screen.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart'
    as local_notifications; // Alias for local notification service
import 'features/transactions/presentation/screens/deposits_screen.dart';
import 'core/services/audio_service.dart';
import 'core/providers/tor_providers.dart';
import 'core/services/tor_service.dart';
import 'core/config/app_config.dart';

import 'features/auth/controller/auth_controller.dart';
import 'shared/widgets/offline_overlay.dart';
import 'core/utils/snackbar_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _configureGlobalErrorHandling();
  _configureImageCache();

  // SharedPreferences is needed before the ProviderContainer is built. Keep
  // everything else out of the critical path so the first frame renders fast.
  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
  );

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startAppServices(container));
  });
}

void _configureGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 GLOBAL FLUTTER ERROR CAUGHT: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 ASYNC PLATFORM ERROR CAUGHT: $error');
    return true; // Prevent default crash behavior
  };
}

void _configureImageCache() {
  // Keep a generous cache for premium textures without reserving hundreds of MB
  // on low-memory devices.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 160 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 180;
}

Future<void> _startAppServices(ProviderContainer container) async {
  await Future.wait([
    _runStartupTask(
      'Local notifications',
      () => local_notifications.NotificationService().init(),
    ),
    _runStartupTask('Background service', initializeBackgroundService),
    _runStartupTask('Audio service', AudioService.instance.init),
    _runStartupTask('Tor network', () => _bootstrapTor(container)),
  ]);
}

Future<void> _runStartupTask(String name, Future<void> Function() task) async {
  try {
    await task();
  } catch (error, stackTrace) {
    debugPrint('$name startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _bootstrapTor(ProviderContainer container) async {
  debugPrint('🚀 Starting Tor Network Bootstrap...');
  final bool torStarted = await TorService.instance.start();
  AppConfig.isTorEnabled = torStarted;

  if (!torStarted) {
    debugPrint('⚠️ Tor is UNAVAILABLE. Backend connection may fail.');
    return;
  }

  debugPrint('✅ Tor Network Ready.');
  final host = Uri.parse(AppConfig.onionBaseUrl).host;
  final int relayPort = await TorService.instance.startRelay(host, 80);
  final newApiUrl = 'http://127.0.0.1:$relayPort';
  AppConfig.apiUrl = newApiUrl;

  container.read(torApiUrlProvider.notifier).updateUrl(newApiUrl);

  debugPrint(
    '🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> http://$host',
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;

    return MaterialApp(
      title: 'Kerosene',
      navigatorKey: SnackbarHelper.navigatorKey,
      scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const KeroseneScrollBehavior(),
      theme: AppTheme.darkTheme,
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
      builder: (context, child) =>
          OfflineOverlay(child: child ?? const SizedBox.shrink()),
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
        '/create_wallet': (context) => const CreateWalletScreen(),
        '/send-money': (context) => const SendMoneyScreen(),
        '/deposits': (context) => const DepositsScreen(),
      },
    );
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
