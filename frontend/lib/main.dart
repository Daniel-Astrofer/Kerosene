import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/core/theme/app_theme.dart';

// Temporarily commented - uncomment after flutter gen-l10n runs successfully
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/wallet/presentation/screens/create_wallet_screen.dart';
import 'features/wallet/presentation/screens/send_money_screen.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart'
    as local_notifications; // Alias for local notification service
import 'features/transactions/presentation/screens/deposits_screen.dart';
import 'core/services/audio_service.dart';
import 'core/services/tor_service.dart';
import 'core/config/app_config.dart';

import 'l10n/app_localizations.dart';
import 'shared/widgets/offline_overlay.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/utils/snackbar_helper.dart';

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

  // 🧅 INITIALIZE TOR MANDATORY (Only Network Layer)
  try {
    debugPrint('🚀 Starting Tor Network Bootstrap...');
    await TorService.instance.start();
    debugPrint('✅ Tor Network Ready.');

    // Start local relay to the .onion backend
    // By tunneling our API through a raw TCP socket, we completely bypass Dart's limits
    final host = Uri.parse(AppConfig.onionBaseUrl).host;
    final int relayPort = await TorService.instance.startRelay(host, 80);
    AppConfig.apiUrl = 'http://127.0.0.1:$relayPort';
    debugPrint('🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> $host');
  } catch (e) {
    debugPrint('❌ CRITICAL ERROR: Tor or Relay failed to start: $e');
    // We could show a critical error screen here if needed,
    // but TorService fallback should handle system Tor.
  }

  // Aumentar o limite do cachê de imagens para acomodar texturas premium
  // 500MB de cache e 300 imagens simultâneas
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 300;

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override do provider de SharedPreferences
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force initialization of AuthProvider to trigger auth check and FCM registration
    ref.watch(authProvider);
    final locale = ref.watch(localeProvider).locale;

    return MaterialApp(
      title: 'Kerosene',
      navigatorKey: SnackbarHelper.navigatorKey,
      scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const KeroseneScrollBehavior(),
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: const [
        // Temporarily commented - uncomment after flutter gen-l10n runs successfully
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', ''),
        Locale('es', ''),
      ],
      builder: (context, child) {
        return OfflineOverlay(child: child!);
      },
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupFlowScreen(),
        '/home': (context) => const HomeScreen(),
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
