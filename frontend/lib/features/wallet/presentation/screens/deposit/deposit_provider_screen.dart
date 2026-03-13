import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/wallet.dart';
import 'deposit_lightning_invoice_screen.dart';
import 'deposit_onchain_invoice_screen.dart';
import '../../../../../shared/widgets/brushed_metal_container.dart';

class DepositProviderScreen extends ConsumerWidget {
  final Wallet wallet;
  final double amountFiat;
  final String method; // 'Fiat'

  const DepositProviderScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
    required this.method,
  });

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
                    const SizedBox(height: 32),

                    _buildProviderCard(
                      context,
                      name: 'MoonPay',
                      description: 'Pix, Visa, Mastercard, Apple Pay',
                      iconData: Icons.shield_moon_rounded, // placeholder logo
                      badgeText: 'RECOMENDADO',
                      badgeColor: const Color(0xFF1A5CFF),
                    ),
                    const SizedBox(height: 16),
                    _buildProviderCard(
                      context,
                      name: 'Banxa',
                      description: 'Pix, Transferência Bancária, Cartão',
                      iconData:
                          Icons.currency_exchange_rounded, // placeholder logo
                      badgeText: 'Mais Rápido',
                      badgeColor: Colors.white.withOpacity(0.08),
                      badgeTextColor: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    _buildProviderCard(
                      context,
                      name: 'Mt Pelerin',
                      description: 'Sem KYC até R\$ 5.000, Pix, Cartão',
                      iconData:
                          Icons.account_balance_rounded, // placeholder logo
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLightning(BuildContext context, String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositLightningInvoiceScreen(
          wallet: wallet,
          amountFiat: amountFiat, // Pass fiat
          providerName: provider,
        ),
      ),
    );
  }

  void _navigateToOnchain(BuildContext context, String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositOnchainInvoiceScreen(
          wallet: wallet,
          amountFiat: amountFiat, // Pass fiat
          providerName: provider,
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
            'Selecione o Provedor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como deseja comprar?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione o melhor provedor para Pix ou Cartão.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData iconData,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (badgeColor ?? const Color(0xFF0033FF)).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (badgeColor ?? const Color(0xFF0033FF)).withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(iconData, color: Colors.black87, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeTextColor ?? Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNetworkButton(
                  icon: Icons.bolt_rounded,
                  label: 'Lightning',
                  onTap: () => _navigateToLightning(context, name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNetworkButton(
                  icon: Icons.link_rounded,
                  label: 'On-chain',
                  onTap: () => _navigateToOnchain(context, name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.06), // Dark button
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
