import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/admin_routes.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/authenticated_devices/authenticated_devices_screen.dart';
import '../screens/audit/audit_screen.dart';
import '../screens/checks/checks_screen.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/lightning/lightning_screen.dart';
import '../screens/monitoring/monitoring_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onchain/onchain_screen.dart';
import '../screens/payment_links/payment_links_screen.dart';
import '../screens/settings/admin_settings_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/volatility/volatility_screen.dart';

class AdminContentRouter extends ConsumerWidget {
  const AdminContentRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdminRoute route = ref.watch(adminRouteProvider);

    return switch (route) {
      AdminRoute.dashboard => const DashboardScreen(),
      AdminRoute.monitoring => const MonitoringScreen(),
      AdminRoute.transactions => const TransactionsScreen(),
      AdminRoute.lightning => const LightningScreen(),
      AdminRoute.onchain => const OnchainScreen(),
      AdminRoute.checks => const ChecksScreen(),
      AdminRoute.paymentLinks => const PaymentLinksScreen(),
      AdminRoute.analytics => const AnalyticsScreen(),
      AdminRoute.volatility => const VolatilityScreen(),
      AdminRoute.companies => const CompaniesScreen(),
      AdminRoute.audit => const AuditScreen(),
      AdminRoute.authenticatedDevices => const AuthenticatedDevicesScreen(),
      AdminRoute.notifications => const NotificationsScreen(),
      AdminRoute.settings => const AdminSettingsScreen(),
    };
  }
}
