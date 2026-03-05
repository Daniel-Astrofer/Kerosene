import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/brushed_metal_container.dart';
import '../../domain/entities/wallet.dart';
import '../providers/wallet_provider.dart';
import '../screens/wallet_config_screen.dart';

class WalletCreditCard extends ConsumerStatefulWidget {
  final Wallet? wallet;
  final int colorIndex;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isAddCard;

  /// Controls dynamic shadow depth (0.0 = flat, 1.0 = lifted)
  final double elevation;

  /// Whether to show sensitive details like balance/number
  final bool showDetails;

  const WalletCreditCard({
    super.key,
    this.wallet,
    required this.colorIndex,
    this.isSelected = false,
    this.onTap,
    this.elevation = 0.0,
    this.showDetails = true,
    this.isAddCard = false,
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

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        if (widget.isAddCard) return;
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WalletConfigScreen(wallet: widget.wallet!),
          ),
        );
      },
      child: Center(
        child: Container(
          height: 170,
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.secondaryColor],
            ),
            boxShadow: [
              if (showShadow)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Stack(
            children: [
              // 0. Animated Moving Glow Background
              if (!widget.isAddCard)
                _AnimatedCardGlow(
                  primaryColor: theme.primaryColor,
                  secondaryColor: theme.secondaryColor,
                ),

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
                child: widget.isAddCard
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "ADICIONAR CARD",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
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
                                  widget.wallet?.name.toUpperCase() ?? "",
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
                                _buildFormattedBalance(
                                  isBalanceVisible
                                      ? (widget.wallet?.balance ?? 0.0)
                                      : null,
                                ),
                                const SizedBox(height: 4),

                                // Address (Masked)
                                Text(
                                  _maskAddress(widget.wallet?.address ?? ""),
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

  Widget _buildFormattedBalance(double? balance) {
    if (balance == null) {
      return const Text(
        "************",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
    }

    final String btcStr = balance.toStringAsFixed(8);
    final List<String> parts = btcStr.split('.');
    final String mainPart = parts[0];
    final String decimalPart = parts.length > 1 ? parts[1] : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          mainPart,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const Text(
          ".",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          decimalPart,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          "BTC",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  _WalletTheme _getWalletTheme(int index) {
    final themes = [
      _WalletTheme(
        primaryColor: const Color(0xFF0A0A0A),
        secondaryColor: const Color(0xFF00BFFF), // Deep Sky Blue
        isMetallic: true,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF0D1B2A),
        secondaryColor: const Color(0xFF4CC9F0), // Cyan
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF1B4332),
        secondaryColor: const Color(0xFF74C69D), // Light Green
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF480CA8),
        secondaryColor: const Color(0xFFB517AD), // Magenta
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF370617),
        secondaryColor: const Color(0xFFD00000), // Red
        isMetallic: false,
      ),
      _WalletTheme(
        primaryColor: const Color(0xFF2D1E2F),
        secondaryColor: const Color(0xFFFF9E00), // Orange
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

class _AnimatedCardGlow extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _AnimatedCardGlow({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_AnimatedCardGlow> createState() => _AnimatedCardGlowState();
}

class _AnimatedCardGlowState extends State<_AnimatedCardGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        final double x = sin(t * 2 * pi) * 0.3;
        final double y = cos(t * 2 * pi) * 0.2;

        return Stack(
          children: [
            // Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Moving Glow
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(x, y),
                    radius: 1.5,
                    colors: [
                      widget.secondaryColor.withValues(alpha: 0.4),
                      widget.secondaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Top highlight
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
