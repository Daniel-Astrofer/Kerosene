import 'package:flutter/material.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import '../../../bitcoin_accounts/presentation/bitcoin_accounts_screen.dart'
    deferred as bitcoin_accounts;
import 'settings_modern_components.dart';
import 'settings_route_helpers.dart';

class SettingsWalletsPane extends StatelessWidget {
  const SettingsWalletsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPaneScaffold(
      eyebrow: 'Carteiras',
      title: 'Custódia e carteiras KFE',
      subtitle:
          'A gestão de carteiras usa endpoints KFE reais: criar, listar, editar rótulo, arquivar, UTXOs e PSBT de cold wallet.',
      animation: KeroseneAnimationAsset.emptyWallet,
      children: [
        const SettingsInfoGrid(
          items: [
            SettingsInfoItem(
                'Regra de criação', 'Uma carteira por método de custódia'),
            SettingsInfoItem('Endpoint principal', '/kfe/wallets'),
            SettingsInfoItem('Lifecycle', 'PATCH label e POST archive'),
            SettingsInfoItem('Cold wallet', 'UTXOs e PSBT persistido'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsActionTile(
          icon: KeroseneIcons.wallet,
          title: 'Abrir carteiras',
          subtitle: 'Navega para a tela ativa de contas Bitcoin/KFE.',
          onTap: () => pushSettingsDeferred(
            context,
            bitcoin_accounts.loadLibrary,
            (_) => bitcoin_accounts.BitcoinAccountsScreen(),
          ),
        ),
      ],
    );
  }
}
