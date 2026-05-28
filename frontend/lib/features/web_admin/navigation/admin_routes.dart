import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  dashboard('Dashboard', Icons.dashboard_outlined),
  monitoring('Monitoring', Icons.monitor_heart_outlined),
  transactions('Integrity Proofs', Icons.fingerprint),
  lightning('Lightning', Icons.flash_on_outlined),
  onchain('On-chain', Icons.link),
  checks('Hash Chain', Icons.account_tree_outlined),
  paymentLinks('Payment Metrics', Icons.qr_code_2_outlined),
  analytics('Analytics', Icons.bar_chart),
  volatility('Volatility', Icons.show_chart),
  companies('Infrastructure', Icons.business_outlined),
  audit('Audit & Security', Icons.security_outlined),
  authenticatedDevices('Dispositivos autenticados', Icons.devices_outlined),
  notifications('Notifications', Icons.notifications_none_outlined),
  settings('Settings', Icons.settings_outlined);

  final String label;
  final IconData icon;

  const AdminRoute(this.label, this.icon);
}
