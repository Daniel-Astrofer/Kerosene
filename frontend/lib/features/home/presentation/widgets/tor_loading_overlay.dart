import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';

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
  Widget build(BuildContext context) {
    ref.listen<WalletState>(walletProvider, (previous, next) {
      if (next is WalletLoaded || next is WalletError) {
        _finishLoading();
      }
    });

    return AnimatedOpacity(
      opacity: _transitionOpacity,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutBack,
      child: const KeroseneLogoLoadingView(),
    );
  }
}
