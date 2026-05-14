import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Analytics module with aggregate metrics only.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminDashboardKpisProvider);
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Analytics & Metrics',
            subtitle: 'Aggregate operational KPIs. No readable user timeline is rendered here.',
          ),
          AdminResponsiveGrid(
            children: [
              AdminMetricCard(
                label: 'Success Rate',
                value: '${(kpis.successRate * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                accentColor: kpis.successRate > 0.95 ? AdminColors.positive : AdminColors.warning,
              ),
              AdminMetricCard(
                label: 'Failure Rate',
                value: '${(kpis.failureRate * 100).toStringAsFixed(1)}%',
                icon: Icons.error_outline,
                accentColor: kpis.failureRate < 0.05 ? AdminColors.positive : AdminColors.negative,
              ),
              AdminMetricCard(
                label: 'Link Conversion',
                value: '${(kpis.linkConversionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.trending_up,
              ),
              AdminMetricCard(
                label: 'Avg Aggregate Event',
                value: '${kpis.avgTicketBtc.toStringAsFixed(8)} BTC',
                icon: Icons.receipt_outlined,
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingXl),
          AdminResponsiveGrid(
            children: [
              AdminMetricCard(
                label: 'Total Fees',
                value: '${kpis.totalFeesBtc.toStringAsFixed(8)} BTC',
                subtitle: btcPriceAsync.whenOrNull(
                  data: (p) => (p['btcUsd'] ?? 0) > 0
                      ? 'approx \$${(kpis.totalFeesBtc * (p['btcUsd'] ?? 0)).toStringAsFixed(2)}'
                      : null,
                ),
                icon: Icons.payments_outlined,
                accentColor: AdminColors.warning,
              ),
              AdminMetricCard(
                label: 'On-chain Fee Ratio',
                value: kpis.onchainVolumeBtc > 0
                    ? '${(kpis.onchainFeesBtc / kpis.onchainVolumeBtc * 100).toStringAsFixed(3)}%'
                    : '0.000%',
                icon: Icons.link,
              ),
              AdminMetricCard(
                label: 'Lightning Fee Ratio',
                value: kpis.lightningVolumeBtc > 0
                    ? '${(kpis.lightningFeesBtc / kpis.lightningVolumeBtc * 100).toStringAsFixed(3)}%'
                    : '0.000%',
                icon: Icons.flash_on_outlined,
              ),
              AdminMetricCard(
                label: 'Net Flow',
                value:
                    '${kpis.netFlowBtc >= 0 ? '+' : ''}${kpis.netFlowBtc.toStringAsFixed(8)} BTC',
                icon: Icons.swap_vert,
                accentColor: kpis.netFlowBtc >= 0 ? AdminColors.positive : AdminColors.negative,
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingXl),
          Container(
            width: double.infinity,
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
                const SizedBox(height: AdminTheme.spacingLg),
                _DistributionBar(
                  label: 'On-chain',
                  count: kpis.onchainCount,
                  total: kpis.totalTransactions,
                  color: AdminColors.info,
                ),
                const SizedBox(height: AdminTheme.spacingMd),
                _DistributionBar(
                  label: 'Lightning',
                  count: kpis.lightningCount,
                  total: kpis.totalTransactions,
                  color: AdminColors.warning,
                ),
                const SizedBox(height: AdminTheme.spacingMd),
                _DistributionBar(
                  label: 'Payment links',
                  count: kpis.linksCreated,
                  total: kpis.totalTransactions,
                  color: AdminColors.accent,
                ),
              ],
            ),
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

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

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
            Text(
              '$count (${(pct * 100).toStringAsFixed(1)}%)',
              style: AdminTypography.mono.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AdminTheme.spacingXs),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: AdminColors.backgroundElevated,
            borderRadius: AdminTheme.borderRadiusXs,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AdminTheme.borderRadiusXs,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
