import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/design_system/brand.dart';
import '../navigation/admin_routes.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_copy.dart';
import '../theme/admin_theme.dart';
import '../providers/admin_providers.dart';
import 'package:kerosene/design_system/icons.dart';

/// The main shell for the enterprise web admin panel.
/// Contains sidebar navigation, top bar, and content area.
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed = constraints.maxWidth < 920;

        return Scaffold(
          backgroundColor: AdminColors.background,
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _AdminSidebar(collapsed: collapsed),
                Expanded(
                  child: Column(
                    children: [
                      _AdminTopBar(compact: collapsed),
                      const Divider(height: 1, color: AdminColors.border),
                      const _AdminAccessNotice(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminAccessNotice extends StatelessWidget {
  const _AdminAccessNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingLg,
        vertical: AdminTheme.spacingSm,
      ),
      color: AdminColors.warningSubtle,
      child: Text(
        context.tr.adminLoginApprovalRegistered,
        style: AdminTypography.caption.copyWith(color: AdminColors.warning),
      ),
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  final bool collapsed;

  const _AdminSidebar({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminRouteProvider);

    return Container(
      width: collapsed
          ? AdminTheme.sidebarCollapsedWidth
          : AdminTheme.sidebarWidth,
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            height: AdminTheme.topBarHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.spacingLg,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
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
                      AdminCopy.brandInitial,
                      style: TextStyle(
                        fontFamily: AdminTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: AdminTheme.spacingMd),
                  Text(
                    KeroseneBrand.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AdminTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
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
                  label: context.tr.adminShellNavOverview,
                  items: [
                    AdminRoute.dashboard,
                    AdminRoute.monitoring,
                    AdminRoute.analytics,
                    AdminRoute.volatility,
                  ],
                  activeRoute: activeRoute,
                  collapsed: collapsed,
                  onSelect: (r) =>
                      ref.read(adminRouteProvider.notifier).navigate(r),
                ),
                const SizedBox(height: AdminTheme.spacingLg),
                _NavSection(
                  label: context.tr.adminShellNavOperations,
                  items: [
                    AdminRoute.transactions,
                    AdminRoute.lightning,
                    AdminRoute.onchain,
                    AdminRoute.checks,
                    AdminRoute.paymentLinks,
                  ],
                  activeRoute: activeRoute,
                  collapsed: collapsed,
                  onSelect: (r) =>
                      ref.read(adminRouteProvider.notifier).navigate(r),
                ),
                const SizedBox(height: AdminTheme.spacingLg),
                _NavSection(
                  label: context.tr.adminShellNavManagement,
                  items: [
                    AdminRoute.companies,
                    AdminRoute.audit,
                    AdminRoute.authenticatedDevices,
                    AdminRoute.settings,
                  ],
                  activeRoute: activeRoute,
                  collapsed: collapsed,
                  onSelect: (r) =>
                      ref.read(adminRouteProvider.notifier).navigate(r),
                ),
              ],
            ),
          ),

          // Bottom status
          const Divider(height: 1, color: AdminColors.borderSubtle),
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.positive,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: AdminTheme.spacingSm),
                  Flexible(
                    child: Text(
                      context.tr.adminShellSystemOperational,
                      overflow: TextOverflow.ellipsis,
                      style: AdminTypography.caption.copyWith(
                        color: AdminColors.textTertiary,
                      ),
                    ),
                  ),
                ],
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
  final bool collapsed;
  final ValueChanged<AdminRoute> onSelect;

  const _NavSection({
    required this.label,
    required this.items,
    required this.activeRoute,
    required this.collapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!collapsed)
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
        ...items.map(
          (route) => _NavItem(
            route: route,
            isActive: activeRoute == route,
            collapsed: collapsed,
            onTap: () => onSelect(route),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  final AdminRoute route;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.route,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final routeLabel = widget.route.localizedLabel(context);
    final item = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KeroseneMotion.fast,
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
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.route.icon,
                size: 18,
                color: widget.isActive
                    ? AdminColors.sidebarTextActive
                    : AdminColors.sidebarText,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: AdminTheme.spacingMd),
                Expanded(
                  child: Text(
                    routeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: widget.isActive
                          ? AdminColors.sidebarTextActive
                          : AdminColors.sidebarText,
                      fontWeight:
                          widget.isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.collapsed) {
      return item;
    }

    return Tooltip(
      message: routeLabel,
      waitDuration: KeroseneMotion.medium,
      child: item,
    );
  }
}

class _AdminTopBar extends ConsumerWidget {
  final bool compact;

  const _AdminTopBar({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminRouteProvider);
    final activeRouteLabel = activeRoute.localizedLabel(context);
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);

    return Container(
      height: AdminTheme.topBarHeight,
      color: AdminColors.backgroundElevated,
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.spacingXl),
      child: Row(
        children: [
          Flexible(
            child: Text(
              activeRouteLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AdminTypography.h4,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingLg),

          // BTC Price indicator
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    btcPriceAsync.when(
                      data: (prices) {
                        final usd = prices['btcUsd'] ?? 0;
                        return _TopBarPill(
                          icon: KeroseneIcons.bitcoin,
                          label: 'BTC \$${_formatPrice(usd)}',
                          iconColor: AdminColors.warning,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AdminTheme.spacingLg),
                      _TopBarPill(
                        icon: KeroseneIcons.verified,
                        label: context.tr.adminShellIntegrityOnly,
                        iconColor: AdminColors.positive,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: AdminTheme.spacingLg),

          // Compact account avatar.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AdminColors.surfaceElevated,
              border: Border.all(color: AdminColors.border),
              borderRadius: AdminTheme.borderRadiusXs,
            ),
            child: const Icon(
              KeroseneIcons.user,
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

class _TopBarPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _TopBarPill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AdminTheme.spacingXs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AdminTypography.mono.copyWith(
              color: AdminColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
