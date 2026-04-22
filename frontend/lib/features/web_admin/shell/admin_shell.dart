import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/admin_routes.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

/// The main shell for the enterprise web admin panel.
/// Contains sidebar navigation, top bar, and content area.
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          const _AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                const _AdminTopBar(),
                const Divider(height: 1, color: AdminColors.border),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminRouteProvider);

    return Container(
      width: AdminTheme.sidebarWidth,
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            height: AdminTheme.topBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AdminTheme.spacingLg),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AdminColors.accent,
                    borderRadius: AdminTheme.borderRadiusXs,
                  ),
                  child: const Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        fontFamily: 'HubotSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                const Text(
                  'KEROSENE',
                  style: TextStyle(
                    fontFamily: 'HubotSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.borderSubtle),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AdminTheme.spacingMd,
                horizontal: AdminTheme.spacingSm,
              ),
              children: [
                _NavSection(
                  label: 'OVERVIEW',
                  items: [
                    AdminRoute.dashboard,
                    AdminRoute.analytics,
                    AdminRoute.volatility,
                  ],
                  activeRoute: activeRoute,
                  onSelect: (r) => ref.read(adminRouteProvider.notifier).navigate(r),
                ),
                const SizedBox(height: AdminTheme.spacingLg),
                _NavSection(
                  label: 'OPERATIONS',
                  items: [
                    AdminRoute.transactions,
                    AdminRoute.lightning,
                    AdminRoute.onchain,
                    AdminRoute.checks,
                    AdminRoute.paymentLinks,
                  ],
                  activeRoute: activeRoute,
                  onSelect: (r) => ref.read(adminRouteProvider.notifier).navigate(r),
                ),
                const SizedBox(height: AdminTheme.spacingLg),
                _NavSection(
                  label: 'MANAGEMENT',
                  items: [
                    AdminRoute.companies,
                    AdminRoute.audit,
                    AdminRoute.settings,
                  ],
                  activeRoute: activeRoute,
                  onSelect: (r) => ref.read(adminRouteProvider.notifier).navigate(r),
                ),
              ],
            ),
          ),

          // Bottom status
          const Divider(height: 1, color: AdminColors.borderSubtle),
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.positive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingSm),
                Text(
                  'System Operational',
                  style: AdminTypography.caption.copyWith(
                    color: AdminColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String label;
  final List<AdminRoute> items;
  final AdminRoute activeRoute;
  final ValueChanged<AdminRoute> onSelect;

  const _NavSection({
    required this.label,
    required this.items,
    required this.activeRoute,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminTheme.spacingMd,
            0,
            AdminTheme.spacingMd,
            AdminTheme.spacingSm,
          ),
          child: Text(
            label,
            style: AdminTypography.label.copyWith(
              fontSize: 10,
              color: AdminColors.textDisabled,
            ),
          ),
        ),
        ...items.map((route) => _NavItem(
              route: route,
              isActive: activeRoute == route,
              onTap: () => onSelect(route),
            )),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  final AdminRoute route;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.route,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AdminTheme.spacingMd,
            vertical: AdminTheme.spacingSm + 2,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AdminColors.sidebarActive
                : _isHovered
                    ? AdminColors.sidebarHover
                    : Colors.transparent,
            borderRadius: AdminTheme.borderRadiusXs,
            border: widget.isActive
                ? Border.all(color: AdminColors.borderSubtle, width: 0.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.route.icon,
                size: 18,
                color: widget.isActive
                    ? AdminColors.sidebarTextActive
                    : AdminColors.sidebarText,
              ),
              const SizedBox(width: AdminTheme.spacingMd),
              Text(
                widget.route.label,
                style: AdminTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: widget.isActive
                      ? AdminColors.sidebarTextActive
                      : AdminColors.sidebarText,
                  fontWeight:
                      widget.isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminRouteProvider);
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);
    final totalBalance = ref.watch(adminTotalBalanceProvider);

    return Container(
      height: AdminTheme.topBarHeight,
      color: AdminColors.backgroundElevated,
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.spacingXl),
      child: Row(
        children: [
          Text(
            activeRoute.label,
            style: AdminTypography.h4,
          ),
          const Spacer(),

          // BTC Price indicator
          btcPriceAsync.when(
            data: (prices) {
              final usd = prices['btcUsd'] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminTheme.spacingMd,
                  vertical: AdminTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  border: Border.all(color: AdminColors.border),
                  borderRadius: AdminTheme.borderRadiusXs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_bitcoin,
                        size: 14, color: AdminColors.warning),
                    const SizedBox(width: AdminTheme.spacingXs),
                    Text(
                      'BTC \$${_formatPrice(usd)}',
                      style: AdminTypography.mono.copyWith(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(width: AdminTheme.spacingLg),

          // Consolidated balance
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.spacingMd,
              vertical: AdminTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              border: Border.all(color: AdminColors.border),
              borderRadius: AdminTheme.borderRadiusXs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: AdminColors.textTertiary),
                const SizedBox(width: AdminTheme.spacingXs),
                Text(
                  '${totalBalance.toStringAsFixed(8)} BTC',
                  style: AdminTypography.mono.copyWith(
                    color: AdminColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AdminTheme.spacingLg),

          // User avatar placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AdminColors.surfaceElevated,
              border: Border.all(color: AdminColors.border),
              borderRadius: AdminTheme.borderRadiusXs,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 18,
              color: AdminColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}k';
    }
    return price.toStringAsFixed(2);
  }
}
