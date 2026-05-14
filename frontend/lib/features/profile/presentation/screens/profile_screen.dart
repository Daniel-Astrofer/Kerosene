import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/alert_preferences_provider.dart';
import 'package:teste/core/providers/biometric_provider.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';

import '../../../security/presentation/screens/sovereignty_status_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import 'personal_data_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final biometricState = ref.watch(biometricProvider);
    final alertPreferences = ref.watch(alertPreferencesProvider);

    final username = authState is AuthAuthenticated
        ? authState.user.name.trim()
        : context.l10n.profileFallbackUser;
    final displayName = username.isEmpty
        ? context.l10n.profileFallbackUser
        : username;
    final handle = '@${displayName.toLowerCase().replaceAll(' ', '')}';
    final isAuthenticated = authState is AuthAuthenticated;
    final responsive = context.responsive;

    final walletCount = walletState is WalletLoaded
        ? walletState.wallets.length
        : 0;
    final securityLabel =
        walletState is WalletLoaded && walletState.selectedWallet != null
        ? _formatAccountSecurityLabel(
            context,
            walletState.selectedWallet!.accountSecurity,
          )
        : context.l10n.profileNoWallet;

    final walletLabel = switch (walletCount) {
      0 => context.l10n.profileNoWallets,
      1 => context.l10n.profileOneActiveWallet,
      _ => context.l10n.profileActiveWallets(walletCount),
    };

    final biometricLabel = biometricState.isLoading
        ? context.l10n.profileBiometricsChecking
        : biometricState.isSupported
        ? (biometricState.isEnabled
              ? context.l10n.profileBiometricsEnabled
              : context.l10n.profileBiometricsDisabled)
        : context.l10n.profileBiometricsUnavailable;

    final routingLabel = alertPreferences.backgroundAlertsEnabled
        ? (alertPreferences.inAppBannersEnabled
              ? context.l10n.profileAlertsMonitoringActive
              : context.l10n.profileMonitoringNoBanners)
        : context.l10n.profileRealtimeAlertsDisabled;

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: ColoredBox(
        color: authenticatedSurfaceBackgroundColor,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              responsive.isTinyPhone ? 16 : 20,
              responsive.horizontalPadding,
              120,
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.profileAccessHeader
                                      .toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.buttonText.copyWith(
                                    fontSize: 12,
                                    letterSpacing: 0,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.profileAccessSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HeaderButton(
                            icon: Icons.settings_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _ProfilePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: responsive.isTinyPhone ? 48 : 56,
                                  height: responsive.isTinyPhone ? 48 : 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      displayName.characters.first
                                          .toUpperCase(),
                                      style: AppTypography.h3.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontSize: responsive.isTinyPhone
                                            ? 18
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.h1.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          fontSize: responsive.compactFontSize(
                                            tiny: 26,
                                            compact: 30,
                                            regular: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _StatusBadge(
                                            label: handle,
                                            color: AppColors.success,
                                          ),
                                          _StatusBadge(
                                            label: isAuthenticated
                                                ? context
                                                      .l10n
                                                      .profileAuthenticated
                                                : context
                                                      .l10n
                                                      .profileAwaitingAuthentication,
                                            color: isAuthenticated
                                                ? AppColors.success
                                                : const Color(0xFFF2C94C),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              context.l10n.profileIntro,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: context.l10n.profilePostureTitle,
                        subtitle: context.l10n.profilePostureSubtitle,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _PosturePill(
                            label: AppCopy.profileWallets.resolve(context),
                            value: walletLabel,
                            accent: Theme.of(context).colorScheme.secondary,
                          ),
                          _PosturePill(
                            label: AppCopy.profileProtection.resolve(context),
                            value: securityLabel,
                            accent: AppColors.success,
                          ),
                          _PosturePill(
                            label: AppCopy.profileBiometrics.resolve(context),
                            value: biometricLabel,
                            accent: const Color(0xFFF2C94C),
                          ),
                          _PosturePill(
                            label: AppCopy.profilePrivacy.resolve(context),
                            value: routingLabel,
                            accent: const Color(0xFF7AA2F7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle(
                        title: context.l10n.profilePrioritiesTitle,
                        subtitle: context.l10n.profilePrioritiesSubtitle,
                      ),
                      const SizedBox(height: 12),
                      _ProfilePanel(
                        child: Column(
                          children: [
                            _ProfileActionTile(
                              icon: Icons.shield_outlined,
                              iconColor: AppColors.success,
                              title: context.l10n.security,
                              subtitle: context.l10n.profileSecuritySubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const _PanelDivider(),
                            _ProfileActionTile(
                              icon: Icons.verified_user_outlined,
                              iconColor: const Color(0xFF7AA2F7),
                              title: context.l10n.profileSovereigntyReportTitle,
                              subtitle:
                                  context.l10n.profileSovereigntyReportSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SovereigntyStatusScreen(),
                                  ),
                                );
                              },
                            ),
                            const _PanelDivider(),
                            _ProfileActionTile(
                              icon: Icons.settings_outlined,
                              iconColor: Colors.white70,
                              title: context.l10n.settingsTitle,
                              subtitle: context.l10n.profileSettingsSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: context.l10n.profileAccountSupportTitle,
                        subtitle: context.l10n.profileAccountSupportSubtitle,
                      ),
                      const SizedBox(height: 12),
                      _ProfilePanel(
                        child: Column(
                          children: [
                            _ProfileActionTile(
                              icon: Icons.person_outline_rounded,
                              iconColor: Colors.white70,
                              title: context.l10n.personalData,
                              subtitle:
                                  context.l10n.profilePersonalDataSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PersonalDataScreen(),
                                  ),
                                );
                              },
                            ),
                            const _PanelDivider(),
                            _ProfileActionTile(
                              icon: Icons.notifications_none_rounded,
                              iconColor: const Color(0xFFA78BFA),
                              title: context.l10n.notifications,
                              subtitle:
                                  context.l10n.profileNotificationsSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const _PanelDivider(),
                            _ProfileActionTile(
                              icon: Icons.help_outline_rounded,
                              iconColor: Colors.white70,
                              title: context.l10n.helpSupport,
                              subtitle: context.l10n.profileSupportSubtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SupportScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ProfilePanel(
                        borderColor: AppColors.error.withValues(alpha: 0.20),
                        child: _ProfileActionTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.error,
                          title: context.l10n.logout,
                          subtitle: context.l10n.profileLogoutSubtitle,
                          titleColor: AppColors.error,
                          trailingColor: AppColors.error.withValues(
                            alpha: 0.65,
                          ),
                          onTap: () {
                            ref.read(authControllerProvider.notifier).logout();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/welcome',
                              (route) => false,
                            );
                          },
                        ),
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
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _ProfilePanel({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTinyPhone ? AppSpacing.sm : 12,
        vertical: responsive.isTinyPhone ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(color: AppColors.white70),
        ),
      ],
    );
  }
}

class _PosturePill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PosturePill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: responsive.isTinyPhone ? responsive.clampWidth(320) : 160,
      padding: EdgeInsets.all(responsive.isTinyPhone ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? trailingColor;

  const _ProfileActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTinyPhone ? 14 : 18,
            vertical: responsive.isTinyPhone ? 14 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: responsive.isTinyPhone ? 38 : 42,
                height: responsive.isTinyPhone ? 38 : 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            titleColor ??
                            Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: trailingColor ?? Colors.white.withValues(alpha: 0.30),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 18,
      endIndent: 18,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

String _formatAccountSecurityLabel(BuildContext context, String rawValue) {
  switch (rawValue.toUpperCase()) {
    case 'SHAMIR':
    case 'SHAMIR_SLIP39':
    case 'SLIP39':
      return context.l10n.profileSecurityShamir;
    case 'MULTISIG':
    case 'MULTISIG_VAULT':
    case '2FA_MULTISIG':
      return context.l10n.profileSecurityMultisig;
    case 'STANDARD':
    default:
      return context.l10n.profileSecurityStandard;
  }
}
