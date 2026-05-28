import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/auth_controller.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _phoneMockupAsset = 'assets/welcome_phone_mockup.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_phoneMockupAsset), context);
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 432),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _WelcomeHeader(),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: (constraints.maxHeight * 0.42)
                                .clamp(280.0, 440.0)
                                .toDouble(),
                            child: const Center(child: _PhoneHeroImage()),
                          ),
                          const SizedBox(height: 34),
                          _WelcomeActions(
                            onCreateAccount: () =>
                                Navigator.pushNamed(context, '/signup'),
                            onSignIn: () =>
                                Navigator.pushNamed(context, '/login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Custódia institucional.\n'),
              TextSpan(
                text: 'Simplicidade absoluta.',
                style: GoogleFonts.ibmPlexSerif(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSerif(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w500,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Segurança de nível superior para seu patrimônio digital. '
          'Projetado para quem exige o melhor.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PhoneHeroImage extends StatelessWidget {
  const _PhoneHeroImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize =
            constraints.biggest.shortestSide.clamp(280.0, 500.0).toDouble();

        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              _WelcomeScreenState._phoneMockupAsset,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0, 0.62, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.onCreateAccount,
    required this.onSignIn,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WelcomeButton(
          label: 'Criar conta',
          onPressed: onCreateAccount,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          borderColor: Colors.white,
        ),
        const SizedBox(height: 14),
        _WelcomeButton(
          label: 'Já tenho conta',
          onPressed: onSignIn,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          borderColor: Colors.white.withValues(alpha: 0.22),
        ),
      ],
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Color.alphaBlend(
                foregroundColor.withValues(alpha: 0.08),
                backgroundColor,
              );
            }
            return backgroundColor;
          }),
          foregroundColor: WidgetStateProperty.all(foregroundColor),
          overlayColor: WidgetStateProperty.all(
            foregroundColor.withValues(alpha: 0.08),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }
}
