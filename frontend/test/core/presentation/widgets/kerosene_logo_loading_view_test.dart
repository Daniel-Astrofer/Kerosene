import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/presentation/widgets/kerosene_logo_loading_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLoadingView(
    WidgetTester tester, {
    required Size size,
    bool isDelayed = false,
    bool isError = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: KeroseneLogoLoadingView(
          status: isError
              ? 'FALHA DE AUTENTICAÇÃO'
              : (isDelayed ? 'CONEXÃO LENTA' : 'SINCRONIZANDO'),
          detail: isDelayed
              ? 'Tentando carregar seus dados...'
              : 'Garantindo segurança total para seus ativos',
          isDelayed: isDelayed,
          isError: isError,
          errorMessage: isError ? 'Sessão inválida' : null,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }
    return exceptions;
  }

  testWidgets('renders on compact and regular screens without layout errors', (
    tester,
  ) async {
    for (final size in const [Size(320, 640), Size(430, 932)]) {
      await pumpLoadingView(tester, size: size);

      expect(find.text('SINCRONIZANDO'), findsNothing);
      expect(find.text('CONEXÃO LENTA'), findsNothing);
      expect(find.text('FALHA DE AUTENTICAÇÃO'), findsNothing);
      expect(find.byType(Image), findsWidgets);
      expect(
        takeAllExceptions(tester),
        isEmpty,
        reason: 'Loading view produced layout errors at $size',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('renders delayed and error states', (tester) async {
    await pumpLoadingView(
      tester,
      size: const Size(320, 640),
      isDelayed: true,
    );
    expect(find.text('CONEXÃO LENTA'), findsNothing);
    expect(takeAllExceptions(tester), isEmpty);

    await pumpLoadingView(
      tester,
      size: const Size(320, 640),
      isError: true,
    );
    expect(find.text('FALHA DE AUTENTICAÇÃO'), findsNothing);
    expect(find.text('Sessão inválida'), findsNothing);
    expect(takeAllExceptions(tester), isEmpty);
  });
}
