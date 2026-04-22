import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Volatility module — BTC price and exposure analysis.
class VolatilityScreen extends ConsumerWidget {
  const VolatilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(adminBtcPriceProvider);
    final totalBalance = ref.watch(adminTotalBalanceProvider);
    final kpis = ref.watch(adminDashboardKpisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Volatility & Exposure',
            subtitle: 'BTC price monitoring and portfolio risk assessment',
          ),
          btcPriceAsync.when(
            data: (prices) {
              final btcUsd = prices['btcUsd'] ?? 0;
              final btcBrl = prices['btcBrl'] ?? 0;
              final usdBrl = prices['usdBrl'] ?? 0;
              final portfolioUsd = totalBalance * btcUsd;
              final portfolioBrl = totalBalance * btcBrl;
              final volumeUsd = kpis.totalVolumeBtc * btcUsd;

              return Column(
                children: [
                  // Price cards
                  Row(
                    children: [
                      Expanded(child: AdminMetricCard(label: 'BTC/USD', value: '\$${_fmtPrice(btcUsd)}', icon: Icons.currency_bitcoin, accentColor: AdminColors.warning)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'BTC/BRL', value: 'R\$${_fmtPrice(btcBrl)}', icon: Icons.currency_bitcoin, accentColor: AdminColors.warning)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'USD/BRL', value: 'R\$${usdBrl.toStringAsFixed(2)}', icon: Icons.swap_horiz)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Portfolio Value', value: '\$${_fmtPrice(portfolioUsd)}', subtitle: 'R\$${_fmtPrice(portfolioBrl)}', icon: Icons.account_balance, accentColor: AdminColors.accent)),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),

                  // Exposure breakdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _ExposureCard(
                        totalBalance: totalBalance,
                        btcUsd: btcUsd,
                        btcBrl: btcBrl,
                        inflowBtc: kpis.inflowBtc,
                        outflowBtc: kpis.outflowBtc,
                      )),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: _ExecutiveSummary(
                        totalBalance: totalBalance,
                        btcUsd: btcUsd,
                        volumeUsd: volumeUsd,
                        txCount: kpis.totalTransactions,
                        feesBtc: kpis.totalFeesBtc,
                      )),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(AdminTheme.spacing3xl), child: CircularProgressIndicator(color: AdminColors.textTertiary))),
            error: (e, _) => AdminErrorState(message: 'Failed to load price data: $e', onRetry: () => ref.invalidate(adminBtcPriceProvider)),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}k';
    return v.toStringAsFixed(2);
  }
}

class _ExposureCard extends StatelessWidget {
  final double totalBalance;
  final double btcUsd;
  final double btcBrl;
  final double inflowBtc;
  final double outflowBtc;

  const _ExposureCard({required this.totalBalance, required this.btcUsd, required this.btcBrl, required this.inflowBtc, required this.outflowBtc});

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
          Text('EXPOSURE ANALYSIS', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingXl),
          _Row('Current BTC Balance', '${totalBalance.toStringAsFixed(8)} BTC'),
          _Row('USD Exposure', '\$${(totalBalance * btcUsd).toStringAsFixed(2)}'),
          _Row('BRL Exposure', 'R\$${(totalBalance * btcBrl).toStringAsFixed(2)}'),
          const Divider(height: AdminTheme.spacingXl, color: AdminColors.border),
          _Row('Total Inflow', '${inflowBtc.toStringAsFixed(8)} BTC'),
          _Row('Total Outflow', '${outflowBtc.toStringAsFixed(8)} BTC'),
          _Row('Net Position', '${(inflowBtc - outflowBtc).toStringAsFixed(8)} BTC'),
          const Divider(height: AdminTheme.spacingXl, color: AdminColors.border),
          // Hypothetical impact scenarios
          Text('IMPACT SCENARIOS', style: AdminTypography.label.copyWith(fontSize: 10)),
          const SizedBox(height: AdminTheme.spacingSm),
          _ImpactRow('BTC +10%', totalBalance * btcUsd * 0.10, true),
          _ImpactRow('BTC -10%', totalBalance * btcUsd * 0.10, false),
          _ImpactRow('BTC +25%', totalBalance * btcUsd * 0.25, true),
          _ImpactRow('BTC -25%', totalBalance * btcUsd * 0.25, false),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AdminTypography.bodySmall),
          Text(value, style: AdminTypography.mono.copyWith(fontSize: 13, color: AdminColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;
  const _ImpactRow(this.label, this.amount, this.isPositive);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AdminTypography.caption),
          Text(
            '${isPositive ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
            style: AdminTypography.mono.copyWith(fontSize: 12, color: isPositive ? AdminColors.positive : AdminColors.negative),
          ),
        ],
      ),
    );
  }
}

class _ExecutiveSummary extends StatelessWidget {
  final double totalBalance;
  final double btcUsd;
  final double volumeUsd;
  final int txCount;
  final double feesBtc;

  const _ExecutiveSummary({required this.totalBalance, required this.btcUsd, required this.volumeUsd, required this.txCount, required this.feesBtc});

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
          Text('EXECUTIVE SUMMARY', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingXl),
          _Row('Portfolio (BTC)', '${totalBalance.toStringAsFixed(8)}'),
          _Row('Portfolio (USD)', '\$${(totalBalance * btcUsd).toStringAsFixed(2)}'),
          _Row('Volume (USD)', '\$${volumeUsd.toStringAsFixed(2)}'),
          _Row('Transactions', '$txCount'),
          _Row('Total Fees', '${feesBtc.toStringAsFixed(8)} BTC'),
          _Row('Fee Cost (USD)', '\$${(feesBtc * btcUsd).toStringAsFixed(2)}'),
          const SizedBox(height: AdminTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingMd),
            decoration: BoxDecoration(
              color: AdminColors.warningSubtle,
              border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
              borderRadius: AdminTheme.borderRadiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, size: 16, color: AdminColors.warning),
                const SizedBox(width: AdminTheme.spacingSm),
                Expanded(
                  child: Text(
                    'BTC exposure is unhedged. Values fluctuate with market price.',
                    style: AdminTypography.bodySmall.copyWith(color: AdminColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
