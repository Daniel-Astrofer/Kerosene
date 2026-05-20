import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/utils/device_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/providers/alert_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/monochrome_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/biometric_provider.dart';
import '../../../../core/providers/appearance_provider.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../auth/controller/auth_providers.dart';
import '../../../profile/presentation/screens/security_settings_screen.dart';
import '../../../notifications/presentation/providers/session_notification_provider.dart';
import '../../../security/presentation/screens/sovereignty_status_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../security/domain/entities/admin_access.dart';
import '../../../wallet/presentation/providers/balance_settings_provider.dart';

part 'settings_screen_header.dart';
part 'settings_screen_preferences.dart';
part 'settings_screen_security.dart';
part 'settings_screen_notifications.dart';
part 'settings_screen_session.dart';
part 'settings_screen_components.dart';

// ─── Screen Entry ─────────────────────────────────────────────────────────────

final backupCodesProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.read(authRepositoryProvider).getBackupCodes();
  return result.fold((_) => const <String>[], (codes) => codes);
});

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const SettingsScreen({super.key, this.showPrimaryNavigation = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _sectionsController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _sectionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _sectionsController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appearanceProvider);
    final responsive = context.responsive;
    final bottomSectionPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : 80.0;

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientSideGlowBackdrop.authenticated()),
          SafeArea(
            child: Column(
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _SettingsHeader(
                      onBack: widget.showPrimaryNavigation
                          ? () => AppPrimaryNavigationBar.backOrHome(context)
                          : () => Navigator.maybePop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _sectionsController,
                      curve: Curves.easeOut,
                    ),
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                        vertical: AppSpacing.sm,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: responsive.mobileContentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                const _SettingsOverviewCard(),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.shield_outlined,
                                  label: context
                                      .l10n.settingsUiSecurityAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _SecuritySection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: context
                                      .l10n.settingsUiEnterpriseAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _EnterpriseAccessSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.privacy_tip_outlined,
                                  label: context.tr.settingsUiPrivacySection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _PrivacySection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.manage_accounts_outlined,
                                  label: context
                                      .l10n.settingsUiAccountAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _CredentialsSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.notifications_outlined,
                                  label: context
                                      .l10n.settingsUiNotificationsSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _NotificationsSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.palette_outlined,
                                  label: context
                                      .l10n.settingsUiAppearanceSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _AppearanceSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.language_rounded,
                                  label: context
                                      .l10n.settingsUiLocaleCurrencySection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _LocaleSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.power_settings_new_rounded,
                                  label: context.tr.settingsUiSessionSection
                                      .toUpperCase(),
                                  color: Colors.white54,
                                  child: const _SessionSection(),
                                ),
                                SizedBox(height: bottomSectionPadding),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showPrimaryNavigation)
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.settings,
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: icon, label: label, color: color),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
