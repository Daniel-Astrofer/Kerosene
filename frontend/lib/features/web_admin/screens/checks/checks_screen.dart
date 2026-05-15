import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Hash-chain module.
///
/// This screen deliberately avoids listing internal user transfers. The admin
/// terminal should show integrity state and aggregate operational posture only.
class ChecksScreen extends ConsumerWidget {
  const ChecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestRoot = ref.watch(adminAuditLatestRootProvider);
    final sov = ref.watch(adminSovereigntyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Hash Chain',
            subtitle:
                'Sequential ledger hashes and Merkle roots for integrity, not readable user history.',
          ),
          AdminResponsiveGrid(
            children: [
              _HashPolicyCard(),
              _LatestRootCard(latestRoot: latestRoot),
              _LedgerIntegrityCard(sov: sov),
            ],
          ),
        ],
      ),
    );
  }
}

class _HashPolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Retention policy',
      icon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Readable buffer', '<= 24h'),
          _Line('Durable history', 'mobile encrypted storage'),
          _Line('Backend proof', 'hashes, commitments, Merkle roots'),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(
            'Ledger sem payload: the server proves consistency without acting as a permanent user statement.',
            style: AdminTypography.bodySmall.copyWith(
              color: AdminColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestRootCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> latestRoot;

  const _LatestRootCard({required this.latestRoot});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Merkle audit root',
      icon: Icons.account_tree_outlined,
      child: latestRoot.when(
        data: (root) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Line('Root', _short(root['merkleRoot'])),
            _Line('Ledger count', '${root['ledgerCount'] ?? 0}'),
            _Line('Created', '${root['createdAt'] ?? 'unknown'}'),
          ],
        ),
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load Merkle root: $error',
          style: AdminTypography.caption,
        ),
      ),
    );
  }
}

class _LedgerIntegrityCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> sov;

  const _LedgerIntegrityCard({required this.sov});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Integrity state',
      icon: Icons.fingerprint,
      child: sov.when(
        data: (data) {
          final value = data['ledgerIntegrity'];
          final integrity = value is Map
              ? Map<String, dynamic>.from(value)
              : <String, dynamic>{};
          if (integrity.isEmpty) {
            return Text(
              'Ledger integrity data unavailable',
              style: AdminTypography.bodyMedium,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: integrity.entries
                .take(5)
                .map((entry) => _Line(entry.key, _short(entry.value)))
                .toList(),
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load integrity data: $error',
          style: AdminTypography.caption,
        ),
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
              Icon(icon, color: AdminColors.warning, size: 16),
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

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line(this.label, this.value);

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
            child: Text(
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

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
