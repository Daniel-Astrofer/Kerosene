import 'package:flutter/material.dart';

class KeroseneMotion {
  const KeroseneMotion._();

  static const int targetRefreshRateFps = 120;
  static const Duration frameBudget = Duration(microseconds: 8333);

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration pageIn = Duration(milliseconds: 136);
  static const Duration pageOut = Duration(milliseconds: 92);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration long = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration calm = Duration(milliseconds: 1000);
  static const Duration status = Duration(milliseconds: 1500);
  static const Duration loop = Duration(milliseconds: 1800);
  static const Duration offlineRetryPulse = Duration(milliseconds: 520);
  static const Duration offlineRetryInterval = Duration(seconds: 4);
  static const Duration startupConnectionProgressTick =
      Duration(milliseconds: 420);
  static const Duration startupConnectionTimeout = Duration(seconds: 55);
  static const Curve expressiveBack = Curves.easeOutBack;
  static const Duration route = pageIn;
  static const Duration ceremonial = Duration(milliseconds: 2600);
  static const Duration ambient = Duration(seconds: 20);
  static const Duration heroLoop = Duration(milliseconds: 2200);
  static const Duration secureLoop = Duration(milliseconds: 5200);
  static const Duration passkeyPulse = Duration(milliseconds: 5000);
  static const Duration passkeyScene = Duration(milliseconds: 900);
  static const Duration passkeySceneCompact = Duration(milliseconds: 760);
  static const Duration totpTransition = Duration(milliseconds: 850);
  static const Duration noticeHold = Duration(seconds: 3);
  static const Duration noticeExtendedHold = Duration(seconds: 4);
  static const Duration loadingMinimum = Duration(seconds: 3);
  static const Duration loadingRetryMedium = Duration(seconds: 6);
  static const Duration loadingRetryLong = Duration(seconds: 12);
  static const Duration loadingTimeout = Duration(seconds: 15);
  static const Duration notificationHold = Duration(seconds: 5);
  static const Duration notificationLongHold = Duration(seconds: 6);
  static const Duration walletLoop = Duration(seconds: 4);
  static const Duration nfcSceneIntro = Duration(milliseconds: 1600);
  static const Duration nfcSceneReady = Duration(milliseconds: 3900);
  static const Duration interactionCooldown = Duration(milliseconds: 500);
  static const Duration odometerInitial = Duration(milliseconds: 3000);
  static const Duration odometerUpdate = calm;
  static const Duration microStagger = Duration(milliseconds: 50);
  static const Duration authStagger = Duration(milliseconds: 34);
  static const Duration listStagger = Duration(milliseconds: 60);
  static const Duration compactStagger = Duration(milliseconds: 45);
  static const Duration surfaceStagger = Duration(milliseconds: 28);

  static Duration stagger(
    int index, {
    Duration step = microStagger,
    int maxIndex = 100,
  }) {
    final safeIndex = index.clamp(0, maxIndex);
    return Duration(microseconds: step.inMicroseconds * safeIndex);
  }

  static Duration exponentialBackoff(
    int retryCount, {
    Duration base = short,
    int maxRetryCount = 5,
  }) {
    final safeRetryCount = retryCount.clamp(0, maxRetryCount).toInt();
    return Duration(
      microseconds: base.inMicroseconds * (1 << safeRetryCount),
    );
  }

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutExpo;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }

  static Duration duration(BuildContext context, Duration duration) {
    return reduceMotion(context) ? instant : duration;
  }
}
