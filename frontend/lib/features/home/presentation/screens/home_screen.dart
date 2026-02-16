import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';

import '../../../wallet/presentation/widgets/wallet_card_stack_draggable.dart';
import '../../../wallet/presentation/widgets/wallet_card.dart';
import '../../../wallet/presentation/screens/wallet_details_screen.dart';
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../widgets/nfc_searching_overlay.dart';
import 'qr_scanner_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/receive_screen.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/domain/entities/transaction.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../market/presentation/screens/market_screen.dart';
import '../../../p2p/presentation/screens/p2p_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _activeTab = 0; // 0: Home, 1: Market, 2: Chat, 3: Profile
  bool _isNfcSearching = false;

  @override
  void initState() {
    super.initState();

    // Iniciar carregamento das wallets e transações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
      ref.read(transactionHistoryProvider.notifier).loadTransactions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-carregar imagens dos cartões para evitar flickering/sumiço
    WalletCard.precacheAllImages(context);
  }

  void _onIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    final walletState = ref.read(walletProvider);
    if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
      final selectedWallet = walletState.wallets[index];
      ref.read(walletProvider.notifier).selectWallet(selectedWallet);
      ref.read(walletProvider.notifier).updateWalletBalance(selectedWallet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Main Content
          KeyedSubtree(
            key: ValueKey('tab_$_activeTab'),
            child: _buildBody(walletState),
          ),

          // Floating Bottom Navigation Dock
          _buildFloatingDock(),

          // NFC Searching Overlay
          if (_isNfcSearching)
            NfcSearchingOverlay(
              onCancel: () {
                setState(() {
                  _isNfcSearching = false;
                });
              },
              onTagRead: (tagData) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('NFC: $tagData')));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody(WalletState walletState) {
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
      child: RefreshIndicator(
        onRefresh: () async {
          // Re-precarregar e atualizar dados
          WalletCard.precacheAllImages(context);
          await ref.read(walletProvider.notifier).refresh();
        },
        color: const Color(0xFF00D4FF),
        backgroundColor: const Color(0xFF1A1F3C),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "Error loading wallets",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                TextButton(
                  onPressed: () => ref.read(walletProvider.notifier).refresh(),
                  child: const Text("Try Again"),
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
                    child: DraggableWalletCardStack(
                      wallets: state.wallets,
                      onIndexChanged: _onIndexChanged,
                      onCardTap: (wallet) {
                        ref.read(walletProvider.notifier).selectWallet(wallet);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalletDetailsScreen(wallet: wallet),
                          ),
                        );
                      },
                      onCardSwipedAway: (wallet) {
                        // Trigger haptic feedback
                        HapticFeedback.mediumImpact();
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
                              label: "Add",
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
                              icon: Icons.arrow_outward_rounded,
                              label: "Send",
                              color: Colors.blueAccent,
                              onTap: () {
                                if (state.selectedWallet != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SendMoneyScreen(
                                        walletId: state.selectedWallet!.id,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Flexible(
                            child: CircularActionItem(
                              icon: Icons.call_received_rounded,
                              label: "Receive",
                              color: Colors.greenAccent,
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
                              label: "NFC",
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
                              label: "QR Code",
                              color: Colors.grey[700]!,
                              onTap: () async {
                                final result = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const QrScannerScreen(),
                                  ),
                                );
                                if (result != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('QR Code: $result')),
                                  );
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

          // 4. Transactions Title
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: TransactionListHeader()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 5. Optimized Transaction List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Consumer(
              builder: (context, ref, child) {
                final transactions = ref.watch(transactionHistoryProvider);
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "No transactions yet",
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
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
                          isSent ? Icons.arrow_outward : Icons.arrow_downward,
                          color: isSent
                              ? const Color(0xFF7B61FF)
                              : const Color(0xFF00FF94),
                          size: 20,
                        ),
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
                    isSent ? "Enviado para" : "Recebido de",
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
                        child: _buildDetailItem(
                          "VALOR",
                          "${tx.amountBTC.toStringAsFixed(8)} BTC",
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          "TAXA",
                          "${tx.feeBTC.toStringAsFixed(8)} BTC",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          "DATA",
                          "${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}",
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          "STATUS",
                          tx.status.displayName.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "HASH DA TRANSAÇÃO",
                    style: TextStyle(
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tx.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Hash copiado!")),
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

  Widget _buildDetailItem(String label, String value) {
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
          const Text(
            "No Wallets Found",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first Bitcoin wallet to get started.",
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.black),
                  SizedBox(width: 12),
                  Text(
                    "Create Wallet",
                    style: TextStyle(
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
}

class TotalBalanceDisplay extends StatefulWidget {
  final List<dynamic> wallets;
  const TotalBalanceDisplay({super.key, required this.wallets});

  @override
  State<TotalBalanceDisplay> createState() => _TotalBalanceDisplayState();
}

class _TotalBalanceDisplayState extends State<TotalBalanceDisplay> {
  bool _isBalanceVisible = true;

  String _formatTotalBtcBalance(List<dynamic> wallets) {
    double total = 0;
    for (var w in wallets) {
      total += w.balance ?? 0.0;
    }
    return total.toStringAsFixed(8);
  }

  @override
  Widget build(BuildContext context) {
    final balanceText = _isBalanceVisible
        ? _formatTotalBtcBalance(widget.wallets)
        : "••••••••";

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Balance (BTC)",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isBalanceVisible = !_isBalanceVisible;
                });
              },
              child: Icon(
                _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF00D4FF),
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          key: ValueKey(balanceText),
          tween: Tween(begin: 0.0, end: balanceText.length.toDouble()),
          duration: Duration(milliseconds: balanceText.length * 110),
          builder: (context, value, child) {
            final currentText = balanceText.substring(0, value.toInt());
            return Text(
              currentText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.5,
              ),
            );
          },
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
  const TransactionListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            "See All",
            style: TextStyle(
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

class TransactionListItem extends StatelessWidget {
  final dynamic transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = transaction.type == TransactionType.send;
    final title = isSent ? transaction.toAddress : transaction.fromAddress;
    final subtitle =
        "${transaction.type.displayName} • ${timeago.format(transaction.timestamp)}";
    final amount =
        "${isSent ? '-' : '+'}${transaction.amountBTC.toStringAsFixed(8)} BTC";

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
                  isSent ? Icons.arrow_outward : Icons.arrow_downward,
                  color: Colors.white,
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
                    transaction.status.displayName,
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
