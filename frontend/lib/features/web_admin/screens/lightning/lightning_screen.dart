import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Lightning Network operations module.
///
/// This enterprise view is operational only: LND health, channel state, and
/// aggregate liquidity. It must not render individual invoices, payment hashes,
/// destinations, readable user history, or wallet-level personal data.
class LightningScreen extends ConsumerWidget {
  const LightningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightning = ref.watch(adminLightningMonitorProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminLightningMonitorProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Lightning Operations',
              subtitle:
                  'LND node health, channel state, and aggregate liquidity. No individual invoice or payment payload is shown.',
            ),
            lightning.when(
              data: (data) {
                final node = _map(data['node']);
                final status = '${data['status'] ?? 'UNKNOWN'}';
                final peers = _asInt(node['numPeers']);
                final activeChannels = _asInt(node['numActiveChannels']);
                final inactiveChannels = _asInt(node['numInactiveChannels']);
                final pendingChannels = _asInt(node['numPendingChannels']);
                final totalChannels = activeChannels + inactiveChannels + pendingChannels;
                final localBalance = _asInt(node['localBalanceSats']);
                final remoteBalance = _asInt(node['remoteBalanceSats']);
                final walletBalance = _asInt(node['walletConfirmedBalanceSats']);

                return Column(
                  children: [
                    AdminResponsiveGrid(
                      children: [
                        AdminMetricCard(
                          label: 'LND Status',
                          value: status,
                          subtitle: '${data['message'] ?? 'operational probe'}',
                          icon: Icons.flash_on_outlined,
                          accentColor: _statusColor(status),
                        ),
                        AdminMetricCard(
                          label: 'Block Height',
                          value: '${node['blockHeight'] ?? 0}',
                          subtitle: 'synced chain ${node['syncedToChain'] == true}',
                          icon: Icons.layers_outlined,
                        ),
                        AdminMetricCard(
                          label: 'Peers',
                          value: '$peers',
                          subtitle: 'graph synced ${node['syncedToGraph'] == true}',
                          icon: Icons.hub_outlined,
                        ),
                        AdminMetricCard(
                          label: 'Channels',
                          value: '$totalChannels',
                          subtitle: '$activeChannels active | $pendingChannels pending',
                          icon: Icons.account_tree_outlined,
                          accentColor:
                              pendingChannels == 0 ? AdminColors.positive : AdminColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AdminTheme.spacingXl),
                    _Panel(
                      title: 'Node State',
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _KeyValue('Primary source', '${data['primarySource']}'),
                          _KeyValue('Checked at', '${data['checkedAt'] ?? 'unknown'}'),
                          _KeyValue('Alias', '${node['alias'] ?? 'not configured'}'),
                          _KeyValue('Version', '${node['version'] ?? 'unknown'}'),
                          _KeyValue('Node key', _short(node['identityPubkey'])),
                          _KeyValue('Block hash', _short(node['blockHash'])),
                          _KeyValue('Synced to chain', '${node['syncedToChain'] == true}'),
                          _KeyValue('Synced to graph', '${node['syncedToGraph'] == true}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingXl),
                    _Panel(
                      title: 'Channel Liquidity',
                      child: AdminResponsiveGrid(
                        minItemWidth: 220,
                        children: [
                          AdminMetricCard(
                            label: 'Local Balance',
                            value: '${_formatSats(localBalance)} sats',
                            subtitle: 'aggregate outbound capacity',
                            icon: Icons.arrow_upward,
                          ),
                          AdminMetricCard(
                            label: 'Remote Balance',
                            value: '${_formatSats(remoteBalance)} sats',
                            subtitle: 'aggregate inbound capacity',
                            icon: Icons.arrow_downward,
                          ),
                          AdminMetricCard(
                            label: 'Wallet Balance',
                            value: '${_formatSats(walletBalance)} sats',
                            subtitle: 'confirmed LND wallet aggregate',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingXl),
                    _Panel(
                      title: 'Privacy Boundary',
                      child: Column(
                        children: const [
                          _BoundaryRow(
                            label: 'Visible here',
                            value: 'node status, sync flags, channel counts, aggregate balances',
                            variant: AdminBadgeVariant.info,
                          ),
                          _BoundaryRow(
                            label: 'Not visible here',
                            value:
                                'invoice payload, payment hash, destination, user wallet, personal history',
                            variant: AdminBadgeVariant.warning,
                          ),
                          _BoundaryRow(
                            label: 'Durable history',
                            value:
                                'kept on the user mobile device; backend readable buffer expires within 24h',
                            variant: AdminBadgeVariant.positive,
                          ),
                        ],
                      ),
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
              error: (error, _) => AdminErrorState(
                message: 'Failed to load Lightning monitor: $error',
                onRetry: () => ref.invalidate(adminLightningMonitorProvider),
              ),
            ),
          ],
        ),
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
          Text(title.toUpperCase(), style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          child,
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
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AdminTypography.label),
          const SizedBox(height: 4),
          Tooltip(
            message: value,
            child: Text(
              value.isEmpty ? 'absent' : value,
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

class _BoundaryRow extends StatelessWidget {
  final String label;
  final String value;
  final AdminBadgeVariant variant;

  const _BoundaryRow({
    required this.label,
    required this.value,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AdminTheme.spacingSm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: AdminStatusBadge(label: label, variant: variant),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Expanded(
            child: Text(
              value,
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.textSecondary,
                height: 1.45,
              ),
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
  if (normalized == 'UP' || normalized == 'OK' || normalized == 'ONLINE') {
    return AdminColors.positive;
  }
  if (normalized == 'DOWN' || normalized == 'ERROR') return AdminColors.negative;
  return AdminColors.warning;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatSats(int value) {
  final chars = value.toString().split('').reversed.toList();
  final grouped = <String>[];
  for (var index = 0; index < chars.length; index += 3) {
    grouped.add(chars.skip(index).take(3).toList().reversed.join());
  }
  return grouped.reversed.join(',');
}

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
