import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/market/presentation/screens/market_screen.dart';
import 'package:teste/features/p2p/presentation/screens/p2p_screen.dart';
import 'package:teste/features/profile/presentation/screens/profile_screen.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/payment_request.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../widgets/wallet_card_stack.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'send_money_screen.dart';
import 'create_wallet_screen.dart';
import 'receive_screen.dart';
import 'wallet_details_screen.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/presentation/widgets/nfc_scan_dialog.dart';
import 'qr_scanner_screen.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class WalletHomeScreen extends ConsumerStatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  ConsumerState<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends ConsumerState<WalletHomeScreen> {
  int _currentIndex = 0;
  int _currentTabIndex = 0;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
    });
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
      ref
          .read(transactionProvider.notifier)
          .loadTransactions(selectedWallet.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient
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
          IndexedStack(
            index: _currentTabIndex,
            children: [
              // 0: Home Tab
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: () async {
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
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/welcome',
                                    );
                                  },
                                  child: const Icon(
                                    Icons.logout_rounded,
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
                      SliverToBoxAdapter(
                        child: _buildWalletContent(walletState),
                      ),

                      // Padding bottom for floating dock
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),

              // 1: Market Tab
              const MarketScreen(),

              // 2: P2P Tab
              const P2PScreen(),

              // 3: Profile Tab
              const ProfileScreen(),
            ],
          ),

          // Floating Bottom Navigation Dock
          _buildFloatingDock(),
        ],
      ),
    );
  }

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
              _buildDockIcon(Icons.home_rounded, 0),
              const SizedBox(width: 20),
              _buildDockIcon(
                Icons.show_chart_rounded,
                1,
              ), // Changed to Chart for Monitor
              const SizedBox(width: 20),
              _buildDockIcon(Icons.chat_bubble_outline_rounded, 2),
              const SizedBox(width: 20),
              _buildDockIcon(Icons.person_outline_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD0F288) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildWalletContent(WalletState state) {
    if (state is WalletLoading) {
      return const SizedBox(
        height: 600,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
      );
    }

    if (state is WalletError) {
      return SizedBox(
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
      );
    }

    if (state is WalletLoaded) {
      if (state.wallets.isEmpty) {
        return _buildEmptyState();
      }

      if (_currentIndex >= state.wallets.length) {
        _currentIndex = 0;
      }

      final currentWallet = state.wallets[_currentIndex];
      final totalBalanceBtc = state.wallets.fold<double>(
        0,
        (sum, w) => sum + w.balance,
      );
      final screenWidth = MediaQuery.of(context).size.width;
      final maxContentWidth = screenWidth > 500 ? 440.0 : screenWidth;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 400 ? 24 : 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 1. Balance Section (Top Center) - Animated Entry (0ms delay)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Column(
                          children: [
                            Text(
                              'Saldo total',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isBalanceVisible
                                          ? '${totalBalanceBtc.toStringAsFixed(8)} BTC'
                                          : "••••••••",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 44, // Increased size
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isBalanceVisible = !_isBalanceVisible;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: const Color(0xFF00D4FF),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // 2. Cards Stack - Animated Entry (200ms delay)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    final visibility = (value * 1.25 - 0.25).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: visibility,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - visibility)),
                        child: WalletCardStack(
                          wallets: state.wallets,
                          onIndexChanged: _onIndexChanged,
                          onAddressCopied: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Endereço copiado'),
                                  backgroundColor: Color(0xFFF7931A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onCardTap: (wallet) {
                            ref
                                .read(walletProvider.notifier)
                                .selectWallet(wallet);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WalletDetailsScreen(wallet: wallet),
                              ),
                            );
                          },
                          onNfcPressed: () async {
                            final paymentRequestString =
                                await showDialog<String>(
                                  context: context,
                                  builder: (context) => const NfcScanDialog(),
                                );

                            if (paymentRequestString == null || !mounted)
                              return;

                            final request = PaymentRequest.tryParse(
                              paymentRequestString,
                            );
                            if (request == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tag NFC não contém um pedido de pagamento válido.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            final walletState = ref.read(walletProvider);
                            if (walletState is! WalletLoaded ||
                                walletState.selectedWallet == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selecione uma carteira para enviar.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SendMoneyScreen(
                                  walletId: walletState.selectedWallet!.name,
                                  initialAddress: request.address,
                                  initialAmountBtc: request.amountBtc,
                                ),
                              ),
                            );
                          },
                          onQrPressed: () async {
                            final code = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            );

                            if (code == null || !mounted) return;

                            final request = PaymentRequest.tryParse(code);
                            if (request == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QR Code inválido.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final walletState = ref.read(walletProvider);
                            if (walletState is! WalletLoaded ||
                                walletState.selectedWallet == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selecione uma carteira para enviar.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SendMoneyScreen(
                                  walletId: walletState.selectedWallet!.name,
                                  initialAddress: request.address,
                                  initialAmountBtc: request.amountBtc,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Saldo da carteira selecionada — abaixo do cartão, à esquerda
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentWallet.name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentWallet.balance.toStringAsFixed(8)} BTC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Actions Panel - Animated Entry (400ms delay)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final visibility = (value * 1.5 - 0.5).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: visibility,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * visibility),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ações",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Improved Action Buttons Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: _buildCircularAction(
                                    icon: Icons.add_rounded,
                                    label: "Add",
                                    color: Colors.white60,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateWalletScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Flexible(
                                  child: _buildCircularAction(
                                    icon: Icons.arrow_outward_rounded,
                                    label: "Send",
                                    color: Colors.white60,
                                    onTap: () {
                                      final selected = state.selectedWallet;
                                      if (selected != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SendMoneyScreen(
                                              walletId: selected.name,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Flexible(
                                  child: _buildCircularAction(
                                    icon: Icons.call_received_rounded,
                                    label: "Receive",
                                    color: Colors.white60,
                                    onTap: () {
                                      final selected = state.selectedWallet;
                                      if (selected != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiveScreen(wallet: selected),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const SizedBox(height: 30),
                // 4. Transactions List - Animated Entry (600ms delay)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final visibility = (value * 2.0 - 1.0).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: visibility,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - visibility)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Transações",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionsWidget(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTransactionsWidget() {
    return Consumer(
      builder: (context, ref, _) {
        final transactions = ref.watch(transactionHistoryProvider);

        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Nenhuma transação encontrada",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          children: transactions.take(5).map((tx) {
            final isReceive = tx.type == TransactionType.receive;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildTransactionItem(
                icon: isReceive ? Icons.arrow_downward : Icons.arrow_outward,
                title: tx.description ?? "Transferência",
                time: timeago.format(tx.timestamp),
                amount:
                    '${isReceive ? '+' : '-'}${tx.amountBTC.toStringAsFixed(8)} BTC',
                type: isReceive ? "Income" : "Transfer",
                isPositive: isReceive,
                onTap: () => _showTransactionDetails(context, tx),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 54, // Explicit smaller width
            height: 54, // Explicit smaller height
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
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

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String time,
    required String amount,
    required String type,
    bool isPositive = false,
    VoidCallback? onTap,
  }) {
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
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
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
                      color: isPositive
                          ? const Color(0xFF00FF94)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              height: 600, // Increased height
              blur: 50,
              opacity: 0.08,
              borderRadius: BorderRadius.circular(40),
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
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
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FROM
                    const Text(
                      "DE",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      tx.fromAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // TO
                    const Text(
                      "PARA",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      tx.toAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
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
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Hash copiado!"),
                                  ),
                                );
                              }
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
