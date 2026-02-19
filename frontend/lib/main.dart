import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'core/services/background_service.dart';
// Temporarily commented - uncomment after flutter gen-l10n runs successfully
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/wallet/presentation/screens/create_wallet_screen.dart';
import 'features/wallet/presentation/screens/send_money_screen.dart';
import 'features/transactions/presentation/screens/deposits_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service
  await initializeBackgroundService();

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
    final locale = ref.watch(localeProvider).locale;

    return MaterialApp(
      title: 'Kerosene',
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
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
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
