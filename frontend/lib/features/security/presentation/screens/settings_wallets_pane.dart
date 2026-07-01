import 'package:flutter/material.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_screen.dart'
    deferred as bitcoin_accounts;
import 'settings_section_components.dart';
import 'settings_route_helpers.dart';

class SettingsWalletsPane extends StatelessWidget {
  const SettingsWalletsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Carteiras',
            style: AppTypography.newsreader(
                color: KeroseneBrandTokens.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: 0)),
        const SizedBox(height: AppSpacing.md),
        Text(
            'Gerencie apenas ações administrativas das carteiras Bitcoin desta sessão.',
            style: AppTypography.inter(
                color: KeroseneBrandTokens.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.55,
                letterSpacing: 0)),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(title: 'Gerenciamento', children: [
          SettingsSectionRow(
              icon: KeroseneIcons.edit,
              title: 'Trocar nome',
              subtitle: 'Abra a carteira desejada e altere o nome exibido.',
              onTap: () => pushSettingsDeferred(
                  context,
                  bitcoin_accounts.loadLibrary,
                  (_) => bitcoin_accounts.BitcoinAccountsScreen())),
          SettingsSectionRow(
              icon: KeroseneIcons.lock,
              title: 'Apagar carteiras',
              subtitle: 'Abra a carteira desejada e confirme a remoção segura.',
              onTap: () => pushSettingsDeferred(
                  context,
                  bitcoin_accounts.loadLibrary,
                  (_) => bitcoin_accounts.BitcoinAccountsScreen())),
        ]),
      ],
    );
  }
}
