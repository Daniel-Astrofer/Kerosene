import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // If already authenticated, skip auth screens entirely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-carregar imagens pesadas para evitar "Jank" ao navegar para as telas
    precacheImage(const AssetImage('assets/presentationimage.png'), context);
    precacheImage(const AssetImage('assets/kerosenelogo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    // Handles the case where _checkAuthStatus resolves after first frame
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/presentationimage.png'),
            fit: BoxFit.cover,
          ),
        ),
        // Add a dark overlay to ensure text readability
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo and Platform Name side-by-side
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const KeroseneLogo(size: 80), // Increased size
                        const SizedBox(width: 16),
                        Text(
                          'Kerosene',
                          style: const TextStyle(
                            fontFamily: 'HubotSansExpanded',
                            fontWeight: FontWeight.w800,
                            fontSize: 56,
                            color: Colors.white,
                            letterSpacing: -2,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 12.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.welcomeSlogan,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      shadows: [
                        const Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4.0,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF7B61FF,
                            ), // Electric Purple
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.signIn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.createAccount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
