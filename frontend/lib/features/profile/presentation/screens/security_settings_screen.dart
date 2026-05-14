import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/tor_loading_dots.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/providers/biometric_provider.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/controller/auth_providers.dart';
import 'package:teste/features/security/domain/entities/app_pin_status.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/domain/entities/passkey_inventory.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final _totpCodeController = TextEditingController();

  String _setupUri = '';
  String _setupSecret = '';
  List<String> _latestGeneratedCodes = const [];
  bool _busy = false;

  @override
  void dispose() {
    _totpCodeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _refreshSecurityProviders() {
    ref.invalidate(securityStatusProvider);
    ref.invalidate(backupCodesStatusProvider);
    ref.invalidate(accountSecurityProfileProvider);
    ref.invalidate(appPinStatusProvider);
  }

  Future<void> _beginTotpSetup() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.setupTotp();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: context.l10n.securityTotpFailureTitle,
            message: ErrorTranslator.translate(
              context.l10n,
              failure.toString(),
            ),
          );
        },
        (setup) {
          setState(() {
            _setupUri = setup.otpUri;
            _setupSecret = setup.secret;
            _totpCodeController.clear();
          });
        },
      );
    });
  }

  Future<void> _verifyTotpSetup() async {
    if (_totpCodeController.text.trim().length != 6) {
      AppNotice.showError(
        context,
        title: context.l10n.securityInvalidCodeTitle,
        message: context.l10n.securityTotpCodeRequiredMessage,
      );
      return;
    }

    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyTotpSetup(
        totpCode: _totpCodeController.text.trim(),
      );
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: context.l10n.securityTotpFailureTitle,
            message: ErrorTranslator.translate(
              context.l10n,
              failure.toString(),
            ),
          );
        },
        (status) {
          setState(() {
            _setupUri = '';
            _setupSecret = '';
            _latestGeneratedCodes = status.newlyGeneratedCodes;
          });
          _refreshSecurityProviders();
          AppNotice.showSuccess(
            context,
            title: context.l10n.securityTotpEnabledTitle,
            message: context.l10n.securityTotpEnabledMessage,
          );
          if (status.newlyGeneratedCodes.isNotEmpty) {
            _showBackupCodesSheet(status.newlyGeneratedCodes);
          }
        },
      );
    });
  }

  Future<void> _disableTotp() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.disableTotp();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: context.l10n.securityTotpDisableFailedTitle,
            message: ErrorTranslator.translate(
              context.l10n,
              failure.toString(),
            ),
          );
        },
        (_) {
          setState(() {
            _setupUri = '';
            _setupSecret = '';
            _latestGeneratedCodes = const [];
          });
          _refreshSecurityProviders();
          AppNotice.showSuccess(
            context,
            title: context.l10n.securityTotpDisabledTitle,
            message: context.l10n.securityTotpDisabledMessage,
          );
        },
      );
    });
  }

  Future<void> _regenerateBackupCodes() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.regenerateBackupCodes();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: context.l10n.securityBackupRegenerateFailedTitle,
            message: ErrorTranslator.translate(
              context.l10n,
              failure.toString(),
            ),
          );
        },
        (status) {
          setState(() {
            _latestGeneratedCodes = status.newlyGeneratedCodes;
          });
          _refreshSecurityProviders();
          if (status.newlyGeneratedCodes.isNotEmpty) {
            _showBackupCodesSheet(status.newlyGeneratedCodes);
          }
        },
      );
    });
  }

  Future<void> _showAppPinSheet({
    required AppPinStatus status,
    required _AppPinSheetMode mode,
  }) async {
    final refreshed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppPinManagementSheet(
        initialStatus: status,
        mode: mode,
      ),
    );

    if (refreshed == true) {
      _refreshSecurityProviders();
    }
  }

  void _showBackupCodesSheet(List<String> codes) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: monochromePanelDecoration(
              color: monoSurfaceColor,
              borderColor: monoBorderStrongColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 1,
                  width: 52,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  color: monoBorderStrongColor,
                ),
                Text(
                  context.l10n.securityBackupCodesTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: monoMutedTextColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.securityBackupCodesBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: monoMutedTextColor,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: codes
                      .map(
                        (code) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: monochromePanelDecoration(
                            color: monoSurfaceAltColor,
                            borderColor: monoBorderStrongColor,
                            showShadow: false,
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: monoTextColor,
                              fontFamily: 'JetBrainsMono',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _registerPasskey() async {
    await _run(() async {
      await ref.read(authControllerProvider.notifier).registerPasskey();
      final authState = ref.read(authControllerProvider);
      if (!mounted) {
        return;
      }

      if (authState is AuthError) {
        AppNotice.showError(
          context,
          title: context.l10n.securityRegisterDeviceFailedTitle,
          message: ErrorTranslator.translate(
            context.l10n,
            authState.toString(),
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
        return;
      }

      _refreshSecurityProviders();
      AppNotice.showSuccess(
        context,
        title: context.l10n.securityDeviceRegisteredTitle,
        message: context.l10n.securityDeviceRegisteredMessage,
      );
    });
  }

  String _authenticatedDevicesSubtitle(
    dynamic security,
    AccountSecurityProfile? profile,
  ) {
    final inventory = profile?.passkeys;
    if (inventory == null || !inventory.passkeyRegistered) {
      return security.passkeyRegistered
          ? context.l10n.securityDeviceInventoryLoadingSubtitle
          : context.l10n.securityRegisterDeviceSubtitle;
    }

    if (inventory.compatibleForCurrentLogin) {
      final compatibleCount = inventory.devices
          .where((device) => device.compatibleWithCurrentLogin)
          .length;
      return compatibleCount == 1
          ? context.l10n.securityCompatibleDeviceOne
          : context.l10n.securityCompatibleDeviceMany(compatibleCount);
    }

    if (inventory.legacyCredentialsPresent) {
      return context.l10n.securityLegacyDeviceSubtitle;
    }

    return context.l10n.securityNoCompatibleDeviceSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final bioState = ref.watch(biometricProvider);
    final securityAsync = ref.watch(securityStatusProvider);
    final backupCodesAsync = ref.watch(backupCodesStatusProvider);
    final securityProfileAsync = ref.watch(accountSecurityProfileProvider);

    return CyberBackground.authenticated(
      useScroll: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: monoSurfaceAltColor,
                    foregroundColor: monoTextColor,
                    minimumSize: const Size(42, 42),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    side: const BorderSide(color: monoBorderStrongColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.securityScreenTitle,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: monoTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.securityScreenSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: monoMutedTextColor,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            securityAsync.when(
              data: (security) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (security.unprotected)
                    _BannerCard(
                      color: Colors.white54,
                      icon: Icons.warning_amber_rounded,
                      title: context.l10n.securityUnprotectedTitle,
                      body: security.warningMessage.isNotEmpty
                          ? security.warningMessage
                          : context.l10n.securityUnprotectedFallback,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _StatusCard(
                    security: security,
                    biometricEnabled: bioState.isEnabled,
                    appPinEnabled: securityProfileAsync.maybeWhen(
                      data: (profile) => profile.appPin.enabled,
                      orElse: () => false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  securityProfileAsync.when(
                    data: (profile) => _AppPinSectionCard(
                      status: profile.appPin,
                      onEnable: () => _showAppPinSheet(
                        status: profile.appPin,
                        mode: _AppPinSheetMode.enable,
                      ),
                      onChange: () => _showAppPinSheet(
                        status: profile.appPin,
                        mode: _AppPinSheetMode.change,
                      ),
                      onDisable: () => _showAppPinSheet(
                        status: profile.appPin,
                        mode: _AppPinSheetMode.disable,
                      ),
                    ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _ErrorCard(
                      title: context.l10n.securityPinEntryTitle,
                      body: context.l10n.securityPinLoadError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: context.l10n.securityAuthenticatedDevicesTitle,
                    subtitle: securityProfileAsync.maybeWhen(
                      data: (profile) =>
                          _authenticatedDevicesSubtitle(security, profile),
                      orElse: () => security.passkeyRegistered
                          ? context.l10n.securityRegisteredDeviceSubtitle
                          : context.l10n.securityRegisterThisDeviceSubtitle,
                    ),
                    actionLabel: security.passkeyRegistered
                        ? context.l10n.securityLinkNewDeviceAction.toUpperCase()
                        : context.l10n.securityRegisterDeviceAction
                            .toUpperCase(),
                    onAction: _registerPasskey,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  securityProfileAsync.when(
                    data: (profile) => _PasskeyInventoryCard(
                      inventory: profile.passkeys,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _ErrorCard(
                      title: context.l10n.securityAuthenticatedDevicesTitle,
                      body: context.l10n.securityDeviceCompatibilityError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_setupUri.isNotEmpty) ...[
                    _TotpSetupCard(
                      setupUri: _setupUri,
                      setupSecret: _setupSecret,
                      controller: _totpCodeController,
                      busy: _busy,
                      onVerify: _verifyTotpSetup,
                    ),
                  ] else
                    _SectionCard(
                      title: context.l10n.securityTotpOptionalTitle,
                      subtitle: security.totpEnabled
                          ? context.l10n.securityTotpEnabledSubtitle
                          : context.l10n.securityTotpDisabledSubtitle,
                      actionLabel: security.totpEnabled
                          ? context.l10n.securityDisableTotpAction.toUpperCase()
                          : context.l10n.securityEnableTotpAction.toUpperCase(),
                      destructive: security.totpEnabled,
                      onAction:
                          security.totpEnabled ? _disableTotp : _beginTotpSetup,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  backupCodesAsync.when(
                    data: (backupStatus) => _SectionCard(
                      title: context.l10n.securityBackupCodesTitle,
                      subtitle: security.totpEnabled
                          ? context.l10n.securityBackupCodesRemaining(
                              backupStatus.remainingCodes,
                            )
                          : context.l10n.securityBackupCodesLockedSubtitle,
                      actionLabel: security.totpEnabled
                          ? context.l10n.securityRegenerateCodesAction
                              .toUpperCase()
                          : context.l10n.securityWaitingTotpAction
                              .toUpperCase(),
                      disabled: !security.totpEnabled,
                      onAction:
                          security.totpEnabled ? _regenerateBackupCodes : null,
                      trailing: _latestGeneratedCodes.isNotEmpty
                          ? TextButton(
                              onPressed: () =>
                                  _showBackupCodesSheet(_latestGeneratedCodes),
                              style: monochromeTextButtonStyle(),
                              child: Text(
                                context.l10n.securityViewLatestAction
                                    .toUpperCase(),
                              ),
                            )
                          : null,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _ErrorCard(
                      title: context.l10n.securityBackupCodesTitle,
                      body: context.l10n.securityBackupCodesLoadError,
                    ),
                  ),
                ],
              ),
              loading: () => const _LoadingCard(),
              error: (_, __) => _ErrorCard(
                title: context.l10n.securityScreenTitle,
                body: context.l10n.securityStatusLoadError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _BannerCard({
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

class _StatusCard extends StatelessWidget {
  final dynamic security;
  final bool biometricEnabled;
  final bool appPinEnabled;

  const _StatusCard({
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
            context.l10n.securityCurrentStatusTitle,
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
              _StatusPill(
                context.l10n.securityStrongPasswordPill,
                security.passwordConfigured,
              ),
              _StatusPill(
                context.l10n.securityDevicePill,
                security.passkeyRegistered,
              ),
              _StatusPill('TOTP', security.totpEnabled),
              _StatusPill(
                context.l10n.securityInboundPill,
                security.inboundEnabled,
              ),
              _StatusPill(context.l10n.securityAppPinPill, appPinEnabled),
              _StatusPill(
                context.l10n.securityLocalBiometricsPill,
                biometricEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool enabled;

  const _StatusPill(this.label, this.enabled);

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

class _PasskeyInventoryCard extends StatelessWidget {
  final PasskeyInventory? inventory;

  const _PasskeyInventoryCard({required this.inventory});

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
            context.l10n.securityAuthenticatedDevicesTitle,
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
                Icon(Icons.devices_rounded, color: summaryColor),
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
                  _InventoryContextChip(
                    label: context.l10n.securityCurrentHostLabel,
                    value: inventory.currentHost,
                  ),
                if (inventory.currentRelyingPartyId.isNotEmpty)
                  _InventoryContextChip(
                    label: context.l10n.securityCurrentRpLabel,
                    value: inventory.currentRelyingPartyId,
                  ),
              ],
            ),
          ],
          if (inventory?.legacyCredentialsPresent == true) ...[
            const SizedBox(height: AppSpacing.md),
            _BannerCard(
              color: Colors.white54,
              icon: Icons.history_toggle_off_rounded,
              title: context.l10n.securityLegacyCredentialsTitle,
              body: context.l10n.securityLegacyCredentialsBody,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (inventory == null || !inventory.passkeyRegistered)
            Text(
              context.l10n.securityNoAuthenticatedDevice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            )
          else if (inventory.devices.isEmpty)
            Text(
              context.l10n.securityDeviceDetailsUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            )
          else
            Column(
              children: inventory.devices
                  .map((device) => _PasskeyDeviceRow(device: device))
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
      return context.l10n.securityInventoryNotLoaded;
    }
    if (!inventory.passkeyRegistered) {
      return context.l10n.securityInventoryNone;
    }
    if (inventory.compatibleForCurrentLogin) {
      return context.l10n.securityInventoryCompatible;
    }
    if (inventory.legacyCredentialsPresent) {
      return context.l10n.securityInventoryLegacy;
    }
    return context.l10n.securityInventoryIncompatible;
  }

  static String _summaryBanner(
    BuildContext context,
    PasskeyInventory? inventory,
  ) {
    if (inventory == null) {
      return context.l10n.securityInventoryUnknownBanner;
    }
    if (!inventory.passkeyRegistered) {
      return context.l10n.securityInventoryRegisterBanner;
    }
    if (inventory.compatibleForCurrentLogin) {
      final compatibleCount = inventory.devices
          .where((device) => device.compatibleWithCurrentLogin)
          .length;
      return compatibleCount > 0
          ? context.l10n.securityInventoryCompatibleCount(compatibleCount)
          : context.l10n.securityInventoryCompatibleFallback;
    }
    if (inventory.legacyCredentialsPresent) {
      return context.l10n.securityInventoryLegacyBanner;
    }
    return context.l10n.securityInventoryIncompatibleBanner;
  }
}

class _AppPinSectionCard extends StatelessWidget {
  final AppPinStatus status;
  final VoidCallback onEnable;
  final VoidCallback onChange;
  final VoidCallback onDisable;

  const _AppPinSectionCard({
    required this.status,
    required this.onEnable,
    required this.onChange,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = status.enabled
        ? status.locked
            ? context.l10n.securityPinActiveLockedSubtitle
            : context.l10n.securityPinActiveAttemptsSubtitle(
                status.remainingAttempts,
              )
        : context.l10n.securityPinDisabledSubtitle;

    return _SectionCard(
      title: context.l10n.securityPinEntryTitle,
      subtitle: subtitle,
      actionLabel: status.enabled
          ? context.l10n.securityChangePinAction.toUpperCase()
          : context.l10n.securityEnablePinAction.toUpperCase(),
      onAction: status.enabled ? onChange : onEnable,
      trailing: status.enabled
          ? TextButton(
              onPressed: onDisable,
              style: monochromeTextButtonStyle(),
              child: Text(context.l10n.securityDisableAction.toUpperCase()),
            )
          : null,
    );
  }
}

enum _AppPinSheetMode { enable, change, disable }

class _AppPinManagementSheet extends ConsumerStatefulWidget {
  final AppPinStatus initialStatus;
  final _AppPinSheetMode mode;

  const _AppPinManagementSheet({
    required this.initialStatus,
    required this.mode,
  });

  @override
  ConsumerState<_AppPinManagementSheet> createState() =>
      _AppPinManagementSheetState();
}

class _AppPinManagementSheetState
    extends ConsumerState<_AppPinManagementSheet> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _totpController = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _requiresNewPin => widget.mode != _AppPinSheetMode.disable;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_requiresNewPin &&
        _newPinController.text.trim() != _confirmPinController.text.trim()) {
      setState(
        () => _error = context.l10n.securityPinMismatchError,
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref.read(securityRepositoryProvider).configureAppPin(
          enabled: widget.mode != _AppPinSheetMode.disable,
          pin: _requiresNewPin ? _newPinController.text.trim() : null,
          currentPin: _currentPinController.text.trim().isNotEmpty
              ? _currentPinController.text.trim()
              : null,
          totpCode: _totpController.text.trim().isNotEmpty
              ? _totpController.text.trim()
              : null,
        );

    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _error = ErrorTranslator.translate(context.l10n, failure.message);
        });
      },
      (_) {
        ref.invalidate(accountSecurityProfileProvider);
        ref.invalidate(appPinStatusProvider);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      _AppPinSheetMode.enable => context.l10n.securityPinEnableTitle,
      _AppPinSheetMode.change => context.l10n.securityPinChangeTitle,
      _AppPinSheetMode.disable => context.l10n.securityPinDisableTitle,
    };

    final body = switch (widget.mode) {
      _AppPinSheetMode.enable => context.l10n.securityPinEnableBody,
      _AppPinSheetMode.change => context.l10n.securityPinChangeBody,
      _AppPinSheetMode.disable => context.l10n.securityPinDisableBody,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: monochromePanelDecoration(
          color: monoSurfaceColor,
          borderColor: monoBorderStrongColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 1,
              width: 52,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              color: monoBorderStrongColor,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: monoTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.initialStatus.enabled) ...[
              TextField(
                controller: _currentPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.l10n.securityCurrentPinLabel,
                  counterText: '',
                ),
              ),
              if (widget.initialStatus.resettableWithTotp)
                TextField(
                  controller: _totpController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  style: const TextStyle(color: monoTextColor),
                  decoration: monochromeInputDecoration(
                    label: context.l10n.securityTotpCodeLabel,
                    counterText: '',
                  ),
                ),
            ],
            if (_requiresNewPin) ...[
              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.l10n.securityNewPinLabel(
                    widget.initialStatus.minPinLength,
                    widget.initialStatus.maxPinLength,
                  ),
                  counterText: '',
                ),
              ),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.l10n.securityConfirmNewPinLabel,
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: monoMutedTextColor,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: monochromeFilledButtonStyle(
                emphasis: widget.mode != _AppPinSheetMode.disable,
                destructive: widget.mode == _AppPinSheetMode.disable,
              ),
              child: _busy
                  ? SizedBox(
                      height: 18,
                      child: TorLoadingDots(
                        dotSize: 6,
                        spacing: 8,
                        travel: 10,
                        color: widget.mode == _AppPinSheetMode.disable
                            ? monoTextColor
                            : Colors.black,
                      ),
                    )
                  : Text(
                      widget.mode == _AppPinSheetMode.disable
                          ? context.l10n.securityDisablePinAction.toUpperCase()
                          : context.l10n.securitySavePinAction.toUpperCase(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryContextChip extends StatelessWidget {
  final String label;
  final String value;

  const _InventoryContextChip({
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
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasskeyDeviceRow extends StatelessWidget {
  final PasskeyDevice device;

  const _PasskeyDeviceRow({required this.device});

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
              _PasskeyStatusBadge(status: device.compatibilityStatus),
            ],
          ),
          const SizedBox(height: 10),
          if (device.brand.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceBrandLabel,
              value: device.brand,
            ),
          if (device.model.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceModelLabel,
              value: device.model,
            ),
          if (device.serialNumber.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceSerialLabel,
              value: device.serialNumber,
            )
          else if (device.deviceInstallId.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceInstallIdLabel,
              value: device.deviceInstallId,
            ),
          if (device.browser.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceBrowserLabel,
              value: device.browser,
            ),
          if (device.platform.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceSystemLabel,
              value: device.platform,
            ),
          _DeviceMetaLine(
            label: context.l10n.securityDeviceStatusLabel,
            value: _statusLabel(context, device.status),
          ),
          if (device.firstAccessAt != null)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceFirstAccessLabel,
              value: _dateLabel(device.firstAccessAt!),
            ),
          if (device.lastAccessAt != null)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceLastAccessLabel,
              value: _dateLabel(device.lastAccessAt!),
            ),
          if (device.originHost.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceOriginLabel,
              value: device.originHost,
            ),
          if (device.relyingPartyId.isNotEmpty)
            _DeviceMetaLine(
              label: context.l10n.securityDeviceRelyingPartyLabel,
              value: device.relyingPartyId,
            ),
          const SizedBox(height: 8),
          Text(
            device.compatibleWithCurrentLogin
                ? context.l10n.securityDeviceCanUse
                : _compatibilityHint(context, device.compatibilityStatus),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: device.compatibleWithCurrentLogin
                      ? monoTextColor
                      : monoMutedTextColor,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  static String _compatibilityHint(
    BuildContext context,
    PasskeyCompatibilityStatus status,
  ) {
    switch (status) {
      case PasskeyCompatibilityStatus.compatible:
        return context.l10n.securityDeviceCanUse;
      case PasskeyCompatibilityStatus.incompatible:
        return context.l10n.securityDeviceCannotUse;
      case PasskeyCompatibilityStatus.unknown:
        return context.l10n.securityDeviceUnknownUse;
    }
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return context.l10n.securityStatusPending;
      case 'BLOCKED':
        return context.l10n.securityStatusBlocked;
      case 'REVOKED':
        return context.l10n.securityStatusRevoked;
      default:
        return context.l10n.securityStatusActive;
    }
  }

  static String _dateLabel(DateTime value) {
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _DeviceMetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _DeviceMetaLine({
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
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasskeyStatusBadge extends StatelessWidget {
  final PasskeyCompatibilityStatus status;

  const _PasskeyStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PasskeyCompatibilityStatus.compatible => (
          context.l10n.securityCompatibleBadge.toUpperCase(),
          monoTextColor,
        ),
      PasskeyCompatibilityStatus.incompatible => (
          context.l10n.securityIncompatibleBadge.toUpperCase(),
          monoFaintTextColor,
        ),
      PasskeyCompatibilityStatus.unknown => (
          context.l10n.securityUnknownBadge.toUpperCase(),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool destructive;
  final bool disabled;
  final Widget? trailing;

  const _SectionCard({
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

class _TotpSetupCard extends StatelessWidget {
  final String setupUri;
  final String setupSecret;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onVerify;

  const _TotpSetupCard({
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
            context.l10n.securityTotpSetupTitle,
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
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.l10n.securityTotpCodeLabel,
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
                : Text(context.l10n.securityValidateTotpAction.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: const Center(
        child: TorLoadingDots(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String body;

  const _ErrorCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      color: Colors.white24,
      icon: Icons.error_outline_rounded,
      title: title,
      body: body,
    );
  }
}
