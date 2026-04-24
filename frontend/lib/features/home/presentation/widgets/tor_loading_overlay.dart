import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/tor_loading_dots.dart';

import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';

class TorLoadingOverlay extends ConsumerStatefulWidget {
  final Future<void> Function() onComplete;

  const TorLoadingOverlay({super.key, required this.onComplete});

  @override
  ConsumerState<TorLoadingOverlay> createState() => _TorLoadingOverlayState();
}

class _TorLoadingOverlayState extends ConsumerState<TorLoadingOverlay> {
  bool _isTransitioning = false;
  double _transitionOpacity = 1.0;
  bool _minDurationReached = false;

  @override
  void initState() {
    super.initState();

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
              const TorLoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}
