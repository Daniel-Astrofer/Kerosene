import 'dart:convert';

import 'package:kerosene/core/l10n/app_localizations.dart';

class ErrorTranslator {
  static String translate(AppLocalizations l10n, String codeOrMessage) {
    if (codeOrMessage.isEmpty) return l10n.errUnexpected;

    String codeToTest = codeOrMessage;
    String? extractedMessage;

    // Try to parse JSON from AppException.toString()
    try {
      final decoded = jsonDecode(codeOrMessage);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final guidance = data['guidance']?.toString().trim();
          if (guidance != null &&
              guidance.isNotEmpty &&
              !_looksTechnical(guidance)) {
            return guidance;
          }
        }
        extractedMessage = decoded['message']?.toString();
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

    final sovereignCode = RegExp(
      r'SovereignAuthException\((ERR_[A-Z0-9_]+)\)',
    ).firstMatch(codeOrMessage);
    if (sovereignCode != null) {
      codeToTest = sovereignCode.group(1) ?? codeToTest;
    }

    final normalizedCode = codeToTest.trim().toUpperCase();
    final safeExtractedMessage = _safeUserMessage(extractedMessage);

    // Check for exact known Error Codes explicitly
    switch (normalizedCode) {
      // Auth Errors
      case 'AUTH_001':
      case 'ERR_AUTH_USER_ALREADY_EXISTS':
        return l10n.errAuthUserAlreadyExists;
      case 'AUTH_002':
      case 'ERR_AUTH_USERNAME_MISSING':
        return l10n.errAuthUsernameMissing;
      case 'AUTH_003':
      case 'ERR_AUTH_PASSPHRASE_MISSING':
      case 'ERR_AUTH_PASSWORD_MISSING':
        return l10n.errAuthPassphraseMissing;
      case 'AUTH_004':
      case 'ERR_AUTH_INVALID_USERNAME_FORMAT':
        return l10n.errAuthInvalidUsernameFormat;
      case 'AUTH_005':
      case 'ERR_AUTH_CHARACTER_LIMIT_EXCEEDED':
        return l10n.errAuthCharLimitExceeded;
      case 'AUTH_006':
      case 'ERR_AUTH_USER_NOT_FOUND':
        return l10n.errAuthUserNotFound;
      case 'AUTH_007':
      case 'ERR_AUTH_INVALID_PASSPHRASE_FORMAT':
      case 'ERR_AUTH_INVALID_PASSWORD_FORMAT':
        return l10n.errAuthInvalidPassphraseFormat;
      case 'AUTH_008':
      case 'ERR_AUTH_INCORRECT_TOTP':
        return l10n.errAuthIncorrectTotp;
      case 'AUTH_009':
      case 'ERR_AUTH_INVALID_CREDENTIALS':
        return l10n.errAuthInvalidCredentials;
      case 'AUTH_010':
      case 'ERR_AUTH_UNRECOGNIZED_DEVICE':
      case 'ERR_AUTH_PASSKEY_NOT_REGISTERED':
        return l10n.errPasskeyDeviceNotLinked;
      case 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS':
        return l10n.passkeyNoBiometrics;
      case 'AUTH_011':
      case 'ERR_AUTH_TOTP_TIMEOUT':
        return l10n.errAuthTotpTimeout;
      case 'AUTH_012':
      case 'ERR_AUTH_PASSKEY_CHALLENGE':
        return l10n.errPasskeyRequired;
      case 'AUTH_013':
        return l10n.errSessionExpired;
      case 'AUTH_014':
      case 'ERR_AUTH_PASSKEY_LINK_REQUIRED':
        return l10n.errPasskeyDeviceNotLinked;
      case 'AUTH_015':
      case 'ERR_AUTH_PASSKEY_ASSERTION_FAILED':
        return l10n.errPasskeyRejected;
      case 'AUTH_016':
      case 'ERR_AUTH_PASSKEY_REPLAY':
        return l10n.errPasskeyRejected;
      case 'AUTH_017':
      case 'ERR_AUTH_PASSKEY_CREDENTIAL_NOT_FOUND':
        return l10n.errPasskeyDeviceNotLinked;
      case 'AUTH_018':
      case 'ERR_AUTH_APP_PIN_NOT_CONFIGURED':
        return l10n.appEntryPinUnavailableMessage;
      case 'AUTH_019':
      case 'ERR_AUTH_APP_PIN_INVALID':
        return l10n.errAuthInvalidCredentials;
      case 'AUTH_020':
      case 'ERR_AUTH_APP_PIN_LOCKED':
        return l10n.appEntryLockedHelper;
      case 'AUTH_021':
      case 'ERR_AUTH_APP_PIN_DEVICE_REQUIRED':
        return l10n.appEntryPinUnavailableMessage;
      case 'AUTH_022':
      case 'ERR_AUTH_PASSKEY_INVALID_ORIGIN':
        return l10n.errPasskeyRejected;
      case 'AUTH_099':
      case 'ERR_AUTH_GENERIC':
        return l10n.errUnexpected;
      case 'ERR_AUTH_PASSKEY_INVALID':
        return l10n.passkeyErrorFinishing(
            l10n.errUnexpected); // Fallback to generic message
      case 'ERR_AUTH_PASSKEY_TIMEOUT':
        return l10n.errTimeout;
      case 'ERR_AUTH_PASSKEY_ALREADY_REGISTERED':
        return l10n.errAuthUserAlreadyExists;
      case 'ERR_AUTH_SESSION_NOT_FOUND':
        return l10n.passkeySessionNotFound;

      // Ledger / Balance Errors
      case 'LEDGER_001':
      case 'ERR_LEDGER_NOT_FOUND':
        return l10n.errLedgerNotFound;
      case 'LEDGER_003':
      case 'ERR_LEDGER_ALREADY_EXISTS':
        return l10n.errLedgerAlreadyExists;
      case 'LEDGER_004':
      case 'ERR_LEDGER_INSUFFICIENT_BALANCE':
        return l10n.errLedgerInsufficientBalance;
      case 'LEDGER_005':
      case 'ERR_LEDGER_INVALID_OPERATION':
        return l10n.errLedgerInvalidOperation;
      case 'LEDGER_002':
      case 'ERR_LEDGER_RECEIVER_NOT_FOUND':
        return l10n.errLedgerReceiverNotFound;
      case 'LEDGER_099':
      case 'ERR_LEDGER_GENERIC':
        return l10n.errLedgerGeneric;
      case 'LEDGER_006':
      case 'ERR_LEDGER_PAYMENT_REQUEST_NOT_FOUND':
      case 'ERR_LEDGER_PAYMENT_NOT_FOUND':
        return l10n.errLedgerPaymentRequestNotFound;
      case 'LEDGER_007':
      case 'ERR_LEDGER_PAYMENT_REQUEST_EXPIRED':
      case 'ERR_LEDGER_PAYMENT_EXPIRED':
        return l10n.errLedgerPaymentRequestExpired;
      case 'LEDGER_008':
      case 'ERR_LEDGER_PAYMENT_REQUEST_ALREADY_PAID':
      case 'ERR_LEDGER_PAYMENT_ALREADY_PAID':
        return l10n.errLedgerPaymentRequestAlreadyPaid;
      case 'LEDGER_009':
      case 'ERR_LEDGER_PAYMENT_REQUEST_SELF_PAY':
      case 'ERR_LEDGER_PAYMENT_SELF_PAY':
        return l10n.errLedgerPaymentRequestSelfPay;

      // Wallet Errors
      case 'WALLET_001':
      case 'ERR_WALLET_ALREADY_EXISTS':
        return l10n.errWalletAlreadyExists;
      case 'WALLET_002':
      case 'ERR_WALLET_NOT_FOUND':
        return l10n.errWalletNotFound;
      case 'WALLET_099':
      case 'ERR_WALLET_GENERIC':
        return l10n.errWalletGeneric;

      // Notifications & System Errors
      case 'ERR_NOTIF_MISSING_TOKEN':
        return l10n.errNotifMissingToken;
      case 'ERR_NOTIF_MISSING_FIELDS':
        return l10n.errNotifMissingFields;
      case 'SYS_001':
        return safeExtractedMessage ?? l10n.errUnexpected;
      case 'SYS_002':
        return safeExtractedMessage ?? l10n.errUnexpected;
      case 'SYS_404':
        return safeExtractedMessage ?? l10n.errUnexpected;
      case 'SYS_500':
      case 'ERR_INTERNAL_SERVER':
        return l10n.errInternalServer;
      case 'HYDRA_001':
      case 'VAULT_001':
      case 'KRS_099':
        return l10n.errInternalServer;

      // Payment rail errors
      case 'LIGHTNING_INSUFFICIENT_LIQUIDITY':
        return l10n.errLightningInsufficientLiquidity;
      case 'LIGHTNING_ROUTE_NOT_FOUND':
        return l10n.errLightningRouteNotFound;
      case 'LIGHTNING_RECEIVER_METHOD_NOT_FOUND':
        return l10n.errLightningReceiverMethodNotFound;
      case 'ONCHAIN_RECEIVER_METHOD_NOT_FOUND':
        return l10n.errOnchainReceiverMethodNotFound;
      case 'QUOTE_EXPIRED':
        return l10n.errQuoteExpired;
      case 'QUOTE_CHANGED':
        return l10n.errQuoteChanged;
    }

    // Fallback translations based on message content
    String messageToReturn = extractedMessage ?? codeOrMessage;
    final lower = messageToReturn.toLowerCase();

    if (_looksTechnical(messageToReturn) ||
        (extractedMessage == null && _looksTechnical(codeOrMessage))) {
      return l10n.errUnexpected;
    }

    if (lower.contains('passkey') &&
        (lower.contains('not registered') ||
            lower.contains('not linked') ||
            lower.contains('unrecognized device') ||
            lower.contains('nenhuma passkey'))) {
      return l10n.errPasskeyDeviceNotLinked;
    }

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
    if (lower.contains('not found')) {
      return l10n.errLedgerNotFound;
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
    if (lower.contains('forbidden') || lower.contains('access denied')) {
      return l10n.errForbidden;
    }
    if (lower.contains('too many signup attempts')) {
      return l10n.errTooManySignupAttempts;
    }
    if (lower.contains('connection refused') ||
        lower.contains('network is unreachable')) {
      return l10n.errNoInternet;
    }
    if (lower.contains('timeout') || lower.contains('deadline exceeded')) {
      return l10n.errTimeout;
    }
    if (lower.contains('format exception') ||
        lower.contains('unexpected character')) {
      return l10n.errCommFailure;
    }
    if (lower.contains('invalid address') ||
        lower.contains('bitcoin address')) {
      return l10n.errInvalidBtcAddress;
    }

    if (safeExtractedMessage != null &&
        (safeExtractedMessage.contains(' ') ||
            safeExtractedMessage.length < 40)) {
      return safeExtractedMessage;
    }

    final cleaned = codeOrMessage
        .replaceFirst('ServerException:', '')
        .replaceFirst('ValidationException:', '')
        .replaceFirst('AuthException:', '')
        .replaceFirst('AppException:', '')
        .replaceFirst('Exception:', '')
        .replaceFirst('Erro:', '')
        .trim();

    if (codeOrMessage.length > 80 && !codeOrMessage.contains(' ')) {
      return l10n.errUnexpected;
    }
    if (cleaned.isEmpty || _looksTechnical(cleaned)) {
      return l10n.errUnexpected;
    }

    return cleaned;
  }

  static String? _safeUserMessage(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'null') {
      return null;
    }
    if (_looksTechnical(trimmed)) {
      return null;
    }
    return trimmed;
  }

  static bool _looksTechnical(String value) {
    final lower = value.toLowerCase();
    final technicalPattern = RegExp(
      r'(statuscode|status code|status_code|status=|http\s*\d{3}|errorcode|error code|error_code|dioexception|serverexception|validationexception|authexception|appexception|stack trace|traceback|requestoptions|response\.data|/api/|invalid payload|<!doctype html|<html|socketexception|handshakeexception|xmlhttprequest)',
      caseSensitive: false,
    );

    if (technicalPattern.hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\bERR_[A-Z0-9_]+\b').hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\b[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+\b').hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\b[45]\d{2}\b').hasMatch(value) &&
        (lower.contains('http') ||
            lower.contains('status') ||
            lower.contains('code'))) {
      return true;
    }

    return value.length > 220 && RegExp(r'[{}\[\]"]|=>|#\d+').hasMatch(value);
  }
}
