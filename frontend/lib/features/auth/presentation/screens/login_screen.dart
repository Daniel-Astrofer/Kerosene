import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/theme/cyber_theme.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';
import 'unknown_device_screen.dart';
import '../../../../core/providers/ghost_mode_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final localDataSource = ref.read(authLocalDataSourceProvider);
      final creds = await localDataSource.getCredentials();
      if (creds != null && mounted) {
        setState(() {
          _usernameController.text = creds['username'] ?? '';
          _passwordController.text = creds['passphrase'] ?? '';
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        final localDataSource = ref.read(authLocalDataSourceProvider);
        if (_rememberMe) {
          await localDataSource.saveCredentials(
            _usernameController.text,
            _passwordController.text,
          );
        } else {
          await localDataSource.removeCredentials();
        }

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (next is AuthRequiresLoginTotp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnknownDeviceScreen(
              username: next.username,
              passphrase: next.passphrase,
              rememberMe: _rememberMe,
            ),
          ),
        );
      } else if (next is AuthError) {
        showCustomErrorDialog(context, ErrorTranslator.translate(next.message));
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, // no back arrow from login
        actions: const [_GhostModeButton()],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            physics: const ClampingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // ─── Logo ───────────────────────────
                  const Center(child: KeroseneLogo(size: 72)),
                  const SizedBox(height: 36),

                  // ─── Title ──────────────────────────
                  Text(
                    AppLocalizations.of(context)!.welcomeBack,
                    style: CyberTheme.heading(size: 30),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.signInToAccess,
                    style: CyberTheme.label(
                      size: 14,
                      color: CyberTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // ─── Username ───────────────────────
                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(
                      color: CyberTheme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: CyberTheme.cyberInput(
                      label: AppLocalizations.of(context)!.username,
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppLocalizations.of(context)!.required
                        : null,
                  ),

                  const SizedBox(height: 18),

                  // ─── Passphrase ─────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: CyberTheme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: CyberTheme.cyberInput(
                      label: AppLocalizations.of(context)!.passphrase,
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: CyberTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppLocalizations.of(context)!.required
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ─── Remember Me ────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? CyberTheme.neonCyan.withValues(alpha: 0.15)
                                : CyberTheme.bgInput,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _rememberMe
                                  ? CyberTheme.neonCyan
                                  : CyberTheme.border,
                              width: 1.5,
                            ),
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: CyberTheme.neonCyan,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.rememberMe,
                          style: TextStyle(
                            color: _rememberMe
                                ? CyberTheme.textPrimary
                                : CyberTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ─── Login Button ───────────────────
                  _CyberLoginButton(
                    isLoading: isLoading,
                    label: AppLocalizations.of(context)!.signIn,
                    onPressed: _handleLogin,
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
    }
  }
}

// ═══════════════════════════════════════════════
// Extracted Stateless Widget — CyberLoginButton
// ═══════════════════════════════════════════════
class _CyberLoginButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  const _CyberLoginButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading
            ? []
            : CyberTheme.glow(CyberTheme.neonCyan, blur: 16),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: CyberTheme.neonButton(CyberTheme.neonCyan),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: CyberTheme.bgDeep,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CyberTheme.bgDeep,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Extracted Stateful Widget — GhostModeButton
// ═══════════════════════════════════════════════
class _GhostModeButton extends ConsumerStatefulWidget {
  const _GhostModeButton();

  @override
  ConsumerState<_GhostModeButton> createState() => _GhostModeButtonState();
}

class _GhostModeButtonState extends ConsumerState<_GhostModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Permanently active, no toggle allowed
  Future<void> _toggleGhostMode() async {
    // Tor is now mandatory and starts in main.dart
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.torOnionActive),
          backgroundColor: Color(0xFF00FF94),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGhostMode = ref.watch(ghostModeProvider);

    // Ensure animation is running if ghost mode somehow got activated externally
    if (isGhostMode && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!isGhostMode && _animController.isAnimating) {
      _animController.stop();
      _animController.reset();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: _toggleGhostMode,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final activeColor = const Color(0xFF00FF94); // Hacker Green
            final inactiveColor = Colors.white38;
            final currentColor = isGhostMode ? activeColor : inactiveColor;
            final glowRadius = isGhostMode ? _glowAnimation.value : 0.0;

            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGhostMode
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                boxShadow: [
                  if (glowRadius > 0)
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.4),
                      blurRadius: glowRadius,
                      spreadRadius: glowRadius / 2,
                    ),
                ],
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: currentColor,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _VMaskPainter(color: currentColor),
                      size: const Size(24, 24),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _VMaskPainter extends CustomPainter {
  final Color color;

  _VMaskPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // A stylized, minimalist "V for Vendetta" Guy Fawkes mask path
    final w = size.width;
    final h = size.height;

    // Face Outline (shield-ish shape)
    final path = Path();
    path.moveTo(w * 0.2, h * 0.2); // Top left
    path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.8, h * 0.2); // Top curve
    path.quadraticBezierTo(w * 0.9, h * 0.6, w * 0.5, h * 0.9); // Jaw right
    path.quadraticBezierTo(w * 0.1, h * 0.6, w * 0.2, h * 0.2); // Jaw left
    canvas.drawPath(path, paint);

    // Evil/Sly Eyes
    final eyePath = Path();
    // Left eye
    eyePath.moveTo(w * 0.35, h * 0.4);
    eyePath.lineTo(w * 0.45, h * 0.45);
    // Right eye
    eyePath.moveTo(w * 0.65, h * 0.4);
    eyePath.lineTo(w * 0.55, h * 0.45);
    canvas.drawPath(eyePath, paint);

    // Iconic Mustache + Smiling Goatee
    final stachePath = Path();
    // Left curl
    stachePath.moveTo(w * 0.3, h * 0.65);
    stachePath.quadraticBezierTo(w * 0.45, h * 0.55, w * 0.5, h * 0.6);
    // Right curl
    stachePath.quadraticBezierTo(w * 0.55, h * 0.55, w * 0.7, h * 0.65);
    canvas.drawPath(stachePath, paint);

    // Goatee (small dot/dash at bottom)
    canvas.drawCircle(Offset(w * 0.5, h * 0.75), 1.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _VMaskPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
