import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import '../../data/admin_data_service.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_copy.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';

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
                  icon: KeroseneIcons.dns,
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
                  icon: KeroseneIcons.bitcoin,
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
                  icon: KeroseneIcons.lightning,
                ),
                _AsyncMetric(
                  title: context.tr.adminMonitoringMetricVaultRaft,
                  asyncValue: vault,
                  valueBuilder: (data) => '${data['status'] ?? 'UNKNOWN'}',
                  subtitleBuilder: (data) => context.tr.adminVotersValue(
                    '${data['votingServers'] ?? 0}',
                    '${data['expectedServers'] ?? 3}',
                  ),
                  icon: KeroseneIcons.network,
                ),
                _AsyncMetric(
                  title: context.tr.adminSettingsReleaseTitle,
                  asyncValue: release,
                  valueBuilder: (data) => data['authorized'] == true
                      ? context.tr.adminStatusAuthorized
                      : context.tr.adminStatusBlocked,
                  subtitleBuilder: (data) =>
                      '${data['reason'] ?? context.tr.unknown}',
                  icon: KeroseneIcons.security,
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

class _BlockchainPanel extends ConsumerStatefulWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _BlockchainPanel({required this.asyncValue});

  @override
  ConsumerState<_BlockchainPanel> createState() => _BlockchainPanelState();
}

class _BlockchainPanelState extends ConsumerState<_BlockchainPanel> {
  bool _isSyncing = false;
  String? _syncStatus;
  String? _syncError;

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      final response =
          await ref.read(adminDataServiceProvider).triggerBlockchainSync();
      final status = _syncStatusFromResponse(response);

      if (!mounted) return;
      setState(() {
        _syncStatus = status;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AdminCopy.blockchainSyncStarted)),
        );
      ref.invalidate(adminBlockchainMonitorProvider);
    } catch (e) {
      if (!mounted) return;
      final message = _syncErrorMessage(e);
      setState(() {
        _syncStatus = 'FAILED';
        _syncError = message;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AdminCopy.blockchainSyncIssue)),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.tr.adminMonitoringBitcoinPanel,
      trailing: _BlockchainSyncAction(
        isSyncing: _isSyncing,
        status: _syncStatus,
        error: _syncError,
        onPressed: _triggerSync,
      ),
      child: widget.asyncValue.when(
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
        error: (_, __) => const Text(AdminCopy.blockchainMonitorUnavailable),
      ),
    );
  }
}

class _BlockchainSyncAction extends StatelessWidget {
  final bool isSyncing;
  final String? status;
  final String? error;
  final VoidCallback onPressed;

  const _BlockchainSyncAction({
    required this.isSyncing,
    required this.status,
    required this.error,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminTheme.spacingSm,
      runSpacing: AdminTheme.spacingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isSyncing)
          const AdminStatusBadge(
            label: 'SYNCING',
            variant: AdminBadgeVariant.info,
          )
        else if (status != null)
          AdminStatusBadge(
            label: status!,
            variant: _variant(status!),
          ),
        if (error != null)
          Tooltip(
            message: error!,
            child: const Icon(
              KeroseneIcons.error,
              color: AdminColors.negative,
              size: 16,
            ),
          ),
        OutlinedButton.icon(
          onPressed: isSyncing ? null : onPressed,
          icon: isSyncing
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminColors.textTertiary,
                  ),
                )
              : const Icon(KeroseneIcons.sync, size: 16),
          label: Text(isSyncing ? AdminCopy.syncInProgress : AdminCopy.syncNow),
        ),
      ],
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
        error: (_, __) => const Text(AdminCopy.lightningMonitorUnavailable),
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
        error: (_, __) => const Text(AdminCopy.loadIssue),
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
        error: (_, __) => const Text(AdminCopy.loadIssue),
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
        error: (_, __) => const Text(AdminCopy.loadIssue),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final titleWidget = Text(title, style: AdminTypography.h3);
              if (trailing == null) return titleWidget;

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: AdminTheme.spacingMd),
                    trailing!,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: AdminTheme.spacingMd),
                  trailing!,
                ],
              );
            },
          ),
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

String _syncStatusFromResponse(Map<String, dynamic> response) {
  final status = response['status'] ??
      response['syncStatus'] ??
      response['result'] ??
      response['state'];
  final normalized = status?.toString().trim();
  if (normalized == null || normalized.isEmpty) return 'TRIGGERED';
  return normalized.toUpperCase();
}

String _syncErrorMessage(Object error) {
  final message = error.toString().trim();
  return message.isEmpty
      ? AdminCopy.blockchainSyncIssue
      : AdminCopy.blockchainSyncIssue;
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
      normalized.contains('TRIGGERED') ||
      normalized.contains('SYNCED') ||
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
      normalized.contains('THROTTLED') ||
      normalized.contains('DEGRADED')) {
    return AdminBadgeVariant.warning;
  }
  return AdminBadgeVariant.neutral;
}
