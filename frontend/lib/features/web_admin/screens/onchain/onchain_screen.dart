import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';
import '../../theme/admin_copy.dart';

/// On-chain BTC operations module.
///
/// Shows node and mempool state, not individual on-chain user history.
class OnchainScreen extends ConsumerWidget {
  const OnchainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockchain = ref.watch(adminBlockchainMonitorProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminBlockchainMonitorProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'On-chain Operations',
              subtitle:
                  'Bitcoin Core status, block height, mempool, and sanitized watched-transaction fingerprints.',
            ),
            blockchain.when(
              data: (data) {
                final chain = _map(data['chain']);
                final mempool = _map(data['mempool']);
                final fees = _map(data['fees']);
                final relevant =
                    (data['relevantTransactions'] as List?) ?? const [];
                return Column(
                  children: [
                    AdminResponsiveGrid(
                      children: [
                        AdminMetricCard(
                          label: 'Status',
                          value: '${data['status'] ?? 'UNKNOWN'}',
                          icon: KeroseneIcons.onchain,
                          accentColor: _statusColor('${data['status'] ?? ''}'),
                        ),
                        AdminMetricCard(
                          label: 'Block Height',
                          value: '${chain['height'] ?? 0}',
                          icon: KeroseneIcons.layers,
                        ),
                        AdminMetricCard(
                          label: 'Mempool',
                          value: '${mempool['transactions'] ?? 0} tx',
                          icon: KeroseneIcons.memory,
                        ),
                        AdminMetricCard(
                          label: 'Fee Rate',
                          value:
                              '${fees['fastestFee'] ?? fees['halfHourFee'] ?? 0} sat/vB',
                          icon: KeroseneIcons.payments,
                          accentColor: AdminColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AdminTheme.spacingXl),
                    _Panel(
                      title: 'Node state',
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _KeyValue(
                              'Primary source', '${data['primarySource']}'),
                          _KeyValue('Network', '${data['network']}'),
                          _KeyValue(
                              'Best hash', _short(chain['bestBlockHash'])),
                          _KeyValue('Pruned', '${chain['pruned'] ?? false}'),
                          _KeyValue(
                              'Prune height', '${chain['pruneHeight'] ?? 0}'),
                          _KeyValue('Indexer', '${data['indexer']}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingXl),
                    _Panel(
                      title: 'Watched transaction fingerprints',
                      child: relevant.isEmpty
                          ? Text(
                              AdminCopy.noOnchainActions,
                              style: AdminTypography.bodySmall.copyWith(
                                color: AdminColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: relevant.take(12).map((item) {
                                final row = _map(item);
                                return _EventRow(
                                  title: '${row['status'] ?? 'UNKNOWN'}',
                                  body:
                                      '${row['txidRef'] ?? 'absent'} | ${row['confirmations'] ?? 0} confirmations',
                                );
                              }).toList(),
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
              error: (e, _) => AdminErrorState(
                message: AdminCopy.blockchainMonitorUnavailable,
                onRetry: () => ref.invalidate(adminBlockchainMonitorProvider),
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
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AdminTypography.label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AdminTypography.mono.copyWith(
              fontSize: 12,
              color: AdminColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String title;
  final String body;

  const _EventRow({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminColors.backgroundElevated,
        border: Border.all(color: AdminColors.borderSubtle),
        borderRadius: AdminTheme.borderRadiusXs,
      ),
      child: Row(
        children: [
          const Icon(KeroseneIcons.biometric,
              color: AdminColors.textTertiary, size: 15),
          const SizedBox(width: AdminTheme.spacingMd),
          Expanded(
            child: Text(
              '$title | $body',
              style: AdminTypography.mono.copyWith(fontSize: 12),
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

Color _statusColor(String status) {
  final normalized = status.toUpperCase();
  if (normalized == 'UP' || normalized == 'OK' || normalized == 'ONLINE') {
    return AdminColors.positive;
  }
  if (normalized == 'DOWN' || normalized == 'ERROR') {
    return AdminColors.negative;
  }
  return AdminColors.warning;
}

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
