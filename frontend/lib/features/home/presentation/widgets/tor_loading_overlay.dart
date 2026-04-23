import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';

class TorLoadingOverlay extends ConsumerStatefulWidget {
  final Future<void> Function() onComplete;

  const TorLoadingOverlay({super.key, required this.onComplete});

  @override
  ConsumerState<TorLoadingOverlay> createState() => _TorLoadingOverlayState();
}

class _TorLoadingOverlayState extends ConsumerState<TorLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isTransitioning = false;
  double _transitionOpacity = 1.0;
  bool _minDurationReached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      if ((state is WalletLoaded || state is WalletError) &&
          _minDurationReached) {
        _finishLoading();
      }
    });
  }

  Future<void> _finishLoading() async {
    if (_isTransitioning) return;
    if (!_minDurationReached) return;
    if (!mounted) return;

    setState(() {
      _isTransitioning = true;
      _transitionOpacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next is WalletLoaded || next is WalletError) {
        _finishLoading();
      }
    });

    return AnimatedOpacity(
      opacity: _transitionOpacity,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutQuad,
      child: Scaffold(
        backgroundColor: const Color(0xFF020202), // Dark mode profundo
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _JumpingDots(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _JumpingDots extends StatelessWidget {
  final AnimationController controller;

  const _JumpingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    const dotSize = 10.0;
    const spacing = 12.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: spacing / 2),
          child: _SingleJumpingDot(
            index: index,
            controller: controller,
            size: dotSize,
          ),
        );
      }),
    );
  }
}

class _SingleJumpingDot extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final double size;

  const _SingleJumpingDot({
    required this.index,
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 0.0 to 1.0 cycle
    // Stagger dots: 0.0, 0.2, 0.4 start times
    final start = index * 0.15;
    final end = start + 0.5;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: _BouncyCurve(),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double dy = -16.0 * animation.value; // Slightly higher jump
        final double opacity = 0.2 + (0.8 * animation.value);
        final double scale = 0.8 + (0.3 * animation.value); // Scale effect

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A curve that goes up and down (0 -> 1 -> 0)
class _BouncyCurve extends Curve {
  @override
  double transformInternal(double t) {
    // Basic sine wave segment for jump
    return (t < 0.5)
        ? Curves.easeOutCubic.transform(t * 2)
        : Curves.easeInCubic.transform(1 - (t - 0.5) * 2);
  }
}
