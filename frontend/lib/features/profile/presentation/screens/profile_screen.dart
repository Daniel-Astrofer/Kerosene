import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/alert_preferences_provider.dart';
import 'package:teste/core/providers/biometric_provider.dart';
import 'package:teste/core/theme/app_colors.dart';
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

    final username =
        authState is AuthAuthenticated ? authState.user.name.trim() : 'Usuario';
    final displayName = username.isEmpty ? 'Usuario' : username;
    final handle = '@${displayName.toLowerCase().replaceAll(' ', '')}';
    final isAuthenticated = authState is AuthAuthenticated;

    final walletCount =
        walletState is WalletLoaded ? walletState.wallets.length : 0;
    final securityLabel =
        walletState is WalletLoaded && walletState.selectedWallet != null
            ? _formatAccountSecurityLabel(
                walletState.selectedWallet!.accountSecurity,
              )
            : 'Sem carteira';

    final walletLabel = switch (walletCount) {
      0 => 'Nenhuma carteira',
      1 => '1 carteira ativa',
      _ => '$walletCount carteiras ativas',
    };

    final biometricLabel = biometricState.isLoading
        ? 'Verificando'
        : biometricState.isSupported
            ? (biometricState.isEnabled
                ? 'Biometria ativa'
                : 'Biometria desativada')
            : 'Biometria indisponível';

    final routingLabel = alertPreferences.backgroundAlertsEnabled
        ? 'Monitoramento em segundo plano'
        : 'Alertas locais desativados';

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: ColoredBox(
        color: authenticatedSurfaceBackgroundColor,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
            physics: const BouncingScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERFIL E ACESSO',
                          style: AppTypography.buttonText.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.8,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Identidade, postura de segurança e controle de sessão.',
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              displayName.characters.first.toUpperCase(),
                              style: AppTypography.h3.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppTypography.h1.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
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
                                        ? 'Conta autenticada'
                                        : 'Aguardando autenticação',
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
                      'Esta área concentra o estado atual de acesso, proteção da conta e superfícies críticas de suporte.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Postura atual',
                subtitle:
                    'Sinais operacionais visíveis sem métricas decorativas.',
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
                title: 'Prioridades',
                subtitle: 'Acesso, soberania e ajustes de confiança.',
              ),
              const SizedBox(height: 12),
              _ProfilePanel(
                child: Column(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.success,
                      title: context.l10n.security,
                      subtitle:
                          'Revise biometria, recuperação, passkey e práticas de acesso.',
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
                      title: 'Relatório de soberania',
                      subtitle:
                          'Abra o painel operacional de hardware, consenso e integridade.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SovereigntyStatusScreen(),
                          ),
                        );
                      },
                    ),
                    const _PanelDivider(),
                    _ProfileActionTile(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.white70,
                      title: context.l10n.settingsTitle,
                      subtitle:
                          'Consolide privacidade, idioma, aparência e política de sessão.',
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
                title: 'Conta e suporte',
                subtitle: 'Dados pessoais, notificações e ajuda operacional.',
              ),
              const SizedBox(height: 12),
              _ProfilePanel(
                child: Column(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.white70,
                      title: context.l10n.personalData,
                      subtitle: 'Revise nome, dados e informações da conta.',
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
                          'Controle alertas de transação e segurança em segundo plano.',
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
                      subtitle:
                          'Abra os canais de suporte para dúvidas ou incidentes.',
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
                  subtitle:
                      'Encerra a sessão atual e exige nova autenticação completa.',
                  titleColor: AppColors.error,
                  trailingColor: AppColors.error.withValues(alpha: 0.65),
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
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
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

  const _ProfilePanel({
    required this.child,
    this.borderColor,
  });

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
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

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.white70,
          ),
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
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: titleColor ??
                            Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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

String _formatAccountSecurityLabel(String rawValue) {
  switch (rawValue.toUpperCase()) {
    case 'SHAMIR':
    case 'SHAMIR_SLIP39':
    case 'SLIP39':
      return 'Shamir SLIP-39';
    case 'MULTISIG':
    case 'MULTISIG_VAULT':
    case '2FA_MULTISIG':
      return 'Cofre multisig';
    case 'STANDARD':
    default:
      return 'Semente padrão';
  }
}
