import 'package:kerosene/design_system/animation/kerosene_animation_asset.dart';

enum KeroseneAnimationRuntime { lottie, rive }

enum KeroseneAnimationRole {
  passiveIllustration,
  stateFeedback,
  interactiveStateMachine,
  loading,
}

class KeroseneAnimationPolicy {
  const KeroseneAnimationPolicy._();

  static KeroseneAnimationRuntime runtimeFor(KeroseneAnimationAsset asset) {
    return asset.path.endsWith('.riv')
        ? KeroseneAnimationRuntime.rive
        : KeroseneAnimationRuntime.lottie;
  }

  static bool isInteractive(KeroseneAnimationAsset asset) {
    return runtimeFor(asset) == KeroseneAnimationRuntime.rive;
  }

  static KeroseneAnimationRole roleFor(KeroseneAnimationAsset asset) {
    switch (asset) {
      case KeroseneAnimationAsset.passkeyAuth:
      case KeroseneAnimationAsset.nfcReceive:
      case KeroseneAnimationAsset.transactionStatus:
      case KeroseneAnimationAsset.securityShield:
      case KeroseneAnimationAsset.bitcoinConfirmation:
      case KeroseneAnimationAsset.torConnection:
        return KeroseneAnimationRole.interactiveStateMachine;
      case KeroseneAnimationAsset.pendingConfirmation:
      case KeroseneAnimationAsset.secureConnection:
      case KeroseneAnimationAsset.networkReview:
        return KeroseneAnimationRole.loading;
      case KeroseneAnimationAsset.successCheck:
      case KeroseneAnimationAsset.paymentReceived:
        return KeroseneAnimationRole.stateFeedback;
      case KeroseneAnimationAsset.emptyWallet:
        return KeroseneAnimationRole.passiveIllustration;
    }
  }

  static bool shouldRepeat(KeroseneAnimationAsset asset) {
    switch (roleFor(asset)) {
      case KeroseneAnimationRole.loading:
      case KeroseneAnimationRole.interactiveStateMachine:
        return true;
      case KeroseneAnimationRole.passiveIllustration:
      case KeroseneAnimationRole.stateFeedback:
        return false;
    }
  }
}
