import 'package:flutter/material.dart';
import 'package:kerosene/core/navigation/deferred_page.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

void pushSettingsDeferred(
  BuildContext context,
  Future<void> Function() loadLibrary,
  WidgetBuilder builder,
) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: KeroseneMotion.medium,
      reverseTransitionDuration: KeroseneMotion.short,
      pageBuilder: (_, __, ___) => DeferredPage(
        loadLibrary: loadLibrary,
        builder: builder,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: KeroseneMotion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
