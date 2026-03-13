import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../../core/providers/shader_provider.dart';

class TorLoadingOverlay extends ConsumerStatefulWidget {
  final Future<void> Function() onComplete;

  const TorLoadingOverlay({super.key, required this.onComplete});

  @override
  ConsumerState<TorLoadingOverlay> createState() => _TorLoadingOverlayState();
}

class _TorLoadingOverlayState extends ConsumerState<TorLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeController;
  bool _isTransitioning = false;
  double _transitionOpacity = 1.0;
  bool _minDurationReached = false;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Ensure we wait at least 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _minDurationReached = true;
        });
        final state = ref.read(walletProvider);
        if (state is WalletLoaded || state is WalletError) {
          _finishLoading();
        }
      }
    });

    // Check if data is already loaded immediately (for edge cases)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(walletProvider);
      if ((state is WalletLoaded || state is WalletError) && _minDurationReached) {
        _finishLoading();
      }
    });
  }

  Future<void> _finishLoading() async {
    if (_isTransitioning) return;
    
    // Logic: Only finish if both conditions are met
    // 1. Minimum duration (3s) reached
    // 2. Data is loaded (handled by listener or callback)
    if (!_minDurationReached) return;

    if (!mounted) return;

    // Trigger visual fade out
    setState(() {
      _isTransitioning = true;
      _transitionOpacity = 0.0;
    });

    // Wait for fade animation to end
    await Future.delayed(const Duration(milliseconds: 1000));

    // Unblock the main app UI
    widget.onComplete();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next is WalletLoaded || next is WalletError) {
        _finishLoading();
      }
    });

    final shaderAsync = ref.watch(bitcoinShaderProvider);

    return AnimatedOpacity(
      opacity: _transitionOpacity,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutBack,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: shaderAsync.when(
          data: (program) => SizedBox.expand(
            child: AnimatedBuilder(
              animation: _timeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BitcoinHodlPainter(
                    program: program,
                    time: _timeController.value * 6.28318,
                    isDelayed: _minDurationReached,
                  ),
                );
              },
            ),
          ),
          loading: () => const SizedBox.expand(),
          error: (err, stack) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BitcoinHodlPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final bool isDelayed;

  _BitcoinHodlPainter({
    required this.program,
    required this.time,
    required this.isDelayed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // 1. iResolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2. iTime
    shader.setFloat(2, time);

    // 3. uIsDelayed
    shader.setFloat(3, isDelayed ? 1.0 : 0.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _BitcoinHodlPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
