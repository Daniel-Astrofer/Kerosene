import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/utils/safe_display_text.dart';
import 'package:teste/core/l10n/app_localizations.dart';

void main() {
  test('masks long Bitcoin identifiers consistently', () {
    expect(
      SafeDisplayText.maskAddress(
        'bc1qabcdefghijklmnopqrstuvwxyz0123456789',
      ),
      'bc1qabcd...456789',
    );
    expect(SafeDisplayText.maskTxid('a' * 64), 'aaaaaaaaaa...aaaaaaaa');
    expect(SafeDisplayText.maskInvoice('lnbc1pjexampleinvoice'),
        'lnbc1pje...nvoice');
  });

  testWidgets('uses localized fallback for missing identifiers',
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

    expect(
      SafeDisplayText.displayAddress(capturedContext, ''),
      'Endereço indisponível',
    );
  });
}
