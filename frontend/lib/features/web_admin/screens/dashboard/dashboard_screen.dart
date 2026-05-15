import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Executive dashboard for operational and integrity posture.
///
/// This dashboard does not list user wallets, user balances, or readable
/// transaction history. It uses aggregate operational metrics and proof state.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminDashboardKpisProvider);
    final btcPrice = ref.watch(adminBtcPriceProvider);
    final overview = ref.watch(adminOperationsOverviewProvider);
    final latestRoot = ref.watch(adminAuditLatestRootProvider);
    final release = ref.watch(adminReleaseSnapshotProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminBtcPriceProvider);
        ref.invalidate(adminOperationsOverviewProvider);
        ref.invalidate(adminAuditLatestRootProvider);
        ref.invalidate(adminReleaseSnapshotProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Executive Dashboard',
              subtitle:
                  'Infrastructure health, aggregate operations, and cryptographic integrity.',
            ),
            AdminResponsiveGrid(
              children: [
                _AsyncMetric(
                  title: 'BTC/USD',
                  asyncValue: btcPrice,
                  icon: Icons.currency_bitcoin,
                  valueBuilder: (data) {
                    final usd = data['btcUsd'] ?? 0;
                    return '\$${_fmtPrice(usd)}';
                  },
                  subtitleBuilder: (_) => 'market reference',
                  accent: AdminColors.warning,
                ),
                AdminMetricCard(
                  label: 'Aggregate Volume',
                  value: '${kpis.totalVolumeBtc.toStringAsFixed(8)} BTC',
                  subtitle: '${kpis.totalTransactions} operational events',
                  icon: Icons.bar_chart,
                ),
                AdminMetricCard(
                  label: 'On-chain Ops',
                  value: '${kpis.onchainCount}',
                  subtitle:
                      '${kpis.onchainVolumeBtc.toStringAsFixed(6)} BTC aggregate',
                  icon: Icons.link,
                ),
                AdminMetricCard(
                  label: 'Lightning Ops',
                  value: '${kpis.lightningCount}',
                  subtitle:
                      '${kpis.lightningVolumeBtc.toStringAsFixed(6)} BTC aggregate',
                  icon: Icons.flash_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            AdminResponsiveGrid(
              children: [
                AdminMetricCard(
                  label: 'Payment Links',
                  value: '${kpis.linksCreated}',
                  subtitle:
                      '${kpis.linksPaid} paid | ${kpis.linksPending} pending',
                  icon: Icons.qr_code_2_outlined,
                ),
                AdminMetricCard(
                  label: 'Success Rate',
                  value: '${(kpis.successRate * 100).toStringAsFixed(1)}%',
                  subtitle:
                      '${kpis.confirmedTransactions} confirmed | ${kpis.failedTransactions} failed',
                  icon: Icons.check_circle_outline,
                  accentColor: kpis.successRate > 0.95
                      ? AdminColors.positive
                      : AdminColors.warning,
                ),
                AdminMetricCard(
                  label: 'Network Fees',
                  value: '${kpis.totalFeesBtc.toStringAsFixed(8)} BTC',
                  subtitle:
                      'on-chain ${kpis.onchainFeesBtc.toStringAsFixed(6)} | lightning ${kpis.lightningFeesBtc.toStringAsFixed(6)}',
                  icon: Icons.payments_outlined,
                  accentColor: AdminColors.warning,
                ),
                AdminMetricCard(
                  label: 'Readable Retention',
                  value: '<= 24h',
                  subtitle: 'durable history lives on mobile',
                  icon: Icons.timer_outlined,
                  accentColor: AdminColors.info,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            LayoutBuilder(
              builder: (context, constraints) {
                final operations = _OperationsCard(overview: overview);
                final integrity = _IntegrityCard(latestRoot: latestRoot);
                final releaseCard = _ReleaseCard(release: release);

                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      operations,
                      const SizedBox(height: AdminTheme.spacingLg),
                      integrity,
                      const SizedBox(height: AdminTheme.spacingLg),
                      releaseCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: operations),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(child: integrity),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(child: releaseCard),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> overview;

  const _OperationsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Operations',
      icon: Icons.monitor_heart_outlined,
      child: overview.when(
        data: (data) {
          final health = _map(data['health']);
          final blockchain = _map(data['blockchain']);
          final lightning = _map(data['lightning']);
          final vault = _map(data['vaultRaft']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Services', '${health['status'] ?? 'UNKNOWN'}'),
              _InfoRow('Bitcoin Core', '${blockchain['status'] ?? 'UNKNOWN'}'),
              _InfoRow('Lightning LND', '${lightning['status'] ?? 'UNKNOWN'}'),
              _InfoRow('Vault/Raft', '${vault['status'] ?? 'UNKNOWN'}'),
              _InfoRow('Checked', '${data['checkedAt'] ?? 'unknown'}'),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load operations: $error',
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _IntegrityCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> latestRoot;

  const _IntegrityCard({required this.latestRoot});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Integrity',
      icon: Icons.fingerprint,
      child: latestRoot.when(
        data: (root) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Merkle root', _short(root['merkleRoot'])),
            _InfoRow('Ledger count', '${root['ledgerCount'] ?? 0}'),
            _InfoRow('Created', '${root['createdAt'] ?? 'unknown'}'),
            const SizedBox(height: AdminTheme.spacingMd),
            Text(
              'Hash sequential audit, not readable financial history.',
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load integrity root: $error',
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> release;

  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Release',
      icon: Icons.verified_user_outlined,
      child: release.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Authorized', '${data['authorized'] == true}'),
            _InfoRow('Reason', '${data['reason'] ?? 'unknown'}'),
            _InfoRow('Commit', _short(data['gitCommit'])),
            _InfoRow('Image', _short(data['imageDigest'])),
          ],
        ),
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load release: $error',
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _AsyncMetric extends StatelessWidget {
  final String title;
  final AsyncValue<Map<String, double>> asyncValue;
  final IconData icon;
  final String Function(Map<String, double>) valueBuilder;
  final String Function(Map<String, double>) subtitleBuilder;
  final Color accent;

  const _AsyncMetric({
    required this.title,
    required this.asyncValue,
    required this.icon,
    required this.valueBuilder,
    required this.subtitleBuilder,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) => AdminMetricCard(
        label: title,
        value: valueBuilder(data),
        subtitle: subtitleBuilder(data),
        icon: icon,
        accentColor: accent,
      ),
      loading: () =>
          AdminMetricCard(label: title, value: 'Loading', icon: icon),
      error: (_, __) => AdminMetricCard(
        label: title,
        value: 'Unavailable',
        icon: icon,
        accentColor: AdminColors.negative,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 16, color: AdminColors.warning),
              const SizedBox(width: AdminTheme.spacingSm),
              Text(title.toUpperCase(), style: AdminTypography.label),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          child,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AdminTypography.caption)),
          const SizedBox(width: AdminTheme.spacingMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AdminTypography.mono.copyWith(
                fontSize: 12,
                color: AdminColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _fmtPrice(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}k';
  return value.toStringAsFixed(2);
}

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
