import 'package:flutter/services.dart';

/// Kerosene — Unified Interaction Feedback
/// Provides strict haptic and auditory feedback for all user interactions.
class KeroseneFeedback {
  KeroseneFeedback._();

  /// Standard feedback for button clicks/taps.
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  /// Feedback for significant actions (confirming a selection, saving data).
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
    // SystemSound handles 'click' for all types usually, but focus on the haptic weight.
    await SystemSound.play(SystemSoundType.click);
  }

  /// Feedback for heavy, critical actions (finishing a transaction).
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  /// Feedback for errors or failed validations.
  static Future<void> error() async {
    await HapticFeedback.vibrate();
    // Some platforms have alert sounds but we stick to the required system/services.
  }
}
