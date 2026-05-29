import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/wallet/presentation/state/wallet_state.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';

class HomeLoadingScreen extends ConsumerStatefulWidget {
  const HomeLoadingScreen({super.key});

  @override
  ConsumerState<HomeLoadingScreen> createState() => _HomeLoadingScreenState();
}

class _HomeLoadingScreenState extends ConsumerState<HomeLoadingScreen> {
  double _uIsDelayed = 0.0;
  Timer? _timeoutTimer;
  Timer? _minDurationTimer;
  Timer? _walletRetryTimer;
  bool _isNavigating = false;
  bool _minDurationPassed = false;
  bool _hasError = false;
  String _errorMessage = "";
  bool _walletSetupRedirectAttempted = false;
  int _walletRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    _minDurationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _minDurationPassed = true);
    });

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
    _minDurationTimer?.cancel();
    _timeoutTimer?.cancel();
    _walletRetryTimer?.cancel();
    super.dispose();
  }

  void _scheduleWalletRetry() {
    if (_walletRetryTimer?.isActive ?? false) {
      return;
    }

    final delay = switch (_walletRetryAttempt) {
      0 => const Duration(seconds: 3),
      1 => const Duration(seconds: 6),
      _ => const Duration(seconds: 12),
    };
    _walletRetryAttempt += 1;

    _walletRetryTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      ref.read(walletProvider.notifier).refresh();
      ref.invalidate(transactionHistoryProvider);
    });
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

  Future<void> _navigateToWalletSetup(String? userId) async {
    if (_isNavigating || _hasError || _walletSetupRedirectAttempted) return;
    _isNavigating = true;
    _walletSetupRedirectAttempted = true;
    _timeoutTimer?.cancel();

    _markWalletSetupRedirectSeen(userId);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BitcoinAccountsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );

    if (!mounted) return;
    await ref.read(walletProvider.notifier).refresh();
    ref.invalidate(transactionHistoryProvider);

    _isNavigating = false;
    _navigateToHome();
  }

  bool _hasSeenWalletSetupRedirect(String? userId) {
    if (userId == null || userId.isEmpty) {
      return false;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_walletSetupRedirectKey(userId)) ?? false;
  }

  void _markWalletSetupRedirectSeen(String? userId) {
    if (userId == null || userId.isEmpty) {
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setBool(_walletSetupRedirectKey(userId), true));
  }

  String _walletSetupRedirectKey(String userId) =>
      'home.wallet_setup_redirect_seen.$userId';

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final authState = ref.watch(authControllerProvider);
    final authenticatedUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next is WalletError) {
        if (mounted) {
          setState(() {
            _uIsDelayed = 1.0;
            _hasError = true;
            _errorMessage = next.message;
          });
        }
        _scheduleWalletRetry();
        return;
      }

      if (next is WalletLoaded) {
        _walletRetryTimer?.cancel();
        _walletRetryAttempt = 0;
        if (mounted && (_hasError || _uIsDelayed > 0.0)) {
          setState(() {
            _uIsDelayed = 0.0;
            _hasError = false;
            _errorMessage = '';
          });
        }
      }
    });

    // Only move away if data is loaded AND minimum animation time completed
    if (walletState is WalletLoaded &&
        _uIsDelayed == 0.0 &&
        _minDurationPassed &&
        !_hasError) {
      if (walletState.wallets.isEmpty &&
          !_hasSeenWalletSetupRedirect(authenticatedUserId)) {
        unawaited(_navigateToWalletSetup(authenticatedUserId));
      } else {
        _navigateToHome();
      }
    }

    return KeroseneLogoLoadingView(
      status: _hasError
          ? 'CONEXÃO INDISPONÍVEL'
          : (_uIsDelayed > 0.5 ? 'CONEXÃO LENTA' : 'SINCRONIZANDO'),
      detail: _hasError
          ? 'Sessão preservada. Tentando reconectar...'
          : (_uIsDelayed > 0.5
              ? 'Tentando carregar seus dados...'
              : 'Garantindo segurança total para seus ativos'),
      isDelayed: _uIsDelayed > 0.5,
      isError: _hasError,
      errorMessage: _errorMessage,
    );
  }
}
