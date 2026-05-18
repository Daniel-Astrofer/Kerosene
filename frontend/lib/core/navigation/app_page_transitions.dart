import 'package:flutter/material.dart';
import 'package:teste/core/motion/app_motion.dart';

const PageTransitionsTheme kerosenePageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: KerosenePageTransitionsBuilder(),
    TargetPlatform.fuchsia: KerosenePageTransitionsBuilder(),
    TargetPlatform.iOS: KerosenePageTransitionsBuilder(),
    TargetPlatform.linux: KerosenePageTransitionsBuilder(),
    TargetPlatform.macOS: KerosenePageTransitionsBuilder(),
    TargetPlatform.windows: KerosenePageTransitionsBuilder(),
  },
);

Route<T> keroseneHorizontalRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: KeroseneMotion.route,
    reverseTransitionDuration: KeroseneMotion.medium,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return buildKeroseneRouteTransition(
        context: context,
        animation: animation,
        child: child,
      );
    },
  );
}

class KerosenePageTransitionsBuilder extends PageTransitionsBuilder {
  const KerosenePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildKeroseneRouteTransition(
      context: context,
      animation: animation,
      child: child,
    );
  }
}

Widget buildKeroseneRouteTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Widget child,
}) {
  if (KeroseneMotion.reduceMotion(context)) {
    return child;
  }

  final curved = CurvedAnimation(
    parent: animation,
    curve: KeroseneMotion.entrance,
    reverseCurve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0.96, end: 1).animate(curved),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.045, 0),
        end: Offset.zero,
      ).animate(curved),
      transformHitTests: false,
      child: child,
    ),
  );
}
