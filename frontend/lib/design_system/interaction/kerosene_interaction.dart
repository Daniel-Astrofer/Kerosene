/// Kerosene advanced interaction policy.
///
/// This file is intentionally dependency-light. Runtime wrappers for Rive/Lottie
/// should live in the design system and be introduced only when those packages
/// are added to `pubspec.yaml`.
class KeroseneInteraction {
  const KeroseneInteraction._();

  /// Main principle for advanced interaction.
  static const String principle =
      'Interação deve esclarecer estado, reduzir ansiedade e reforçar confiança.';

  /// Interaction should feel like this.
  static const List<String> traits = [
    'cordial',
    'executiva',
    'silenciosa',
    'responsiva',
    'precisa',
    'acessível',
    'discreta',
    'orientada a estado',
  ];

  /// Interaction should avoid this tone.
  static const List<String> avoid = [
    'gamer',
    'neon como linguagem principal',
    'excessivamente celebratória',
    'ansiosa',
    'invasiva',
    'ornamental sem função',
    'dependente de animação para compreensão',
  ];

  /// Approved interaction layers.
  static const List<String> layers = [
    'motion tokens',
    'microinterações nativas',
    'ícones e ícones animados',
    'Rive e Lottie',
  ];
}

enum KeroseneInteractionLayer {
  motionToken,
  nativeMicrointeraction,
  animatedIcon,
  lottie,
  rive,
}

enum KeroseneInteractionRole {
  press,
  hover,
  focus,
  loading,
  feedback,
  emptyState,
  onboarding,
  security,
  payment,
  transactionStatus,
  networkStatus,
}

class KeroseneInteractionDecision {
  const KeroseneInteractionDecision._();

  static KeroseneInteractionLayer forRole(KeroseneInteractionRole role) {
    return switch (role) {
      KeroseneInteractionRole.press =>
        KeroseneInteractionLayer.nativeMicrointeraction,
      KeroseneInteractionRole.hover =>
        KeroseneInteractionLayer.nativeMicrointeraction,
      KeroseneInteractionRole.focus =>
        KeroseneInteractionLayer.nativeMicrointeraction,
      KeroseneInteractionRole.loading =>
        KeroseneInteractionLayer.nativeMicrointeraction,
      KeroseneInteractionRole.feedback => KeroseneInteractionLayer.animatedIcon,
      KeroseneInteractionRole.emptyState => KeroseneInteractionLayer.lottie,
      KeroseneInteractionRole.onboarding => KeroseneInteractionLayer.lottie,
      KeroseneInteractionRole.security => KeroseneInteractionLayer.rive,
      KeroseneInteractionRole.payment => KeroseneInteractionLayer.rive,
      KeroseneInteractionRole.transactionStatus =>
        KeroseneInteractionLayer.rive,
      KeroseneInteractionRole.networkStatus => KeroseneInteractionLayer.rive,
    };
  }
}
