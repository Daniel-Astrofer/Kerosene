import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/core/providers/shared_preferences_provider.dart';
import 'package:teste/core/localization/app_localization_manager.dart';
import 'package:teste/core/presentation/widgets/kerosene_logo_loading_view.dart';

import 'package:teste/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/home_loading_screen.dart';
import 'features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'features/mining/presentation/screens/mining_screen.dart';
import 'features/auth/presentation/screens/server_unavailable_screen.dart';
import 'features/notifications/presentation/widgets/global_notification_host.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/wallet/presentation/screens/create_wallet_screen.dart';
import 'features/wallet/presentation/screens/send_money_screen.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart'
    as local_notifications; // Alias for local notification service
import 'features/transactions/presentation/screens/deposits_screen.dart';
import 'core/services/audio_service.dart';
import 'core/providers/tor_providers.dart';
import 'core/services/tor_network_bootstrap.dart';
import 'core/services/tor_service.dart';

import 'features/auth/controller/auth_controller.dart';
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

  unawaited(_bootstrapTor(container));

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
  await bootstrapTorNetwork(
    torService: TorService.instance,
    updateApiUrl: (url) {
      container.read(torApiUrlProvider.notifier).updateUrl(url);
    },
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
        return AppLocalizationManager.resolve(locale);
      },
      builder: (context, child) => GlobalNotificationHost(
        child: ServerAvailabilityGate(child: child ?? const SizedBox.shrink()),
      ),
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          if (authState is AuthInitial || authState is AuthLoading) {
            return const KeroseneLogoLoadingView(
              status: 'INICIALIZANDO',
              detail: 'Verificando sessão segura',
            );
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
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupFlowScreen(),
        '/server-unavailable': (context) => const ServerUnavailableScreen(),
        '/home': (context) => const HomeScreen(),
        '/home_loading': (context) => const HomeLoadingScreen(),
        '/settings': (context) =>
            const SettingsScreen(showPrimaryNavigation: true),
        '/history': (context) => const DepositsScreen(),
        '/card': (context) => const BitcoinAccountsScreen(),
        '/mining': (context) => const MiningScreen(),
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
