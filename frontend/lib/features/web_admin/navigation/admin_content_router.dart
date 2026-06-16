import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/deferred_page.dart';
import '../navigation/admin_routes.dart';

import '../screens/analytics/analytics_screen.dart' deferred as analytics_screen;
import '../screens/authenticated_devices/authenticated_devices_screen.dart' deferred as authenticated_devices_screen;
import '../screens/audit/audit_screen.dart' deferred as audit_screen;
import '../screens/checks/checks_screen.dart' deferred as checks_screen;
import '../screens/companies/companies_screen.dart' deferred as companies_screen;
import '../screens/dashboard/dashboard_screen.dart' deferred as dashboard_screen;
import '../screens/lightning/lightning_screen.dart' deferred as lightning_screen;
import '../screens/monitoring/monitoring_screen.dart' deferred as monitoring_screen;
import '../screens/notifications/notifications_screen.dart' deferred as notifications_screen;
import '../screens/onchain/onchain_screen.dart' deferred as onchain_screen;
import '../screens/payment_links/payment_links_screen.dart' deferred as payment_links_screen;
import '../screens/settings/admin_settings_screen.dart' deferred as admin_settings_screen;
import '../screens/transactions/transactions_screen.dart' deferred as transactions_screen;
import '../screens/volatility/volatility_screen.dart' deferred as volatility_screen;

class AdminContentRouter extends ConsumerWidget {
  const AdminContentRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdminRoute route = ref.watch(adminRouteProvider);

    return switch (route) {
      AdminRoute.dashboard => DeferredPage(
          loadLibrary: dashboard_screen.loadLibrary,
          builder: (_) => dashboard_screen.DashboardScreen()),
      AdminRoute.monitoring => DeferredPage(
          loadLibrary: monitoring_screen.loadLibrary,
          builder: (_) => monitoring_screen.MonitoringScreen()),
      AdminRoute.transactions => DeferredPage(
          loadLibrary: transactions_screen.loadLibrary,
          builder: (_) => transactions_screen.TransactionsScreen()),
      AdminRoute.lightning => DeferredPage(
          loadLibrary: lightning_screen.loadLibrary,
          builder: (_) => lightning_screen.LightningScreen()),
      AdminRoute.onchain => DeferredPage(
          loadLibrary: onchain_screen.loadLibrary,
          builder: (_) => onchain_screen.OnchainScreen()),
      AdminRoute.checks => DeferredPage(
          loadLibrary: checks_screen.loadLibrary,
          builder: (_) => checks_screen.ChecksScreen()),
      AdminRoute.paymentLinks => DeferredPage(
          loadLibrary: payment_links_screen.loadLibrary,
          builder: (_) => payment_links_screen.PaymentLinksScreen()),
      AdminRoute.analytics => DeferredPage(
          loadLibrary: analytics_screen.loadLibrary,
          builder: (_) => analytics_screen.AnalyticsScreen()),
      AdminRoute.volatility => DeferredPage(
          loadLibrary: volatility_screen.loadLibrary,
          builder: (_) => volatility_screen.VolatilityScreen()),
      AdminRoute.companies => DeferredPage(
          loadLibrary: companies_screen.loadLibrary,
          builder: (_) => companies_screen.CompaniesScreen()),
      AdminRoute.audit => DeferredPage(
          loadLibrary: audit_screen.loadLibrary,
          builder: (_) => audit_screen.AuditScreen()),
      AdminRoute.authenticatedDevices => DeferredPage(
          loadLibrary: authenticated_devices_screen.loadLibrary,
          builder: (_) => authenticated_devices_screen.AuthenticatedDevicesScreen()),
      AdminRoute.notifications => DeferredPage(
          loadLibrary: notifications_screen.loadLibrary,
          builder: (_) => notifications_screen.NotificationsScreen()),
      AdminRoute.settings => DeferredPage(
          loadLibrary: admin_settings_screen.loadLibrary,
          builder: (_) => admin_settings_screen.AdminSettingsScreen()),
    };
  }
}
