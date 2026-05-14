import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Audit & Security module — logs, merkle proofs, and system integrity.
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditStatsAsync = ref.watch(adminAuditStatsProvider);
    final auditHistoryAsync = ref.watch(adminAuditHistoryProvider);
    final latestRootAsync = ref.watch(adminAuditLatestRootProvider);
    final sovAsync = ref.watch(adminSovereigntyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Audit & Security',
            subtitle: 'System integrity, Merkle proofs, and operational monitoring',
          ),

          // Audit stats
          auditStatsAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return const AdminEmptyState(
                  title: 'Audit data unavailable',
                  subtitle: 'The audit service may not be configured yet',
                  icon: Icons.security_outlined,
                );
              }
              return Column(
                children: [
                  Row(
                    children: stats.entries.take(4).map<Widget>((e) {
                      return Expanded(
                        child: AdminMetricCard(
                          label: _formatKey(e.key),
                          value: _formatValue(e.value),
                          icon: Icons.analytics_outlined,
                        ),
                      );
                    }).expand((w) => [w, const SizedBox(width: AdminTheme.spacingLg)]).toList()..removeLast(),
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Latest root proof
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _MerkleRootCard(latestRootAsync: latestRootAsync),
              ),
              const SizedBox(width: AdminTheme.spacingLg),
              Expanded(
                child: _SovereigntyCard(sovAsync: sovAsync),
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // Audit history timeline
          _AuditHistoryCard(historyAsync: auditHistoryAsync),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim();
  }

  String _formatValue(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is double) return value.toStringAsFixed(4);
    return value.toString();
  }
}

class _MerkleRootCard extends StatelessWidget {
  final AsyncValue latestRootAsync;
  const _MerkleRootCard({required this.latestRootAsync});

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
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 16, color: AdminColors.positive),
              const SizedBox(width: AdminTheme.spacingSm),
              Text('LATEST MERKLE ROOT', style: AdminTypography.label),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          latestRootAsync.when(
            data: (root) {
              if (root.isEmpty) {
                return Text('No root available', style: AdminTypography.bodyMedium);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: root.entries.map<Widget>((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            e.key,
                            style: AdminTypography.caption,
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            e.value.toString(),
                            style: AdminTypography.mono.copyWith(fontSize: 11, color: AdminColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AdminColors.textTertiary)),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }
}

class _SovereigntyCard extends StatelessWidget {
  final AsyncValue sovAsync;
  const _SovereigntyCard({required this.sovAsync});

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
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: AdminColors.info),
              const SizedBox(width: AdminTheme.spacingSm),
              Text('SOVEREIGNTY STATUS', style: AdminTypography.label),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          sovAsync.when(
            data: (data) {
              if (data.isEmpty) return Text('Not available', style: AdminTypography.bodyMedium);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.take(10).map<Widget>((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(e.key, style: AdminTypography.caption, overflow: TextOverflow.ellipsis)),
                        Text(
                          e.value is bool ? (e.value ? '✓' : '✗') : e.value.toString(),
                          style: AdminTypography.mono.copyWith(
                            fontSize: 11,
                            color: e.value is bool ? (e.value ? AdminColors.positive : AdminColors.negative) : AdminColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AdminColors.textTertiary)),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }
}

class _AuditHistoryCard extends StatelessWidget {
  final AsyncValue historyAsync;
  const _AuditHistoryCard({required this.historyAsync});

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
          Text('AUDIT HISTORY', style: AdminTypography.label),
          const SizedBox(height: AdminTheme.spacingLg),
          historyAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Text('No audit entries found', style: AdminTypography.bodyMedium);
              }
              return Column(
                children: (entries as List<Map<String, dynamic>>).take(20).map<Widget>((entry) {
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
                        const Icon(Icons.history, size: 14, color: AdminColors.textTertiary),
                        const SizedBox(width: AdminTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.entries.take(4).map<Widget>((e) {
                              return Text(
                                '${e.key}: ${e.value}',
                                style: AdminTypography.mono.copyWith(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AdminColors.textTertiary)),
            error: (e, _) => Text('Error: $e', style: AdminTypography.caption),
          ),
        ],
      ),
    );
  }
}
