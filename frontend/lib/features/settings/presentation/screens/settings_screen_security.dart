part of 'settings_screen.dart';

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioState = ref.watch(biometricProvider);
    final securityAsync = ref.watch(securityStatusProvider);
    final securitySubtitle = securityAsync.when(
      data: (security) => security.unprotected
          ? context.tr.settingsUiSecurityUnprotectedSubtitle
          : context.tr.settingsUiSecurityProtectedSubtitle,
      loading: () => context.tr.settingsUiSecurityLoadingSubtitle,
      error: (_, __) => context.tr.settingsUiSecurityErrorSubtitle,
    );
    final passkeySubtitle = securityAsync.when(
      data: (security) => security.passkeyRegistered
          ? context.tr.settingsUiPasskeyRegisteredSubtitle
          : context.tr.settingsUiPasskeyRegisterSubtitle,
      loading: () => context.tr.settingsUiPasskeyLoadingSubtitle,
      error: (_, __) => context.tr.settingsUiPasskeyErrorSubtitle,
    );
    final showUnprotectedBanner = securityAsync.maybeWhen(
      data: (security) => security.unprotected,
      orElse: () => false,
    );

    return _Card(
      children: [
        if (showUnprotectedBanner) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.settingsUiUnprotectedBannerTitle.toUpperCase(),
                  style: const TextStyle(
                    color: monoTextColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr.settingsUiUnprotectedBannerBody,
                  style: const TextStyle(
                    color: monoMutedTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _Divider(),
        ],
        if (bioState.isSupported)
          _SwitchTile(
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: context.tr.settingsUiBiometricUnlockTitle,
            subtitle: context.tr.settingsUiBiometricUnlockSubtitle,
            value: bioState.isEnabled,
            accentColor: const Color(0xFFF59E0B),
            onChanged: (v) {
              HapticFeedback.mediumImpact();
              ref.read(biometricProvider.notifier).toggleBiometric(v);
            },
          ),
        if (bioState.isSupported) _Divider(),
        _ActionTile(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF7AA2F7),
          title: context.tr.settingsUiSecurityCenterTitle,
          subtitle: securitySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
          ),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: context.tr.securityAuthenticatedDevicesTitle,
          subtitle: passkeySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showAuthenticatedDevicesSheet(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.devices_rounded,
          iconColor: Colors.white38,
          title: context.tr.settingsUiSessionsActiveTitle,
          subtitle: context.tr.settingsUiSessionsActiveSubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showSessionInfoSheet(context),
        ),
      ],
    );
  }

  void _showAuthenticatedDevicesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuthenticatedDevicesSheet(ref: ref),
    );
  }

  void _showSessionInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.devices_rounded,
        iconColor: Colors.white38,
        title: context.tr.settingsUiSessionsActiveTitle,
        message: context.tr.settingsUiSessionsActiveMessage,
      ),
    );
  }
}

class _EnterpriseAccessSection extends ConsumerWidget {
  const _EnterpriseAccessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyStatus = ref.watch(adminKeyStatusProvider);
    final pendingAttempts = ref.watch(pendingAdminAccessAttemptsProvider);

    return _Card(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.settingsUiEnterpriseIntro,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              keyStatus.when(
                data: (status) => _AdminKeyStatusSummary(status: status),
                loading: () => Text(
                  context.tr.settingsUiEnterpriseKeyLoading,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
                error: (_, __) => Text(
                  context.tr.settingsUiEnterpriseKeyLoadError,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.vpn_key_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: context.tr.settingsUiEnterpriseCreateKeyTitle,
          subtitle: context.tr.settingsUiEnterpriseCreateKeySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _confirmCreateKey(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.rotate_right_rounded,
          iconColor: Colors.white54,
          title: context.tr.settingsUiEnterpriseRotateKeyTitle,
          subtitle: context.tr.settingsUiEnterpriseRotateKeySubtitle,
          trailing: Icons.refresh_rounded,
          onTap: () => _confirmCreateKey(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.block_rounded,
          iconColor: Colors.white38,
          title: context.tr.settingsUiEnterpriseRevokeKeyTitle,
          subtitle: context.tr.settingsUiEnterpriseRevokeKeySubtitle,
          trailing: Icons.delete_outline_rounded,
          onTap: () => _revokeKey(context, ref),
        ),
        pendingAttempts.when(
          data: (attempts) => attempts.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    _Divider(),
                    ...attempts.map(
                      (attempt) => _AdminAccessAttemptTile(
                        attempt: attempt,
                        onApprove: () =>
                            _decideAttempt(context, ref, attempt, true),
                        onBlock: () =>
                            _decideAttempt(context, ref, attempt, false),
                      ),
                    ),
                  ],
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _confirmCreateKey(BuildContext context, WidgetRef ref) async {
    var confirmed = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => _ConfirmationDialog(
            icon: Icons.admin_panel_settings_outlined,
            title: context.tr.settingsUiEnterpriseCreateKeyTitle,
            message: context.tr.settingsUiEnterpriseCreateDialogMessage,
            confirmLabel: context.tr.settingsUiEnterpriseCreateKeyAction,
            cancelLabel: context.tr.cancel,
            requireConfirmation: true,
            confirmed: confirmed,
            onConfirmationChanged: (value) => setState(() => confirmed = value),
            onConfirm:
                confirmed ? () => Navigator.pop(dialogContext, true) : null,
          ),
        );
      },
    );

    if (accepted != true || !context.mounted) {
      return;
    }

    final key = _generateAdminKey();
    final keyHash = crypto.sha256.convert(utf8.encode(key)).toString();
    final metadata = await DeviceHelper.getDeviceMetadata();
    final result = await ref.read(securityRepositoryProvider).createAdminKey(
          keyMaterialHash: keyHash,
          deviceInstallId: metadata.deviceInstallId,
        );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.tr.settingsUiEnterpriseCreateKeyFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(adminKeyStatusProvider);
        _showCreatedKey(context, key);
      },
    );
  }

