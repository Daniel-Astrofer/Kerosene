import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production frontend does not author notification messages', () {
    const forbiddenSnippetsByFile = {
      'lib/app/providers/price_alert_provider.dart': [
        'SessionNotificationItem(',
        'showTransactionNotification(',
        'Bitcoin \$sign',
      ],
      'lib/core/services/background_service_mobile.dart': [
        'showTransactionNotification(',
        'BTC recebido',
      ],
      'lib/features/financial_accounts/presentation/providers/'
          'balance_websocket_provider.dart': [
        'Você recebeu \$displayAmount',
        '\${selectedCurrency.code} recebido',
      ],
      'lib/features/movement/screens/send_payment_review_helpers.dart': [
        'showSendSentTransactionNotification',
        'Transferência enviada',
        'Envio on-chain iniciado',
        'Pagamento Lightning enviado',
      ],
      'lib/features/notifications/presentation/widgets/'
          'global_notification_host.dart': [
        'background-alerts-nudge',
        'Ative alertas em segundo plano',
      ],
    };

    final violations = <String>[];
    for (final entry in forbiddenSnippetsByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final snippet in entry.value) {
        if (source.contains(snippet)) {
          violations.add('${entry.key}: $snippet');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Notification title/body creation must come from backend only.',
    );
  });
}
