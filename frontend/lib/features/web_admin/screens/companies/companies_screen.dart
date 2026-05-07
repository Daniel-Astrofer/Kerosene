import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Infrastructure module.
///
/// Enterprise operators manage infrastructure posture here. User accounts,
/// wallet names, individual balances, and readable transaction history are not
/// rendered in this admin terminal.
class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminOperationsOverviewProvider);
    final mobile = ref.watch(adminMobileReleaseProvider);
    final release = ref.watch(adminReleaseSnapshotProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOperationsOverviewProvider);
        ref.invalidate(adminMobileReleaseProvider);
        ref.invalidate(adminReleaseSnapshotProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Infrastructure',
              subtitle:
                  'Operational posture for services, release, and mobile distribution. No personal account ledger is exposed.',
            ),
            AdminResponsiveGrid(
              children: [
                _OverviewCard(overview: overview),
                _ReleaseCard(release: release),
                _MobileCard(mobile: mobile),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> overview;

  const _OverviewCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Operations',
      icon: Icons.dns_outlined,
      child: overview.when(
        data: (data) {
          final health = _map(data['health']);
          final blockchain = _map(data['blockchain']);
          final lightning = _map(data['lightning']);
          final vault = _map(data['vaultRaft']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line('Health', '${health['status'] ?? 'UNKNOWN'}'),
              _Line('Bitcoin Core', '${blockchain['status'] ?? 'UNKNOWN'}'),
              _Line('Lightning', '${lightning['status'] ?? 'UNKNOWN'}'),
              _Line('Vault/Raft', '${vault['status'] ?? 'UNKNOWN'}'),
              _Line('Checked', '${data['checkedAt'] ?? 'unknown'}'),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load operations overview: $error',
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
      title: 'Release attestation',
      icon: Icons.verified_user_outlined,
      child: release.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Line('Authorized', '${data['authorized'] == true}'),
            _Line('Version', '${data['version'] ?? 'unknown'}'),
            _Line('Reason', '${data['reason'] ?? 'unknown'}'),
            _Line('Commit', _short(data['gitCommit'])),
            _Line('Image digest', _short(data['imageDigest'])),
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

class _MobileCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> mobile;

  const _MobileCard({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Mobile release',
      icon: Icons.phone_iphone,
      child: mobile.when(
        data: (data) {
          final artifacts = _map(data['artifacts']);
          final android = _map(artifacts['android']);
          final ios = _map(artifacts['ios']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line('Version', '${data['version'] ?? 'unknown'}'),
              _Line('Build', '${data['buildNumber'] ?? 'unknown'}'),
              _Line('Android SHA-256', _short(android['sha256'])),
              _Line('iOS SHA-256', _short(ios['sha256'])),
              const SizedBox(height: AdminTheme.spacingMd),
              Text(
                'Mobile keeps durable readable history in encrypted local storage.',
                style: AdminTypography.bodySmall.copyWith(
                  color: AdminColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(
          color: AdminColors.textTertiary,
        ),
        error: (error, _) => Text(
          'Failed to load mobile release: $error',
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

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _short(Object? value) {
  final text = value?.toString() ?? 'absent';
  if (text.isEmpty) return 'absent';
  if (text.length <= 22) return text;
  return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
}
