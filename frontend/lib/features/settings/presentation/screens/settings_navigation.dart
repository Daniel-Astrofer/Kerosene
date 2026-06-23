import 'package:flutter/material.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_modern_components.dart';

enum SettingsPane { account, security, notifications, appearance, wallets }

class SettingsHeader extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SettingsIconButtonFrame(
            icon: KeroseneIcons.back,
            semanticLabel: 'Voltar',
            onTap: onClose,
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class SettingsHero extends StatelessWidget {
  const SettingsHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajuste sua conta',
          style: AppTypography.newsreader(
            color: KeroseneBrandTokens.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w500,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Gerencie segurança, privacidade e preferências da sua experiência bancária.',
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class SettingsNavigationRail extends StatelessWidget {
  final SettingsPane selected;
  final ValueChanged<SettingsPane> onSelected;

  const SettingsNavigationRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = <SettingsPaneSpec>[
      SettingsPaneSpec(
        pane: SettingsPane.account,
        icon: KeroseneIcons.userCheck,
        animation: KeroseneAnimationAsset.secureConnection,
        title: 'Perfil',
        subtitle: 'Dados pessoais e informações da conta',
      ),
      SettingsPaneSpec(
        pane: SettingsPane.security,
        icon: KeroseneIcons.security,
        animation: KeroseneAnimationAsset.securityShield,
        title: 'Segurança',
        subtitle: 'Senha, biometria e autenticação em 2 fatores',
      ),
      SettingsPaneSpec(
        pane: SettingsPane.notifications,
        icon: KeroseneIcons.notifications,
        animation: KeroseneAnimationAsset.transactionStatus,
        title: 'Notificações',
        subtitle: 'Alertas de transações e comunicações',
      ),
      SettingsPaneSpec(
        pane: SettingsPane.appearance,
        icon: KeroseneIcons.contrast,
        animation: KeroseneAnimationAsset.networkReview,
        title: 'Aparência',
        subtitle: 'Tema e escala local',
      ),
      SettingsPaneSpec(
        pane: SettingsPane.wallets,
        icon: KeroseneIcons.wallet,
        animation: KeroseneAnimationAsset.emptyWallet,
        title: 'Carteiras',
        subtitle: 'Custódia e ciclo KFE',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferências'.toUpperCase(),
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items)
          SettingsNavigationTile(
            spec: item,
            selected: item.pane == selected,
            onTap: () => onSelected(item.pane),
          ),
      ],
    );
  }
}

class SettingsPaneSpec {
  final SettingsPane pane;
  final IconData icon;
  final KeroseneAnimationAsset animation;
  final String title;
  final String subtitle;

  const SettingsPaneSpec({
    required this.pane,
    required this.icon,
    required this.animation,
    required this.title,
    required this.subtitle,
  });
}

class SettingsNavigationTile extends StatelessWidget {
  final SettingsPaneSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const SettingsNavigationTile({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: KeroseneMotion.short,
            curve: KeroseneMotion.standard,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.hexFF2C2C2E : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.hexFF1C1C1E
                        : KeroseneBrandTokens.surface,
                  ),
                  child: Icon(
                    spec.icon,
                    color: selected
                        ? KeroseneBrandTokens.textPrimary
                        : KeroseneBrandTokens.textSecondary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: AppTypography.inter(
                          color: KeroseneBrandTokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spec.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: KeroseneBrandTokens.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0.45,
                  duration: KeroseneMotion.short,
                  child: Icon(
                    KeroseneIcons.chevronRight,
                    color: KeroseneBrandTokens.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
