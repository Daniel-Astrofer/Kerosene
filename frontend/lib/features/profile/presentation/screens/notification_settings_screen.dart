import 'package:flutter/material.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Mock state for alerts
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _transactionAlerts = true;
  bool _marketingUpdates = false;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return CyberBackground.authenticated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  _buildSectionHeader(
                      context.l10n.notificationChannels.toUpperCase()),
                  _buildSwitchItem(
                    context,
                    context.l10n.pushNotifications,
                    context.l10n.pushNotificationsDesc,
                    _pushEnabled,
                    (val) => setState(() => _pushEnabled = val),
                    Icons.notifications_active_rounded,
                  ),
                  _buildSwitchItem(
                    context,
                    context.l10n.emailNotifications,
                    context.l10n.emailNotificationsDesc,
                    _emailEnabled,
                    (val) => setState(() => _emailEnabled = val),
                    Icons.email_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(
                      context.l10n.notificationAlerts.toUpperCase()),
                  _buildSwitchItem(
                    context,
                    context.l10n.transactionUpdates,
                    context.l10n.transactionUpdatesDesc,
                    _transactionAlerts,
                    (val) => setState(() => _transactionAlerts = val),
                    Icons.swap_horiz_rounded,
                  ),
                  _buildSwitchItem(
                    context,
                    context.l10n.securityAlertsTitle,
                    context.l10n.securityAlertsDesc,
                    _securityAlerts,
                    (val) => setState(() => _securityAlerts = val),
                    Icons.security_rounded,
                  ),
                  _buildSwitchItem(
                    context,
                    context.l10n.marketingNews,
                    context.l10n.marketingNewsDesc,
                    _marketingUpdates,
                    (val) => setState(() => _marketingUpdates = val),
                    Icons.campaign_rounded,
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
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
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
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.l10n.notifications.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(letterSpacing: 2),
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
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.7),
                size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            inactiveThumbColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            inactiveTrackColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }
}
