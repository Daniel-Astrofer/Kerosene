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
        Navigator.pushReplacementNamed(context, '/home_loading');
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/presentationimage.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Logo and Platform Name side-by-side
                  // Logo and Platform Name side-by-side
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            // Secret shortcut for developers
                            Navigator.pushNamed(context, '/gallery');
                          },
                          child: const KeroseneLogo(size: 60),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Kerosene',
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
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BouncingButton(
                        text: AppLocalizations.of(context)!.signIn,
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        variant: BouncingButtonVariant.solid,
                      ),
                      const SizedBox(height: 16),
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
                        variant: BouncingButtonVariant.outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