  Future<void> _revokeKey(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmationDialog(
        icon: Icons.block_rounded,
        title: context.tr.settingsUiEnterpriseRevokeKeyTitle,
        message: context.tr.settingsUiEnterpriseRevokeDialogMessage,
        confirmLabel: context.tr.settingsUiEnterpriseRevokeAction,
        cancelLabel: context.tr.cancel,
        destructive: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (accepted != true) {
      return;
    }

    final result = await ref.read(securityRepositoryProvider).revokeAdminKey();
    if (!context.mounted) {
      return;
    }
    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.tr.settingsUiEnterpriseRevokeFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(adminKeyStatusProvider);
        AppNotice.showSuccess(
          context,
          title: context.tr.settingsUiEnterpriseKeyRevokedTitle,
          message: context.tr.settingsUiEnterpriseKeyRevokedMessage,
        );
      },
    );
  }

  Future<void> _decideAttempt(
    BuildContext context,
    WidgetRef ref,
    AdminAccessAttempt attempt,
    bool approve,
  ) async {
    final result = await ref
        .read(securityRepositoryProvider)
        .decideAdminAttempt(attemptId: attempt.attemptId, approve: approve);
    if (!context.mounted) {
      return;
    }
    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.tr.settingsUiEnterpriseDecisionFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(pendingAdminAccessAttemptsProvider);
        AppNotice.showSuccess(
          context,
          title: approve
              ? context.tr.settingsUiEnterpriseAccessAllowedTitle
              : context.tr.settingsUiEnterpriseDeviceBlockedTitle,
          message: approve
              ? context.tr.settingsUiEnterpriseAccessAllowedMessage
              : context.tr.settingsUiEnterpriseDeviceBlockedMessage,
        );
      },
    );
  }

  void _showCreatedKey(BuildContext context, String key) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: monoSurfaceColor,
        title: Text(
          context.tr.settingsUiEnterpriseKeyCreatedTitle,
          style: const TextStyle(color: monoTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.settingsUiEnterpriseKeyCreatedMessage,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              key,
              style: const TextStyle(
                color: monoTextColor,
                fontFamily: 'IBM Plex Mono',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr.settingsUiCloseAction.toUpperCase()),
          ),
        ],
      ),
    );
  }

  String _generateAdminKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return 'krs-admin-${base64Url.encode(bytes).replaceAll('=', '')}';
  }
}

class _AdminKeyStatusSummary extends StatelessWidget {
  final AdminKeyStatus status;

  const _AdminKeyStatusSummary({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          status.configured ? Icons.check_circle_outline : Icons.info_outline,
          color: status.configured ? Colors.white70 : Colors.white38,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            status.configured
                ? context.tr.settingsUiEnterpriseKeyActive
                : context.tr.settingsUiEnterpriseKeyMissing,
            style: AppTypography.bodySmall.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

class _AdminAccessAttemptTile extends StatelessWidget {
  final AdminAccessAttempt attempt;
  final VoidCallback onApprove;
  final VoidCallback onBlock;

  const _AdminAccessAttemptTile({
    required this.attempt,
    required this.onApprove,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.settingsUiEnterpriseAttemptTitle,
            style: AppTypography.bodyMedium.copyWith(color: monoTextColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (attempt.browser.isNotEmpty)
                '${context.tr.settingsUiBrowserLabel}: ${attempt.browser}',
              if (attempt.deviceName.isNotEmpty)
                '${context.tr.settingsUiDeviceLabel}: ${attempt.deviceName}',
              if (attempt.requestedAt != null)
                '${context.tr.settingsUiTimeLabel}: ${_formatDate(attempt.requestedAt!)}',
            ].join('\n'),
            style: AppTypography.bodySmall.copyWith(
              color: monoMutedTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: monochromeFilledButtonStyle(),
                  child: Text(context.tr.settingsUiAllowAction.toUpperCase()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onBlock,
                  style: monochromeOutlinedButtonStyle(),
                  child: Text(context.tr.settingsUiBlockAction.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

// ─── Credentials Section ──────────────────────────────────────────────────────

class _CredentialsSection extends ConsumerWidget {
  const _CredentialsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final username = authState is AuthAuthenticated ? authState.user.name : '—';

    return _Card(
      children: [
        // Current user info
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: monochromePanelDecoration(
                  color: monoSurfaceAltColor,
                  borderColor: monoBorderStrongColor,
                  showShadow: false,
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.tr.settingsUiAuthenticatedLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: monoMutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _Divider(),

        // Danger zone: delete account
        _ActionTile(
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.error,
          title: context.tr.settingsUiDeleteAccountTitle,
          subtitle: context.tr.settingsUiDeleteAccountSubtitle,
          trailing: Icons.chevron_right_rounded,
          titleColor: AppColors.error,
          onTap: () => _showDeleteConfirmDialog(context, ref),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _DangerDialog(
        title: context.tr.settingsUiDeleteAccountDialogTitle,
        message: context.tr.settingsUiDeleteAccountDialogMessage,
        confirmLabel: context.tr.settingsUiDeleteForeverAction,
        onConfirm: () {
          Navigator.pop(context);
          // Logout and inform user — actual deletion depends on backend support
          ref.read(authControllerProvider.notifier).logout();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/welcome', (_) => false);
        },
      ),
    );
  }
}

// ─── Notifications Section ────────────────────────────────────────────────────
