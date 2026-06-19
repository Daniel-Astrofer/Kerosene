import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';
import '../../theme/admin_copy.dart';

/// Volatility module.
///
/// Shows market and aggregate operational exposure signals without reading or
/// rendering individual wallet balances.
class VolatilityScreen extends ConsumerWidget {
  const VolatilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);
    final kpis = ref.watch(adminDashboardKpisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Volatility & Exposure',
            subtitle:
                'BTC market reference and aggregate flow exposure. Individual balances are not displayed.',
          ),
          btcPriceAsync.when(
            data: (prices) {
              final btcUsd = prices['btcUsd'] ?? 0;
              final btcBrl = prices['btcBrl'] ?? 0;
              final usdBrl = prices['usdBrl'] ?? 0;
              final volumeUsd = kpis.totalVolumeBtc * btcUsd;
              final feesUsd = kpis.totalFeesBtc * btcUsd;

              return Column(
                children: [
                  AdminResponsiveGrid(
                    children: [
                      AdminMetricCard(
                        label: 'BTC/USD',
                        value: '\$${_fmtPrice(btcUsd)}',
                        icon: KeroseneIcons.bitcoin,
                        accentColor: AdminColors.warning,
                      ),
                      AdminMetricCard(
                        label: 'BTC/BRL',
                        value: 'R\$${_fmtPrice(btcBrl)}',
                        icon: KeroseneIcons.bitcoin,
                        accentColor: AdminColors.warning,
                      ),
                      AdminMetricCard(
                        label: 'USD/BRL',
                        value: 'R\$${usdBrl.toStringAsFixed(2)}',
                        icon: KeroseneIcons.swap,
                      ),
                      AdminMetricCard(
                        label: 'Aggregate Volume USD',
                        value: '\$${_fmtPrice(volumeUsd)}',
                        subtitle:
                            '${kpis.totalVolumeBtc.toStringAsFixed(8)} BTC aggregate',
                        icon: KeroseneIcons.chart,
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  AdminResponsiveGrid(
                    children: [
                      _ExposureCard(
                        title: 'Aggregate flow',
                        rows: [
                          (
                            'Total inflow',
                            '${kpis.inflowBtc.toStringAsFixed(8)} BTC'
                          ),
                          (
                            'Total outflow',
                            '${kpis.outflowBtc.toStringAsFixed(8)} BTC'
                          ),
                          (
                            'Net flow',
                            '${kpis.netFlowBtc.toStringAsFixed(8)} BTC'
                          ),
                          ('Fees USD', '\$${feesUsd.toStringAsFixed(2)}'),
                        ],
                      ),
                      _ExposureCard(
                        title: 'Privacy posture',
                        rows: const [
                          ('Readable backend window', '<= 24h'),
                          ('Durable user history', 'mobile encrypted'),
                          ('Admin balance view', 'aggregate only'),
                          ('Proof model', 'hash-chain / Merkle'),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AdminTheme.spacing3xl),
                child: CircularProgressIndicator(
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
            error: (e, _) => AdminErrorState(
              message: AdminCopy.priceDataUnavailable,
              onRetry: () => ref.invalidate(adminBtcPriceProvider),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}k';
    return value.toStringAsFixed(2);
  }
}

class _ExposureCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _ExposureCard({
    required this.title,
    required this.rows,
  });

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
          Text(title.toUpperCase(), style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          ...rows.map((row) => _Row(row.$1, row.$2)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AdminTypography.bodySmall)),
          const SizedBox(width: AdminTheme.spacingMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AdminTypography.mono.copyWith(
                fontSize: 13,
                color: AdminColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
