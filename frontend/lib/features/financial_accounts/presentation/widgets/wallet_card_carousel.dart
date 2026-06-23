import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'wallet_credit_card.dart';

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
      height: 218,
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
            duration: KeroseneMotion.medium,
            child: _buildWalletCard(wallet),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: WalletCreditCard(
          wallet: wallet,
          colorIndex: WalletCardType.values.indexOf(wallet.cardType),
          isSelected: wallet.id == selectedWallet?.id,
          showDetails: true,
          onTap: () => onWalletSelected(wallet),
        ),
      ),
    );
  }
}
