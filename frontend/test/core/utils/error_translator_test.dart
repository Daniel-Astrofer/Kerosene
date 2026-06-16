import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations_pt.dart';
import 'package:kerosene/core/utils/error_translator.dart';

void main() {
  final l10n = AppLocalizationsPt();

  group('ErrorTranslator', () {
    test('maps standard numeric backend error codes to localized messages', () {
      final expectations = <String, String>{
        'AUTH_001': l10n.errAuthUserAlreadyExists,
        'AUTH_002': l10n.errAuthUsernameMissing,
        'AUTH_003': l10n.errAuthPassphraseMissing,
        'AUTH_004': l10n.errAuthInvalidUsernameFormat,
        'AUTH_005': l10n.errAuthCharLimitExceeded,
        'AUTH_006': l10n.errAuthUserNotFound,
        'AUTH_007': l10n.errAuthInvalidPassphraseFormat,
        'AUTH_008': l10n.errAuthIncorrectTotp,
        'AUTH_009': l10n.errAuthInvalidCredentials,
        'AUTH_010': l10n.errPasskeyDeviceNotLinked,
        'AUTH_011': l10n.errAuthTotpTimeout,
        'AUTH_012': l10n.errPasskeyRequired,
        'AUTH_013': l10n.errSessionExpired,
        'AUTH_014': l10n.errPasskeyDeviceNotLinked,
        'AUTH_015': l10n.errPasskeyRejected,
        'AUTH_016': l10n.errPasskeyRejected,
        'AUTH_017': l10n.errPasskeyDeviceNotLinked,
        'AUTH_018': l10n.appEntryPinUnavailableMessage,
        'AUTH_019': l10n.errAuthInvalidCredentials,
        'AUTH_020': l10n.appEntryLockedHelper,
        'AUTH_021': l10n.appEntryPinUnavailableMessage,
        'AUTH_022': l10n.errPasskeyRejected,
        'AUTH_099': l10n.errUnexpected,
        'LEDGER_001': l10n.errLedgerNotFound,
        'LEDGER_002': l10n.errLedgerReceiverNotFound,
        'LEDGER_003': l10n.errLedgerAlreadyExists,
        'LEDGER_004': l10n.errLedgerInsufficientBalance,
        'LEDGER_005': l10n.errLedgerInvalidOperation,
        'LEDGER_006': l10n.errLedgerPaymentRequestNotFound,
        'LEDGER_007': l10n.errLedgerPaymentRequestExpired,
        'LEDGER_008': l10n.errLedgerPaymentRequestAlreadyPaid,
        'LEDGER_009': l10n.errLedgerPaymentRequestSelfPay,
        'LEDGER_099': l10n.errLedgerGeneric,
        'WALLET_001': l10n.errWalletAlreadyExists,
        'WALLET_002': l10n.errWalletNotFound,
        'WALLET_099': l10n.errWalletGeneric,
        'HYDRA_001': l10n.errInternalServer,
        'VAULT_001': l10n.errInternalServer,
        'KRS_099': l10n.errInternalServer,
        'SYS_001': l10n.errUnexpected,
        'SYS_002': l10n.errUnexpected,
        'SYS_404': l10n.errUnexpected,
        'SYS_500': l10n.errInternalServer,
      };

      for (final entry in expectations.entries) {
        expect(
          ErrorTranslator.translate(l10n, entry.key),
          entry.value,
          reason: '${entry.key} should map to localized copy',
        );
      }
    });

    test('uses structured backend guidance for assisted financial UX', () {
      final guidanceByCode = <String, String>{
        'ERR_ACCOUNT_DEPOSIT_REQUIRED':
            'Ative uma carteira ou adicione saldo para receber pela plataforma.',
        'ERR_VAULT_NOT_READY':
            'O cofre master não pôde ser ativado para esta conta. Tente novamente em instantes.',
        'ERR_LEDGER_RECEIVER_NOT_READY':
            'O destinatário ainda não concluiu a ativação da carteira.',
        'ERR_KFE_RAIL_PROVIDER_UNAVAILABLE':
            'Os serviços de custódia e trilhos financeiros estão indisponíveis no momento. Tente novamente mais tarde.',
        'ERR_DUPLICATE_TRANSACTION':
            'Esta transação já foi processada recentemente. Evite duplicidade.',
      };

      for (final entry in guidanceByCode.entries) {
        final payload = jsonEncode({
          'type': 'AppException',
          'message': 'Backend fallback message',
          'statusCode': 409,
          'errorCode': entry.key,
          'data': {'guidance': entry.value},
        });

        expect(
          ErrorTranslator.translate(l10n, payload),
          entry.value,
          reason: '${entry.key} should prefer data.guidance',
        );
      }
    });

    test('uses sanitized backend message for validation system codes', () {
      expect(
        ErrorTranslator.translate(
          l10n,
          jsonEncode({
            'type': 'AppException',
            'message': 'Informe um valor válido para continuar.',
            'statusCode': 400,
            'errorCode': 'SYS_001',
          }),
        ),
        'Informe um valor válido para continuar.',
      );
    });

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

    test('maps unsupported local passkey platforms to biometric setup guidance',
        () {
      expect(
        ErrorTranslator.translate(
          l10n,
          'SovereignAuthException(ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS): Passkey confirmation requires biometrics or a local device lock on a supported platform.',
        ),
        'Configure biometria ou um bloqueio de tela neste dispositivo para usar a chave do dispositivo.',
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
