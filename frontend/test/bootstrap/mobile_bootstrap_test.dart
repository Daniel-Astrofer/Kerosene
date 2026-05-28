import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/bootstrap/mobile_bootstrap.dart';

void main() {
  test('buildApp exposes the official mobile app shell', () {
    expect(buildApp(), isA<MyApp>());
  });

  testWidgets('mobile scroll behavior stays bouncing and always scrollable', (
    tester,
  ) async {
    late ScrollPhysics physics;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          physics = const KeroseneScrollBehavior().getScrollPhysics(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(physics, isA<BouncingScrollPhysics>());
    expect((physics as BouncingScrollPhysics).parent,
        isA<AlwaysScrollableScrollPhysics>());
  });
}
