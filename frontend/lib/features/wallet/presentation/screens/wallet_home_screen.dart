import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../widgets/wallet_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'send_money_screen.dart';

class WalletHomeScreen extends ConsumerStatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  ConsumerState<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends ConsumerState<WalletHomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050511),
      // Use Stack to place Floating Navigation Bar on top
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header (AppBar substitute)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 24,
                      right: 24,
                      bottom: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Cards',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        // Add Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            color: const Color(0xFF1A1F3C),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/create_wallet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Loading / Error / Content States
                if (walletState is WalletLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B61FF),
                      ),
                    ),
                  )
                else if (walletState is WalletError)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: ${walletState.message}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else if (walletState is WalletLoaded &&
                    walletState.wallets.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else if (walletState is WalletLoaded) ...[
                  // 3. Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260, // Accommodate card + shadow
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: walletState.wallets.length,
                        onPageChanged: (index) {
                          ref
                              .read(walletProvider.notifier)
                              .selectWallet(walletState.wallets[index]);
                          ref
                              .read(transactionProvider.notifier)
                              .loadTransactions(
                                walletState.wallets[index].name,
                              );
                        },
                        itemBuilder: (context, index) {
                          // Pass true/false for selection styling if desired, but we want all to look good
                          return GestureDetector(
                            onTap: () {
                              // Optional: Navigate to details or just select
                            },
                            child: WalletCard(
                              wallet: walletState.wallets[index],
                              isSelected:
                                  true, // Always show colorful card in carousel
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 4. Action Buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionPill(
                              icon: Icons.arrow_outward_rounded,
                              label: 'Transfer',
                              onTap: () {
                                final selected = walletState.selectedWallet;
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionPill(
                              icon: Icons.add_rounded,
                              label: 'Top up',
                              onTap: () {
                                // TODO: Receive
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // 5. "Features" Section (Security Toggles)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildFeatureToggle(
                          'Contactless Payment',
                          true,
                          Icons.contactless_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureToggle(
                          'Online Payment',
                          true,
                          Icons.public,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureToggle(
                          'ATM Withdrawals',
                          false,
                          Icons.local_atm_outlined,
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // 6. Transactions Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Weekly',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 7. Transactions List (SliverList)
                  _buildSliverTransactionsList(),

                  // Bottom Padding to clear Floating Nav Bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          ),

          // Floating Bottom Navigation
          _buildFloatingNavBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.wallet, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "No wallets yet",
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/create_wallet'),
              child: const Text("Create First Wallet"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggle(String title, bool value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFF7B61FF),
            activeTrackColor: const Color(0xFF7B61FF).withOpacity(0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTransactionsList() {
    return Consumer(
      builder: (context, ref, _) {
        final txState = ref.watch(transactionProvider);
        if (txState is TransactionLoaded) {
          if (txState.transactions.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    "No transactions",
                    style: TextStyle(color: Colors.white30),
                  ),
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tx = txState.transactions[index];
                final isReceive = tx.type == TransactionType.receive;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3C),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isReceive
                              ? const Color(0xFF00D4FF).withOpacity(0.1)
                              : const Color(0xFFFF5F6D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isReceive ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isReceive
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFFFF5F6D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              tx.timestamp.toString().substring(0, 10),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isReceive ? '+' : '-'}${tx.amountSatoshis}',
                        style: TextStyle(
                          color: isReceive
                              ? const Color(0xFF00D4FF)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: txState.transactions.length),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C).withOpacity(0.9),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(
                Icons.home_filled,
                color: Color(0xFF7B61FF),
                size: 28,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.credit_card,
                color: Colors.white38,
                size: 28,
              ),
              onPressed: () {},
            ),
            // Middle special button
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () {},
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.pie_chart_outline,
                color: Colors.white38,
                size: 28,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.person_outline,
                color: Colors.white38,
                size: 28,
              ),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
