import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/design_system/icons.dart';

class AdminRouteNotifier extends Notifier<AdminRoute> {
  @override
  AdminRoute build() => AdminRoute.dashboard;

  void navigate(AdminRoute route) {
    state = route;
  }
}

final adminRouteProvider =
    NotifierProvider<AdminRouteNotifier, AdminRoute>(AdminRouteNotifier.new);

enum AdminRoute {
  dashboard('Dashboard', KeroseneIcons.gauge),
  monitoring('Monitoring', KeroseneIcons.activity),
  transactions('Integrity Proofs', KeroseneIcons.biometric),
  lightning('Lightning', KeroseneIcons.lightning),
  onchain('On-chain', KeroseneIcons.onchain),
  checks('Hash Chain', KeroseneIcons.network),
  paymentLinks('Payment Metrics', KeroseneIcons.qr),
  analytics('Analytics', KeroseneIcons.chart),
  volatility('Volatility', KeroseneIcons.trendUp),
  companies('Infrastructure', KeroseneIcons.business),
  audit('Audit & Security', KeroseneIcons.security),
  authenticatedDevices('Authenticated Devices', KeroseneIcons.devices),
  notifications('Notifications', KeroseneIcons.notifications),
  settings('Settings', KeroseneIcons.settings);

  final String label;
  final IconData icon;

  const AdminRoute(this.label, this.icon);
}

extension AdminRouteLabels on AdminRoute {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      AdminRoute.dashboard => context.tr.adminRouteDashboard,
      AdminRoute.monitoring => context.tr.adminRouteMonitoring,
      AdminRoute.transactions => context.tr.adminRouteTransactions,
      AdminRoute.lightning => context.tr.adminRouteLightning,
      AdminRoute.onchain => context.tr.adminRouteOnchain,
      AdminRoute.checks => context.tr.adminRouteChecks,
      AdminRoute.paymentLinks => context.tr.adminRoutePaymentLinks,
      AdminRoute.analytics => context.tr.adminRouteAnalytics,
      AdminRoute.volatility => context.tr.adminRouteVolatility,
      AdminRoute.companies => context.tr.adminRouteCompanies,
      AdminRoute.audit => context.tr.adminRouteAudit,
      AdminRoute.authenticatedDevices =>
        context.tr.adminRouteAuthenticatedDevices,
      AdminRoute.notifications => context.tr.adminRouteNotifications,
      AdminRoute.settings => context.tr.adminRouteSettings,
    };
  }
}
