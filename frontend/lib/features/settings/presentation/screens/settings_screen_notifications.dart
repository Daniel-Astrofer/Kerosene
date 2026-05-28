part of 'settings_screen.dart';

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection();

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertPreferencesProvider);
    final notificationCount = ref.watch(sessionNotificationUnreadCountProvider);
    final alertsEnabled = alerts.backgroundAlertsEnabled;

    return _Card(
      children: [
        _SwitchTile(
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: context.tr.settingsUiTransactionSecurityAlertsTitle,
          subtitle: alertsEnabled
              ? context.tr.settingsUiBackgroundAlertsOnSubtitle
              : context.tr.settingsUiBackgroundAlertsOffSubtitle,
          value: alertsEnabled,
          accentColor: const Color(0xFFA78BFA),
          onChanged: _isSaving ? (_) {} : _handleBackgroundAlertsToggle,
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: context.tr.settingsUiInAppBannersTitle,
          subtitle: alerts.inAppBannersEnabled
              ? context.tr.settingsUiInAppBannersOnSubtitle
              : context.tr.settingsUiInAppBannersOffSubtitle,
          value: alerts.inAppBannersEnabled,
          accentColor: const Color(0xFF60A5FA),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setInAppBannersEnabled(value),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.swap_vert_rounded,
          iconColor: const Color(0xFF7DD3A0),
          title: context.tr.settingsUiFinancialEventsTitle,
          subtitle: alerts.transactionAlertsEnabled
              ? context.tr.settingsUiFinancialEventsOnSubtitle
              : context.tr.settingsUiFinancialEventsOffSubtitle,
          value: alerts.transactionAlertsEnabled,
          accentColor: const Color(0xFF7DD3A0),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setTransactionAlertsEnabled(value),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.gpp_maybe_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: context.tr.settingsUiSecurityEventsTitle,
          subtitle: alerts.securityAlertsEnabled
              ? context.tr.settingsUiSecurityEventsOnSubtitle
              : context.tr.settingsUiSecurityEventsOffSubtitle,
          value: alerts.securityAlertsEnabled,
          accentColor: const Color(0xFFF59E0B),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setSecurityAlertsEnabled(value),
        ),
        _Divider(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isSaving ? Icons.sync_rounded : Icons.info_outline_rounded,
                  color: monoTextColor,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isSaving
                        ? context.tr.settingsUiUpdatingBackgroundAlerts
                        : context.tr.settingsUiBackgroundAlertsInfo(
                            notificationCount,
                          ),
                    style: AppTypography.bodySmall.copyWith(
                      color: monoMutedTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBackgroundAlertsToggle(bool enabled) async {
    if (_isSaving) {
      return;
    }

    if (enabled) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _BackgroundAlertsConsentSheet(),
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() => _isSaving = true);
      final permissionsGranted =
          await NotificationService().requestPermissions();
      if (!mounted) {
        return;
      }
      if (!permissionsGranted) {
        setState(() => _isSaving = false);
        AppNotice.showWarning(
          context,
          title: context.tr.settingsUiPermissionRequiredTitle,
          message: context.tr.settingsUiPermissionRequiredMessage,
        );
        return;
      }
    } else {
      setState(() => _isSaving = true);
    }

    try {
      await ref
          .read(alertPreferencesProvider.notifier)
          .setBackgroundAlertsEnabled(enabled);
      if (enabled) {
        await startBackgroundService();
      } else {
        await stopBackgroundService();
      }

      if (!mounted) {
        return;
      }

      AppNotice.showInfo(
        context,
        title: enabled
            ? context.tr.settingsUiMonitoringActiveTitle
            : context.tr.settingsUiMonitoringInactiveTitle,
        message: enabled
            ? context.tr.settingsUiMonitoringActiveMessage
            : context.tr.settingsUiMonitoringInactiveMessage,
      );
    } catch (_) {
      if (mounted) {
        AppNotice.showError(
          context,
          title: context.tr.settingsUiAlertsUpdateFailedTitle,
          message: context.tr.settingsUiAlertsUpdateFailedMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// ─── Session Section ──────────────────────────────────────────────────────────
