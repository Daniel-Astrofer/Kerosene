import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/providers/appearance_provider.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_section_components.dart';

class SettingsAppearancePane extends ConsumerWidget {
  const SettingsAppearancePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aparência',
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
          'Controle local do tema visual do aplicativo. A preferência não altera dados financeiros nem depende do backend.',
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
          title: 'Tema',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.contrast,
              title: 'Modo escuro',
              subtitle: appearance.darkModeEnabled
                  ? 'Ativado para esta sessão.'
                  : 'Desativado para esta sessão.',
              trailing: SettingsReadonlySwitch(
                value: appearance.darkModeEnabled,
              ),
              onTap: () => notifier.setDarkModeEnabled(
                !appearance.darkModeEnabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
