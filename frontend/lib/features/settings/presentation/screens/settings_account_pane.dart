import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';

import 'settings_formatters.dart';
import 'settings_modern_components.dart';

class SettingsAccountPane extends ConsumerWidget {
  const SettingsAccountPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SettingsPaneScaffold(
      eyebrow: 'Conta',
      title: 'Acesso e sessão',
      subtitle:
          'Exibe apenas dados disponíveis na sessão autenticada. Não há edição de perfil exposta pelo backend neste momento.',
      animation: KeroseneAnimationAsset.secureConnection,
      children: [
        SettingsInfoGrid(
          items: [
            SettingsInfoItem(
                'Identificador', settingsFormatHandle(user?.username ?? '')),
            SettingsInfoItem('Função', user?.role ?? 'USER'),
            SettingsInfoItem(
                'Perfil', user?.isAdmin == true ? 'Administrador' : 'Usuário'),
            SettingsInfoItem('Criada em', settingsDateLabel(user?.createdAt)),
            SettingsInfoItem(
                'Último acesso', settingsDateLabel(user?.lastLogin)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsActionTile(
          icon: KeroseneIcons.logout,
          title: 'Sair desta conta',
          subtitle: 'Encerra a sessão atual e retorna para a entrada do app.',
          destructive: true,
          onTap: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/welcome', (_) => false);
            }
          },
        ),
      ],
    );
  }
}
