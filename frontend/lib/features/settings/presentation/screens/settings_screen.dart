import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/l10n/l10n_extension.dart';
import '../../../../core/providers/alert_preferences_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/monochrome_theme.dart';
import '../../../../core/providers/appearance_provider.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../auth/controller/auth_providers.dart';
import '../../../bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import '../../../profile/presentation/screens/notification_settings_screen.dart';
import '../../../profile/presentation/screens/security_settings_screen.dart';
import '../../../notifications/presentation/providers/session_notification_provider.dart';

part 'settings_screen_header.dart';
part 'settings_screen_preferences.dart';
part 'settings_screen_security.dart';
part 'settings_screen_notifications.dart';
part 'settings_screen_session.dart';
part 'settings_screen_components.dart';

// ─── Screen Entry ─────────────────────────────────────────────────────────────

class _SettingsDesignColors {
  static const background = Color(0xFF050505);
  static const surfaceContainer = Color(0xFF201F1F);
  static const surfaceContainerHighest = Color(0xFF353434);
  static const borderMuted = Color(0xFF2A2A2A);
  static const outlineVariant = Color(0xFF444748);
  static const onSurfaceVariant = Color(0xFFC4C7C8);
  static const primary = Color(0xFFFFFFFF);
}

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

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(appearanceProvider);
    final responsive = context.responsive;
    final bottomSectionPadding = MediaQuery.viewPaddingOf(context).bottom + 32;
    final contentMaxWidth = responsive.isCompact ? 480.0 : 768.0;

    return Scaffold(
      backgroundColor: _SettingsDesignColors.background,
      body: Column(
        children: [
          _SettingsHeader(onBack: _handleClose),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                0,
                responsive.horizontalPadding,
                bottomSectionPadding,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Configurações',
                          style: GoogleFonts.ebGaramond(
                            color: _SettingsDesignColors.primary,
                            fontSize: responsive.compactFontSize(
                              tiny: 42,
                              compact: 48,
                              regular: 48,
                            ),
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie sua conta, segurança e dispositivos',
                          style: GoogleFonts.inter(
                            color: _SettingsDesignColors.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SettingsOverviewCard(onQrTap: _showAccountQrSheet),
                        const SizedBox(height: 24),
                        _SettingsNavigationList(
                          items: [
                            _SettingsNavigationItem(
                              icon: Icons.manage_accounts_rounded,
                              title: 'Conta',
                              subtitle: 'Dados da sessão e perfil',
                              onTap: _showAccountSheet,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.shield_outlined,
                              title: 'Segurança',
                              subtitle: 'Proteção da conta e transações',
                              onTap: _openSecuritySettings,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.devices_rounded,
                              title: 'Passkeys e dispositivos',
                              subtitle: 'Gerencie acessos confiáveis',
                              onTap: _showAuthenticatedDevicesSheet,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.phonelink_lock_rounded,
                              title: 'Autenticador TOTP',
                              subtitle: 'Verificação em duas etapas',
                              onTap: _openSecuritySettings,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.dialpad_rounded,
                              title: 'PIN do app',
                              subtitle: 'Proteção local',
                              onTap: _openSecuritySettings,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.settings_backup_restore_rounded,
                              title: 'Backup e recuperação',
                              subtitle: 'Códigos de emergência',
                              onTap: _openSecuritySettings,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.notifications_rounded,
                              title: 'Notificações',
                              subtitle: 'Alertas e dispositivos',
                              onTap: _openNotificationSettings,
                            ),
                            _SettingsNavigationItem(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Carteiras',
                              subtitle: 'Gerencie carteiras da conta',
                              onTap: _openWallets,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      HapticFeedback.selectionClick();
      navigator.pop();
      return;
    }

    final routeName = ModalRoute.of(context)?.settings.name;
    if (widget.showPrimaryNavigation && routeName == '/settings') {
      AppPrimaryNavigationBar.backOrHome(context);
      return;
    }

    HapticFeedback.selectionClick();
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openSecuritySettings() {
    _openScreen(const SecuritySettingsScreen());
  }

  void _openNotificationSettings() {
    _openScreen(const NotificationSettingsScreen());
  }

  void _openWallets() {
    _openScreen(const BitcoinAccountsScreen());
  }

  void _showAuthenticatedDevicesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuthenticatedDevicesSheet(ref: ref),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AccountDetailsSheet(),
    );
  }

  void _showAccountQrSheet() {
    final authState = ref.read(authControllerProvider);
    final username =
        authState is AuthAuthenticated ? authState.user.username : 'lucas_01';
    final handle = _formatAccountHandle(username);

    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.qr_code_rounded,
        iconColor: Colors.white54,
        title: handle,
        message: 'Identificador público da conta para acesso e recuperação.',
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
