import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/providers/tor_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';

/// Settings screen for admin configuration.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiUrl = ref.watch(torApiUrlProvider);
    final apiHost = Uri.tryParse(apiUrl)?.host ?? 'unconfigured';
    final routeMode =
        apiHost.endsWith('.onion') ? 'Onion service' : 'Gateway/direct route';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administrative Settings', style: AdminTypography.h2),
          const SizedBox(height: AdminTheme.spacingSm),
          Text(
            'System configuration and organizational preferences',
            style: AdminTypography.bodyMedium,
          ),
          const SizedBox(height: AdminTheme.spacingXl),

          // General settings section
          _SettingsSection(
            title: 'General',
            children: [
              _SettingRow(
                icon: Icons.language,
                label: 'Language',
                value: 'English',
              ),
              _SettingRow(
                icon: Icons.access_time,
                label: 'Timezone',
                value: 'UTC-3 (São Paulo)',
              ),
              _SettingRow(
                icon: Icons.attach_money,
                label: 'Display Currency',
                value: 'USD / BRL',
              ),
              _SettingRow(
                icon: Icons.format_list_numbered,
                label: 'BTC Display',
                value: '8 decimal places',
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          _SettingsSection(
            title: 'Security',
            children: [
              _SettingRow(
                icon: Icons.lock_outline,
                label: 'Session Timeout',
                value: '30 minutes',
              ),
              _SettingRow(
                icon: Icons.fingerprint,
                label: '2FA (TOTP)',
                value: 'Enabled',
              ),
              _SettingRow(
                icon: Icons.devices_outlined,
                label: 'Authenticated Devices',
                value: 'Registered',
              ),
              _SettingRow(
                icon: Icons.vpn_key,
                label: 'API Access',
                value: 'Token-based',
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingRow(
                icon: Icons.notifications_outlined,
                label: 'Transaction Alerts',
                value: 'All types',
              ),
              _SettingRow(
                icon: Icons.security,
                label: 'Security Events',
                value: 'Enabled',
              ),
              _SettingRow(
                icon: Icons.warning_amber,
                label: 'Risk Alerts',
                value: 'High priority only',
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          _SettingsSection(
            title: 'Network',
            children: [
              _SettingRow(
                icon: Icons.router,
                label: 'API Route',
                value: routeMode,
              ),
              _SettingRow(
                icon: Icons.cloud_outlined,
                label: 'API Host',
                value: apiHost,
              ),
              _SettingRow(
                icon: Icons.timer,
                label: 'Request Timeout',
                value: '30s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Text(title.toUpperCase(), style: AdminTypography.label),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingLg,
        vertical: AdminTheme.spacingMd,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AdminColors.textTertiary),
          const SizedBox(width: AdminTheme.spacingMd),
          Expanded(
            child: Text(
              label,
              style: AdminTypography.bodyLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AdminTypography.mono.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
