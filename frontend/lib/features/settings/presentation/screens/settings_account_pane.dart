import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';

import 'settings_formatters.dart';
import 'settings_section_components.dart';

class SettingsAccountPane extends ConsumerWidget {
  const SettingsAccountPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Perfil',
          style: AppTypography.newsreader(
            color: KeroseneBrandTokens.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Dados da conta autenticada, identificação de sessão e encerramento seguro do acesso local.',
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Identidade',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.userCheck,
              title: 'Nome de usuário',
              subtitle: settingsFormatHandle(user?.username ?? ''),
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Sessão',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.history,
              title: 'Criada em',
              subtitle: settingsDateLabel(user?.createdAt),
              onTap: null,
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.device,
              title: 'Último acesso',
              subtitle: settingsDateLabel(user?.lastLogin),
              onTap: null,
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.logout,
              title: 'Sair desta conta',
              subtitle:
                  'Encerra a sessão atual e retorna para a entrada do app.',
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/welcome', (_) => false);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
