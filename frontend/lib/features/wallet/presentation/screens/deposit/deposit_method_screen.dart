import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/wallet.dart';
import 'deposit_provider_screen.dart';
import 'deposit_lightning_invoice_screen.dart'; // We'll create this later
import 'deposit_onchain_invoice_screen.dart'; // We'll create this later
import '../../../../../shared/widgets/brushed_metal_container.dart';

class DepositMethodScreen extends ConsumerWidget {
  final Wallet wallet;
  final double amountFiat;

  const DepositMethodScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
  });

  void _navigateToProvider(BuildContext context, String method) {
    if (method == 'Lightning') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositLightningInvoiceScreen(
            wallet: wallet,
            amountFiat: amountFiat,
            providerName: 'Kerosene', // Direct crypto fallback
          ),
        ),
      );
    } else if (method == 'On-chain') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositOnchainInvoiceScreen(
            wallet: wallet,
            amountFiat: amountFiat,
            providerName: 'Kerosene', // Direct crypto fallback
          ),
        ),
      );
    } else {
      // Fiat gateway selected -> Go to provider screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositProviderScreen(
            wallet: wallet,
            amountFiat: amountFiat, // Pass fiat instead of BTC
            method: method,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BrushedMetalContainer(
        baseColor: const Color(0xFF0A0A0A),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 48),

                    _buildCategoryLabel('FIAT GATEWAY'),
                    const SizedBox(height: 16),
                    _buildMethodCard(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Pix & Credit Card',
                      subtitle: 'Instant funding via Ramps',
                      badgeText: 'FEE 0.99%',
                      badgeColor: const Color(0xFF1A5CFF),
                      onTap: () => _navigateToProvider(context, 'Fiat'),
                    ),

                    const SizedBox(height: 32),

                    _buildCategoryLabel('DIRECT CRYPTO'),
                    const SizedBox(height: 16),
                    _buildMethodCard(
                      context,
                      icon: Icons.bolt_rounded,
                      title: 'Lightning Network',
                      subtitle: 'Zero-fee, instant BTC transfer',
                      badgeText: 'FASTEST',
                      badgeColor: const Color(0xFF1A5CFF),
                      onTap: () => _navigateToProvider(context, 'Lightning'),
                    ),
                    const SizedBox(height: 16),
                    _buildMethodCard(
                      context,
                      icon: Icons.currency_bitcoin_rounded,
                      title: 'On-chain Transfer',
                      subtitle: 'Legacy Bitcoin deposit',
                      badgeText: '3 CONFIRMATIONS',
                      badgeColor: Colors.white.withOpacity(0.08),
                      badgeTextColor: Colors.white54,
                      onTap: () => _navigateToProvider(context, 'On-chain'),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooterSecurity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Text(
            'Deposit Funds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Select Method',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred funding source to begin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF1A5CFF).withOpacity(0.8), // Blue label
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    Color? badgeTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0033FF),
                borderRadius: BorderRadius.circular(16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor ?? badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSecurity() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            color: const Color(0xFF1A5CFF).withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'BANK-GRADE ENCRYPTED SECURITY',
            style: TextStyle(
              color: const Color(0xFF1A5CFF).withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
