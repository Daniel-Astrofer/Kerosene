import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../../controller/auth_controller.dart';
import 'presentation_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String _copy({
    required BuildContext context,
    required String pt,
    required String en,
    required String es,
  }) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-carregar imagens pesadas para evitar "Jank" ao navegar para as telas
    precacheImage(const AssetImage('assets/presentationimage.png'), context);
    precacheImage(const AssetImage('assets/logo/kerosene-logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    // Handles the case where _checkAuthStatus resolves after first frame
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthAuthenticated && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home_loading',
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/presentationimage.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.72),
                    const Color(0xFF05070B),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.15),
                  radius: 0.9,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            Navigator.pushNamed(context, '/gallery');
                          },
                          child: const KeroseneLogo(size: 64),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Kerosene Bank',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                letterSpacing: 0,
                                height: 1.0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.welcomeSlogan,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.white,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Spacer(),
                  BouncingButton(
                    text: AppLocalizations.of(context)!.createAccount,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PresentationScreen(),
                        ),
                      );
                    },
                    variant: BouncingButtonVariant.solid,
                  ),
                  const SizedBox(height: 16),
                  BouncingButton(
                    text: AppLocalizations.of(context)!.signIn,
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    variant: BouncingButtonVariant.outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _copy(
                      context: context,
                      pt: 'Se você já tem uma conta, entre diretamente. Se estiver começando agora, revise os requisitos antes de avançar.',
                      en: 'If you already have an account, sign in directly. If you are just getting started, review the requirements before you continue.',
                      es: 'Si ya tienes una cuenta, entra directamente. Si estás comenzando ahora, revisa los requisitos antes de continuar.',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
