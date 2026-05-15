// Kerosene Storybook — Core UI Component Stories
// Contains stories for primitive and atomic widgets from lib/core/widgets/
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';
import 'package:teste/core/widgets/cyber_progress_bar.dart';
import 'package:teste/core/widgets/neon_action_button.dart';
import 'package:teste/core/widgets/kerosene_logo.dart';
import 'package:teste/core/widgets/kerosene_header.dart';

List<Story> uiStories() {
  return [
    Story(
      name: 'UI/Atomic/Kerosene Logo',
      builder: (context) => const Center(
        child: KeroseneLogo(size: 80),
      ),
    ),
    Story(
      name: 'UI/Atomic/Bouncing Button',
      builder: (context) {
        final text = context.knobs
            .text(label: 'Button Text', initial: 'FORJAR CARTEIRA');
        final isLoading =
            context.knobs.boolean(label: 'Loading State', initial: false);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: BouncingButton(
              text: text,
              isLoading: isLoading,
              onPressed: () {},
            ),
          ),
        );
      },
    ),
    Story(
      name: 'UI/Atomic/Cyber Text Field',
      builder: (context) {
        final label = context.knobs.text(label: 'Label', initial: 'USERNAME');
        final hint = context.knobs.text(label: 'Hint', initial: 'ex: satoshi');
        final error = context.knobs.text(label: 'Error', initial: '');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CyberTextField(
              controller: TextEditingController(),
              label: label,
              hint: hint,
              errorText: error.isEmpty ? null : error,
              prefixIcon: const Icon(LucideIcons.user, size: 20),
            ),
          ),
        );
      },
    ),
    Story(
      name: 'UI/Atomic/Neon Action Button',
      builder: (context) {
        final text = context.knobs.text(label: 'Text', initial: 'ATIVAR');
        return Center(
          child: NeonActionButton(
            text: text,
            onPressed: () {},
          ),
        );
      },
    ),
    Story(
      name: 'UI/Atomic/Cyber Progress Bar',
      builder: (context) {
        final currentStep = context.knobs
            .sliderInt(label: 'Current Step', initial: 5, min: 0, max: 10);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CyberProgressBar(
              currentStep: currentStep,
              totalSteps: 10,
            ),
          ),
        );
      },
    ),
    Story(
      name: 'UI/Molecules/Kerosene Header',
      builder: (context) {
        final title = context.knobs.text(label: 'Title', initial: 'SEGURANÇA');
        return Column(
          children: [
            KeroseneHeader(
              title: title,
              onBackPressed: () {},
            ),
            const Spacer(),
          ],
        );
      },
    ),
  ];
}
