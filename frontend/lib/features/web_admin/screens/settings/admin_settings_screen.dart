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

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(adminCurrentUserProvider);
    final release = ref.watch(adminReleaseSnapshotProvider);
    final mobileRelease = ref.watch(adminMobileReleaseProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCurrentUserProvider);
        ref.invalidate(adminReleaseSnapshotProvider);
        ref.invalidate(adminMobileReleaseProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: context.tr.adminRouteSettings,
              subtitle: context.tr.adminSettingsSubtitle,
              trailing: OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(adminCurrentUserProvider);
                  ref.invalidate(adminReleaseSnapshotProvider);
                  ref.invalidate(adminMobileReleaseProvider);
                },
                icon: const Icon(KeroseneIcons.refresh, size: 16),
                label: Text(context.tr.adminActionRefresh),
              ),
            ),
            AdminResponsiveGrid(
              children: [
                AdminMetricCard(
                  label: context.tr.adminLabelApiRoute,
                  value: AppConfig.isTorEnabled
                      ? context.tr.adminValueTor
                      : context.tr.adminValueDirect,
                  subtitle: AppConfig.activeNodeName,
                  icon: KeroseneIcons.route,
                  accentColor: AppConfig.isTorEnabled ? AdminColors.info : null,
                ),
                AdminMetricCard(
                  label: context.tr.adminLabelSession,
                  value: currentUser.when(
                    data: (_) => context.tr.adminValueAuthenticated,
                    loading: () => context.tr.adminValueChecking,
                    error: (_, __) => context.tr.unknown,
                  ),
                  subtitle: currentUser.asData?.value['username']?.toString() ??
                      context.tr.adminValueAdminContext,
                  icon: KeroseneIcons.badge,
                ),
                AdminMetricCard(
                  label: context.tr.security,
                  value: AppConfig.effectivePasskeyRpId,
                  subtitle: context.tr.adminLabelPasskeyRelyingParty,
                  icon: KeroseneIcons.key,
                  accentColor: AdminColors.accent,
                ),
                AdminMetricCard(
                  label: context.tr.adminLabelVersion,
                  value: AppConfig.appVersion,
                  subtitle: mobileRelease.when(
                    data: (data) =>
                        '${data['version'] ?? context.tr.adminValueMobileUnknown}',
                    loading: () => context.tr.adminValueCheckingRelease,
                    error: (_, __) => context.tr.adminValueReleaseUnavailable,
                  ),
                  icon: KeroseneIcons.verified,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            LayoutBuilder(
              builder: (context, constraints) {
                final routing = _RoutingSettingsPanel();
                final security =
                    _SecuritySettingsPanel(currentUser: currentUser);
                final releasePanel = _ReleaseSettingsPanel(
                  release: release,
                  mobileRelease: mobileRelease,
                );

                if (constraints.maxWidth < 1020) {
                  return Column(
                    children: [
                      routing,
                      const SizedBox(height: AdminTheme.spacingLg),
                      security,
                      const SizedBox(height: AdminTheme.spacingLg),
                      releasePanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: routing),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(child: security),
                    const SizedBox(width: AdminTheme.spacingLg),
                    Expanded(child: releasePanel),
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

class _RoutingSettingsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr.adminSettingsApiRoutingTitle,
      icon: KeroseneIcons.route,
      child: Column(
        children: [
          AdminKeyValueRow(
            label: context.tr.adminLabelApiUrl,
            value: AppConfig.apiUrl,
            monospace: true,
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelActiveNode,
            value: AppConfig.activeNodeName,
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelOnionBase,
            value: AppConfig.onionBaseUrl,
            monospace: true,
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelConnectionTimeout,
            value: '${AppConfig.connectionTimeout} ms',
          ),
          AdminKeyValueRow(
            label: context.tr.adminLabelReceiveTimeout,
            value: '${AppConfig.receiveTimeout} ms',
          ),
        ],
      ),
    );
  }
}

class _SecuritySettingsPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> currentUser;

  const _SecuritySettingsPanel({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr.adminSettingsSessionSecurityTitle,
      icon: KeroseneIcons.security,
      child: currentUser.when(
        loading: () => const AdminSkeleton(height: 120),
        error: (_, __) => AdminErrorState(
          message: context.tr.adminSettingsCurrentSessionError,
        ),
        data: (user) => Column(
          children: [
            AdminKeyValueRow(
              label: context.tr.adminLabelUser,
              value: '${user['username'] ?? user['email'] ?? 'admin'}',
            ),
            AdminKeyValueRow(
              label: context.tr.adminLabelRole,
              value: '${user['role'] ?? user['authority'] ?? 'operator'}',
            ),
            AdminKeyValueRow(
              label: context.tr.adminLabelJwtRefreshHeader,
              value: AppConfig.newTokenHeader,
            ),
            AdminKeyValueRow(
              label: context.tr.adminLabelPasskeyRp,
              value: AppConfig.effectivePasskeyRpId,
            ),
            AdminKeyValueRow(
              label: context.tr.adminLabelDebugLogs,
              value: AppConfig.enableLogs
                  ? context.tr.adminValueEnabled
                  : context.tr.adminValueDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseSettingsPanel extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> release;
  final AsyncValue<Map<String, dynamic>> mobileRelease;

  const _ReleaseSettingsPanel({
    required this.release,
    required this.mobileRelease,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr.adminSettingsReleaseTitle,
      icon: KeroseneIcons.security,
      child: Column(
        children: [
          release.when(
            loading: () => const AdminSkeleton(height: 74),
            error: (_, __) => Text(
              context.tr.adminSettingsReleaseAttestationUnavailable,
              style:
                  AdminTypography.caption.copyWith(color: AdminColors.negative),
            ),
            data: (data) => Column(
              children: [
                AdminKeyValueRow(
                  label: context.tr.adminLabelAuthorized,
                  value: _boolText(context, data['authorized'] == true),
                ),
                AdminKeyValueRow(
                  label: context.tr.adminLabelReason,
                  value: '${data['reason'] ?? context.tr.unknown}',
                ),
                AdminKeyValueRow(
                  label: context.tr.adminLabelCommit,
                  value: _short(context, data['gitCommit']),
                  monospace: true,
                ),
              ],
            ),
          ),
          const Divider(height: AdminTheme.spacingXl),
          mobileRelease.when(
            loading: () => const AdminSkeleton(height: 42),
            error: (_, __) => Text(
              context.tr.adminSettingsMobileReleaseUnavailable,
              style:
                  AdminTypography.caption.copyWith(color: AdminColors.negative),
            ),
            data: (data) => Column(
              children: [
                AdminKeyValueRow(
                  label: context.tr.adminLabelMobileVersion,
                  value: '${data['version'] ?? AppConfig.appVersion}',
                ),
                AdminKeyValueRow(
                  label: context.tr.adminLabelPlatform,
                  value: '${data['platform'] ?? context.tr.unknown}',
                ),
              ],
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

String _short(BuildContext context, Object? value) {
  final text = value?.toString() ?? context.tr.unknown;
  if (text.length <= 18) return text;
  return '${text.substring(0, 8)}...${text.substring(text.length - 8)}';
}
