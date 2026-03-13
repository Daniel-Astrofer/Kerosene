import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF101018)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context)!.notifications,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("CHANNELS"),
                      _buildSwitchItem(
                        context,
                        "Push Notifications",
                        "Receive alerts on your device",
                        _pushEnabled,
                        (val) => setState(() => _pushEnabled = val),
                        Icons.notifications_active_rounded,
                      ),
                      _buildSwitchItem(
                        context,
                        "Email Notifications",
                        "Receive updates via email",
                        _emailEnabled,
                        (val) => setState(() => _emailEnabled = val),
                        Icons.email_rounded,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader("ALERTS"),

                      _buildSwitchItem(
                        context,
                        "Transaction Updates",
                        "Incoming and outgoing transactions",
                        _transactionAlerts,
                        (val) => setState(() => _transactionAlerts = val),
                        Icons.swap_horiz_rounded,
                      ),
                      _buildSwitchItem(
                        context,
                        "Security Alerts",
                        "Login attempts and password changes",
                        _securityAlerts,
                        (val) => setState(() => _securityAlerts = val),
                        Icons.security_rounded,
                      ),
                      _buildSwitchItem(
                        context,
                        "Marketing & News",
                        "Stay updated with latest features",
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
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
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
      child: GlassContainer(
        blur: 10,
        opacity: 0.05,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF00D4FF),
              activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
