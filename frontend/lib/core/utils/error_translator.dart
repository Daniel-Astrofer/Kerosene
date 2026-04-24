import 'dart:convert';
import 'package:teste/l10n/app_localizations.dart';

class ErrorTranslator {
  static String translate(AppLocalizations l10n, String codeOrMessage) {
    if (codeOrMessage.isEmpty) return l10n.errUnexpected;

    String codeToTest = codeOrMessage;
    String? extractedMessage;
    Map<String, dynamic>? extractedData;

    // Try to parse JSON from AppException.toString()
    try {
      final decoded = jsonDecode(codeOrMessage);
      if (decoded is Map<String, dynamic> &&
          (decoded.containsKey('message') ||
              decoded.containsKey('errorCode') ||
              decoded.containsKey('data'))) {
        extractedMessage = decoded['message']?.toString();
        extractedData = _mapFromDynamic(decoded['data']);
        final code = decoded['errorCode']?.toString();
        if (code != null && code.isNotEmpty && code != 'null') {
          codeToTest = code;
        }
      }
    } catch (_) {
      // Fallback to regex just in case older strings are logged or passed
      final regex = RegExp(
        r'AppException\(message:\s*(.+?),\s*statusCode:\s*(.+?),\s*errorCode:\s*(.+?)\)',
      );
      final match = regex.firstMatch(codeOrMessage);
      if (match != null) {
        extractedMessage = match.group(1)?.trim();
        final code = match.group(3)?.trim();
        if (code != null && code != 'null') {
          codeToTest = code;
        }
      }
    }

    final internalCodeMatch = RegExp(
      r'(ERR_[A-Z0-9_]+|[A-Z]+_\d{3}|USER_NOT_FOUND|AUTH_FAILED|INVALID_SIGNATURE|VERIFY_ERROR|MISSING_CREDENTIAL_ID|CHALLENGE_EXPIRED)',
    ).firstMatch(codeOrMessage);
    if (internalCodeMatch != null && internalCodeMatch.group(0) != null) {
      codeToTest = internalCodeMatch.group(0)!;
    }

    // Check for exact known Error Codes explicitly
    switch (codeToTest) {
      // Auth Errors
      case 'ERR_AUTH_USER_ALREADY_EXISTS':
        return l10n.errAuthUserAlreadyExists;
      case 'ERR_AUTH_USERNAME_MISSING':
        return l10n.errAuthUsernameMissing;
      case 'ERR_AUTH_PASSPHRASE_MISSING':
        return l10n.errAuthPassphraseMissing;
      case 'ERR_AUTH_INVALID_USERNAME_FORMAT':
        return l10n.errAuthInvalidUsernameFormat;
      case 'ERR_AUTH_CHARACTER_LIMIT_EXCEEDED':
        return l10n.errAuthCharLimitExceeded;
      case 'ERR_AUTH_USER_NOT_FOUND':
        return l10n.errAuthUserNotFound;
      case 'ERR_AUTH_INVALID_PASSPHRASE_FORMAT':
        return l10n.errAuthInvalidPassphraseFormat;
      case 'ERR_AUTH_INCORRECT_TOTP':
        return l10n.errAuthIncorrectTotp;
      case 'ERR_AUTH_INVALID_CREDENTIALS':
        return l10n.errAuthInvalidCredentials;
      case 'ERR_AUTH_UNRECOGNIZED_DEVICE':
        return _passkeyDeviceNotLinkedMessage(l10n);
      case 'ERR_AUTH_TOTP_TIMEOUT':
        return l10n.errAuthTotpTimeout;
      case 'ERR_AUTH_INVALID_PREAUTH':
        return l10n.errSessionExpired;
      case 'ERR_AUTH_PASSKEY_INVALID':
        return l10n.passkeyErrorFinishing(
            l10n.errUnexpected); // Fallback to generic message
      case 'ERR_AUTH_PASSKEY_TIMEOUT':
        return l10n.errTimeout;
      case 'ERR_AUTH_PASSKEY_ALREADY_REGISTERED':
        return l10n.errAuthUserAlreadyExists;
      case 'ERR_AUTH_SESSION_NOT_FOUND':
        return l10n.passkeySessionNotFound;
      case 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS':
        return l10n.passkeyNoBiometrics;
      case 'ERR_AUTH_PASSKEY_NOT_REGISTERED':
      case 'ERR_AUTH_PASSKEY_CORRUPTED_KEY_MATERIAL':
        return _passkeyDeviceNotLinkedMessage(l10n);
      case 'AUTH_012':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallbackPt:
              'Uma passkey compatível com este login é obrigatória para concluir a operação.',
          fallbackEn:
              'A passkey compatible with this login is required to finish this operation.',
          fallbackEs:
              'Se requiere una passkey compatible con este acceso para completar esta operación.',
        );
      case 'AUTH_014':
      case 'AUTH_017':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallbackPt:
              'Esta passkey não serve para este login. Entre com senha + TOTP e vincule uma nova passkey neste dispositivo.',
          fallbackEn:
              'This passkey cannot be used for this login. Sign in with passphrase + TOTP and link a new passkey on this device.',
          fallbackEs:
              'Esta passkey no sirve para este acceso. Entra con frase secreta + TOTP y vincula una nueva passkey en este dispositivo.',
        );
      case 'AUTH_015':
      case 'AUTH_016':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallbackPt:
              'A passkey foi rejeitada nesta operação. Se o problema persistir, vincule outra passkey compatível.',
          fallbackEn:
              'This passkey was rejected for the operation. If the problem persists, link another compatible passkey.',
          fallbackEs:
              'La passkey fue rechazada en esta operación. Si el problema persiste, vincula otra passkey compatible.',
        );
      case 'ERR_AUTH_PASSKEY_AUTH_CANCELLED':
        return l10n.passkeyAuthFailed;
      case 'USER_NOT_FOUND':
        return l10n.errAuthUserNotFound;
      case 'AUTH_FAILED':
      case 'INVALID_SIGNATURE':
        return l10n.passkeyErrorFinishing(l10n.errAuthInvalidCredentials);
      case 'CHALLENGE_EXPIRED':
        return l10n.errTimeout;
      case 'VERIFY_ERROR':
      case 'MISSING_CREDENTIAL_ID':
        return l10n.passkeyErrorFinishing(l10n.errUnexpected);
      case 'RECOVERY_BAD_REQUEST':
        return 'Dados de recuperação inválidos. Revise os códigos, a nova frase e o TOTP.';
      case 'RECOVERY_REJECTED':
        return 'A recuperação foi rejeitada. O backend não informa se o erro veio do usuário, dos códigos ou da prova criptográfica.';
      case 'RECOVERY_SESSION_EXPIRED':
        return 'A sessão de recuperação expirou ou já foi consumida. Reinicie o processo.';
      case 'RECOVERY_RATE_LIMITED':
        return 'A recuperação foi bloqueada temporariamente por excesso de tentativas.';

      // Ledger / Balance Errors
      case 'ERR_LEDGER_NOT_FOUND':
        return l10n.errLedgerNotFound;
      case 'ERR_LEDGER_ALREADY_EXISTS':
        return l10n.errLedgerAlreadyExists;
      case 'ERR_LEDGER_INSUFFICIENT_BALANCE':
        return l10n.errLedgerInsufficientBalance;
      case 'ERR_LEDGER_INVALID_OPERATION':
        return l10n.errLedgerInvalidOperation;
      case 'ERR_LEDGER_RECEIVER_NOT_FOUND':
        return l10n.addressNotAvailable;
      case 'ERR_LEDGER_GENERIC':
        return l10n.errLedgerGeneric;
      case 'ERR_LEDGER_PAYMENT_REQUEST_NOT_FOUND':
        return l10n.errLedgerPaymentRequestNotFound;
      case 'ERR_LEDGER_PAYMENT_REQUEST_EXPIRED':
        return l10n.errLedgerPaymentRequestExpired;
      case 'ERR_LEDGER_PAYMENT_REQUEST_ALREADY_PAID':
        return l10n.errLedgerPaymentRequestAlreadyPaid;
      case 'ERR_LEDGER_PAYMENT_REQUEST_SELF_PAY':
        return l10n.errLedgerPaymentRequestSelfPay;

      // Wallet Errors
      case 'ERR_WALLET_ALREADY_EXISTS':
        return l10n.errWalletAlreadyExists;
      case 'ERR_WALLET_NOT_FOUND':
        return l10n.errWalletNotFound;
      case 'ERR_WALLET_GENERIC':
        return l10n.errWalletGeneric;
      case 'ERR_INVALID_NETWORK_ADDRESS':
        return 'O endereço Bitcoin não pertence à rede configurada para esta carteira ou é inválido.';
      case 'ERR_CUSTODY_PROVIDER_UNAVAILABLE':
        return 'A rota externa necessária não está operacional neste ambiente no momento.';

      // Notifications & System Errors
      case 'ERR_NOTIF_MISSING_TOKEN':
        return l10n.errNotifMissingToken;
      case 'ERR_NOTIF_MISSING_FIELDS':
        return l10n.errNotifMissingFields;
      case 'ERR_INTERNAL_SERVER':
        return l10n.errInternalServer;
    }

    // Fallback translations based on message content
    String messageToReturn = extractedMessage ?? codeOrMessage;
    final lower = messageToReturn.toLowerCase();

    if (lower.contains('invalid credentials') ||
        lower.contains('wrong password')) {
      return l10n.errAuthInvalidCredentials;
    }
    if (lower.contains('totp') &&
        (lower.contains('expired') ||
            lower.contains('incorrect') ||
            lower.contains('invalid'))) {
      return l10n.errAuthIncorrectTotp;
    }
    if (lower.contains('already exists')) {
      return l10n.errAuthUserAlreadyExists;
    }
    if (lower.contains('insufficient balance') ||
        lower.contains('not enough funds')) {
      return l10n.errLedgerInsufficientBalance;
    }
    if (lower.contains('unauthorized') ||
        lower.contains('token expired') ||
        lower.contains('invalid token')) {
      return l10n.errSessionExpired;
    }
    if (lower.contains('unrecognized device') ||
        lower.contains('device has not been linked') ||
        lower.contains('device not linked')) {
      return _passkeyDeviceNotLinkedMessage(l10n);
    }
    if (lower.contains('forbidden') || lower.contains('access denied')) {
      return l10n.errForbidden;
    }
    if (lower.contains('too many signup attempts')) {
      return l10n.errTooManySignupAttempts;
    }
    if (lower.contains('localauthexception(code nocredentialsset') ||
        lower.contains('localauthexception(code nobiometricsenrolled') ||
        lower.contains('localauthexception(code nobiometrichardware')) {
      return l10n.passkeyNoBiometrics;
    }
    if (lower.contains('localauthexception(code usercanceled') ||
        lower.contains('localauthexception(code systemcanceled') ||
        lower.contains('localauthexception(code userrequestedfallback')) {
      return l10n.passkeyAuthFailed;
    }
    if (lower.contains('connection refused') ||
        lower.contains('network is unreachable')) {
      return l10n.errNoInternet;
    }
    if (lower.contains('timeout') || lower.contains('deadline exceeded')) {
      return l10n.errTimeout;
    }
    if (lower.contains('challenge expired')) {
      return l10n.errTimeout;
    }
    if (lower.contains('format exception') ||
        lower.contains('unexpected character')) {
      return l10n.errCommFailure;
    }
    if (lower.contains('no sovereign key is registered') ||
        lower.contains('register the device first') ||
        lower.contains('invalid passkey signature') ||
        lower.contains('proof of possession failed')) {
      return _passkeyDeviceNotLinkedMessage(l10n);
    }
    if (lower.contains('passkey enviada nao esta vinculada') ||
        lower.contains('passkey foi vinculada a outro login') ||
        lower.contains('contador do autenticador nao avancou')) {
      return _passkeyActionMessage(
        l10n,
        extractedData,
        fallbackPt:
            'Entre com senha + TOTP e vincule uma passkey compatível com este dispositivo.',
        fallbackEn:
            'Sign in with passphrase + TOTP and link a passkey compatible with this device.',
        fallbackEs:
            'Entra con frase secreta + TOTP y vincula una passkey compatible con este dispositivo.',
      );
    }
    if ((lower.contains('receiver') && lower.contains('not found')) ||
        lower.contains('wallet, username, or address') ||
        (lower.contains('destination') && lower.contains('does not exist'))) {
      return l10n.addressNotAvailable;
    }
    if (lower.contains('not found')) {
      return l10n.errLedgerNotFound;
    }
    if (lower.contains('invalid address') ||
        lower.contains('bitcoin address')) {
      return l10n.errInvalidBtcAddress;
    }

    if (extractedMessage != null &&
        extractedMessage.isNotEmpty &&
        extractedMessage != 'null') {
      if (extractedMessage.contains(' ') || extractedMessage.length < 40) {
        return extractedMessage;
      }
    }

    if (codeOrMessage.length > 80 && !codeOrMessage.contains(' ')) {
      return l10n.errUnexpected;
    }
    return codeOrMessage
        .replaceFirst('ServerException:', '')
        .replaceFirst('Exception:', '')
        .replaceFirst('Erro:', '')
        .trim();
  }

  static String _passkeyDeviceNotLinkedMessage(AppLocalizations l10n) {
    switch (l10n.localeName) {
      case 'en':
        return 'This device is not linked to your account for passkey confirmation. Link this device and try again.';
      case 'es':
        return 'Este dispositivo no está vinculado a tu cuenta para confirmar con passkey. Vincula este dispositivo e inténtalo de nuevo.';
      default:
        return 'Este dispositivo não está vinculado à sua conta para confirmar com passkey. Vincule este aparelho e tente novamente.';
    }
  }

  static String _passkeyActionMessage(
    AppLocalizations l10n,
    Map<String, dynamic>? data, {
    required String fallbackPt,
    required String fallbackEn,
    required String fallbackEs,
  }) {
    final guidance = data?['guidance']?.toString().trim();
    if (guidance != null && guidance.isNotEmpty) {
      return guidance;
    }

    switch (l10n.localeName) {
      case 'en':
        return fallbackEn;
      case 'es':
        return fallbackEs;
      default:
        return fallbackPt;
    }
  }

  static Map<String, dynamic>? _mapFromDynamic(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
