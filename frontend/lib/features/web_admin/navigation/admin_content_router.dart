import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/admin_routes.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/audit/audit_screen.dart';
import '../screens/checks/checks_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/lightning/lightning_screen.dart';
import '../screens/monitoring/monitoring_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onchain/onchain_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/volatility/volatility_screen.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_theme.dart';

class AdminContentRouter extends ConsumerWidget {
  const AdminContentRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(adminRouteProvider);

    return switch (route) {
      AdminRoute.dashboard => const DashboardScreen(),
      AdminRoute.monitoring => const MonitoringScreen(),
      AdminRoute.transactions => const TransactionsScreen(),
      AdminRoute.lightning => const LightningScreen(),
      AdminRoute.onchain => const OnchainScreen(),
      AdminRoute.checks => const ChecksScreen(),
      AdminRoute.paymentLinks => _AdminModulePlaceholder(route: route),
      AdminRoute.analytics => const AnalyticsScreen(),
      AdminRoute.volatility => const VolatilityScreen(),
      AdminRoute.companies => _AdminModulePlaceholder(route: route),
      AdminRoute.audit => const AuditScreen(),
      AdminRoute.authenticatedDevices => _AdminModulePlaceholder(route: route),
      AdminRoute.notifications => const NotificationsScreen(),
      AdminRoute.settings => _AdminModulePlaceholder(route: route),
    };
  }
}

class _AdminModulePlaceholder extends StatelessWidget {
  final AdminRoute route;

  const _AdminModulePlaceholder({required this.route});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          border: Border.all(color: AdminColors.border),
          borderRadius: AdminTheme.borderRadiusSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(route.icon, size: 32, color: AdminColors.textTertiary),
            const SizedBox(height: AdminTheme.spacingLg),
            Text(route.label, style: AdminTypography.h3),
            const SizedBox(height: AdminTheme.spacingSm),
            Text(
              'Module unavailable in this build.',
              textAlign: TextAlign.center,
              style: AdminTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
