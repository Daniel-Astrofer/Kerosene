import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';
import '../../theme/admin_copy.dart';

/// Integrity proofs module.
///
/// The enterprise terminal must not expose a user's readable transaction
/// history. It shows only cryptographic roots and operational proof state.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestRoot = ref.watch(adminAuditLatestRootProvider);
    final auditHistory = ref.watch(adminAuditHistoryProvider);
    final sovereignty = ref.watch(adminSovereigntyProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminAuditLatestRootProvider);
        ref.invalidate(adminAuditHistoryProvider);
        ref.invalidate(adminSovereigntyProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Integrity Proofs',
              subtitle:
                  'Ledger sem payload: hash-chain, Merkle root e estado operacional sem historico pessoal.',
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AdminTheme.spacingXl),
              padding: const EdgeInsets.all(AdminTheme.spacingLg),
              decoration: BoxDecoration(
                color: AdminColors.warningSubtle,
                border: Border.all(
                  color: AdminColors.warning.withValues(alpha: 0.35),
                ),
                borderRadius: AdminTheme.borderRadiusSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    KeroseneIcons.privacyTip,
                    color: AdminColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AdminTheme.spacingMd),
                  Expanded(
                    child: Text(
                      AdminCopy.readableRowsRetentionPolicy,
                      style: AdminTypography.bodySmall.copyWith(
                        color: AdminColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AdminResponsiveGrid(
              children: [
                _LatestRootCard(asyncValue: latestRoot),
                _SovereigntyIntegrityCard(asyncValue: sovereignty),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            _AuditRootsTimeline(asyncValue: auditHistory),
          ],
        ),
      ),
    );
  }
}

class _LatestRootCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _LatestRootCard({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _ProofCard(
      title: 'Latest Merkle root',
      icon: KeroseneIcons.network,
      child: asyncValue.when(
        data: (root) {
          if (root.isEmpty) {
            return Text(AdminCopy.rootUnavailable,
                style: AdminTypography.bodyMedium);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row('Root', _short(root['merkleRoot'])),
              _Row('Ledger count', '${root['ledgerCount'] ?? 0}'),
              _Row('Created', '${root['createdAt'] ?? 'unknown'}'),
              _Row('Anchor', _short(root['anchorTxid'])),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          AdminCopy.merkleRootUnavailable,
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _SovereigntyIntegrityCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> asyncValue;

  const _SovereigntyIntegrityCard({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _ProofCard(
      title: 'Hash-chain state',
      icon: KeroseneIcons.biometric,
      child: asyncValue.when(
        data: (data) {
          final ledgerIntegrity = data['ledgerIntegrity'];
          final integrity = ledgerIntegrity is Map
              ? Map<String, dynamic>.from(ledgerIntegrity)
              : <String, dynamic>{};
          if (integrity.isEmpty) {
            return Text(
              AdminCopy.integrityStateUnavailable,
              style: AdminTypography.bodyMedium,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: integrity.entries.take(6).map((entry) {
              return _Row(_formatKey(entry.key), _short(entry.value));
            }).toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          AdminCopy.integrityStateUnavailable,
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _AuditRootsTimeline extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncValue;

  const _AuditRootsTimeline({required this.asyncValue});

  @override
  Widget build(BuildContext context) {
    return _ProofCard(
      title: 'Merkle audit roots',
      icon: KeroseneIcons.history,
      child: asyncValue.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Text(AdminCopy.noAuditCheckpoints,
                style: AdminTypography.bodyMedium);
          }
          return Column(
            children: entries.take(20).map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
                padding: const EdgeInsets.all(AdminTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundElevated,
                  border: Border.all(color: AdminColors.borderSubtle),
                  borderRadius: AdminTheme.borderRadiusXs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      KeroseneIcons.network,
                      color: AdminColors.textTertiary,
                      size: 15,
                    ),
                    const SizedBox(width: AdminTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _short(entry['merkleRoot']),
                            style: AdminTypography.mono.copyWith(
                              fontSize: 12,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AdminCopy.auditRootTimelineEntry(
                                entry['createdAt'], entry['ledgerCount']),
                            style: AdminTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          AdminCopy.auditRootsUnavailable,
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProofCard({
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
          Expanded(child: Text(label, style: AdminTypography.caption)),
          const SizedBox(width: AdminTheme.spacingMd),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
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

String _formatKey(String key) {
  return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim();
}

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
