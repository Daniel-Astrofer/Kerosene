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
import 'package:teste/core/widgets/state_feedback_view.dart';

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
      name: 'UI/States/State Feedback View',
      builder: (context) {
        final state = context.knobs.options<FeedbackState>(
          label: 'State',
          initial: FeedbackState.loading,
          options: const [
            Option(label: 'Loading', value: FeedbackState.loading),
            Option(label: 'Empty', value: FeedbackState.empty),
            Option(label: 'Error', value: FeedbackState.error),
            Option(label: 'Network Error', value: FeedbackState.networkError),
          ],
        );
        final showAction =
            context.knobs.boolean(label: 'Show Action', initial: true);

        final title = switch (state) {
          FeedbackState.loading => 'Sincronizando dados',
          FeedbackState.empty => 'Nada por aqui',
          FeedbackState.error => 'Nao foi possivel concluir',
          FeedbackState.networkError => 'Conexao indisponivel',
        };
        final description = switch (state) {
          FeedbackState.loading =>
            'Estamos atualizando as informacoes sem bloquear a tela.',
          FeedbackState.empty =>
            'Quando houver dados disponiveis, eles aparecerao neste espaco.',
          FeedbackState.error =>
            'A resposta nao pode ser processada agora. Tente novamente.',
          FeedbackState.networkError =>
            'Verifique a rota Tor ou a conexao de rede antes de repetir.',
        };

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StateFeedbackView(
            state: state,
            title: title,
            description: description,
            actionLabel: showAction ? 'Tentar novamente' : null,
            onAction: showAction ? () {} : null,
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
