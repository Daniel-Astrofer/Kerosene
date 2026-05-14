import 'package:flutter/material.dart';
import 'package:teste/design_system/motion/kerosene_motion.dart';

const Duration kKerosenePageTransitionDuration = KeroseneMotion.pageIn;
const Duration kKerosenePageReverseTransitionDuration = KeroseneMotion.pageOut;

Widget buildKeroseneHorizontalTransition({
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  bool disableAnimations = false,
}) {
  if (disableAnimations) {
    return child;
  }

  final incoming = CurvedAnimation(
    parent: animation,
    curve: KeroseneMotion.enterCurve,
    reverseCurve: KeroseneMotion.exitCurve,
  );

  return RepaintBoundary(
    child: FadeTransition(
      opacity: incoming,
      child: SlideTransition(
        transformHitTests: false,
        position: Tween<Offset>(
          begin: KeroseneMotion.pageSlideBegin,
          end: Offset.zero,
        ).animate(incoming),
        child: child,
      ),
    ),
  );
}

Route<T> keroseneHorizontalRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  Duration transitionDuration = kKerosenePageTransitionDuration,
  Duration reverseTransitionDuration = kKerosenePageReverseTransitionDuration,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return buildKeroseneHorizontalTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
        disableAnimations:
            MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      );
    },
  );
}

class KeroseneHorizontalPageTransitionsBuilder extends PageTransitionsBuilder {
  const KeroseneHorizontalPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildKeroseneHorizontalTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
      disableAnimations:
          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
  }
}

const PageTransitionsTheme kerosenePageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: KeroseneHorizontalPageTransitionsBuilder(),
    TargetPlatform.fuchsia: KeroseneHorizontalPageTransitionsBuilder(),
    TargetPlatform.iOS: KeroseneHorizontalPageTransitionsBuilder(),
    TargetPlatform.linux: KeroseneHorizontalPageTransitionsBuilder(),
    TargetPlatform.macOS: KeroseneHorizontalPageTransitionsBuilder(),
    TargetPlatform.windows: KeroseneHorizontalPageTransitionsBuilder(),
  },
);
