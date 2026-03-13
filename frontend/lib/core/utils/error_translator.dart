import 'dart:convert';
import 'package:teste/l10n/app_localizations.dart';

class ErrorTranslator {
  static String translate(AppLocalizations l10n, String codeOrMessage) {
    if (codeOrMessage.isEmpty) return l10n.errUnexpected;

    String codeToTest = codeOrMessage;
    String? extractedMessage;

    // Try to parse JSON from AppException.toString()
    try {
      final decoded = jsonDecode(codeOrMessage);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'AppException') {
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
        return l10n.errAuthUnrecognizedDevice;
      case 'ERR_AUTH_TOTP_TIMEOUT':
        return l10n.errAuthTotpTimeout;

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
        return l10n.errLedgerReceiverNotFound;
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
}
