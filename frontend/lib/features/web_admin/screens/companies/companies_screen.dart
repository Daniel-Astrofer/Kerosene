import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminOperationsOverviewProvider);
    final health = ref.watch(adminOperationalHealthProvider);
    final blockchain = ref.watch(adminBlockchainMonitorProvider);
    final lightning = ref.watch(adminLightningMonitorProvider);
    final vault = ref.watch(adminVaultRaftHealthProvider);
    final release = ref.watch(adminReleaseSnapshotProvider);

    return RefreshIndicator(
      onRefresh: () async {
        _invalidate(ref);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: context.tr.adminRouteCompanies,
              subtitle: context.tr.adminCompaniesSubtitle,
              trailing: OutlinedButton.icon(
                onPressed: () => _invalidate(ref),
                icon: const Icon(KeroseneIcons.refresh, size: 16),
                label: Text(context.tr.adminActionRefresh),
              ),
            ),
            AdminResponsiveGrid(
              children: [
                _AsyncEntityMetric(
                  title: context.tr.adminCompaniesMetricControlPlane,
                  asyncValue: health,
                  icon: KeroseneIcons.dns,
                  subtitleKey: 'service',
                ),
                _AsyncEntityMetric(
                  title: 'Bitcoin Core',
                  asyncValue: blockchain,
                  icon: KeroseneIcons.bitcoin,
                  subtitleBuilder: (data) {
                    final chain = _map(data['chain']);
                    return context.tr
                        .adminHeightValue('${chain['height'] ?? 0}');
                  },
                ),
                _AsyncEntityMetric(
                  title: 'Lightning LND',
                  asyncValue: lightning,
                  icon: KeroseneIcons.lightning,
                  subtitleBuilder: (data) {
                    final node = _map(data['node']);
                    return context.tr.adminActiveChannelsValue(
                      '${node['numActiveChannels'] ?? 0}',
                    );
                  },
                ),
                _AsyncEntityMetric(
                  title: context.tr.adminCompaniesMetricVaultRaft,
                  asyncValue: vault,
                  icon: KeroseneIcons.network,
                  subtitleBuilder: (data) => context.tr.adminVotersValue(
                    '${data['votingServers'] ?? 0}',
                    '${data['expectedServers'] ?? 3}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            LayoutBuilder(
              builder: (context, constraints) {
                final entities = _OperationalEntitiesPanel(
                  health: health,
                  blockchain: blockchain,
                  lightning: lightning,
                  vault: vault,
                  release: release,
                );
                final routing = _RoutingPanel(overview: overview);

                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      entities,
                      const SizedBox(height: AdminTheme.spacingLg),
                      routing,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: entities),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(flex: 2, child: routing),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(adminOperationsOverviewProvider);
    ref.invalidate(adminOperationalHealthProvider);
    ref.invalidate(adminBlockchainMonitorProvider);
    ref.invalidate(adminLightningMonitorProvider);
    ref.invalidate(adminVaultRaftHealthProvider);
    ref.invalidate(adminReleaseSnapshotProvider);
  }
}

class _AsyncEntityMetric extends StatelessWidget {
  final String title;
  final AsyncValue<Map<String, dynamic>> asyncValue;
  final IconData icon;
  final String? subtitleKey;
  final String Function(Map<String, dynamic>)? subtitleBuilder;

  const _AsyncEntityMetric({
    required this.title,
    required this.asyncValue,
    required this.icon,
    this.subtitleKey,
    this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        final status = _status(data);
        return AdminMetricCard(
          label: title,
          value: status,
          subtitle: subtitleBuilder?.call(data) ??
              '${data[subtitleKey ?? 'primarySource'] ?? 'kerosene'}',
          icon: icon,
          accentColor: _statusColor(status),
        );
      },
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

class _OperationalEntitiesPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> health;
  final AsyncValue<Map<String, dynamic>> blockchain;
  final AsyncValue<Map<String, dynamic>> lightning;
  final AsyncValue<Map<String, dynamic>> vault;
  final AsyncValue<Map<String, dynamic>> release;

  const _OperationalEntitiesPanel({
    required this.health,
    required this.blockchain,
    required this.lightning,
    required this.vault,
    required this.release,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _row(
        context: context,
        name: context.tr.adminCompaniesEntityKeroseneApi,
        role: context.tr.adminCompaniesRoleControlPlane,
        environment: 'admin',
        asyncValue: health,
        detail: (data) => '${data['service'] ?? 'kerosene'}',
      ),
      _row(
        context: context,
        name: 'Bitcoin Core',
        role: context.tr.adminCompaniesRoleOnchainSource,
        environment: 'bitcoin',
        asyncValue: blockchain,
        detail: (data) {
          final chain = _map(data['chain']);
          return context.tr.adminHeightValue('${chain['height'] ?? 0}');
        },
      ),
      _row(
        context: context,
        name: 'Lightning LND',
        role: context.tr.adminCompaniesRoleLightningRouting,
        environment: 'lightning',
        asyncValue: lightning,
        detail: (data) {
          final node = _map(data['node']);
          return context.tr.adminPeersValue(
            '${node['alias'] ?? 'node'}',
            '${node['numPeers'] ?? 0}',
          );
        },
      ),
      _row(
        context: context,
        name: 'Vault/Raft',
        role: context.tr.adminCompaniesRoleReleaseQuorum,
        environment: 'vault',
        asyncValue: vault,
        detail: (data) => context.tr.adminVotersValue(
          '${data['votingServers'] ?? 0}',
          '${data['expectedServers'] ?? 3}',
        ),
      ),
      _row(
        context: context,
        name: context.tr.adminCompaniesEntityReleaseGate,
        role: context.tr.adminCompaniesRoleDeploymentAttestation,
        environment: 'mobile/web',
        asyncValue: release,
        detail: (data) => '${data['reason'] ?? context.tr.unknown}',
      ),
    ];

    return AdminPanel(
      title: context.tr.adminCompaniesOperationalEntities,
      icon: KeroseneIcons.business,
      child: AdminDataTable(
        columns: [
          context.tr.adminColumnEntity,
          context.tr.adminColumnRole,
          context.tr.adminColumnEnvironment,
          context.tr.adminColumnHealth,
          context.tr.adminColumnDetail,
        ],
        rows: rows,
      ),
    );
  }
}

class _RoutingPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> overview;

  const _RoutingPanel({required this.overview});

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr.adminCompaniesRoutingDependencies,
      icon: KeroseneIcons.route,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminKeyValueRow(
            label: context.tr.adminLabelActiveNode,
            value: AppConfig.activeNodeName,
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelApiRoute,
            value: AppConfig.apiUrl,
            monospace: true,
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelTorEnabled,
            value: _boolText(context, AppConfig.isTorEnabled),
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          Text(context.tr.adminCompaniesRemoteNodes, style: AdminTypography.h4),
          const SizedBox(height: AdminTheme.spacingSm),
          AdminDataTable(
            columns: [
              context.tr.adminColumnName,
              context.tr.adminColumnEndpoint,
            ],
            rows: [
              for (final entry in AppConfig.nodes.entries)
                [
                  Text(entry.key, style: AdminTypography.tableCell),
                  _MonoText(entry.value),
                ],
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          overview.when(
            data: (data) => Column(
              children: [
                AdminKeyValueRow(
                  label: context.tr.adminLabelChecked,
                  value: '${data['checkedAt'] ?? context.tr.unknown}',
                ),
                AdminKeyValueRow(
                  label: context.tr.adminLabelPrimarySource,
                  value:
                      '${data['primarySource'] ?? context.tr.adminValueBackend}',
                ),
              ],
            ),
            loading: () => const AdminSkeleton(height: 38),
            error: (_, __) => Text(
              context.tr.adminCompaniesOverviewUnavailable,
              style:
                  AdminTypography.caption.copyWith(color: AdminColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _row({
  required BuildContext context,
  required String name,
  required String role,
  required String environment,
  required AsyncValue<Map<String, dynamic>> asyncValue,
  required String Function(Map<String, dynamic>) detail,
}) {
  return asyncValue.when(
    data: (data) {
      final status = _status(data);
      return [
        Text(name, style: AdminTypography.tableCell),
        Text(role, style: AdminTypography.tableCell),
        Text(environment, style: AdminTypography.tableCellMono),
        AdminStatusBadge(label: status, variant: _statusVariant(status)),
        _MonoText(detail(data)),
      ];
    },
    loading: () => [
      Text(name, style: AdminTypography.tableCell),
      Text(role, style: AdminTypography.tableCell),
      Text(environment, style: AdminTypography.tableCellMono),
      AdminStatusBadge(
          label: context.tr.loading, variant: AdminBadgeVariant.info),
      _MonoText(context.tr.adminWaitingForResponse),
    ],
    error: (_, __) => [
      Text(name, style: AdminTypography.tableCell),
      Text(role, style: AdminTypography.tableCell),
      Text(environment, style: AdminTypography.tableCellMono),
      AdminStatusBadge(
          label: context.tr.error, variant: AdminBadgeVariant.negative),
      _MonoText(context.tr.adminBackendError),
    ],
  );
}

class _MonoText extends StatelessWidget {
  final String value;

  const _MonoText(this.value);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AdminTypography.tableCellMono,
      ),
    );
  }
}

String _boolText(BuildContext context, bool value) {
  return value ? context.tr.adminValueTrue : context.tr.adminValueFalse;
}

String _status(Map<String, dynamic> data) {
  if (data['authorized'] is bool) {
    return data['authorized'] == true ? 'AUTHORIZED' : 'BLOCKED';
  }
  return '${data['status'] ?? data['reason'] ?? 'UNKNOWN'}';
}

AdminBadgeVariant _statusVariant(String status) {
  final normalized = status.toUpperCase();
  if (normalized.contains('OK') ||
      normalized.contains('UP') ||
      normalized.contains('ACTIVE') ||
      normalized.contains('AUTHORIZED') ||
      normalized.contains('HEALTHY')) {
    return AdminBadgeVariant.positive;
  }
  if (normalized.contains('WARN') ||
      normalized.contains('PENDING') ||
      normalized.contains('SYNC')) {
    return AdminBadgeVariant.warning;
  }
  if (normalized.contains('ERROR') ||
      normalized.contains('DOWN') ||
      normalized.contains('BLOCKED') ||
      normalized.contains('FAIL')) {
    return AdminBadgeVariant.negative;
  }
  return AdminBadgeVariant.neutral;
}

Color _statusColor(String status) {
  return switch (_statusVariant(status)) {
    AdminBadgeVariant.positive => AdminColors.positive,
    AdminBadgeVariant.warning => AdminColors.warning,
    AdminBadgeVariant.negative => AdminColors.negative,
    AdminBadgeVariant.info => AdminColors.info,
    AdminBadgeVariant.accent => AdminColors.accent,
    AdminBadgeVariant.neutral => AdminColors.textTertiary,
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
