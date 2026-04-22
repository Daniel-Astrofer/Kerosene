import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Executive dashboard — KPIs derived from live API data.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminDashboardKpisProvider);
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);
    final totalBalance = ref.watch(adminTotalBalanceProvider);
    final walletsAsync = ref.watch(adminWalletsProvider);
    final historyAsync = ref.watch(adminLedgerHistoryProvider);
    final sovAsync = ref.watch(adminSovereigntyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Executive Dashboard',
            subtitle: 'Real-time overview of all financial operations',
          ),

          // ─── Row 1: Key financial metrics ──────────
          _MetricRow(children: [
            AdminMetricCard(
              label: 'Total Balance',
              value: '${totalBalance.toStringAsFixed(8)} BTC',
              subtitle: btcPriceAsync.whenOrNull(
                data: (p) {
                  final usd = p['btcUsd'] ?? 0;
                  return usd > 0
                      ? '≈ \$${(totalBalance * usd).toStringAsFixed(2)}'
                      : null;
                },
              ),
              icon: Icons.account_balance,
              accentColor: AdminColors.accent,
            ),
            AdminMetricCard(
              label: 'Total Volume',
              value: '${kpis.totalVolumeBtc.toStringAsFixed(8)} BTC',
              subtitle: '${kpis.totalTransactions} transactions',
              icon: Icons.swap_horiz,
            ),
            AdminMetricCard(
              label: 'Net Flow',
              value: '${kpis.netFlowBtc >= 0 ? '+' : ''}${kpis.netFlowBtc.toStringAsFixed(8)} BTC',
              subtitle: 'Inflow: ${kpis.inflowBtc.toStringAsFixed(6)} | Outflow: ${kpis.outflowBtc.toStringAsFixed(6)}',
              icon: Icons.trending_up,
              accentColor: kpis.netFlowBtc >= 0
                  ? AdminColors.positive
                  : AdminColors.negative,
            ),
            AdminMetricCard(
              label: 'Avg Ticket',
              value: '${kpis.avgTicketBtc.toStringAsFixed(8)} BTC',
              subtitle: 'per transaction',
              icon: Icons.receipt_outlined,
            ),
          ]),

          const SizedBox(height: AdminTheme.spacingXl),

          // ─── Row 2: Fee analysis ──────────────────
          _MetricRow(children: [
            AdminMetricCard(
              label: 'Total Fees Paid',
              value: '${kpis.totalFeesBtc.toStringAsFixed(8)} BTC',
              icon: Icons.payments_outlined,
              accentColor: AdminColors.warning,
            ),
            AdminMetricCard(
              label: 'On-chain Fees',
              value: '${kpis.onchainFeesBtc.toStringAsFixed(8)} BTC',
              subtitle: '${kpis.onchainCount} operations',
              icon: Icons.link,
            ),
            AdminMetricCard(
              label: 'Lightning Fees',
              value: '${kpis.lightningFeesBtc.toStringAsFixed(8)} BTC',
              subtitle: '${kpis.lightningCount} operations',
              icon: Icons.flash_on_outlined,
            ),
            AdminMetricCard(
              label: 'Success Rate',
              value: '${(kpis.successRate * 100).toStringAsFixed(1)}%',
              subtitle: '${kpis.confirmedTransactions} confirmed | ${kpis.failedTransactions} failed',
              icon: Icons.check_circle_outline,
              accentColor: kpis.successRate > 0.95
                  ? AdminColors.positive
                  : AdminColors.warning,
            ),
          ]),

          const SizedBox(height: AdminTheme.spacingXl),

          // ─── Row 3: Payment Links & Operations ────
          _MetricRow(children: [
            AdminMetricCard(
              label: 'Links Created',
              value: '${kpis.linksCreated}',
              icon: Icons.qr_code_2_outlined,
            ),
            AdminMetricCard(
              label: 'Links Paid',
              value: '${kpis.linksPaid}',
              subtitle: 'conversion: ${(kpis.linkConversionRate * 100).toStringAsFixed(1)}%',
              icon: Icons.check_circle_outline,
              accentColor: AdminColors.positive,
            ),
            AdminMetricCard(
              label: 'Pending',
              value: '${kpis.pendingTransactions + kpis.linksPending}',
              subtitle: '${kpis.pendingTransactions} tx + ${kpis.linksPending} links',
              icon: Icons.hourglass_empty,
              accentColor: AdminColors.warning,
            ),
            AdminMetricCard(
              label: 'Failed / Expired',
              value: '${kpis.failedTransactions + kpis.linksExpired}',
              subtitle: '${kpis.failedTransactions} tx + ${kpis.linksExpired} links',
              icon: Icons.error_outline,
              accentColor: AdminColors.negative,
            ),
          ]),

          const SizedBox(height: AdminTheme.spacingXl),

          // ─── Row 4: Channel volume comparison ─────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChannelVolumeCard(
                  title: 'On-chain Volume',
                  volumeBtc: kpis.onchainVolumeBtc,
                  feesBtc: kpis.onchainFeesBtc,
                  count: kpis.onchainCount,
                  icon: Icons.link,
                ),
              ),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(
                child: _ChannelVolumeCard(
                  title: 'Lightning Volume',
                  volumeBtc: kpis.lightningVolumeBtc,
                  feesBtc: kpis.lightningFeesBtc,
                  count: kpis.lightningCount,
                  icon: Icons.flash_on_outlined,
                ),
              ),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(
                child: _WalletsOverviewCard(walletsAsync: walletsAsync),
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // ─── Row 5: System status ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _RecentTransactionsCard(historyAsync: historyAsync),
              ),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(
                child: _SystemStatusCard(sovAsync: sovAsync),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final List<Widget> children;

  const _MetricRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((c) => Expanded(child: c))
          .expand((c) => [c, const SizedBox(width: AdminTheme.spacingLg)])
          .toList()
        ..removeLast(),
    );
  }
}

