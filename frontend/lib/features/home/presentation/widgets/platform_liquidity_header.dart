import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../l10n/l10n_extension.dart';
import 'animated_balance_display.dart';

class PlatformLiquidityHeader extends StatefulWidget {
  const PlatformLiquidityHeader({super.key});

  @override
  State<PlatformLiquidityHeader> createState() =>
      _PlatformLiquidityHeaderState();
}

class _PlatformLiquidityHeaderState extends State<PlatformLiquidityHeader> {
  // Mock Real-time Data
  double _totalLiquidity = 14502.50; // Base BTC
  final List<String> _deposits = [];
  final List<String> _withdrawals = [];
  final _random = math.Random();
  Timer? _mockDataTimer;

  // Track the most recent "action" direction for visual indication
  bool _lastActionWasDeposit = true;
  double _lastActionAmount = 0;

  @override
  void initState() {
    super.initState();
    _startMockStream();
  }

  @override
  void dispose() {
    _mockDataTimer?.cancel();
    super.dispose();
  }

  void _startMockStream() {
    // Initial data
    _generateMockAddress(isDeposit: true);
    _generateMockAddress(isDeposit: false);

    // Update every ~800ms to 2.5s for a realistic incoming feed feel
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (!mounted) return;

      setState(() {
        // 60% chance of deposit, 40% chance of withdrawal for visual variety
        final isDeposit = _random.nextDouble() > 0.4;
        final amount = _random.nextDouble() * 2.5; // Up to 2.5 BTC

        _generateMockAddress(isDeposit: isDeposit);
        _lastActionWasDeposit = isDeposit;
        _lastActionAmount = amount;

        if (isDeposit) {
          _totalLiquidity += amount;
        } else {
          _totalLiquidity -= amount;
        }
      });
    });
  }

  void _generateMockAddress({required bool isDeposit}) {
    // Generate a fake hash that looks like a BTC address snippet
    const chars = 'abcdef0123456789';
    String hash = 'bc1';
    for (int i = 0; i < 6; i++) {
      hash += chars[_random.nextInt(chars.length)];
    }
    hash += '...';
    for (int i = 0; i < 4; i++) {
      hash += chars[_random.nextInt(chars.length)];
    }

    if (isDeposit) {
      _deposits.insert(0, hash);
      if (_deposits.length > 3) _deposits.removeLast(); // Keep only latest 3
    } else {
      _withdrawals.insert(0, hash);
      if (_withdrawals.length > 3) {
        _withdrawals.removeLast(); // Keep only latest 3
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        opacity: 0.1,
        blur: 15,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ensure they always show up but scale down if needed
            final isSmall = constraints.maxWidth < 360;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Deposits (Green) - Hide on very narrow screens or simplify
                Expanded(
                  flex: isSmall ? 1 : 2,
                  child: _buildAddressList(
                    title: context.l10n.homeDeposits,
                    addresses: _deposits,
                    color: const Color(0xFF00FF94),
                    alignRight: false,
                    isSmall: isSmall,
                  ),
                ),

                // Center: Ticking Balance
                Expanded(
                  flex: isSmall ? 2 : 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.homePlatformLiquidity,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedBalanceDisplay(
                            balance: _totalLiquidity,
                            enableFlash: true,
                            decimalPlaces:
                                4, // Show 4 decimals for high frequency updates
                            prefix: '₿',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Small indicator below showing latest +/- amount
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            '${_lastActionWasDeposit ? '+' : '-'}${_lastActionAmount.toStringAsFixed(4)}',
                            key: ValueKey(
                              '$_lastActionAmount-$_lastActionWasDeposit',
                            ),
                            style: TextStyle(
                              color: _lastActionWasDeposit
                                  ? const Color(
                                      0xFF00FF94,
                                    ).withValues(alpha: 0.8)
                                  : const Color(
                                      0xFFFF0055,
                                    ).withValues(alpha: 0.8),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Withdrawals (Red)
                Expanded(
                  flex: isSmall ? 1 : 2,
                  child: _buildAddressList(
                    title: context.l10n.homeWithdrawals,
                    addresses: _withdrawals,
                    color: const Color(0xFFFF0055),
                    alignRight: true,
                    isSmall: isSmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressList({
    required String title,
    required List<String> addresses,
    required Color color,
    required bool alignRight,
    bool isSmall = false,
  }) {
    final AlignmentGeometry alignment = alignRight
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final CrossAxisAlignment colAlign = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: colAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: isSmall ? 7 : 9,
                fontWeight: FontWeight.bold,
                letterSpacing: isSmall ? 0.5 : 1.0,
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48, // Fixed height for 3 lines
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, -0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            // We use a unique key based on the list contents so it animates when it changes
            child: ListView.builder(
              key: ValueKey(addresses.join(',')),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final alpha = 1.0 - (index * 0.35); // Fade out older items
                return Align(
                  alignment: alignment,
                  child: Text(
                    addresses[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isSmall ? 8 : 10,
                      color: color.withValues(alpha: alpha.clamp(0.1, 1.0)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
