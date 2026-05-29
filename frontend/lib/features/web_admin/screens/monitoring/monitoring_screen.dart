import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
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
            AdminSectionHeader(
              title: context.tr.adminRouteMonitoring,
              subtitle: context.tr.adminMonitoringSubtitle,
            ),
            AdminResponsiveGrid(
              children: [
                _AsyncMetric(
                  title: context.tr.adminMonitoringMetricServices,
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
                    return context.tr
                        .adminHeightValue('${chain['height'] ?? 0}');
                  },
                  icon: Icons.currency_bitcoin,
                ),
                _AsyncMetric(
                  title: 'Lightning LND',
                  asyncValue: lightning,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) {
                    final node = _map(data['node']);
                    return context.tr.adminHeightValue(
                      '${node['blockHeight'] ?? 0}',
                    );
                  },
                  icon: Icons.flash_on_outlined,
                ),
                _AsyncMetric(
                  title: context.tr.adminMonitoringMetricVaultRaft,
                  asyncValue: vault,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) => context.tr.adminVotersValue(
                    '${data['votingServers'] ?? 0}',
                    '${data['expectedServers'] ?? 3}',
                  ),
                  icon: Icons.account_tree_outlined,
                ),
                _AsyncMetric(
                  title: context.tr.adminSettingsReleaseTitle,
                  asyncValue: release,
                  valueBuilder: (data) => data['authorized'] == true
                      ? context.tr.adminStatusAuthorized
                      : context.tr.adminStatusBlocked,
                  subtitleBuilder: (data) =>
                      '${data['reason'] ?? context.tr.unknown}',
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
        value: context.tr.loading,
        icon: icon,
      ),
      error: (_, __) => AdminMetricCard(
        label: title,
        value: context.tr.error,
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
      title: context.tr.adminMonitoringBitcoinPanel,
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
                  _KeyValue(
                    context.tr.adminLabelPrimarySource,
                    '${data['primarySource']}',
                  ),
                  _KeyValue(context.tr.adminLabelNetwork, '${data['network']}'),
                  _KeyValue(
                    context.tr.adminLabelBlockHeight,
                    '${chain['height'] ?? 0}',
                  ),
                  _KeyValue(
                    context.tr.adminLabelBestHash,
                    '${chain['bestBlockHash'] ?? ''}',
                  ),
                  _KeyValue(
                    context.tr.adminLabelMempoolTxs,
                    '${mempool['transactions'] ?? 0}',
                  ),
                  _KeyValue(context.tr.adminLabelIndexer, '${data['indexer']}'),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                context.tr.adminMonitoringRelevantTransactions,
                style: AdminTypography.h4,
              ),
              const SizedBox(height: 8),
              if (relevant.isEmpty)
                Text(
                  context.tr.adminMonitoringNoRelevantTransactions,
                  style: AdminTypography.bodySmall.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                )
              else
                ...relevant.take(8).map((item) {
                  final row = _map(item);
                  return _LogRow(
                    title: '${row['status'] ?? context.tr.unknown}',
                    body:
                        '${row['txidRef'] ?? context.tr.adminValueAbsent} · ${context.tr.adminConfirmationsValue('${row['confirmations'] ?? 0}')}',
                    severity: '${row['status'] ?? ''}',
                  );
                }),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text(context.tr.adminMonitoringBlockchainError('$e')),
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
      title: context.tr.adminMonitoringLightningPanel,
      child: asyncValue.when(
        data: (data) {
          final node = _map(data['node']);
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _KeyValue(
                context.tr.adminLabelPrimarySource,
                '${data['primarySource']}',
              ),
              _KeyValue(
                context.tr.adminLabelStatus,
                '${data['status'] ?? 'UNKNOWN'}',
              ),
              _KeyValue(context.tr.adminLabelAlias, '${node['alias'] ?? ''}'),
              _KeyValue(
                  context.tr.adminLabelVersion, '${node['version'] ?? ''}'),
              _KeyValue(
                context.tr.adminLabelSyncedChain,
                _boolText(context, node['syncedToChain'] == true),
              ),
              _KeyValue(
                context.tr.adminLabelSyncedGraph,
                _boolText(context, node['syncedToGraph'] == true),
              ),
              _KeyValue(
                context.tr.adminLabelBlockHeight,
                '${node['blockHeight'] ?? 0}',
              ),
              _KeyValue(
                context.tr.adminLabelBlockHash,
                '${node['blockHash'] ?? ''}',
              ),
              _KeyValue(context.tr.adminLabelPeers, '${node['numPeers'] ?? 0}'),
              _KeyValue(
                context.tr.adminLabelActiveChannels,
                '${node['numActiveChannels'] ?? 0}',
              ),
              _KeyValue(
                context.tr.adminLabelPendingChannels,
                '${node['numPendingChannels'] ?? 0}',
              ),
              _KeyValue(
                context.tr.adminLabelLocalBalance,
                '${node['localBalanceSats'] ?? 0} sats',
              ),
              _KeyValue(
                context.tr.adminLabelRemoteBalance,
                '${node['remoteBalanceSats'] ?? 0} sats',
              ),
              _KeyValue(
                context.tr.adminLabelWalletBalance,
                '${node['walletConfirmedBalanceSats'] ?? 0} sats',
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text(context.tr.adminMonitoringLightningError('$e')),
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
      title: context.tr.adminMonitoringReleasePanel,
      child: asyncValue.when(
        data: (data) => Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _KeyValue(
              context.tr.adminLabelAuthorized,
              _boolText(context, data['authorized'] == true),
            ),
            _KeyValue(
              context.tr.adminLabelManifest,
              '${data['manifestDigest'] ?? context.tr.adminValueAbsent}',
            ),
            _KeyValue(
              context.tr.adminLabelCommit,
              '${data['gitCommit'] ?? context.tr.unknown}',
            ),
            _KeyValue(
              context.tr.adminLabelImageDigest,
              '${data['imageDigest'] ?? context.tr.unknown}',
            ),
            _KeyValue(
              context.tr.adminLabelCodeHash,
              '${data['codeHash'] ?? context.tr.unknown}',
            ),
            _KeyValue(
              context.tr.adminLabelConfigHash,
              '${data['configHash'] ?? context.tr.unknown}',
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text(context.tr.adminMonitoringReleaseError('$e')),
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
      title: context.tr.adminMonitoringHealthPanel,
      child: asyncValue.when(
        data: (data) {
          final checks = _map(data['checks']);
          if (checks.isEmpty) {
            return Text(context.tr.adminMonitoringNoHealthChecks);
          }
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
        error: (e, _) => Text(context.tr.adminMonitoringHealthError('$e')),
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
      title: context.tr.adminMonitoringLogsPanel,
      child: asyncValue.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Text(
              context.tr.adminMonitoringNoLogs,
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.textSecondary,
              ),
            );
          }
          return Column(
            children: logs
                .map(
                  (log) => _LogRow(
                    title: '${log['eventType'] ?? context.tr.unknown}',
                    body: context.tr.adminLogBody(
                      '${log['createdAt'] ?? ''}',
                      '${log['reference'] ?? context.tr.adminValueAbsent}',
                      '${log['userRef'] ?? context.tr.adminValueAbsent}',
                      '${log['payloadRef'] ?? context.tr.adminValueAbsent}',
                    ),
                    severity: '${log['severity'] ?? 'INFO'}',
                  ),
                )
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (e, _) => Text(context.tr.adminMonitoringLogsError('$e')),
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
              value.isEmpty ? context.tr.adminValueNotConfigured : value,
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

String _boolText(BuildContext context, bool value) {
  return value ? context.tr.adminValueTrue : context.tr.adminValueFalse;
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
