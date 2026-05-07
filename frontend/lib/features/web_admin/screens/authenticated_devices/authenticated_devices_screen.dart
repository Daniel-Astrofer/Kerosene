import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_data_service.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_typography.dart';

class AuthenticatedDevicesScreen extends ConsumerWidget {
  const AuthenticatedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobileDevices = ref.watch(adminMobileDevicesProvider);
    final webDevices = ref.watch(adminWebDevicesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispositivos autenticados', style: AdminTypography.h2),
          const SizedBox(height: AdminTheme.spacingSm),
          Text(
            'Mobile devices and web/admin sessions linked to this account.',
            style: AdminTypography.bodyMedium,
          ),
          const SizedBox(height: AdminTheme.spacingXl),
          _DeviceSection(
            title: 'Mobile',
            devicesAsync: mobileDevices,
            source: _DeviceSource.mobile,
          ),
          const SizedBox(height: AdminTheme.spacingXl),
          _DeviceSection(
            title: 'Web/Admin',
            devicesAsync: webDevices,
            source: _DeviceSource.web,
          ),
        ],
      ),
    );
  }
}

enum _DeviceSource { mobile, web }

class _DeviceSection extends ConsumerWidget {
  final String title;
  final AsyncValue<List<Map<String, dynamic>>> devicesAsync;
  final _DeviceSource source;

  const _DeviceSection({
    required this.title,
    required this.devicesAsync,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Text(title.toUpperCase(), style: AdminTypography.label),
          ),
          const Divider(height: 1, color: AdminColors.border),
          devicesAsync.when(
            data: (devices) => devices.isEmpty
                ? const _EmptyDevices()
                : Column(
                    children: devices
                        .map(
                          (device) => _DeviceRow(
                            device: device,
                            source: source,
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(AdminTheme.spacingLg),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(AdminTheme.spacingLg),
              child: Text(
                'Unable to load devices.',
                style: AdminTypography.bodyMedium.copyWith(
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  final Map<String, dynamic> device;
  final _DeviceSource source;

  const _DeviceRow({
    required this.device,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = (device['deviceId'] ?? '').toString();
    final deviceInstallId = (device['deviceInstallId'] ?? '').toString();
    final name = (device['deviceName'] ?? 'Unknown device').toString();
    final status = (device['status'] ?? 'ACTIVE').toString();
    final browser = (device['browser'] ?? '').toString();
    final lastAccess = _date(device['lastAccessAt']);
    final firstAccess = _date(device['firstAccessAt']);

    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.devices_outlined, color: AdminColors.textTertiary),
          const SizedBox(width: AdminTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AdminTypography.bodyLarge),
                const SizedBox(height: AdminTheme.spacingXs),
                Wrap(
                  spacing: AdminTheme.spacingMd,
                  runSpacing: AdminTheme.spacingXs,
                  children: [
                    if ((device['brand'] ?? '').toString().isNotEmpty)
                      _Meta(label: 'Brand', value: device['brand'].toString()),
                    if ((device['model'] ?? '').toString().isNotEmpty)
                      _Meta(label: 'Model', value: device['model'].toString()),
                    if ((device['serialNumber'] ?? '').toString().isNotEmpty)
                      _Meta(
                          label: 'Serial',
                          value: device['serialNumber'].toString()),
                    if (browser.isNotEmpty)
                      _Meta(label: 'Browser', value: browser),
                    if (firstAccess != null)
                      _Meta(label: 'First', value: _formatDate(firstAccess)),
                    if (lastAccess != null)
                      _Meta(label: 'Last', value: _formatDate(lastAccess)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          _StatusPill(status: status),
          if (source == _DeviceSource.mobile && deviceInstallId.isNotEmpty) ...[
            const SizedBox(width: AdminTheme.spacingSm),
            TextButton(
              onPressed: () async {
                await ref
                    .read(adminDataServiceProvider)
                    .blockAuthenticatedMobileDevice(deviceInstallId);
                ref.invalidate(adminMobileDevicesProvider);
              },
              child: const Text('Block'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(adminDataServiceProvider)
                    .revokeAuthenticatedMobileDevice(deviceInstallId);
                ref.invalidate(adminMobileDevicesProvider);
              },
              child: const Text('Revoke'),
            ),
          ] else if (source == _DeviceSource.web && deviceId.isNotEmpty) ...[
            const SizedBox(width: AdminTheme.spacingSm),
            TextButton(
              onPressed: () async {
                await ref
                    .read(adminDataServiceProvider)
                    .blockAdminDevice(deviceId);
                ref.invalidate(adminWebDevicesProvider);
              },
              child: const Text('Block'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(adminDataServiceProvider)
                    .revokeAdminDevice(deviceId);
                ref.invalidate(adminWebDevicesProvider);
              },
              child: const Text('Revoke'),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;

  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: AdminTypography.caption.copyWith(color: AdminColors.textTertiary),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminColors.surfaceElevated,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusXs,
      ),
      child: Text(
        status.toUpperCase(),
        style: AdminTypography.caption,
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Text(
        'No devices found.',
        style: AdminTypography.bodyMedium.copyWith(
          color: AdminColors.textTertiary,
        ),
      ),
    );
  }
}
