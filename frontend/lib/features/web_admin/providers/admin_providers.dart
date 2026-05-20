import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_data_service.dart';

final adminBtcPriceProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchBtcPrice();
});

final adminAuditStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchAuditStats();
});

final adminAuditHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchAuditHistory();
});

final adminAuditLatestRootProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchAuditLatestRoot();
});

final adminSovereigntyProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchSovereigntyStatus();
});

final adminCurrentUserProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchCurrentUser();
});

final adminOperationsOverviewProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchOperationsOverview();
});

final adminOperationalHealthProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchOperationalHealth();
});

final adminBlockchainMonitorProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchBlockchainMonitor();
});

final adminLightningMonitorProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchLightningMonitor();
});

final adminVaultRaftHealthProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchVaultRaftHealth();
});

final adminReleaseSnapshotProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchReleaseSnapshot();
});

final adminMobileReleaseProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchMobileRelease();
});

final adminOperationalMetricsProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchOperationalMetrics();
});

final adminOperationalLogsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchOperationalLogs();
});

final adminMobileDevicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchAuthenticatedMobileDevices();
});

final adminWebDevicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchAdminDevices();
});

final adminDashboardKpisProvider = Provider<DashboardKpis>((ref) {
  final metrics =
      ref.watch(adminOperationalMetricsProvider).asData?.value ?? const {};
  final transfers = _map(metrics['transfers']);
  final links = _map(metrics['paymentLinks']);

  return DashboardKpis(
    totalVolumeBtc: _double(metrics['totalVolumeBtc']),
    totalFeesBtc: _double(metrics['totalFeesBtc']),
    totalTransactions: _int(metrics['totalTransactions']),
    confirmedTransactions: _int(metrics['confirmedTransactions']),
    pendingTransactions: _int(metrics['pendingTransactions']),
    failedTransactions: _int(metrics['failedTransactions']),
    onchainFeesBtc: _double(transfers['onchainFeesBtc']),
    lightningFeesBtc: _double(transfers['lightningFeesBtc']),
    onchainVolumeBtc: _double(transfers['onchainVolumeBtc']),
    lightningVolumeBtc: _double(transfers['lightningVolumeBtc']),
    onchainCount: _int(transfers['onchainCount']),
    lightningCount: _int(transfers['lightningCount']),
    linksCreated: _int(links['linksCreated']),
    linksPaid: _int(links['linksPaid']),
    linksExpired: _int(links['linksExpired']) + _int(links['linksCancelled']),
    linksPending: _int(links['linksPending']),
    inflowBtc: _double(transfers['inflowBtc']),
    outflowBtc: _double(transfers['outflowBtc']),
    avgTicketBtc: _double(metrics['avgTicketBtc']),
  );
});

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class DashboardKpis {
  final double totalVolumeBtc;
  final double totalFeesBtc;
  final int totalTransactions;
  final int confirmedTransactions;
  final int pendingTransactions;
  final int failedTransactions;
  final double onchainFeesBtc;
  final double lightningFeesBtc;
  final double onchainVolumeBtc;
  final double lightningVolumeBtc;
  final int onchainCount;
  final int lightningCount;
  final int linksCreated;
  final int linksPaid;
  final int linksExpired;
  final int linksPending;
  final double inflowBtc;
  final double outflowBtc;
  final double avgTicketBtc;

  const DashboardKpis({
    this.totalVolumeBtc = 0,
    this.totalFeesBtc = 0,
    this.totalTransactions = 0,
    this.confirmedTransactions = 0,
    this.pendingTransactions = 0,
    this.failedTransactions = 0,
    this.onchainFeesBtc = 0,
    this.lightningFeesBtc = 0,
    this.onchainVolumeBtc = 0,
    this.lightningVolumeBtc = 0,
    this.onchainCount = 0,
    this.lightningCount = 0,
    this.linksCreated = 0,
    this.linksPaid = 0,
    this.linksExpired = 0,
    this.linksPending = 0,
    this.inflowBtc = 0,
    this.outflowBtc = 0,
    this.avgTicketBtc = 0,
  });

  double get successRate =>
      totalTransactions > 0 ? confirmedTransactions / totalTransactions : 0;

  double get failureRate =>
      totalTransactions > 0 ? failedTransactions / totalTransactions : 0;

  double get linkConversionRate =>
      linksCreated > 0 ? linksPaid / linksCreated : 0;

  double get netFlowBtc => inflowBtc - outflowBtc;
}
