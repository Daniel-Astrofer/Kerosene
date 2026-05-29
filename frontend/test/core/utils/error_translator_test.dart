import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations_pt.dart';
import 'package:kerosene/core/utils/error_translator.dart';

void main() {
  final l10n = AppLocalizationsPt();

  group('ErrorTranslator', () {
    test('maps receiver not found to address unavailable', () {
      expect(
        ErrorTranslator.translate(l10n, 'ERR_LEDGER_RECEIVER_NOT_FOUND'),
        'Endereço não disponível',
      );
    });

    test('maps unlinked passkey device errors to actionable guidance', () {
      expect(
        ErrorTranslator.translate(
          l10n,
          'SovereignAuthException(ERR_AUTH_PASSKEY_NOT_REGISTERED): No sovereign key is registered on this device.',
        ),
        'Este dispositivo não está vinculado à sua conta para confirmar com passkey. Vincule este aparelho e tente novamente.',
      );
    });

    test('maps backend device recognition errors to actionable guidance', () {
      expect(
        ErrorTranslator.translate(
          l10n,
          '{"type":"AppException","message":"Security Alert: Unrecognized device detected.","statusCode":403,"errorCode":"ERR_AUTH_UNRECOGNIZED_DEVICE"}',
        ),
        'Este dispositivo não está vinculado à sua conta para confirmar com passkey. Vincule este aparelho e tente novamente.',
      );
    });

    test('prefers structured guidance for passkey link-required errors', () {
      expect(
        ErrorTranslator.translate(
          l10n,
          '{"type":"AuthError","message":"Nenhuma passkey compativel com este login esta vinculada a conta.","statusCode":409,"errorCode":"AUTH_014","data":{"action":"LINK_NEW_PASSKEY","guidance":"Entre com senha + TOTP e vincule uma nova passkey neste dispositivo."}}',
        ),
        'Entre com senha + TOTP e vincule uma nova passkey neste dispositivo.',
      );
    });

    test('maps payment rail errors to cordial messages', () {
      expect(
        ErrorTranslator.translate(l10n, 'LIGHTNING_INSUFFICIENT_LIQUIDITY'),
        'Não há liquidez Lightning suficiente para concluir este envio agora. Tente outro método ou um valor menor.',
      );
      expect(
        ErrorTranslator.translate(l10n, 'ONCHAIN_RECEIVER_METHOD_NOT_FOUND'),
        'Este usuário não possui carteira on-chain cadastrada para receber.',
      );
      expect(
        ErrorTranslator.translate(l10n, 'QUOTE_EXPIRED'),
        'A cotação expirou. Gere uma nova antes de confirmar.',
      );
    });

    test('hides technical backend messages', () {
      expect(
        ErrorTranslator.translate(
          l10n,
          'DioException: endpoint /api/payments failed with invalid payload',
        ),
        'Ocorreu um erro inesperado.',
      );
    });
  });
}
