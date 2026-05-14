import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:teste/core/providers/shader_provider.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';

class HomeLoadingScreen extends ConsumerStatefulWidget {
  const HomeLoadingScreen({super.key});

  @override
  ConsumerState<HomeLoadingScreen> createState() => _HomeLoadingScreenState();
}

class _HomeLoadingScreenState extends ConsumerState<HomeLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _uIsDelayed = 0.0;
  Timer? _timeoutTimer;
  bool _isNavigating = false;
  bool _minDurationPassed = false;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    // Mandatory 3-second display of the HODL shader for premium feel
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _minDurationPassed = true);
    });

    // 15s Timeout to show red shader (error/slow connection)
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_hasError) {
        setState(() {
          _uIsDelayed = 1.0;
        });
      }
    });

    // Trigger wallet loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
      ref.invalidate(transactionHistoryProvider);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    if (_isNavigating || _hasError) return;
    _isNavigating = true;
    _timeoutTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shaderAsync = ref.watch(bitcoinShaderProvider);
    final walletState = ref.watch(walletProvider);

    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next is WalletError) {
        if (mounted) {
          setState(() {
            _uIsDelayed = 1.0;
            _hasError = true;
            _errorMessage = next.message;
          });
        }
        ref.read(authControllerProvider.notifier).logout();

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/welcome', (route) => false);
          }
        });
      }
    });

    // Only move away if data is loaded AND minimum animation time completed
    if (walletState is WalletLoaded &&
        _uIsDelayed == 0.0 &&
        _minDurationPassed &&
        !_hasError) {
      _navigateToHome();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: shaderAsync.when(
        data: (program) => AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Stack(
              children: [
                // DRAWING DIRECTLY TO CANVAS INSTEAD OF SHADERMASK
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FullPageShaderPainter(
                      shader: program.fragmentShader()
                        ..setFloat(0, MediaQuery.of(context).size.width)
                        ..setFloat(1, MediaQuery.of(context).size.height)
                        ..setFloat(2, _ctrl.value * 20.0) // iTime
                        ..setFloat(3, _uIsDelayed), // uIsDelayed
                    ),
                  ),
                ),

                // OVERLAY TEXT
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 240),
                      Text(
                        // If error, show error text, else check if delayed
                        _hasError
                            ? "FALHA DE AUTENTICAÇÃO"
                            : (_uIsDelayed > 0.5
                                ? "CONEXÃO LENTA"
                                : "SINCRONIZANDO"),
                        style: AppTypography.bodyMedium.copyWith(
                          color: _uIsDelayed > 0.5
                              ? const Color(0xFFFF0033)
                              : const Color(0xFF00E5BC),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: _hasError ? 4.0 : 10.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _uIsDelayed > 0.5
                                      ? const Color(0xFFFF0033)
                                      : const Color(0xFF00E5BC),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasError
                            ? "Acesso negado."
                            : (_uIsDelayed > 0.5
                                ? "Tentando carregar seus dados..."
                                : "Garantindo segurança total para seus ativos"),
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                      if (_hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFFF0033).withOpacity(0.8),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5BC))),
        error: (e, __) => Center(
            child: Text("Error: $e",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary))),
      ),
    );
  }
}

class _FullPageShaderPainter extends CustomPainter {
  final FragmentShader shader;
  _FullPageShaderPainter({required this.shader});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
