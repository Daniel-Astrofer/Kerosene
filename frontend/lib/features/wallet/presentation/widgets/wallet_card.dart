import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/wallet.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isSelected;

  const WalletCard({super.key, required this.wallet, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  const Color(0xFFFF9966), // Orange
                  const Color(0xFFFF5E62), // Pink
                  const Color(0xFF7B61FF), // Purple
                ]
              : [const Color(0xFF252A40), const Color(0xFF1A1F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF7B61FF).withOpacity(0.4)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 24 : 10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration (Soft glow)
          if (isSelected)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Name/Address + Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Name & Address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: wallet.address),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF00D4FF),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _formatAddress(wallet.address),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12, // Small monospace text
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: Logo (Mastercard style circles for Bitcoin)
                    SizedBox(
                      width: 40,
                      child: Stack(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Positioned(
                            left: 14,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom: Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${wallet.balanceSatoshis}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36, // Big bold balance
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "SATS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return "NO ADDRESS";
    return address;
  }
}
