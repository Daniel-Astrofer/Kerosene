import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/design_system/motion/kerosene_motion.dart';

void main() {
  test('page motion is tuned for high-refresh displays', () {
    expect(KeroseneMotion.targetRefreshRateFps, 120);
    expect(KeroseneMotion.frameBudget.inMicroseconds, 8333);
    expect(kKerosenePageTransitionDuration, KeroseneMotion.pageIn);
    expect(kKerosenePageReverseTransitionDuration, KeroseneMotion.pageOut);
    expect(
        kKerosenePageTransitionDuration.inMilliseconds, lessThanOrEqualTo(140));
    expect(
      kKerosenePageReverseTransitionDuration.inMilliseconds,
      lessThanOrEqualTo(100),
    );
  });

  testWidgets('global transition uses compositor-friendly widgets',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return buildKeroseneHorizontalTransition(
              animation: const AlwaysStoppedAnimation<double>(1),
              secondaryAnimation: const AlwaysStoppedAnimation<double>(0),
              child: const Text('screen'),
            );
          },
        ),
      ),
    );

    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(find.byType(FadeTransition), findsOneWidget);
    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.text('screen'), findsOneWidget);
  });
}
