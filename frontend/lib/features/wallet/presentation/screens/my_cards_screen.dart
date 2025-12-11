import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../widgets/wallet_card_carousel.dart';
import '../widgets/quick_contact_list.dart';
import '../widgets/recent_transactions_list.dart';

/// Tela My Cards
/// Exibe cartões do usuário, contatos rápidos e transações recentes
class MyCardsScreen extends ConsumerWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final transactionState = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Cards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrossel de cartões
            if (walletState is WalletLoaded)
              WalletCardCarousel(
                wallets: walletState.wallets,
                selectedWallet: walletState.selectedWallet,
                btcToUsdRate: walletState.btcToUsdRate,
                onWalletSelected: (wallet) {
                  ref.read(walletProvider.notifier).selectWallet(wallet);
                  // Carregar transações da carteira selecionada
                  ref
                      .read(transactionProvider.notifier)
                      .loadTransactions(wallet.id);
                },
              ),
            const SizedBox(height: 32),

            // Botão Send Money
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/send-money');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Send Money',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Contatos rápidos
            const QuickContactList(),
            const SizedBox(height: 32),

            // Transações recentes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Ver todas as transações
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF7B61FF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de transações
            if (transactionState is TransactionLoaded)
              RecentTransactionsList(
                transactions: transactionState.transactions.take(5).toList(),
              )
            else if (transactionState is TransactionLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7B61FF),
                ),
              )
            else if (transactionState is TransactionError)
              Center(
                child: Text(
                  transactionState.message,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', false),
          _buildNavItem(Icons.credit_card, 'Cards', true),
          _buildNavItem(Icons.analytics_outlined, 'Stats', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF7B61FF) : Colors.white54,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF7B61FF) : Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
