import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/notifications/presentation/widgets/global_notification_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compactPortrait = Size(320, 568);
  const compactLandscape = Size(568, 320);
  const regularPortrait = Size(390, 844);

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }
    return exceptions;
  }

  void configureViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<ProviderContainer> pumpHost(
    WidgetTester tester, {
    required Size size,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    configureViewport(tester, size);

    final sharedPreferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) {
            return GlobalNotificationHost(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const Scaffold(
            body: Center(child: Text('Home')),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  group('GlobalNotificationHost responsiveness', () {
    testWidgets('banner avoids overlay and bottom overflow on compact screens',
        (
      tester,
    ) async {
      for (final size in [
        compactPortrait,
        compactLandscape,
        regularPortrait,
      ]) {
        final container = await pumpHost(tester, size: size);

        container.read(notificationBannerProvider.notifier).show(
              SessionNotificationItem(
                id: 'notification-${size.width}',
                title:
                    'Transferencia recebida com varias confirmacoes pendentes',
                body:
                    'Esta mensagem simula uma notificacao longa recebida em tempo real para garantir que o banner nao ultrapasse a area disponivel em telas pequenas.',
                timestamp: DateTime(2026, 5, 19, 22),
                kind: SessionNotificationItem.kindTransferReceived,
                severity: SessionNotificationItem.severitySuccess,
              ),
            );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        expect(
          takeAllExceptions(tester),
          isEmpty,
          reason: 'Notification banner produced layout errors at $size',
        );
        container.read(notificationBannerProvider.notifier).dismiss();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('screen feedback host avoids overlay and bottom overflow', (
      tester,
    ) async {
      await pumpHost(tester, size: compactLandscape);

      AppScreenFeedbackBus.show(
        type: AppNoticeType.warning,
        title: 'Aviso operacional com texto longo',
        message:
            'Mensagem detalhada para validar que o feedback global continua acessivel e limitado quando nao ha Overlay acima do host.',
        duration: Duration.zero,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(takeAllExceptions(tester), isEmpty);
      AppScreenFeedbackBus.clear();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
