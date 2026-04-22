import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Analytics module — enterprise metrics derived from real data.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminDashboardKpisProvider);
    final historyAsync = ref.watch(adminLedgerHistoryProvider);
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Analytics & Metrics',
            subtitle: 'Operational KPIs and performance indicators',
          ),

          // Main KPIs
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Success Rate', value: '${(kpis.successRate * 100).toStringAsFixed(1)}%', icon: Icons.check_circle_outline, accentColor: kpis.successRate > 0.95 ? AdminColors.positive : AdminColors.warning)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'Failure Rate', value: '${(kpis.failureRate * 100).toStringAsFixed(1)}%', icon: Icons.error_outline, accentColor: kpis.failureRate < 0.05 ? AdminColors.positive : AdminColors.negative)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'Link Conversion', value: '${(kpis.linkConversionRate * 100).toStringAsFixed(1)}%', icon: Icons.trending_up)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'Avg Ticket', value: '${kpis.avgTicketBtc.toStringAsFixed(8)} BTC', icon: Icons.receipt_outlined)),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // Cost analysis
          Row(
            children: [
              Expanded(child: AdminMetricCard(label: 'Total Fees', value: '${kpis.totalFeesBtc.toStringAsFixed(8)} BTC', subtitle: btcPriceAsync.whenOrNull(data: (p) => p['btcUsd']! > 0 ? '≈ \$${(kpis.totalFeesBtc * p['btcUsd']!).toStringAsFixed(2)}' : null), icon: Icons.payments_outlined, accentColor: AdminColors.warning)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'On-chain Cost', value: '${kpis.onchainFeesBtc.toStringAsFixed(8)} BTC', subtitle: kpis.onchainVolumeBtc > 0 ? 'fee ratio: ${(kpis.onchainFeesBtc / kpis.onchainVolumeBtc * 100).toStringAsFixed(3)}%' : null, icon: Icons.link)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'Lightning Cost', value: '${kpis.lightningFeesBtc.toStringAsFixed(8)} BTC', subtitle: kpis.lightningVolumeBtc > 0 ? 'fee ratio: ${(kpis.lightningFeesBtc / kpis.lightningVolumeBtc * 100).toStringAsFixed(3)}%' : null, icon: Icons.flash_on_outlined)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(child: AdminMetricCard(label: 'Net Flow', value: '${kpis.netFlowBtc >= 0 ? '+' : ''}${kpis.netFlowBtc.toStringAsFixed(8)} BTC', icon: Icons.swap_vert, accentColor: kpis.netFlowBtc >= 0 ? AdminColors.positive : AdminColors.negative)),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // Channel distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _ChannelDistribution(kpis: kpis)),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(flex: 3, child: _TransactionTimeline(historyAsync: historyAsync)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelDistribution extends StatelessWidget {
  final DashboardKpis kpis;
  const _ChannelDistribution({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final internalCount = kpis.totalTransactions - kpis.onchainCount - kpis.lightningCount;
    final total = kpis.totalTransactions;

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
          Text('CHANNEL DISTRIBUTION', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingXl),
          _DistributionBar(label: 'Internal', count: internalCount, total: total, color: AdminColors.accent),
          const SizedBox(height: AdminTheme.spacingMd),
          _DistributionBar(label: 'On-chain', count: kpis.onchainCount, total: total, color: AdminColors.info),
          const SizedBox(height: AdminTheme.spacingMd),
          _DistributionBar(label: 'Lightning', count: kpis.lightningCount, total: total, color: AdminColors.warning),
          const SizedBox(height: AdminTheme.spacingXl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AdminTypography.bodyMedium),
              Text('$total', style: AdminTypography.metricSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _DistributionBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AdminTypography.bodySmall),
            Text('$count (${(pct * 100).toStringAsFixed(1)}%)', style: AdminTypography.mono.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: AdminTheme.spacingXs),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AdminColors.backgroundElevated,
            borderRadius: AdminTheme.borderRadiusXs,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: AdminTheme.borderRadiusXs),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTimeline extends StatelessWidget {
  final AsyncValue historyAsync;
  const _TransactionTimeline({required this.historyAsync});

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
          Text('DAILY VOLUME (LAST 7 DAYS)', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          historyAsync.when(
            data: (txs) {
              final now = DateTime.now();
              final days = List.generate(7, (i) {
                final date = now.subtract(Duration(days: 6 - i));
                final dayTxs = (txs as List<Transaction>).where((tx) =>
                  tx.timestamp.year == date.year &&
                  tx.timestamp.month == date.month &&
                  tx.timestamp.day == date.day).toList();
                final volume = dayTxs.fold<double>(0, (s, tx) => s + tx.amountBTC);
                return _DayData(date: date, count: dayTxs.length, volume: volume);
              });
              final maxVol = days.fold<double>(0, (m, d) => d.volume > m ? d.volume : m);

              return Column(
                children: days.map((d) {
                  final pct = maxVol > 0 ? d.volume / maxVol : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${d.date.month.toString().padLeft(2, '0')}/${d.date.day.toString().padLeft(2, '0')}',
                            style: AdminTypography.mono.copyWith(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: AdminColors.backgroundElevated,
                              borderRadius: AdminTheme.borderRadiusXs,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct.clamp(0, 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AdminColors.accent.withValues(alpha: 0.6),
                                  borderRadius: AdminTheme.borderRadiusXs,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AdminTheme.spacingSm),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${d.volume.toStringAsFixed(6)} (${d.count})',
                            style: AdminTypography.mono.copyWith(fontSize: 11),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AdminColors.textTertiary))),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final DateTime date;
  final int count;
  final double volume;
  const _DayData({required this.date, required this.count, required this.volume});
}
