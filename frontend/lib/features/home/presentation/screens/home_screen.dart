import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:light/light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../market/presentation/screens/market_screen.dart';
import '../../../p2p/presentation/screens/p2p_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

import '../../../wallet/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/add_funds_screen.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/balance_websocket_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../wallet/presentation/widgets/infinite_wallet_cards.dart';
// import '../../../wallet/presentation/screens/wallet_config_screen.dart'; // Unused
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/receive_screen.dart';

import '../widgets/animated_balance_display.dart';
import '../widgets/pending_payment_link_item.dart';
import '../widgets/nfc_searching_overlay.dart';
import 'qr_scanner_screen.dart';
import '../../../../shared/widgets/bitcoin_refresh_indicator.dart';
import '../../../../core/utils/transaction_extensions.dart';
import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _activeTab = 0; // 0: Home, 1: Market, 2: Chat, 3: Profile
  bool _isNfcSearching = false;
  bool _showAllTransactions = false;

  // App-lock state
  bool _isLocked = true;
  bool _isAuthenticating = false;
  final _biometricService = BiometricService();
  final _pinService = AppPinService();

  StreamSubscription<int>? _proximitySub;
  StreamSubscription<int>? _lightSub;
  DateTime _lastProximityToggle = DateTime(2000);
  double? _lastLightValue;

  @override
  void initState() {
    super.initState();

    // Iniciar carregamento das wallets e transações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
      ref.read(transactionHistoryProvider.notifier).loadTransactions();
      _authenticate();
    });

    // Proximity & Light Sensor: Dual-detection for robust "wave" gesture
    _initProximitySensor();
    _initLightSensor();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final canAuth = await _biometricService.canAuthenticate();
    final isEnrolled = await _biometricService.isBiometricEnrolled();

    // If device doesn't support security at all, OR if it's supported but nothing is enrolled
    if (!canAuth || !isEnrolled) {
      // Device has no system biometric/PIN or it's not set up — use in-app PIN
      setState(() => _isAuthenticating = false);
      if (!mounted) return;
      final hasPinSet = await _pinService.hasPinSet();
      if (!mounted) return;
      final success = await PinDialog.show(context, isSetup: !hasPinSet);

      if (mounted) setState(() => _isLocked = !success);
      return;
    }

    // Device supports system biometrics/PIN AND is enrolled — use it
    final success = await _biometricService.authenticate(
      localizedReason: 'Authenticate to access Kerosene',
    );

    if (mounted) {
      setState(() {
        _isLocked = !success;
        _isAuthenticating = false;
      });
    }
  }

  bool? _lastProximityValue;

  void _initLightSensor() {
    _lightSub = Light().lightSensorStream.listen((int lux) {
      final double value = lux.toDouble();

      // Se não tivermos valor anterior, apenas atualizamos
      if (_lastLightValue == null) {
        _lastLightValue = value;
        return;
      }

      // LÓGICA DE DETECÇÃO DE SOMBRA/MÃO
      // 1. Ambiente Normal/Claro (> 10 lux): Exige queda brusca
      // 2. Ambiente Escuro (< 10 lux): Exige chegar a 0 ou 1 lux (escuridão total)
      // 3. SE (lux < 3): Ambiente JÁ está muito escuro, ignorar sensor de luz para evitar falsos positivos

      if (_lastLightValue! < 3) {
        _lastLightValue = value;
        return;
      }

      final bool isSignificantDrop =
          (_lastLightValue! > 10 &&
              value < _lastLightValue! * 0.2) || // Queda de 80%
          (_lastLightValue! <= 10 &&
              value < 2); // Queda para escuridão quase total

      if (isSignificantDrop) {
        _togglePrivacy(
          reason: 'Shadow detected (Lux: $_lastLightValue -> $value)',
        );
      }

      _lastLightValue = value;
    }, onError: (error) => debugPrint('Light Sensor Error: $error'));
  }

  void _togglePrivacy({required String reason}) {
    final now = DateTime.now();
    // Compact debounce of 2s shared across sensors
    if (now.difference(_lastProximityToggle).inMilliseconds > 2000) {
      _lastProximityToggle = now;
      debugPrint('PRIVACY TOGGLE: $reason');

      HapticFeedback.heavyImpact();
      Future.delayed(
        const Duration(milliseconds: 50),
        () => HapticFeedback.mediumImpact(),
      );

      final current = ref.read(balanceVisibilityProvider);
      ref.read(balanceVisibilityProvider.notifier).state = !current;
    }
  }

  void _initProximitySensor() {
    _proximitySub = ProximitySensor.events.listen((dynamic event) {
      // No Android, o evento pode vir como bool ou num
      final bool isNear = (event is bool) ? event : (event > 0.0);

      // Simplificamos: se o estado mudou, independente da luz, ele alterna
      if (_lastProximityValue != isNear) {
        _togglePrivacy(reason: 'Physical proximity change');
      }
      _lastProximityValue = isNear;
    });
  }

  @override
  void dispose() {
    _proximitySub?.cancel();
    _lightSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-carregar imagens dos cartões para evitar flickering/sumiço
    // Images removed - using solid gradients now
  }

  Future<void> _handlePaymentRequest(BuildContext context, String data) async {
    String address = data;
    double? amount;

    // Basic parsing for bitcoin URI scheme
    if (data.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        address = uri.path;
        if (uri.queryParameters.containsKey('amount')) {
          amount = double.tryParse(uri.queryParameters['amount']!);
        }
      }
    }

    final walletState = ref.read(walletProvider);
    if (walletState is WalletLoaded && walletState.selectedWallet != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SendMoneyScreen(
            walletId: walletState.selectedWallet!.id,
            initialAddress: address,
            initialAmountBtc: amount,
          ),
        ),
      );

      if (result == true && mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.8),
          builder: (_) => const TransactionSuccessDialog(),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectWalletToSend),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    final walletState = ref.read(walletProvider);
    if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
      final selectedWallet = walletState.wallets[index];
      ref.read(walletProvider.notifier).selectWallet(selectedWallet);
      // CORREÇÃO: usa wallet.name em vez de wallet.id (que é numérico)
      ref
          .read(walletProvider.notifier)
          .updateWalletBalance(selectedWallet.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for received transactions
    ref.listen<ReceivedTxEvent?>(receivedTxEventProvider, (previous, next) {
      if (next != null) {
        if (mounted) {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.8),
            builder: (_) => TransactionSuccessDialog(
              type: TransactionType.receive,
              amount: next.amount,
            ),
          );
        }
      }
    });

    // Ensure WebSocket is connected by watching the provider
    ref.watch(balanceWebSocketServiceProvider);

    final walletState = ref.watch(walletProvider);

    debugPrint(
      '>>> HOME BUILD - _activeTab: $_activeTab, WalletState: ${walletState.runtimeType}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF101018)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content (hidden while locked)
          if (!_isLocked)
            KeyedSubtree(
              key: ValueKey('tab_$_activeTab'),
              child: _buildBody(walletState),
            ),

          // Floating Bottom Navigation Dock
          if (!_isLocked) _buildFloatingDock(),

          // NFC Searching Overlay
          if (_isNfcSearching)
            NfcSearchingOverlay(
              onCancel: () {
                setState(() {
                  _isNfcSearching = false;
                });
              },
              onTagRead: (tagData) {
                setState(() {
                  _isNfcSearching = false;
                });
                _handlePaymentRequest(context, tagData);
              },
            ),

          // Lock Overlay
          if (_isLocked) _buildLockOverlay(),
        ],
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Kerosene',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Authentication required',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            if (_isAuthenticating)
              const CircularProgressIndicator(
                color: Color(0xFFF7931A),
                strokeWidth: 2,
              )
            else
              GestureDetector(
                onTap: _authenticate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WalletState walletState) {
    // Keep WebSocket connection alive
    ref.watch(balanceWebSocketServiceProvider);

    switch (_activeTab) {
      case 0:
        return _buildHomeTab(walletState);
      case 1:
        return const MarketScreen();
      case 2:
        return const P2PScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab(WalletState walletState) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        // Necessário para o CupertinoSliverRefreshControl funcionar no Android
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Custom Pull to Refresh com Bitcoin animado
          BitcoinRefreshIndicator(
            onRefresh: () async {
              // Re-precarregar e atualizar dados
              await ref.read(walletProvider.notifier).refresh();
            },
          ),

          // App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        Navigator.pushReplacementNamed(context, '/welcome');
                      },
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          _buildWalletContent(walletState),

          // Padding bottom for floating dock
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  ///vamos ver se esta fucnionando mesmo
  Widget _buildFloatingDock() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GlassContainer(
          blur: 20,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDockIcon(Icons.home_rounded, _activeTab == 0, 0),
              const SizedBox(width: 20),
              _buildDockIcon(Icons.bar_chart_rounded, _activeTab == 1, 1),
              const SizedBox(width: 20),
              _buildDockIcon(Icons.swap_horiz_rounded, _activeTab == 2, 2),
              const SizedBox(width: 20),
              _buildDockIcon(Icons.person_outline_rounded, _activeTab == 3, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildWalletContent(WalletState state) {
    debugPrint('>>> _buildWalletContent - State type: ${state.runtimeType}');

    if (state is WalletLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 600,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
          ),
        ),
      );
    }

    if (state is WalletError) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 600,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingWallets,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                TextButton(
                  onPressed: () => ref.read(walletProvider.notifier).refresh(),
                  child: Text(AppLocalizations.of(context)!.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is WalletLoaded) {
      debugPrint(
        '>>> State is WalletLoaded - Wallets count: ${state.wallets.length}',
      );
      if (state.wallets.isEmpty) {
        return SliverToBoxAdapter(child: _buildEmptyState());
      }

      if (_currentIndex >= state.wallets.length) {
        _currentIndex = 0;
      }

      return SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 1. Balance Section (Top Center) - Animated Entry
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: TotalBalanceDisplay(wallets: state.wallets),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          // 2. Cards Stack with Draggable 3D
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                final visibility = (value * 1.25 - 0.25).clamp(0.0, 1.0);
                return Opacity(
                  opacity: visibility,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - visibility)),
                    child: InfiniteWalletCards(
                      wallets: state.wallets,
                      initialIndex: _currentIndex,
                      onCardTap: (wallet) {
                        final index = state.wallets.indexOf(wallet);
                        _onIndexChanged(index);
                        // Navigate to configuration - REMOVIDO para manter fluxo de seleção de cartão
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => WalletConfigScreen(wallet: wallet),
                        //   ),
                        // );
                        ref.read(walletProvider.notifier).selectWallet(wallet);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 3. Actions Panel
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final visibility = (value * 1.5 - 0.5).clamp(0.0, 1.0);
                return Opacity(
                  opacity: visibility,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * visibility),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.add_rounded,
                              label: AppLocalizations.of(context)!.add,
                              color: const Color(0xFFF7931A),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateWalletScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.download_rounded,
                              label: AppLocalizations.of(context)!.deposit,
                              color: const Color(0xFF00FF94),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddFundsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.arrow_outward_rounded,
                              label: AppLocalizations.of(context)!.send,
                              color: Colors.grey[700]!,
                              onTap: () async {
                                if (state.selectedWallet != null) {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SendMoneyScreen(
                                        walletId: state.selectedWallet!.id,
                                      ),
                                    ),
                                  );

                                  if (result == true && mounted) {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.black.withValues(
                                        alpha: 0.8,
                                      ),
                                      builder: (_) =>
                                          const TransactionSuccessDialog(),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.call_received_rounded,
                              label: AppLocalizations.of(context)!.receive,
                              color: Colors.grey[700]!,
                              onTap: () {
                                if (state.selectedWallet != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReceiveScreen(
                                        wallet: state.selectedWallet!,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.nfc_rounded,
                              label: AppLocalizations.of(context)!.nfc,
                              color: Colors.grey[700]!,
                              onTap: () {
                                setState(() {
                                  _isNfcSearching = true;
                                });
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.qr_code_scanner_rounded,
                              label: AppLocalizations.of(context)!.qrCode,
                              color: Colors.grey[700]!,
                              onTap: () async {
                                final result = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const QrScannerScreen(),
                                  ),
                                );
                                if (result != null) {
                                  if (!mounted) return;
                                  _handlePaymentRequest(context, result);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          // 4. Pending Transactions
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Consumer(
              builder: (context, ref, child) {
                final paymentLinksAsync = ref.watch(paymentLinksProvider);

                return paymentLinksAsync.when(
                  data: (links) {
                    final relevantLinks = links.where((l) {
                      if (l.isPending) return true;
                      if (l.isCompleted && l.completedAt != null) {
                        return DateTime.now()
                                .difference(l.completedAt!)
                                .inHours <
                            24;
                      }
                      return false;
                    }).toList();

                    if (relevantLinks.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 20),
                            child: Text(
                              AppLocalizations.of(context)!.paymentLinks,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return PendingPaymentLinkItem(
                          paymentLink: relevantLinks[index - 1],
                          onTap: () {
                            // Could show details/QR code
                          },
                        );
                      }, childCount: relevantLinks.length + 1),
                    );
                  },
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // 5. Transactions Title
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: TransactionListHeader(
                onSeeAll: () {
                  setState(() {
                    _showAllTransactions = !_showAllTransactions;
                  });
                },
                showAll: _showAllTransactions,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 5. Optimized Transaction List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Consumer(
              builder: (context, ref, child) {
                final transactions = ref.watch(transactionHistoryProvider);
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTransactions,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                // Show only 5 if not "showAll"
                final displayedTransactions = _showAllTransactions
                    ? transactions
                    : transactions.take(5).toList();

                return SliverList.separated(
                  itemCount: displayedTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final tx = displayedTransactions[index];
                    return TransactionListItem(
                      transaction: tx,
                      onTap: () => _showTransactionDetails(context, tx),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // FALLBACK
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  void _showTransactionDetails(BuildContext context, Transaction tx) {
    final isSent = tx.type == TransactionType.send;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassContainer(
              height: 520,
              blur: 50,
              opacity: 0.08,
              borderRadius: BorderRadius.circular(40),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  (isSent
                                          ? const Color(0xFF7B61FF)
                                          : const Color(0xFF00FF94))
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSent ? Icons.logout : Icons.login,
                              color: isSent
                                  ? const Color(0xFF7B61FF)
                                  : const Color(0xFF00FF94),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                _confirmDeleteTransaction(context, ref, tx),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isSent
                        ? AppLocalizations.of(context)!.sentTo
                        : AppLocalizations.of(context)!.receivedFrom,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSent ? tx.toAddress : tx.fromAddress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final currency = ref.watch(currencyProvider);
                            final btcPrice = ref.watch(latestBtcPriceProvider);
                            final btcEur = ref.watch(btcEurPriceProvider);
                            final btcBrl = ref.watch(btcBrlPriceProvider);

                            final fiatValue = convertFromBtc(
                              tx.amountBTC,
                              currency,
                              btcPrice,
                              btcEur,
                              btcBrl,
                            );

                            final appLocale = Localizations.localeOf(
                              context,
                            ).toString();
                            final formatter = NumberFormat.currency(
                              locale: appLocale,
                              symbol: currency == Currency.brl
                                  ? 'R\$'
                                  : currency == Currency.eur
                                  ? '€'
                                  : '\$',
                              decimalDigits: 2,
                            );

                            final isVisible = ref.watch(
                              balanceVisibilityProvider,
                            );

                            return _buildDetailItem(
                              AppLocalizations.of(context)!.value.toUpperCase(),
                              isVisible
                                  ? "${tx.amountBTC.toStringAsFixed(8)} BTC"
                                  : "•••••••• BTC",
                              subValue: isVisible
                                  ? "≈ ${formatter.format(fiatValue)}"
                                  : "≈ ••••••",
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final currency = ref.watch(currencyProvider);
                            final btcPrice = ref.watch(latestBtcPriceProvider);
                            final btcEur = ref.watch(btcEurPriceProvider);
                            final btcBrl = ref.watch(btcBrlPriceProvider);

                            final feeBtc = tx.feeSatoshis / 100000000;
                            final fiatFee = convertFromBtc(
                              feeBtc,
                              currency,
                              btcPrice,
                              btcEur,
                              btcBrl,
                            );

                            final appLocale = Localizations.localeOf(
                              context,
                            ).toString();
                            final formatter = NumberFormat.currency(
                              locale: appLocale,
                              symbol: currency == Currency.brl
                                  ? 'R\$'
                                  : currency == Currency.eur
                                  ? '€'
                                  : '\$',
                              decimalDigits: 2,
                            );

                            final isVisible = ref.watch(
                              balanceVisibilityProvider,
                            );

                            return _buildDetailItem(
                              AppLocalizations.of(context)!.fee.toUpperCase(),
                              isVisible
                                  ? "${feeBtc.toStringAsFixed(8)} BTC"
                                  : "•••••••• BTC",
                              subValue: isVisible
                                  ? "≈ ${formatter.format(fiatFee)}"
                                  : "≈ ••••••",
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          AppLocalizations.of(context)!.date.toUpperCase(),
                          "${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}",
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          AppLocalizations.of(context)!.status.toUpperCase(),
                          tx.status.localized(context).toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.hash.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.id,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tx.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.hashCopied,
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {String? subValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.errorLoadingData,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.getStartedDescription,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.myWallets,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
  ) async {
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            "Apagar Transação",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Esta ação remove a transação apenas do histórico local. Para confirmar, digite sua passphrase (BIP39) ou senha.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Passphrase / Senha",
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00D4FF)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () async {
                final passphrase = passwordController.text;
                if (passphrase.isEmpty) return;

                final isValid = await ref
                    .read(authProvider.notifier)
                    .validatePassphrase(passphrase);

                if (isValid && context.mounted) {
                  Navigator.pop(context, true);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Senha incorreta"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text(
                "Apagar",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await ref
          .read(transactionHistoryProvider.notifier)
          .removeTransaction(tx.id);
      if (context.mounted) {
        Navigator.pop(context); // Fechar detalhes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transação removida do histórico.")),
        );
      }
    }
  }
}

class TotalBalanceDisplay extends ConsumerWidget {
  final List<dynamic> wallets;
  const TotalBalanceDisplay({super.key, required this.wallets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceBtc = ref.watch(totalBalanceBtcProvider);
    final btcPriceAsync = ref.watch(btcPriceProvider);
    final currency = ref.watch(currencyProvider);

    // We can use a local state provider for visibility if we want to persist it,
    // but for now let's keep it simple or use a StateProvider if needed.
    // actually, let's just make this a StatefulWidget for visibility toggle
    return _TotalBalanceDisplayContent(
      totalBalanceBtc: totalBalanceBtc,
      btcPriceAsync: btcPriceAsync,
      currency: currency,
    );
  }
}

class _TotalBalanceDisplayContent extends ConsumerWidget {
  final double totalBalanceBtc;
  final AsyncValue<double> btcPriceAsync;
  final Currency currency;

  const _TotalBalanceDisplayContent({
    required this.totalBalanceBtc,
    required this.btcPriceAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final isHighPrecision = ref.watch(decimalPrecisionProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.totalBalanceGeneric,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ref.read(balanceVisibilityProvider.notifier).state =
                    !isBalanceVisible;
              },
              child: Icon(
                isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF00D4FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ref.read(decimalPrecisionProvider.notifier).state =
                    !isHighPrecision;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isHighPrecision ? ".00000000" : ".000",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        isBalanceVisible
            ? Column(
                children: [
                  // 1. Primary: BTC Balance (Always)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBalanceDisplay(
                        balance: totalBalanceBtc,
                        decimalPlaces: isHighPrecision ? 8 : 3,
                        enableFlash: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // BTC Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF7931A,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "BTC",
                          style: TextStyle(
                            color: Color(0xFFF7931A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 2. Secondary: Fiat Balance (Converted) with Toggle
                  Consumer(
                    builder: (context, ref, child) {
                      return btcPriceAsync.when(
                        data: (price) {
                          // Determining currency and price
                          final convertedAmount = convertFromBtc(
                            totalBalanceBtc,
                            currency,
                            price,
                            ref.watch(btcEurPriceProvider),
                            ref.watch(btcBrlPriceProvider),
                          );

                          // Formatting based on App Locale for formatting, but Currency symbol from currency

                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(currencyProvider.notifier)
                                  .toggleCurrency();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBalanceDisplay(
                                    balance: convertedAmount,
                                    decimalPlaces: 2,
                                    prefix: currency == Currency.brl
                                        ? 'R\$ '
                                        : currency == Currency.eur
                                        ? '€ '
                                        : '\$ ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.swap_vert_rounded,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 20),
                        error: (_, __) => const SizedBox(height: 20),
                      );
                    },
                  ),
                ],
              )
            : const Text(
                "••••••••",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.5,
                ),
              ),
      ],
    );
  }
}

class CircularActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CircularActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 18)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionListHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  final bool showAll;

  const TransactionListHeader({
    super.key,
    required this.onSeeAll,
    required this.showAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.recentTransactions,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            showAll
                ? AppLocalizations.of(context)!.showLess
                : AppLocalizations.of(context)!.viewAll,
            style: const TextStyle(
              color: Color(0xFF7B61FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSent = transaction.type == TransactionType.send;
    final title = isSent ? transaction.toAddress : transaction.fromAddress;
    final isVisible = ref.watch(balanceVisibilityProvider);

    final typeLabel = transaction.type.localized(context);

    final subtitle = "$typeLabel • ${timeago.format(transaction.timestamp)}";
    final amount = isVisible
        ? "${isSent ? '-' : '+'}${transaction.amountBTC.toStringAsFixed(8)} BTC"
        : "•••••••• BTC";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSent ? Icons.logout : Icons.login,
                  color: isSent
                      ? const Color(0xFF7B61FF)
                      : const Color(0xFF00FF94),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.length > 15
                          ? "${title.substring(0, 8)}...${title.substring(title.length - 6)}"
                          : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      color: !isSent ? const Color(0xFF00FF94) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.status.localized(context),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
