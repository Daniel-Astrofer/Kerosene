import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import '../../controller/auth_controller.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'login_passphrase_screen.dart';
import 'totp_screen.dart';

enum _VerificationStep {
  connecting,
  sendingKeys,
  devicePrompt,
  authorized,
  unauthorized,
  userNotFound,
}

class PasskeyVerificationScreen extends ConsumerStatefulWidget {
  final String username;

  const PasskeyVerificationScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<PasskeyVerificationScreen> createState() =>
      _PasskeyVerificationScreenState();
}

class _PasskeyVerificationScreenState
    extends ConsumerState<PasskeyVerificationScreen>
    with SingleTickerProviderStateMixin {
  _VerificationStep _step = _VerificationStep.connecting;
  late final AnimationController _animController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _runIntroSequence();
  }

  Future<void> _runIntroSequence() async {
    // Stage 1: Connecting to server
    setState(() => _step = _VerificationStep.connecting);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Stage 2: Sending keys
    setState(() => _step = _VerificationStep.sendingKeys);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Stage 3: Device prompt (trigger Passkey logic)
    setState(() => _step = _VerificationStep.devicePrompt);
    ref.read(authControllerProvider.notifier).loginWithPasskey(widget.username);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon() {
    switch (_step) {
      case _VerificationStep.connecting:
        return ScaleTransition(
          scale: _pulseScale,
          child:
              Icon(LucideIcons.server, size: 50, color: AppColors.secondary1),
        );
      case _VerificationStep.sendingKeys:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: const Offset(0, -0.15),
          ).animate(_pulseScale),
          child: Icon(LucideIcons.key, size: 50, color: AppColors.secondary1),
        );
      case _VerificationStep.devicePrompt:
        return ScaleTransition(
          scale: _pulseScale,
          child: Icon(LucideIcons.fingerprint,
              size: 50, color: AppColors.secondary1),
        );
      case _VerificationStep.authorized:
        return Icon(LucideIcons.shieldCheck,
            size: 50, color: AppColors.success);
      case _VerificationStep.unauthorized:
        return Icon(LucideIcons.shieldAlert,
            size: 50, color: Theme.of(context).colorScheme.error);
      case _VerificationStep.userNotFound:
        return Icon(LucideIcons.userX,
            size: 50, color: Theme.of(context).colorScheme.error);
    }
  }

  String _buildStepText() {
    switch (_step) {
      case _VerificationStep.connecting:
        return 'CONECTANDO AO\nSERVIDOR';
      case _VerificationStep.sendingKeys:
        return 'ENVIANDO\nCHAVES';
      case _VerificationStep.devicePrompt:
        return 'VERIFICANDO\nDISPOSITIVO';
      case _VerificationStep.authorized:
        return 'ACESSO\nCONCEDIDO';
      case _VerificationStep.unauthorized:
        return 'ACESSO NÃO AUTORIZADO\nVERIFICAÇÃO MANUAL';
      case _VerificationStep.userNotFound:
        return 'USUÁRIO NÃO\nENCONTRADO';
    }
  }

  Color _getStepColor() {
    if (_step == _VerificationStep.authorized) return AppColors.success;
    if (_step == _VerificationStep.unauthorized ||
        _step == _VerificationStep.userNotFound) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color _getIconGlowColor() {
    if (_step == _VerificationStep.authorized) return AppColors.success;
    if (_step == _VerificationStep.unauthorized ||
        _step == _VerificationStep.userNotFound) {
      return Theme.of(context).colorScheme.error;
    }
    return AppColors.secondary1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        if (mounted) setState(() => _step = _VerificationStep.authorized);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!context.mounted) return;
        HomeScreen.skipNextAuth = true;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
      } else if (next is AuthRequiresLoginTotp) {
        if (mounted) setState(() => _step = _VerificationStep.authorized);
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TotpScreen(
              username: next.username,
              passphrase: next.passphrase,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthError) {
        final statusCode = next.statusCode;
        ref.read(authControllerProvider.notifier).clearError();

        if (statusCode == 404) {
          if (mounted) setState(() => _step = _VerificationStep.userNotFound);
          await Future.delayed(const Duration(milliseconds: 2000));
          if (!context.mounted) return;
          Navigator.of(context).pop();
        } else {
          if (mounted) setState(() => _step = _VerificationStep.unauthorized);
          await Future.delayed(const Duration(milliseconds: 2000));
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPassphraseScreen(
                username: widget.username,
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 112,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl + AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: 0.5),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.arrowLeft,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with concentric glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _getIconGlowColor().withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Inner Circle 1
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getIconGlowColor().withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        // Inner Circle 2
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getIconGlowColor().withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                        ),
                        // The Animated Icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _buildAnimatedIcon(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_step.index),
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Text(
                          _buildStepText(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.w400,
                                letterSpacing: (_step ==
                                            _VerificationStep.unauthorized ||
                                        _step == _VerificationStep.userNotFound)
                                    ? 6.0
                                    : 10.0,
                                height: 1.5,
                                color: _getStepColor(),
                                fontSize: (_step ==
                                            _VerificationStep.unauthorized ||
                                        _step == _VerificationStep.userNotFound)
                                    ? 13
                                    : 16,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
