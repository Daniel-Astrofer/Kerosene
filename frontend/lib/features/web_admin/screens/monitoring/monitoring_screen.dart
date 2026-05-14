import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(adminOperationalHealthProvider);
    final blockchain = ref.watch(adminBlockchainMonitorProvider);
    final lightning = ref.watch(adminLightningMonitorProvider);
    final vault = ref.watch(adminVaultRaftHealthProvider);
    final release = ref.watch(adminReleaseSnapshotProvider);
    final logs = ref.watch(adminOperationalLogsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOperationalHealthProvider);
        ref.invalidate(adminBlockchainMonitorProvider);
        ref.invalidate(adminLightningMonitorProvider);
        ref.invalidate(adminVaultRaftHealthProvider);
        ref.invalidate(adminReleaseSnapshotProvider);
        ref.invalidate(adminOperationalLogsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Monitoring',
              subtitle:
                  'Real service health, Bitcoin Core on-chain state, LND Lightning state, Vault Raft quorum, release attestation, and sanitized operations logs.',
            ),
            AdminResponsiveGrid(
              children: [
                _AsyncMetric(
                  title: 'Services',
                  asyncValue: health,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) => '${data['service'] ?? 'kerosene'}',
                  icon: Icons.dns_outlined,
                ),
                _AsyncMetric(
                  title: 'Bitcoin Core',
                  asyncValue: blockchain,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) {
                    final chain = _map(data['chain']);
                    return 'height ${chain['height'] ?? 0}';
                  },
                  icon: Icons.currency_bitcoin,
                ),
                _AsyncMetric(
                  title: 'Lightning LND',
                  asyncValue: lightning,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) {
                    final node = _map(data['node']);
                    return 'height ${node['blockHeight'] ?? 0}';
                  },
                  icon: Icons.flash_on_outlined,
                ),
                _AsyncMetric(
                  title: 'Vault Raft',
                  asyncValue: vault,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) =>
                      '${data['votingServers'] ?? 0}/${data['expectedServers'] ?? 3} voters',
                  icon: Icons.account_tree_outlined,
                ),
                _AsyncMetric(
                  title: 'Release',
                  asyncValue: release,
                  valueBuilder: (data) => data['authorized'] == true ? 'AUTHORIZED' : 'BLOCKED',
                  subtitleBuilder: (data) => '${data['reason'] ?? 'unknown'}',
                  icon: Icons.verified_user_outlined,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            _BlockchainPanel(asyncValue: blockchain),
            const SizedBox(height: AdminTheme.spacingXl),
            _LightningPanel(asyncValue: lightning),
            const SizedBox(height: AdminTheme.spacingXl),
            _ReleasePanel(asyncValue: release),
            const SizedBox(height: AdminTheme.spacingXl),
            _HealthChecksPanel(asyncValue: health),
            const SizedBox(height: AdminTheme.spacingXl),
            _LogsPanel(asyncValue: logs),
          ],
        ),
      ),
    );
  }
}

class _AsyncMetric extends StatelessWidget {
  final String title;
  final AsyncValue<Map<String, dynamic>> asyncValue;
  final String Function(Map<String, dynamic>) valueBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  final IconData icon;

  const _AsyncMetric({
    required this.title,
    required this.asyncValue,
    required this.valueBuilder,
    required this.subtitleBuilder,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) => AdminMetricCard(
        label: title,
        value: valueBuilder(data),
        subtitle: subtitleBuilder(data),
        icon: icon,
        accentColor: _statusColor('${data['status'] ?? data['reason'] ?? ''}'),
      ),
      loading: () => AdminMetricCard(
        label: title,
        value: 'Loading',
        icon: icon,
      ),
      error: (_, __) => AdminMetricCard(
        label: title,
        value: 'Error',
        icon: icon,
        accentColor: AdminColors.negative,
      ),
    );
  }
}

class _BlockchainPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _BlockchainPanel({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Bitcoin monitor',
      child: asyncValue.when(
        data: (data) {
          final chain = _map(data['chain']);
          final mempool = _map(data['mempool']);
          final relevant = (data['relevantTransactions'] as List?) ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _KeyValue('Primary source', '${data['primarySource']}'),
                  _KeyValue('Network', '${data['network']}'),
                  _KeyValue('Block height', '${chain['height'] ?? 0}'),
                  _KeyValue('Best hash', '${chain['bestBlockHash'] ?? ''}'),
                  _KeyValue('Mempool txs', '${mempool['transactions'] ?? 0}'),
                  _KeyValue('Indexer', '${data['indexer']}'),
                ],
              ),
              const SizedBox(height: 18),
              Text('Relevant transactions', style: AdminTypography.h4),
              const SizedBox(height: 8),
              if (relevant.isEmpty)
                Text(
                  'No watched on-chain transactions currently require action.',
                  style: AdminTypography.bodySmall.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                )
              else
                ...relevant.take(8).map((item) {
                  final row = _map(item);
                  return _LogRow(
                    title: '${row['status'] ?? 'UNKNOWN'}',
                    body:
                        '${row['txidRef'] ?? 'absent'} · ${row['confirmations'] ?? 0} confirmations',
                    severity: '${row['status'] ?? ''}',
                  );
                }),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text('Failed to load blockchain monitor: $e'),
      ),
    );
  }
}