class _ChannelVolumeCard extends StatelessWidget {
  final String title;
  final double volumeBtc;
  final double feesBtc;
  final int count;
  final IconData icon;

  const _ChannelVolumeCard({
    required this.title,
    required this.volumeBtc,
    required this.feesBtc,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final feePercent = volumeBtc > 0 ? (feesBtc / volumeBtc * 100) : 0;
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AdminColors.textTertiary),
              const SizedBox(width: AdminTheme.spacingSm),
              Text(title.toUpperCase(), style: AdminTypography.label),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          Text(
            '${volumeBtc.toStringAsFixed(8)} BTC',
            style: AdminTypography.metricSmall,
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          _InfoRow('Operations', '$count'),
          _InfoRow('Fees paid', '${feesBtc.toStringAsFixed(8)} BTC'),
          _InfoRow('Fee ratio', '${feePercent.toStringAsFixed(3)}%'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AdminTypography.caption),
          Text(value, style: AdminTypography.mono.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _WalletsOverviewCard extends StatelessWidget {
  final AsyncValue walletsAsync;

  const _WalletsOverviewCard({required this.walletsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: AdminColors.textTertiary),
              const SizedBox(width: AdminTheme.spacingSm),
              Text('WALLETS'.toUpperCase(), style: AdminTypography.label),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          walletsAsync.when(
            data: (wallets) {
              if (wallets.isEmpty) {
                return Text('No wallets found', style: AdminTypography.bodyMedium);
              }
              return Column(
                children: (wallets as List).take(5).map<Widget>((w) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            w.name,
                            style: AdminTypography.bodyMedium.copyWith(
                              color: AdminColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${w.balance.toStringAsFixed(8)}',
                          style: AdminTypography.mono.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final AsyncValue historyAsync;

  const _RecentTransactionsCard({required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT TRANSACTIONS', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          historyAsync.when(
            data: (txs) {
              if (txs.isEmpty) {
                return Text('No transactions found',
                    style: AdminTypography.bodyMedium);
              }
              return Column(
                children: (txs as List).take(8).map<Widget>((tx) {
                  final isSend = tx.type.name == 'send' ||
                      tx.type.name == 'withdrawal';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSend
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: isSend
                              ? AdminColors.negative
                              : AdminColors.positive,
                        ),
                        const SizedBox(width: AdminTheme.spacingSm),
                        Expanded(
                          child: Text(
                            tx.description ?? tx.id,
                            style: AdminTypography.bodyMedium.copyWith(
                              color: AdminColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${isSend ? '-' : '+'}${tx.amountBTC.toStringAsFixed(8)}',
                          style: AdminTypography.mono.copyWith(
                            fontSize: 12,
                            color: isSend
                                ? AdminColors.negative
                                : AdminColors.positive,
                          ),
                        ),
                        const SizedBox(width: AdminTheme.spacingMd),
                        AdminStatusBadge(
                          label: tx.status.displayName,
                          variant: _statusVariant(tx.status.name),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }

  AdminBadgeVariant _statusVariant(String status) {
    switch (status) {
      case 'confirmed':
        return AdminBadgeVariant.positive;
      case 'pending':
      case 'confirming':
        return AdminBadgeVariant.warning;
      case 'failed':
        return AdminBadgeVariant.negative;
      default:
        return AdminBadgeVariant.neutral;
    }
  }
}

class _SystemStatusCard extends StatelessWidget {
  final AsyncValue sovAsync;

  const _SystemStatusCard({required this.sovAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM STATUS', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          sovAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return Text('Sovereignty data unavailable',
                    style: AdminTypography.bodyMedium);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.take(8).map<Widget>((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatKey(entry.key),
                            style: AdminTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatValue(entry.value),
                          style: AdminTypography.mono.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // camelCase -> Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is bool) return value ? 'Active' : 'Inactive';
    if (value is double) return value.toStringAsFixed(4);
    return value.toString();
  }
}
