import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

import '../../controller/auth_controller.dart';

class _AuthColors {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color field;
  final Color border;
  final Color borderSoft;
  final Color text;
  final Color muted;
  final Color dim;
  final Color success;
  final Color errorText;

  const _AuthColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.field,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.muted,
    required this.dim,
    required this.success,
    required this.errorText,
  });

  factory _AuthColors.of(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return const _AuthColors(
        isLight: true,
        background: Color(0xFFF7F7F5),
        surface: Color(0xFFFFFFFF),
        field: Color(0xFFF0F1EE),
        border: Color(0xFFDDE0D8),
        borderSoft: Color(0xFFE2E4DE),
        text: Color(0xFF181A17),
        muted: Color(0xFF62675F),
        dim: Color(0xFF8B9087),
        success: Color(0xFF16A34A),
        errorText: Color(0xFFDC2626),
      );
    }
    return const _AuthColors(
      isLight: false,
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0A),
      field: Color(0xFF1A1A1A),
      border: Color(0xFF333333),
      borderSoft: Color(0xFF27272A),
      text: Color(0xFFFFFFFF),
      muted: Color(0xFFA1A1AA),
      dim: Color(0xFF71717A),
      success: Color(0xFF4ADE80),
      errorText: Color(0xFFF4C7C7),
    );
  }

  BorderRadius get radiusMedium =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(12);
  BorderRadius get radiusButton =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(999);
}

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

    final colors = _AuthColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
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
    final colors = _AuthColors.of(context);
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: context.tr.welcomeHeaderTitleCustody),
              TextSpan(
                text: context.tr.welcomeHeaderTitleSimplicity,
                style: GoogleFonts.ibmPlexSerif(
                  color: colors.muted,
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
            color: colors.text,
            fontSize: 40,
            fontWeight: FontWeight.w500,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr.welcomeHeaderSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: colors.muted,
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
    final colors = _AuthColors.of(context);
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
                        colors.background.withValues(alpha: 0.72),
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
    final colors = _AuthColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WelcomeButton(
          label: context.tr.welcomeCreateAccountButton,
          onPressed: onCreateAccount,
          backgroundColor: colors.text,
          foregroundColor: colors.background,
          borderColor: colors.text,
        ),
        const SizedBox(height: 14),
        _WelcomeButton(
          label: context.tr.welcomeAlreadyHaveAccountButton,
          onPressed: onSignIn,
          backgroundColor: Colors.transparent,
          foregroundColor: colors.text,
          borderColor: colors.borderSoft,
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
    final colors = _AuthColors.of(context);
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
              borderRadius: colors.radiusButton,
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
