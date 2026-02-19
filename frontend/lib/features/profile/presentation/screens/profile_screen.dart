import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    String username = "User";
    if (authState is AuthAuthenticated) {
      username = authState.user.name;
    }

    final walletState = ref.watch(walletProvider);
    final walletCount = walletState is WalletLoaded
        ? walletState.wallets.length
        : 0;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by parent/AppTheme
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Bar / Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.profile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GlassContainer(
                        blur: 10,
                        opacity: 0.1,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Avatar Section
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://i.pravatar.cc/300?u=a",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GlassContainer(
                          blur: 10,
                          opacity: 0.2,
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      "@${username.toLowerCase().replaceAll(' ', '')}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          AppLocalizations.of(context)!.wallets,
                          walletCount.toString(),
                          Icons.account_balance_wallet_rounded,
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          AppLocalizations.of(context)!.totalVolume,
                          "\$32.5k",
                          Icons.bar_chart_rounded,
                          const Color(0xFF00FF94),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Menu Options
                  Column(
                    children: [
                      _buildMenuItem(
                        Icons.person_outline_rounded,
                        AppLocalizations.of(context)!.personalData,
                      ),
                      _buildMenuItem(
                        Icons.security_rounded,
                        AppLocalizations.of(context)!.security,
                      ),
                      _buildMenuItem(
                        Icons.notifications_none_rounded,
                        AppLocalizations.of(context)!.notifications,
                      ),
                      _buildMenuItem(
                        Icons.help_outline_rounded,
                        AppLocalizations.of(context)!.helpSupport,
                      ),
                      _buildMenuItem(
                        Icons.settings_rounded,
                        AppLocalizations.of(context)!.settingsTitle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildMenuItem(
                        Icons.logout_rounded,
                        AppLocalizations.of(context)!.logout,
                        isDestructive: true,
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/welcome',
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Bottom padding for dock
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      blur: 15,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        blur: 10,
        opacity: 0.03,
        borderRadius: BorderRadius.circular(20),
        padding: EdgeInsets.zero, // Padding handled by InkWell
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDestructive
                        ? const Color(0xFFFF0055)
                        : Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDestructive
                            ? const Color(0xFFFF0055)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDestructive
                        ? const Color(0xFFFF0055).withValues(alpha: 0.5)
                        : Colors.white24,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
