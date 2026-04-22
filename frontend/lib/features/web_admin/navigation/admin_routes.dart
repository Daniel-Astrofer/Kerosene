import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that tracks the current active admin route.
class AdminRouteNotifier extends Notifier<AdminRoute> {
  @override
  AdminRoute build() => AdminRoute.dashboard;

  void navigate(AdminRoute route) {
    state = route;
  }
}

/// Provider to expose the active route.
final adminRouteProvider =
    NotifierProvider<AdminRouteNotifier, AdminRoute>(AdminRouteNotifier.new);

enum AdminRoute {
  dashboard('Dashboard', Icons.dashboard_outlined),
  transactions('Transactions', Icons.swap_horiz),
  lightning('Lightning', Icons.flash_on_outlined),
  onchain('On-chain', Icons.link),
  checks('Internal Checks', Icons.receipt_long_outlined),
  paymentLinks('Payment Links', Icons.qr_code_2_outlined),
  analytics('Analytics', Icons.bar_chart),
  volatility('Volatility', Icons.show_chart),
  companies('Accounts', Icons.business_outlined),
  audit('Audit & Security', Icons.security_outlined),
  settings('Settings', Icons.settings_outlined);

  final String label;
  final IconData icon;

  const AdminRoute(this.label, this.icon);
}
