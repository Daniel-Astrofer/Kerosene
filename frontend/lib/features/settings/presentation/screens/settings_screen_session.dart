part of 'settings_screen.dart';

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

// ─── Reusable Primitives ──────────────────────────────────────────────────────