class _LightningPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _LightningPanel({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Lightning monitor',
      child: asyncValue.when(
        data: (data) {
          final node = _map(data['node']);
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _KeyValue('Primary source', '${data['primarySource']}'),
              _KeyValue('Status', '${data['status'] ?? 'UNKNOWN'}'),
              _KeyValue('Alias', '${node['alias'] ?? ''}'),
              _KeyValue('Version', '${node['version'] ?? ''}'),
              _KeyValue('Synced chain', '${node['syncedToChain'] == true}'),
              _KeyValue('Synced graph', '${node['syncedToGraph'] == true}'),
              _KeyValue('Block height', '${node['blockHeight'] ?? 0}'),
              _KeyValue('Block hash', '${node['blockHash'] ?? ''}'),
              _KeyValue('Peers', '${node['numPeers'] ?? 0}'),
              _KeyValue('Active channels', '${node['numActiveChannels'] ?? 0}'),
              _KeyValue('Pending channels', '${node['numPendingChannels'] ?? 0}'),
              _KeyValue(
                'Local balance',
                '${node['localBalanceSats'] ?? 0} sats',
              ),
              _KeyValue(
                'Remote balance',
                '${node['remoteBalanceSats'] ?? 0} sats',
              ),
              _KeyValue(
                'Wallet balance',
                '${node['walletConfirmedBalanceSats'] ?? 0} sats',
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text('Failed to load Lightning monitor: $e'),
      ),
    );
  }
}

class _ReleasePanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _ReleasePanel({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Release attestation',
      child: asyncValue.when(
        data: (data) => Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _KeyValue('Authorized', '${data['authorized'] == true}'),
            _KeyValue('Manifest', '${data['manifestDigest'] ?? 'absent'}'),
            _KeyValue('Commit', '${data['gitCommit'] ?? 'unknown'}'),
            _KeyValue('Image digest', '${data['imageDigest'] ?? 'unknown'}'),
            _KeyValue('Code hash', '${data['codeHash'] ?? 'unknown'}'),
            _KeyValue('Config hash', '${data['configHash'] ?? 'unknown'}'),
          ],
        ),
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text('Failed to load release snapshot: $e'),
      ),
    );
  }
}

class _HealthChecksPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _HealthChecksPanel({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Service health',
      child: asyncValue.when(
        data: (data) {
          final checks = _map(data['checks']);
          if (checks.isEmpty) return const Text('No health checks reported.');
          return Column(
            children: checks.entries.map((entry) {
              final value = _map(entry.value);
              final status = '${value['status'] ?? 'UNKNOWN'}';
              return _CheckRow(
                name: entry.key,
                status: status,
                message: '${value['message'] ?? ''}',
              );
            }).toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text('Failed to load health: $e'),
      ),
    );
  }
}

class _LogsPanel extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncValue;

  const _LogsPanel({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Sanitized operational logs',
      child: asyncValue.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Text(
              'No operational events have been recorded yet.',
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.textSecondary,
              ),
            );
          }
          return Column(
            children: logs
                .map(
                  (log) => _LogRow(
                    title: '${log['eventType'] ?? 'event'}',
                    body:
                        '${log['createdAt'] ?? ''} · ref ${log['reference'] ?? 'absent'} · user ${log['userRef'] ?? 'absent'} · payload ${log['payloadRef'] ?? 'absent'}',
                    severity: '${log['severity'] ?? 'INFO'}',
                  ),
                )
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text('Failed to load logs: $e'),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

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
          Text(title, style: AdminTypography.h3),
          const SizedBox(height: AdminTheme.spacingLg),
          child,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String name;
  final String status;
  final String message;

  const _CheckRow({
    required this.name,
    required this.status,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(name, style: AdminTypography.tableCell),
          ),
          AdminStatusBadge(label: status, variant: _variant(status)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final String title;
  final String body;
  final String severity;

  const _LogRow({
    required this.title,
    required this.body,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
      ),
      child: Row(
        children: [
          AdminStatusBadge(label: severity, variant: _variant(severity)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdminTypography.tableCell),
                const SizedBox(height: 3),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AdminTypography.label),
          const SizedBox(height: 4),
          Tooltip(
            message: value,
            child: Text(
              value.isEmpty ? 'not configured' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AdminTypography.tableCellMono,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Color _statusColor(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('UP') || normalized.contains('AUTHORIZED')) {
    return AdminColors.positive;
  }
  if (normalized.contains('DOWN') ||
      normalized.contains('ERROR') ||
      normalized.contains('BLOCKED')) {
    return AdminColors.negative;
  }
  return AdminColors.warning;
}

AdminBadgeVariant _variant(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('UP') ||
      normalized.contains('OK') ||
      normalized.contains('SETTLED') ||
      normalized.contains('COMPLETED') ||
      normalized.contains('INFO')) {
    return AdminBadgeVariant.positive;
  }
  if (normalized.contains('DOWN') ||
      normalized.contains('ERROR') ||
      normalized.contains('FAILED') ||
      normalized.contains('BLOCK')) {
    return AdminBadgeVariant.negative;
  }
  if (normalized.contains('WARN') ||
      normalized.contains('PENDING') ||
      normalized.contains('DEGRADED')) {
    return AdminBadgeVariant.warning;
  }
  return AdminBadgeVariant.neutral;
}
