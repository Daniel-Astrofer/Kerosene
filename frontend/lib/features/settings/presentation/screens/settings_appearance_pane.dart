import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/providers/appearance_provider.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_modern_components.dart';

class SettingsAppearancePane extends ConsumerWidget {
  const SettingsAppearancePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return SettingsPaneScaffold(
      eyebrow: 'Aparência',
      title: 'Tema local do aplicativo',
      subtitle:
          'Preferência local permitida pelo app. Não depende do backend e não altera dados financeiros.',
      animation: KeroseneAnimationAsset.networkReview,
      children: [
        SettingsChoiceGroup<AppThemeVariant>(
          title: 'Tema',
          value: appearance.themeVariant,
          values: AppThemeVariant.values,
          label: (value) => value.label,
          description: (value) => value.description,
          onSelected: notifier.setThemeVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsChoiceGroup<AppFontScale>(
          title: 'Escala de fonte',
          value: appearance.fontScale,
          values: AppFontScale.values,
          label: (value) => value.label,
          description: (value) =>
              '${(value.scaleFactor * 100).round()}% da escala base',
          onSelected: notifier.setFontScale,
        ),
      ],
    );
  }
}
