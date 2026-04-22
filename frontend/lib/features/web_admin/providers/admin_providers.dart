import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/entities/external_transfer.dart';
import '../../transactions/domain/entities/payment_link.dart';
import '../../wallet/domain/entities/transaction.dart';
import '../../wallet/domain/entities/wallet.dart';
import '../data/admin_data_service.dart';

// ─── Raw Data Providers (real API calls) ─────────

final adminWalletsProvider = FutureProvider<List<Wallet>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchWallets();
});

final adminLedgerHistoryProvider = FutureProvider<List<Transaction>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchLedgerHistory(size: 500);
});

final adminExternalTransfersProvider =
    FutureProvider<List<ExternalTransfer>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchExternalTransfers();
});

final adminPaymentLinksProvider = FutureProvider<List<PaymentLink>>((ref) {
  return ref.watch(adminDataServiceProvider).fetchPaymentLinks();
});

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

// ─── Derived KPI Providers ──────────────────────

/// Consolidated balance across all wallets
final adminTotalBalanceProvider = Provider<double>((ref) {
  final walletsAsync = ref.watch(adminWalletsProvider);
  return walletsAsync.whenOrNull(
        data: (wallets) =>
            wallets.fold<double>(0, (sum, w) => sum + w.balance),
      ) ??
      0;
});

/// Dashboard KPIs derived from real ledger history
final adminDashboardKpisProvider = Provider<DashboardKpis>((ref) {
  final historyAsync = ref.watch(adminLedgerHistoryProvider);
  final externalAsync = ref.watch(adminExternalTransfersProvider);
  final linksAsync = ref.watch(adminPaymentLinksProvider);

  final history = historyAsync.asData?.value ?? [];
  final externals = externalAsync.asData?.value ?? [];
  final links = linksAsync.asData?.value ?? [];

  // Transaction volume analysis
  double totalVolume = 0;
  double totalFeesPaid = 0;
  int totalTxCount = history.length;
  int confirmedCount = 0;
  int pendingCount = 0;
  int failedCount = 0;

  for (final tx in history) {
    totalVolume += tx.amountBTC;
    totalFeesPaid += tx.feeBTC;
    switch (tx.status) {
      case TransactionStatus.confirmed:
        confirmedCount++;
        break;
      case TransactionStatus.pending:
      case TransactionStatus.confirming:
        pendingCount++;
        break;
      case TransactionStatus.failed:
        failedCount++;
        break;
    }
  }

  // External network fee analysis
  double onchainFees = 0;
  double lightningFees = 0;
  double onchainVolume = 0;
  double lightningVolume = 0;
  int onchainCount = 0;
  int lightningCount = 0;

  for (final ext in externals) {
    if (ext.isOnchain) {
      onchainFees += ext.networkFeeBtc;
      onchainVolume += ext.amountBtc.abs();
      onchainCount++;
    } else if (ext.isLightning) {
      lightningFees += ext.networkFeeBtc;
      lightningVolume += ext.amountBtc.abs();
      lightningCount++;
    }
  }

  // Payment link analysis
  int linksCreated = links.length;
  int linksPaid = links.where((l) => l.isPaid || l.isCompleted).length;
  int linksExpired = links.where((l) => l.isExpired).length;
  int linksPending = links.where((l) => l.isPending && !l.isExpired).length;

  // Inflow/outflow
  double totalInflow = history
      .where((tx) =>
          tx.type == TransactionType.receive ||
          tx.type == TransactionType.deposit)
      .fold(0, (sum, tx) => sum + tx.amountBTC);
  double totalOutflow = history
      .where((tx) =>
          tx.type == TransactionType.send ||
          tx.type == TransactionType.withdrawal)
      .fold(0, (sum, tx) => sum + tx.amountBTC);

  // Ticket médio
  double avgTicket = totalTxCount > 0 ? totalVolume / totalTxCount : 0;

  return DashboardKpis(
    totalVolumeBtc: totalVolume,
    totalFeesBtc: totalFeesPaid,
    totalTransactions: totalTxCount,
    confirmedTransactions: confirmedCount,
    pendingTransactions: pendingCount,
    failedTransactions: failedCount,
    onchainFeesBtc: onchainFees,
    lightningFeesBtc: lightningFees,
    onchainVolumeBtc: onchainVolume,
    lightningVolumeBtc: lightningVolume,
    onchainCount: onchainCount,
    lightningCount: lightningCount,
    linksCreated: linksCreated,
    linksPaid: linksPaid,
    linksExpired: linksExpired,
    linksPending: linksPending,
    inflowBtc: totalInflow,
    outflowBtc: totalOutflow,
    avgTicketBtc: avgTicket,
  );
});

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
