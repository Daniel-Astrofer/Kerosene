import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

class AuthenticatedDevicesScreen extends ConsumerWidget {
  const AuthenticatedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = ref.watch(adminMobileDevicesProvider);
    final web = ref.watch(adminWebDevicesProvider);
    final mobileDevices =
        mobile.asData?.value ?? const <Map<String, dynamic>>[];
    final webDevices = web.asData?.value ?? const <Map<String, dynamic>>[];
    final mobileCount = mobileDevices.length;
    final webCount = webDevices.length;
    final activeCount = [
      ...mobileDevices,
      ...webDevices,
    ].where((device) => _status(device) == 'ACTIVE').length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminMobileDevicesProvider);
        ref.invalidate(adminWebDevicesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: 'Authenticated Devices',
              subtitle:
                  'Web and mobile sessions with last activity, platform, status, and revoke controls.',
              trailing: OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(adminMobileDevicesProvider);
                  ref.invalidate(adminWebDevicesProvider);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminResponsiveGrid(
              children: [
                AdminMetricCard(
                  label: 'Active Devices',
                  value: '$activeCount',
                  subtitle: 'web and mobile',
                  icon: Icons.verified_user_outlined,
                  accentColor: AdminColors.positive,
                ),
                AdminMetricCard(
                  label: 'Web Sessions',
                  value: '$webCount',
                  subtitle: 'admin browser access',
                  icon: Icons.language_outlined,
                ),
                AdminMetricCard(
                  label: 'Mobile Devices',
                  value: '$mobileCount',
                  subtitle: 'passkey/device-bound access',
                  icon: Icons.phone_android_outlined,
                ),
                AdminMetricCard(
                  label: 'Revocation',
                  value: 'Step-up',
                  subtitle: 'sensitive actions require confirmation',
                  icon: Icons.lock_outline,
                  accentColor: AdminColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            LayoutBuilder(
              builder: (context, constraints) {
                final webPanel = _DevicesPanel(
                  title: 'Web devices',
                  icon: Icons.language_outlined,
                  asyncValue: web,
                  platformFallback: 'Web',
                  onRetry: () => ref.invalidate(adminWebDevicesProvider),
                );
                final mobilePanel = _DevicesPanel(
                  title: 'Mobile devices',
                  icon: Icons.phone_android_outlined,
                  asyncValue: mobile,
                  platformFallback: 'Mobile',
                  onRetry: () => ref.invalidate(adminMobileDevicesProvider),
                );

                if (constraints.maxWidth < 1040) {
                  return Column(
                    children: [
                      webPanel,
                      const SizedBox(height: AdminTheme.spacingLg),
                      mobilePanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: webPanel),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(child: mobilePanel),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicesPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<Map<String, dynamic>>> asyncValue;
  final String platformFallback;
  final VoidCallback onRetry;

  const _DevicesPanel({
    required this.title,
    required this.icon,
    required this.asyncValue,
    required this.platformFallback,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: title,
      icon: icon,
      child: asyncValue.when(
        loading: () => const Column(
          children: [
            AdminSkeleton(height: 42),
            SizedBox(height: AdminTheme.spacingSm),
            AdminSkeleton(height: 42),
          ],
        ),
        error: (_, __) => AdminErrorState(
          message: '$title could not be loaded.',
          onRetry: onRetry,
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return AdminEmptyState(
              title: 'No $platformFallback devices',
              subtitle: 'Authenticated devices appear here after sign-in.',
              icon: icon,
            );
          }
          return AdminDataTable(
            columns: const [
              'Device',
              'Platform',
              'Status',
              'Last Activity',
              'Action'
            ],
            rows: [
              for (final device in devices)
                [
                  _MonoText(_name(device)),
                  Text(
                    _platform(device, platformFallback),
                    style: AdminTypography.tableCell,
                  ),
                  AdminStatusBadge(
                    label: _status(device),
                    variant: _statusVariant(_status(device)),
                  ),
                  _MonoText(_lastActivity(device)),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Revocation requires step-up confirmation.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.block, size: 14),
                    label: const Text('Revoke'),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
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

String _name(Map<String, dynamic> device) {
  return (device['deviceName'] ??
          device['name'] ??
          device['deviceId'] ??
          device['id'] ??
          'unknown device')
      .toString();
}

String _platform(Map<String, dynamic> device, String fallback) {
  return (device['platform'] ?? device['browser'] ?? fallback).toString();
}

String _status(Map<String, dynamic> device) {
  return (device['status'] ?? 'UNKNOWN').toString().toUpperCase();
}

String _lastActivity(Map<String, dynamic> device) {
  return (device['lastSeenAt'] ??
          device['lastAccessAt'] ??
          device['updatedAt'] ??
          device['createdAt'] ??
          'unknown')
      .toString();
}

AdminBadgeVariant _statusVariant(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
    case 'AUTHENTICATED':
      return AdminBadgeVariant.positive;
    case 'PENDING':
    case 'CHALLENGE_REQUIRED':
      return AdminBadgeVariant.warning;
    case 'REVOKED':
    case 'BLOCKED':
    case 'EXPIRED':
      return AdminBadgeVariant.negative;
    default:
      return AdminBadgeVariant.neutral;
  }
}
