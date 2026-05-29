import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/utils/api_display_text.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';

void main() {
  testWidgets('translates backend status codes without exposing raw values',
      (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ApiDisplayText.status(capturedContext, 'PENDING'), 'Aguardando');
    expect(
      ApiDisplayText.status(capturedContext, 'REBALANCE_REQUIRED'),
      'Atenção necessária',
    );
    expect(
      ApiDisplayText.walletCustody(capturedContext, 'WATCH_ONLY'),
      'Carteira fria acompanhada',
    );
  });

  testWidgets('sanitizes technical backend messages', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      ApiDisplayText.message(
        capturedContext,
        'ServerException: backend endpoint returned invalid payload',
      ),
      'Não conseguimos concluir essa ação agora. Tente novamente.',
    );
  });
}
