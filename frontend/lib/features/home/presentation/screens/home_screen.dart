import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../l10n/app_localizations.dart';

import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

import '../../../profile/presentation/screens/profile_screen.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

import '../../../transactions/domain/entities/tx_status.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/balance_websocket_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../wallet/presentation/widgets/infinite_wallet_cards.dart';
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/receive_screen.dart';
import '../../../wallet/presentation/screens/unified_transaction_screen.dart';

import '../widgets/animated_balance_display.dart';
import '../widgets/tor_loading_overlay.dart';

import '../widgets/nfc_searching_overlay.dart';

import '../../../../shared/widgets/bitcoin_refresh_indicator.dart';
import 'package:teste/core/utils/transaction_extensions.dart';

import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';
import '../../../../shared/widgets/cyber_icons.dart';
import '../widgets/platform_liquidity_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static bool skipNextAuth = false;
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _activeTab = 0; // 0: Home, 1: Profile
  bool _isNfcSearching = false;
  bool _showAllTransactions = false;

  bool _isTorLoading = false; // Overlay flag

  StreamSubscription<int>? _proximitySub;
  DateTime _lastProximityToggle = DateTime(2000);

  @override
  void initState() {
    super.initState();

    // Iniciar carregamento das wallets e transações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _isTorLoading = true;
        });
      }
    });

    // Proximity Sensor: Gesture detection for robust "wave" gesture
    _initProximitySensor();
  }

  bool? _lastProximityValue;

    void _togglePrivacy({required String reason}) {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => HapticFeedback.mediumImpact(),
      );

      final current = ref.read(balanceVisibilityProvider);
      ref.read(balanceVisibilityProvider.notifier).state = !current;
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

      if (result is TxStatus && context.mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.8),
          builder: (_) => TransactionSuccessDialog(
            type: TransactionType.send,
            amount: result.amountReceived > 0 ? result.amountReceived : amount,
            counterparty: result.receiver.isNotEmpty
                ? result.receiver
                : address,
          ),
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
              counterparty: next.sender,
            ),
          );
        }
      }
    });

    // Ensure WebSocket is connected by watching the provider
    ref.watch(balanceWebSocketServiceProvider);

    final walletState = ref.watch(walletProvider);

    return PopScope(
      canPop:
          false, // authenticated users cannot navigate back to login/welcome
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        extendBody: true,
        body: Stack(
          children: [
            // Background Gradient (Subtle)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Main Content (always visible)
            KeyedSubtree(
              key: ValueKey('tab_$_activeTab'),
              child: _buildBody(walletState),
            ),

            // Floating Bottom Navigation Dock
            if (walletState is WalletLoaded) _buildFloatingDock(),

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

            // ── TOR SHADER LOADING OVERLAY ───────────────────
            if (_isTorLoading)
              TorLoadingOverlay(
                onComplete: () async {
                  if (mounted) {
                    setState(() => _isTorLoading = false);
                  }
                },
              ),

            // Removed Lock Overlay per user request
          ],
        ),
      ),
    );
  }

  // Lock overlay removed per user request

  Widget _buildBody(WalletState walletState) {
    // Keep WebSocket connection alive
    ref.watch(balanceWebSocketServiceProvider);

    switch (_activeTab) {
      case 0:
        return _buildHomeTab(walletState);
      case 1:
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
              ref.read(walletProvider.notifier).refresh();
              ref.invalidate(transactionHistoryProvider);
            },
          ),

          // Platform Liquidity Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: PlatformLiquidityHeader(),
            ),
          ),

          // Content
          _buildWalletContent(walletState),

          // 5. Recent Transactions
          Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(transactionHistoryProvider);
              final filteredAsync = ref.watch(filteredTransactionsProvider);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: TransactionListHeader(
                        showAll: _showAllTransactions,
                        onSeeAll: () {
                          setState(() {
                            _showAllTransactions = !_showAllTransactions;
                          });
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Transaction list driven by FutureProvider
                    ...historyAsync.when(
                      loading: () => [
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFF00D4FF),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      error: (e, _) => [
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_off_rounded,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Erro ao carregar transações',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      transactionHistoryProvider,
                                    ),
                                    child: const Text(
                                      'Tentar novamente',
                                      style: TextStyle(
                                        color: Color(0xFF00D4FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      data: (_) {
                        final txs = filteredAsync.valueOrNull ?? [];
                        if (txs.isEmpty) {
                          return [
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.noTransactions,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ];
                        }

                        final displayTxs = _showAllTransactions
                            ? txs
                            : txs.take(5).toList();

                        return [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index >= displayTxs.length) return null;
                              final tx = displayTxs[index];
                              return TransactionListItem(
                                transaction: tx,
                                onTap: () => _showTransactionDetails(tx),
                              );
                            }, childCount: displayTxs.length),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Padding bottom for floating dock
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFloatingDock() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 24 + bottomPadding,
      left: 24,
      right: 24,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDockIcon(0, Icons.home_filled),
            _buildDockIcon(1, Icons.account_balance_wallet_rounded),
            _buildDockIcon(2, Icons.bar_chart_rounded),
            _buildDockIcon(3, Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDockIcon(int index, IconData icon) {
    bool isActive = _activeTab == index;

    return GestureDetector(
      onTap: () {
        if (index == 0 || index == 3) { // Only home and profile are handled currently
          setState(() {
            _activeTab = index == 0 ? 0 : 1;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFCFBE9) : Colors.transparent, // A pale yellow/white for active
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildWalletContent(WalletState state) {
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
                        ref.read(walletProvider.notifier).selectWallet(wallet);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // --- NEW: LAST TRANSACTION HIGHLIGHT (CYBER STYLE) ---
          Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(transactionHistoryProvider);
              final filteredAsync = ref.watch(filteredTransactionsProvider);
              return SliverToBoxAdapter(
                child: historyAsync.when(
                  data: (_) {
                    final txs = filteredAsync.valueOrNull ?? [];
                    if (txs.isEmpty) return const SizedBox.shrink();
                    final lastTx = txs.first;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => _showTransactionDetails(lastTx),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (lastTx.type == TransactionType.send
                                          ? const Color(0xFFFF5252)
                                          : const Color(0xFF00FF94))
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  lastTx.type == TransactionType.send
                                      ? Icons.north_east_rounded
                                      : Icons.south_west_rounded,
                                  color: lastTx.type == TransactionType.send
                                      ? const Color(0xFFFF5252)
                                      : const Color(0xFF00FF94),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ÚLTIMA TRANSAÇÃO",
                                      style: TextStyle(
                                        color: Color(0xFF00D4FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastTx.type == TransactionType.send
                                          ? "Enviado para ${lastTx.toAddress.length > 8 ? lastTx.toAddress.substring(0, 8) : lastTx.toAddress}..."
                                          : "Recebido de ${lastTx.fromAddress.length > 8 ? lastTx.fromAddress.substring(0, 8) : lastTx.fromAddress}...",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${lastTx.type == TransactionType.send ? '-' : '+'}${lastTx.amountBTC.toStringAsFixed(8)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              );
            },
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionItem(
                              context,
                              icon: Icons.north_east_rounded,
                              label: 'Transfer',
                              isSend: true,
                            ),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildActionItem(
                              context,
                              icon: Icons.south_west_rounded,
                              label: 'Receive',
                              isSend: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      );
    }

    // FALLBACK
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSend,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final walletState = ref.read(walletProvider);
          if (walletState is! WalletLoaded) return;
          final selectedWallet = walletState.selectedWallet;
          if (selectedWallet == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isSend
                  ? SendMoneyScreen(walletId: selectedWallet.id)
                  : ReceiveScreen(initialWallet: selectedWallet),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        blur: 30,
        opacity: 0.1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // ... mais detalhes ...
            Text(
              "Detalhes da Transação",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailItem("ID", tx.id),
            _buildDetailItem(
              "Status",
              tx.status.localized(context),
              valueColor: tx.status == TransactionStatus.confirmed
                  ? const Color(0xFF00FF94)
                  : Colors.orange,
            ),
            _buildDetailItem(
              "Quantia",
              "${tx.amountBTC.toStringAsFixed(8)} BTC",
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Fechar"),
              ),
            ),
            const SizedBox(height: 12),
            // Opção de excluir apenas se estiver falha ou algo assim?
            // Por agora vamos deixar simples.
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white.withValues(alpha: 0.1),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            "No wallets found",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Create a wallet to start monitoring transactions",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Create Wallet"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }



  // Removed _showWithdrawDialog and _buildWithdrawField
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
    return Column(
      children: [
        const SizedBox(height: 20),
        // Simple Huge Balance Display
        AnimatedBalanceDisplay(
          balance: totalBalanceBtc,
          decimalPlaces: 2, // Like B 22,578.66
          prefix: '₿ ', // Or simple 'B '
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class CircularActionItem extends StatelessWidget {
  final Widget icon;
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
            child: Center(child: icon),
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
        const Text(
          "Transactions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: showAll,
          onChanged: (val) => onSeeAll(),
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF00FF94),
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: Colors.white10,
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
    final isInternal = transaction.isInternal;
    final isPending = transaction.status == TransactionStatus.pending;
    final isVisible = ref.watch(balanceVisibilityProvider);

    // 1. Dynamic Title
    String title;
    if (isInternal) {
      title = isSent ? 'Transferência Enviada' : 'Transferência Recebida';
    } else {
      final address = isSent ? transaction.toAddress : transaction.fromAddress;
      title = address.length > 15
          ? "${address.substring(0, 8)}...${address.substring(address.length - 6)}"
          : address;
    }

    // 2. Dynamic Icon & Color
    IconData iconData;
    Color iconColor;
    Color iconBgColor;

    if (isPending) {
      iconData = Icons.hourglass_top_rounded;
      iconColor = Colors.orangeAccent;
      iconBgColor = Colors.orangeAccent.withValues(alpha: 0.1);
    } else if (isInternal) {
      iconData = isSent ? Icons.swap_horiz_rounded : Icons.swap_horiz_rounded;
      iconColor = const Color(0xFF7B61FF);
      iconBgColor = const Color(0xFF7B61FF).withValues(alpha: 0.1);
    } else {
      iconData = isSent
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
      iconColor = isSent ? const Color(0xFFFF5252) : const Color(0xFF00FF94);
      iconBgColor = iconColor.withValues(alpha: 0.1);
    }

    final typeLabel = transaction.type.localized(context);
    final subtitle = "$typeLabel • ${timeago.format(transaction.timestamp)}";
    final amount = isVisible
        ? "${isSent ? '-' : '+'}${transaction.amountBTC.toStringAsFixed(8)} BTC"
        : "•••••••• BTC";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                // Clean white circular icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isSent ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                      color: Colors.black,
                      size: 20
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Value
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
