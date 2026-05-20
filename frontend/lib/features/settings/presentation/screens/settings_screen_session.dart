part of 'settings_screen.dart';

class _SessionSection extends ConsumerWidget {
  const _SessionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      children: [
        _ActionTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          title: context.tr.settingsUiLogoutTitle,
          subtitle: context.tr.settingsUiLogoutSubtitle,
          trailing: Icons.chevron_right_rounded,
          titleColor: AppColors.error,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _DangerDialog(
        title: context.tr.settingsUiLogoutDialogTitle,
        message: context.tr.settingsUiLogoutDialogMessage,
        confirmLabel: context.tr.settingsUiLogoutTitle,
        onConfirm: () async {
          Navigator.pop(context);
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (_) => false);
          }
        },
      ),
    );
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────

class _AuthenticatedDevicesSheet extends StatelessWidget {
  final WidgetRef ref;
  const _AuthenticatedDevicesSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: context.tr.securityAuthenticatedDevicesTitle,
      icon: Icons.devices_rounded,
      iconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          Text(
            context.tr.settingsUiAuthenticatedDevicesBody,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.tr.settingsUiRegisterNewDeviceAction,
            icon: Icons.add_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).registerPasskey();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: context.tr.settingsUiLearnMoreAction,
            icon: Icons.info_outline_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BackgroundAlertsConsentSheet extends StatelessWidget {
  const _BackgroundAlertsConsentSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: context.tr.settingsUiBackgroundAlertsTitle,
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFFA78BFA),
      child: Column(
        children: [
          Text(
            context.tr.settingsUiBackgroundAlertsConsentBody,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.tr.settingsUiEnableMonitoringAction,
            icon: Icons.check_rounded,
            color: const Color(0xFFA78BFA),
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: context.tr.cancel,
            icon: Icons.close_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _InfoSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: title,
      icon: icon,
      iconColor: iconColor,
      child: Column(
        children: [
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.tr.settingsUiUnderstoodAction,
            icon: Icons.check_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Bottom Sheet Container ───────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BottomSheetContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderTone = Color.lerp(monoBorderStrongColor, iconColor, 0.08) ??
        monoBorderStrongColor;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 1, color: monoBorderStrongColor),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 56,
            height: 56,
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: borderTone,
              showShadow: false,
            ),
            child: Icon(icon, color: monoTextColor, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3.copyWith(color: monoTextColor)),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

// ─── Danger Dialog ────────────────────────────────────────────────────────────

class _ConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool requireConfirmation;
  final bool confirmed;
  final ValueChanged<bool>? onConfirmationChanged;
  final VoidCallback? onConfirm;

  const _ConfirmationDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    this.requireConfirmation = false,
    this.confirmed = false,
    this.onConfirmationChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: monoSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: monoTextColor, size: 30),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: monoTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (requireConfirmation) ...[
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) =>
                    onConfirmationChanged?.call(value == true),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Entendo que esta chave autoriza acesso ao painel admin.',
                  style: AppTypography.bodySmall.copyWith(color: monoTextColor),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: monochromeOutlinedButtonStyle(),
                    child: Text(cancelLabel.toUpperCase()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: destructive
                        ? monochromeOutlinedButtonStyle()
                        : monochromeFilledButtonStyle(),
                    child: Text(confirmLabel.toUpperCase()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _DangerDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: monoSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: monochromePanelDecoration(
                color: monoSurfaceAltColor,
                borderColor: monoBorderStrongColor,
                showShadow: false,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: monoTextColor,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: monoTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: monochromePanelDecoration(
                        color: monoSurfaceAltColor,
                        borderColor: monoBorderStrongColor,
                        showShadow: false,
                      ),
                      child: Text(
                        'Cancelar',
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: monoMutedTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: monochromePanelDecoration(
                        color: monoTextColor,
                        borderColor: monoBorderStrongColor,
                        showShadow: false,
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Primitives ──────────────────────────────────────────────────────
