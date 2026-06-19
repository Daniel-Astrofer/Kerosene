import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_screen_background.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(alertPreferencesProvider);
    final notifier = ref.read(alertPreferencesProvider.notifier);

    return KeroseneScreenBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildHeader(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context.tr.notificationChannels),
                  _buildSwitchItem(
                    context,
                    context.tr.pushNotifications,
                    context.tr.pushNotificationsDesc,
                    preferences.backgroundAlertsEnabled,
                    notifier.setBackgroundAlertsEnabled,
                    KeroseneIcons.notifications,
                  ),
                  _buildSwitchItem(
                    context,
                    context.tr.settingsUiInAppBannersTitle,
                    context.tr.settingsUiInAppBannersOnSubtitle,
                    preferences.inAppBannersEnabled,
                    notifier.setInAppBannersEnabled,
                    KeroseneIcons.info,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(context.tr.notificationAlerts),
                  _buildSwitchItem(
                    context,
                    context.tr.transactionUpdates,
                    context.tr.transactionUpdatesDesc,
                    preferences.transactionAlertsEnabled,
                    notifier.setTransactionAlertsEnabled,
                    KeroseneIcons.history,
                  ),
                  _buildSwitchItem(
                    context,
                    context.tr.securityAlertsTitle,
                    context.tr.securityAlertsDesc,
                    preferences.securityAlertsEnabled,
                    notifier.setSecurityAlertsEnabled,
                    KeroseneIcons.security,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: KeroseneBrandTokens.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: const Icon(
              KeroseneIcons.back,
              color: KeroseneBrandTokens.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.tr.notifications,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: KeroseneBrandTokens.textPrimary,
                letterSpacing: -0.1,
              ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: KeroseneBrandTokens.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: KeroseneBrandTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: KeroseneBrandTokens.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: KeroseneBrandTokens.brand,
            activeTrackColor: KeroseneBrandTokens.brand.withValues(alpha: 0.2),
            inactiveThumbColor:
                KeroseneBrandTokens.textPrimary.withValues(alpha: 0.2),
            inactiveTrackColor:
                KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }
}
