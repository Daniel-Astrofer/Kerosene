import 'package:flutter/material.dart';
import '../../domain/entities/wallet.dart';

/// Carrossel de cartões de carteira
class WalletCardCarousel extends StatelessWidget {
  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final double btcToUsdRate;
  final Function(Wallet) onWalletSelected;

  const WalletCardCarousel({
    super.key,
    required this.wallets,
    this.selectedWallet,
    required this.btcToUsdRate,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: wallets.length,
        controller: PageController(viewportFraction: 0.85),
        onPageChanged: (index) {
          onWalletSelected(wallets[index]);
        },
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          final isSelected = wallet.id == selectedWallet?.id;

          return AnimatedScale(
            scale: isSelected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 300),
            child: _buildWalletCard(wallet),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7B61FF),
            const Color(0xFF00D4FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo do cartão
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Icon(
                Icons.contactless,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),

          // Nome e número do cartão
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatAddress(wallet.address),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length < 16) return address;
    return '${address.substring(0, 4)} ${address.substring(4, 8)} ${address.substring(8, 12)} ****';
  }
}
