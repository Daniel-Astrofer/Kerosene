import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/brushed_metal_container.dart';
import '../../domain/entities/wallet.dart';
import '../providers/wallet_provider.dart';
import '../screens/wallet_config_screen.dart';

class WalletCreditCard extends ConsumerStatefulWidget {
  final Wallet wallet;
  final int colorIndex;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Controls dynamic shadow depth (0.0 = flat, 1.0 = lifted)
  final double elevation;

  /// Whether to show sensitive details like balance/number
  final bool showDetails;

  const WalletCreditCard({
    super.key,
    required this.wallet,
    required this.colorIndex,
    this.isSelected = false,
    this.onTap,
    this.elevation = 0.0,
    this.showDetails = true,
  });

  @override
  ConsumerState<WalletCreditCard> createState() => _WalletCreditCardState();
}

class _WalletCreditCardState extends ConsumerState<WalletCreditCard> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final theme = _getWalletTheme(widget.colorIndex);

    // Watch global privacy state
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);

    // Dynamic shadow physics
    final double effectiveElevation = widget.isSelected
        ? 1.0
        : widget.elevation;
    final bool showShadow = effectiveElevation >= 0.0;

    final double shadowBlur = 10 + (20 * effectiveElevation);
    final double shadowDy = 5 + (15 * effectiveElevation);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WalletConfigScreen(wallet: widget.wallet),
          ),
        );
      },
      child: Center(
        child: Container(
          height: 170,
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.secondaryColor],
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withValues(
                        alpha: (0.4 + (0.2 * effectiveElevation)).clamp(
                          0.0,
                          0.8,
                        ),
                      ),
                      blurRadius: shadowBlur,
                      offset: Offset(0, shadowDy),
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // 1. Texture (Optional/Subtle)
              if (theme.isMetallic)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Opacity(
                    opacity: 0.1,
                    child: BrushedMetalContainer(width: width, height: 200),
                  ),
                ),

              // 2. Card Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header: Wallet Name (Left) + Logo (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Wallet Name (Left)
                        Expanded(
                          child: Text(
                            widget.wallet.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Kerosene Logo (Right, Small)
                        Image.asset(
                          'assets/kerosenelogo.png',
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Footer: Balance & Address
                    if (widget.showDetails)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Balance
                          Text(
                            isBalanceVisible
                                ? "${widget.wallet.balance.toStringAsFixed(8)} BTC"
                                : "************",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Address (Masked)
                          Text(
                            _maskAddress(widget.wallet.address),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    else
                      // Interactive Hint (When collapsed)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
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
  }

  _WalletTheme _getWalletTheme(int index) {
    final themes = [
      _WalletTheme(
        primaryColor: const Color(0xFF1A1A1A),
        secondaryColor: Colors.black,
        isMetallic: true,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF0D47A1),
        secondaryColor: Colors.blue,
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFFB71C1C),
        secondaryColor: Colors.red,
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF1B5E20),
        secondaryColor: Colors.green,
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF4A148C),
        secondaryColor: Colors.purple,
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFFE65100),
        secondaryColor: Colors.orange,
        isMetallic: false,
      ),
    ];
    return themes[index % themes.length];
  }

  String _maskAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }
}

class _WalletTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isMetallic;

  _WalletTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isMetallic,
  });
}
