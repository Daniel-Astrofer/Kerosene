// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/domain/entities/passkey_inventory.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/design_system/icons.dart';

export 'security_app_pin_sheet.dart';

class SecurityBannerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const SecurityBannerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final borderTone =
        Color.lerp(monoBorderStrongColor, color, 0.08) ?? monoBorderStrongColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: borderTone,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: monoTextColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: monoTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: monoMutedTextColor,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityStatusCard extends StatelessWidget {
  final dynamic security;
  final bool biometricEnabled;
  final bool appPinEnabled;

  const SecurityStatusCard({
    required this.security,
    required this.biometricEnabled,
    required this.appPinEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.securityCurrentStatusTitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SecurityStatusPill(
                context.tr.securityStrongPasswordPill,
                security.passwordConfigured,
              ),
              SecurityStatusPill(
                context.tr.securityDevicePill,
                security.passkeyRegistered,
              ),
              SecurityStatusPill('TOTP', security.totpEnabled),
              SecurityStatusPill(
                context.tr.securityInboundPill,
                security.inboundEnabled,
              ),
              SecurityStatusPill(context.tr.securityAppPinPill, appPinEnabled),
              SecurityStatusPill(
                context.tr.securityLocalBiometricsPill,
                biometricEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SecurityStatusPill extends StatelessWidget {
  final String label;
  final bool enabled;

  const SecurityStatusPill(this.label, this.enabled);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? monoTextColor : monoFaintTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: monochromePanelDecoration(
        color: enabled ? monoSurfaceAltColor : monoSurfaceColor,
        borderColor: enabled ? monoBorderStrongColor : monoBorderColor,
        showShadow: false,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class PasskeyInventoryCard extends StatelessWidget {
  final PasskeyInventory? inventory;

  const PasskeyInventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final inventory = this.inventory;
    final summaryColor = _summaryColor(inventory);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr.securityAuthenticatedDevicesTitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _summaryText(context, inventory),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoMutedTextColor,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: summaryColor,
              showShadow: false,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(KeroseneIcons.devices, color: summaryColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _summaryBanner(context, inventory),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: monoTextColor,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (inventory != null &&
              (inventory.currentHost.isNotEmpty ||
                  inventory.currentRelyingPartyId.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inventory.currentHost.isNotEmpty)
                  InventoryContextChip(
                    label: context.tr.securityCurrentHostLabel,
                    value: inventory.currentHost,
                  ),
                if (inventory.currentRelyingPartyId.isNotEmpty)
                  InventoryContextChip(
                    label: context.tr.securityCurrentRpLabel,
                    value: inventory.currentRelyingPartyId,
                  ),
              ],
            ),
          ],
          if (inventory?.legacyCredentialsPresent == true) ...[
            const SizedBox(height: AppSpacing.md),
            SecurityBannerCard(
              color: Colors.white54,
              icon: KeroseneIcons.historyOff,
              title: context.tr.securityLegacyCredentialsTitle,
              body: context.tr.securityLegacyCredentialsBody,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (inventory == null || !inventory.passkeyRegistered)
            Text(
              context.tr.securityNoAuthenticatedDevice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            )
          else if (inventory.devices.isEmpty)
            Text(
              context.tr.securityDeviceDetailsUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            )
          else
            Column(
              children: inventory.devices
                  .map((device) => PasskeyDeviceRow(device: device))
                  .toList(),
            ),
        ],
      ),
    );
  }

  static Color _summaryColor(PasskeyInventory? inventory) {
    if (inventory == null || !inventory.passkeyRegistered) {
      return Colors.white24;
    }
    if (inventory.compatibleForCurrentLogin) {
      return Colors.white70;
    }
    if (inventory.legacyCredentialsPresent) {
      return Colors.white54;
    }
    return Colors.white24;
  }

  static String _summaryText(
      BuildContext context, PasskeyInventory? inventory) {
    if (inventory == null) {
      return context.tr.securityInventoryNotLoaded;
    }
    if (!inventory.passkeyRegistered) {
      return context.tr.securityInventoryNone;
    }
    if (inventory.compatibleForCurrentLogin) {
      return context.tr.securityInventoryCompatible;
    }
    if (inventory.legacyCredentialsPresent) {
      return context.tr.securityInventoryLegacy;
    }
    return context.tr.securityInventoryIncompatible;
  }

  static String _summaryBanner(
    BuildContext context,
    PasskeyInventory? inventory,
  ) {
    if (inventory == null) {
      return context.tr.securityInventoryUnknownBanner;
    }
    if (!inventory.passkeyRegistered) {
      return context.tr.securityInventoryRegisterBanner;
    }
    if (inventory.compatibleForCurrentLogin) {
      final compatibleCount = inventory.devices
          .where((device) => device.compatibleWithCurrentLogin)
          .length;
      return compatibleCount > 0
          ? context.tr.securityInventoryCompatibleCount(compatibleCount)
          : context.tr.securityInventoryCompatibleFallback;
    }
    if (inventory.legacyCredentialsPresent) {
      return context.tr.securityInventoryLegacyBanner;
    }
    return context.tr.securityInventoryIncompatibleBanner;
  }
}

class AppPinSectionCard extends StatelessWidget {
  final AppPinStatus status;
  final VoidCallback onEnable;
  final VoidCallback onChange;
  final VoidCallback onDisable;

  const AppPinSectionCard({
    required this.status,
    required this.onEnable,
    required this.onChange,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = status.enabled
        ? status.locked
            ? context.tr.securityPinActiveLockedSubtitle
            : context.tr.securityPinActiveAttemptsSubtitle(
                status.remainingAttempts,
              )
        : context.tr.securityPinDisabledSubtitle;

    return SecuritySectionCard(
      title: context.tr.securityPinEntryTitle,
      subtitle: subtitle,
      actionLabel: status.enabled
          ? context.tr.securityChangePinAction.toUpperCase()
          : context.tr.securityEnablePinAction.toUpperCase(),
      onAction: status.enabled ? onChange : onEnable,
      trailing: status.enabled
          ? TextButton(
              onPressed: onDisable,
              style: monochromeTextButtonStyle(),
              child: Text(context.tr.securityDisableAction.toUpperCase()),
            )
          : null,
    );
  }
}

class InventoryContextChip extends StatelessWidget {
  final String label;
  final String value;

  const InventoryContextChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderStrongColor,
        showShadow: false,
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(
                color: monoMutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: monoTextColor,
                fontFamily: AppTypography.financialFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasskeyDeviceRow extends ConsumerStatefulWidget {
  final PasskeyDevice device;

  const PasskeyDeviceRow({required this.device});

  @override
  ConsumerState<PasskeyDeviceRow> createState() => PasskeyDeviceRowState();
}

class PasskeyDeviceRowState extends ConsumerState<PasskeyDeviceRow> {
  bool _busy = false;

  PasskeyDevice get device => widget.device;

  bool get _canBlock {
    final status = device.status.toUpperCase();
    return device.deviceInstallId.trim().isNotEmpty &&
        status != 'BLOCKED' &&
        status != 'REVOKED';
  }

  bool get _canRevoke {
    final status = device.status.toUpperCase();
    return device.deviceInstallId.trim().isNotEmpty && status != 'REVOKED';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderStrongColor,
        showShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  device.deviceName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: monoTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PasskeyStatusBadge(status: device.compatibilityStatus),
            ],
          ),
          const SizedBox(height: 10),
          if (device.brand.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceBrandLabel,
              value: device.brand,
            ),
          if (device.model.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceModelLabel,
              value: device.model,
            ),
          if (device.serialNumber.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceSerialLabel,
              value: device.serialNumber,
            )
          else if (device.deviceInstallId.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceInstallIdLabel,
              value: device.deviceInstallId,
            ),
          if (device.browser.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceBrowserLabel,
              value: device.browser,
            ),
          if (device.platform.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceSystemLabel,
              value: device.platform,
            ),
          DeviceMetaLine(
            label: context.tr.securityDeviceStatusLabel,
            value: _statusLabel(context, device.status),
          ),
          if (device.firstAccessAt != null)
            DeviceMetaLine(
              label: context.tr.securityDeviceFirstAccessLabel,
              value: _dateLabel(device.firstAccessAt!),
            ),
          if (device.lastAccessAt != null)
            DeviceMetaLine(
              label: context.tr.securityDeviceLastAccessLabel,
              value: _dateLabel(device.lastAccessAt!),
            ),
          if (device.originHost.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceOriginLabel,
              value: device.originHost,
            ),
          if (device.relyingPartyId.isNotEmpty)
            DeviceMetaLine(
              label: context.tr.securityDeviceRelyingPartyLabel,
              value: device.relyingPartyId,
            ),
          const SizedBox(height: 8),
          Text(
            device.compatibleWithCurrentLogin
                ? context.tr.securityDeviceCanUse
                : _compatibilityHint(context, device.compatibilityStatus),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: device.compatibleWithCurrentLogin
                      ? monoTextColor
                      : monoMutedTextColor,
                  height: 1.4,
                ),
          ),
          if (_canBlock || _canRevoke) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_busy)
                  const SizedBox(
                    width: 42,
                    height: 28,
                    child: Center(
                      child: TorLoadingDots(
                        dotSize: 4,
                        spacing: 5,
                        travel: 7,
                        color: monoMutedTextColor,
                      ),
                    ),
                  ),
                if (_canBlock)
                  OutlinedButton.icon(
                    style: monochromeOutlinedButtonStyle(minHeight: 40),
                    onPressed: _busy
                        ? null
                        : () => _updateDeviceStatus(
                              revoke: false,
                            ),
                    icon: const Icon(KeroseneIcons.blocked, size: 16),
                    label: Text(
                      context.tr.securityDeviceBlockAction.toUpperCase(),
                    ),
                  ),
                if (_canRevoke)
                  OutlinedButton.icon(
                    style: monochromeOutlinedButtonStyle(minHeight: 40),
                    onPressed: _busy
                        ? null
                        : () => _updateDeviceStatus(
                              revoke: true,
                            ),
                    icon: const Icon(KeroseneIcons.linkOff, size: 16),
                    label: Text(
                      context.tr.securityDeviceRevokeAction.toUpperCase(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateDeviceStatus({required bool revoke}) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final repository = ref.read(securityRepositoryProvider);
      final result = revoke
          ? await repository.revokePasskeyDevice(device.deviceInstallId)
          : await repository.blockPasskeyDevice(device.deviceInstallId);

      if (!mounted) return;

      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: revoke
                ? context.tr.securityDeviceRevokeFailedTitle
                : context.tr.securityDeviceBlockFailedTitle,
            message: ErrorTranslator.translate(context.tr, failure.message),
          );
        },
        (_) {
          ref.invalidate(accountSecurityProfileProvider);
          ref.invalidate(securityStatusProvider);
          AppNotice.showSuccess(
            context,
            title: revoke
                ? context.tr.securityDeviceRevokedTitle
                : context.tr.securityDeviceBlockedTitle,
            message: revoke
                ? context.tr.securityDeviceRevokedMessage
                : context.tr.securityDeviceBlockedMessage,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  static String _compatibilityHint(
    BuildContext context,
    PasskeyCompatibilityStatus status,
  ) {
    switch (status) {
      case PasskeyCompatibilityStatus.compatible:
        return context.tr.securityDeviceCanUse;
      case PasskeyCompatibilityStatus.incompatible:
        return context.tr.securityDeviceCannotUse;
      case PasskeyCompatibilityStatus.unknown:
        return context.tr.securityDeviceUnknownUse;
    }
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return context.tr.securityStatusPending;
      case 'BLOCKED':
        return context.tr.securityStatusBlocked;
      case 'REVOKED':
        return context.tr.securityStatusRevoked;
      default:
        return context.tr.securityStatusActive;
    }
  }

  static String _dateLabel(DateTime value) {
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class DeviceMetaLine extends StatelessWidget {
  final String label;
  final String value;

  const DeviceMetaLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: monoMutedTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: monoTextColor,
                fontFamily: AppTypography.financialFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasskeyStatusBadge extends StatelessWidget {
  final PasskeyCompatibilityStatus status;

  const PasskeyStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PasskeyCompatibilityStatus.compatible => (
          context.tr.securityCompatibleBadge.toUpperCase(),
          monoTextColor,
        ),
      PasskeyCompatibilityStatus.incompatible => (
          context.tr.securityIncompatibleBadge.toUpperCase(),
          monoFaintTextColor,
        ),
      PasskeyCompatibilityStatus.unknown => (
          context.tr.securityUnknownBadge.toUpperCase(),
          monoMutedTextColor,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: color,
        showShadow: false,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class SecuritySectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool destructive;
  final bool disabled;
  final Widget? trailing;

  const SecuritySectionCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.destructive = false,
    this.disabled = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoMutedTextColor,
                  height: 1.45,
                ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: monochromeFilledButtonStyle(
              emphasis: !disabled && !destructive,
              destructive: destructive,
            ),
            onPressed: disabled ? null : onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class TotpSetupCard extends StatelessWidget {
  final String setupUri;
  final String setupSecret;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onVerify;

  const TotpSetupCard({
    required this.setupUri,
    required this.setupSecret,
    required this.controller,
    required this.busy,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr.securityTotpSetupTitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: monoBorderStrongColor),
              ),
              child: QrImageView(
                data: setupUri,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            setupSecret,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: monoTextColor,
                  fontFamily: AppTypography.financialFontFamily,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.tr.securityTotpCodeLabel,
              hintText: '000000',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: busy ? null : onVerify,
            style: monochromeFilledButtonStyle(),
            child: busy
                ? const SizedBox(
                    height: 18,
                    child: TorLoadingDots(
                      dotSize: 6,
                      spacing: 8,
                      travel: 10,
                      color: Colors.black,
                    ),
                  )
                : Text(context.tr.securityValidateTotpAction.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class SecurityLoadingCard extends StatelessWidget {
  const SecurityLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Row(
        children: [
          const Icon(
            KeroseneIcons.security,
            color: monoMutedTextColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr.securityScreenTitle,
              style: AppTypography.bodyMedium.copyWith(
                color: monoMutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityErrorCard extends StatelessWidget {
  final String title;
  final String body;

  const SecurityErrorCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SecurityBannerCard(
      color: Colors.white24,
      icon: KeroseneIcons.error,
      title: title,
      body: body,
    );
  }
}
