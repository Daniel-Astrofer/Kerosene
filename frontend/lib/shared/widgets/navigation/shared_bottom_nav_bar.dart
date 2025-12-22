import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/wallet/presentation/providers/wallet_provider.dart';
import '../../../features/wallet/presentation/state/wallet_state.dart';
import '../../../features/wallet/presentation/screens/wallet_home_screen.dart';
import '../../../features/wallet/presentation/screens/my_cards_screen.dart';
import '../../../features/wallet/presentation/screens/send_money_screen.dart';
import '../../../features/wallet/presentation/screens/analytics_screen.dart';

class SharedBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const SharedBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // 0: Home
            _buildNavButton(
              context,
              icon: Icons.home_filled,
              index: 0,
              onPressed: () {
                if (currentIndex != 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletHomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),

            // 1: Cards
            _buildNavButton(
              context,
              icon: Icons.credit_card,
              index: 1,
              onPressed: () {
                if (currentIndex != 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCardsScreen()),
                  );
                }
              },
            ),

            // 2: QR / Send (Center)
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
                onPressed: () {
                  final walletState = ref.read(walletProvider);
                  String? walletName;
                  if (walletState is WalletLoaded &&
                      walletState.selectedWallet != null) {
                    walletName = walletState.selectedWallet!.name;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SendMoneyScreen(walletId: walletName ?? 'default'),
                    ),
                  );
                },
              ),
            ),

            // 3: Analytics
            _buildNavButton(
              context,
              icon: Icons.pie_chart_outline,
              index: 3,
              onPressed: () {
                if (currentIndex != 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                }
              },
            ),

            // 4: Profile (Logout for now)
            _buildNavButton(
              context,
              icon: Icons.person_outline,
              index: 4,
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required int index,
    required VoidCallback onPressed,
  }) {
    final bool isSelected = currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF7B61FF) : Colors.white38,
        size: 28,
      ),
      onPressed: onPressed,
    );
  }
}
