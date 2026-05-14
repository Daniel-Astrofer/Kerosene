import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:teste/core/navigation/app_page_transitions.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/server_unavailable_screen.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

enum _TorBootstrapVisualState { booting, retryReady, retrying }

class HomeLoadingScreen extends ConsumerStatefulWidget {
  const HomeLoadingScreen({super.key});

  @override
  ConsumerState<HomeLoadingScreen> createState() => _HomeLoadingScreenState();
}

class _HomeLoadingScreenState extends ConsumerState<HomeLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _timeoutTimer;
  Timer? _manualRetryTimer;
  bool _isNavigating = false;
  bool _minDurationPassed = false;
  bool _isSyncing = false;
  int _retryCount = 0;
  _TorBootstrapVisualState _visualState = _TorBootstrapVisualState.booting;

  static const Duration _minDisplayDuration = Duration(seconds: 3);
  static const Duration _slowConnectionTimeout = Duration(seconds: 15);
  static const Duration _manualRetryTimeout = Duration(seconds: 10);
  static const int _maxSessionRepairAttempts = 2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    Timer(_minDisplayDuration, () {
      if (!mounted) return;
      setState(() => _minDurationPassed = true);
      _maybeProceedToHome(
        ref.read(walletProvider),
        ref.read(latestBtcPriceProvider),
      );
    });

    _timeoutTimer = Timer(_slowConnectionTimeout, () {
      if (!mounted || _isNavigating) return;
      final walletState = ref.read(walletProvider);
      final btcUsd = ref.read(latestBtcPriceProvider);
      if (_isBootstrapReady(walletState, btcUsd)) return;
      _showRetryPrompt();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshBootstrapData(force: true));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timeoutTimer?.cancel();
    _manualRetryTimer?.cancel();
    super.dispose();
  }

  bool _isAuthFailureMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('usuário não autenticado') ||
        normalized.contains('usuario nao autenticado') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('401') ||
        normalized.contains('403');
  }

  bool _hasLiveQuote(double? btcUsd) => btcUsd != null && btcUsd > 0;

  bool _isBootstrapReady(WalletState walletState, double? btcUsd) {
    return walletState is WalletLoaded && _hasLiveQuote(btcUsd);
  }

  void _restartPriceFeed() {
    ref.invalidate(priceWebSocketServiceProvider);
    ref.invalidate(btcPriceProvider);
    ref.invalidate(backendBtcRatesProvider);
  }

  void _cancelRetryTimers() {
    _timeoutTimer?.cancel();
    _manualRetryTimer?.cancel();
  }

  void _showRetryPrompt() {
    if (!mounted || _isNavigating) return;
    if (_visualState == _TorBootstrapVisualState.retryReady) return;
    setState(() {
      _visualState = _TorBootstrapVisualState.retryReady;
    });
  }

  String _retryHintText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Tap to try again';
      case 'es':
        return 'Toca para reintentar';
      default:
        return 'Toque para tentar novamente';
    }
  }

  String _genericConnectionFailureText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Could not establish a secure connection right now.';
      case 'es':
        return 'No fue posible establecer una conexión segura ahora.';
      default:
        return 'Não foi possível estabelecer uma conexão segura agora.';
    }
  }

  String _fallbackMessageFrom(WalletState walletState) {
    if (walletState is WalletError && walletState.message.trim().isNotEmpty) {
      return walletState.message.trim();
    }
    return _genericConnectionFailureText(context);
  }

  Future<void> _refreshBootstrapData({bool force = false}) async {
    if (!mounted || _isNavigating) return;

    final walletState = ref.read(walletProvider);
    final btcUsd = ref.read(latestBtcPriceProvider);

    if (!force && (_isBootstrapReady(walletState, btcUsd) || _isSyncing)) {
      _maybeProceedToHome(walletState, btcUsd);
      return;
    }

    _isSyncing = true;
    try {
      if (force || !_hasLiveQuote(btcUsd)) _restartPriceFeed();
      ref.invalidate(transactionHistoryProvider);
      await ref.read(walletProvider.notifier).refresh();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _handleRetryTap() async {
    if (_visualState != _TorBootstrapVisualState.retryReady || _isNavigating) {
      return;
    }

    setState(() {
      _visualState = _TorBootstrapVisualState.retrying;
    });

    _manualRetryTimer?.cancel();
    _manualRetryTimer = Timer(_manualRetryTimeout, () {
      if (!mounted || _isNavigating) return;
      final walletState = ref.read(walletProvider);
      final btcUsd = ref.read(latestBtcPriceProvider);
      if (_isBootstrapReady(walletState, btcUsd)) return;
      _navigateToFallback(message: _fallbackMessageFrom(walletState));
    });

    await _refreshBootstrapData(force: true);
    if (!mounted || _isNavigating) return;

    final authState = ref.read(authControllerProvider);
    if (authState is AuthServerUnavailable) {
      _navigateToFallback(message: authState.message);
      return;
    }

    final walletState = ref.read(walletProvider);
    final btcUsd = ref.read(latestBtcPriceProvider);
    if (walletState is WalletError &&
        !_isAuthFailureMessage(walletState.message)) {
      _navigateToFallback(message: _fallbackMessageFrom(walletState));
      return;
    }
    _maybeProceedToHome(walletState, btcUsd);
  }

  Future<void> _repairSessionAndRetry() async {
    if (!mounted || _isNavigating) return;
    if (_retryCount >= _maxSessionRepairAttempts) {
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
      return;
    }

    _retryCount += 1;
    await ref.read(authControllerProvider.notifier).retrySessionCheck();

    if (!mounted || _isNavigating) return;
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      await _refreshBootstrapData(force: true);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
  }

  void _maybeProceedToHome(WalletState walletState, double? btcUsd) {
    if (_isNavigating || !_minDurationPassed) return;
    if (!_isBootstrapReady(walletState, btcUsd)) return;
    _cancelRetryTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isNavigating) return;
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_isNavigating) return;
    _isNavigating = true;
    _cancelRetryTimers();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        keroseneHorizontalRoute<void>(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    });
  }

  void _navigateToFallback({String? message}) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _cancelRetryTimers();
    final fallbackMessage = message?.trim().isNotEmpty == true
        ? message!.trim()
        : _genericConnectionFailureText(context);
    Navigator.of(context).pushAndRemoveUntil(
      keroseneHorizontalRoute<void>(
        builder: (_) => ServerUnavailableScreen(
          message: fallbackMessage,
          retryRouteName: '/home_loading',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);

    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next is WalletLoaded) {
        _retryCount = 0;
        _maybeProceedToHome(next, ref.read(latestBtcPriceProvider));
      } else if (next is WalletError) {
        if (_isAuthFailureMessage(next.message)) {
          if (mounted && _visualState != _TorBootstrapVisualState.retrying) {
            setState(() => _visualState = _TorBootstrapVisualState.retrying);
          }
          unawaited(_repairSessionAndRetry());
        } else if (_visualState == _TorBootstrapVisualState.retrying) {
          _navigateToFallback(message: _fallbackMessageFrom(next));
        } else {
          _showRetryPrompt();
        }
      }
    });

    ref.listen<double?>(latestBtcPriceProvider, (_, next) {
      if (_hasLiveQuote(next)) {
        _retryCount = 0;
        _maybeProceedToHome(ref.read(walletProvider), next);
      }
    });

    _maybeProceedToHome(walletState, btcUsd);

    final showRetryHint = _visualState == _TorBootstrapVisualState.retryReady;

    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: showRetryHint ? _handleRetryTap : null,
        child: Stack(
          children: [
            Center(child: _JumpingDotsLarge(controller: _ctrl)),
            Positioned(
              left: 28,
              right: 28,
              bottom: 64,
              child: AnimatedOpacity(
                opacity: showRetryHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Text(
                  _retryHintText(context),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFFF6B76).withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpingDotsLarge extends StatelessWidget {
  final AnimationController controller;
  const _JumpingDotsLarge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _SingleDot(index: index, controller: controller),
        );
      }),
    );
  }
}

class _SingleDot extends StatelessWidget {
  final int index;
  final AnimationController controller;
  const _SingleDot({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    final start = index * 0.15;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        (start + 0.5).clamp(0.0, 1.0),
        curve: _BounceCurve(),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double dy = -20.0 * animation.value;
        final double scale = 0.8 + (0.4 * animation.value);
        final double opacity = 0.25 + (0.75 * animation.value);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 12,
              height: 12,
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

class _BounceCurve extends Curve {
  @override
  double transformInternal(double t) {
    return (t < 0.5)
        ? Curves.easeOutCubic.transform(t * 2)
        : Curves.easeInCubic.transform(1 - (t - 0.5) * 2);
  }
}
