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
      r'(ERR_[A-Z0-9_]+|[A-Z]+_\d{3}|ONCHAIN_[A-Z0-9_]+|LIGHTNING_[A-Z0-9_]+|QUOTE_[A-Z0-9_]+|RECEIVER_NOT_READY|NET_AMOUNT_NEGATIVE|AMOUNT_NET_NEGATIVE|INSUFFICIENT_BALANCE_FOR_FEES|USER_NOT_FOUND|AUTH_FAILED|INVALID_SIGNATURE|VERIFY_ERROR|MISSING_CREDENTIAL_ID|CHALLENGE_EXPIRED)',
    ).firstMatch(codeOrMessage);
    if (internalCodeMatch != null && internalCodeMatch.group(0) != null) {
      codeToTest = internalCodeMatch.group(0)!;
    }

    final code = _normalizeCode(codeToTest);

    // Check for exact known Error Codes explicitly
    switch (code) {
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
        return l10n.errPasskeyDeviceNotLinked;
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
        return l10n.errPasskeyDeviceNotLinked;
      case 'AUTH_012':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallback: l10n.errPasskeyRequired,
        );
      case 'AUTH_014':
      case 'AUTH_017':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallback: l10n.errPasskeyWrongDevice,
        );
      case 'AUTH_015':
      case 'AUTH_016':
        return _passkeyActionMessage(
          l10n,
          extractedData,
          fallback: l10n.errPasskeyRejected,
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
        return l10n.errRecoveryBadRequest;
      case 'RECOVERY_REJECTED':
        return l10n.errRecoveryRejected;
      case 'RECOVERY_SESSION_EXPIRED':
        return l10n.errRecoverySessionExpired;
      case 'RECOVERY_RATE_LIMITED':
        return l10n.errRecoveryRateLimited;

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
        return l10n.errInvalidNetworkAddress;
      case 'ERR_CUSTODY_PROVIDER_UNAVAILABLE':
        return l10n.errCustodyProviderUnavailable;
      case 'ERR_PAYLOAD_TOO_LARGE':
        return l10n.errPayloadTooLarge;

      // Payment rail / quote errors
      case 'RECEIVER_NOT_READY':
        return l10n.errReceiverNotReady;
      case 'ONCHAIN_RECEIVER_METHOD_NOT_FOUND':
        return l10n.errOnchainReceiverMethodNotFound;
      case 'ONCHAIN_INVALID_ADDRESS':
        return l10n.errOnchainInvalidAddress;
      case 'ONCHAIN_AMOUNT_BELOW_DUST':
        return l10n.errOnchainAmountBelowDust;
      case 'ONCHAIN_INSUFFICIENT_FUNDS_FOR_FEE':
        return l10n.errOnchainInsufficientFundsForFee;
      case 'LIGHTNING_INSUFFICIENT_LIQUIDITY':
        return l10n.errLightningInsufficientLiquidity;
      case 'LIGHTNING_ROUTE_NOT_FOUND':
        return l10n.errLightningRouteNotFound;
      case 'LIGHTNING_RECEIVER_METHOD_NOT_FOUND':
        return l10n.errLightningReceiverMethodNotFound;
      case 'QUOTE_EXPIRED':
        return l10n.errQuoteExpired;
      case 'QUOTE_CHANGED':
        return l10n.errQuoteChanged;
      case 'NET_AMOUNT_NEGATIVE':
      case 'AMOUNT_NET_NEGATIVE':
        return l10n.errNetAmountNegative;
      case 'INSUFFICIENT_BALANCE_FOR_FEES':
        return l10n.errInsufficientBalanceForFees;

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
      return l10n.errPasskeyDeviceNotLinked;
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
      return l10n.errPasskeyDeviceNotLinked;
    }
    if (lower.contains('passkey enviada nao esta vinculada') ||
        lower.contains('passkey foi vinculada a outro login') ||
        lower.contains('contador do autenticador nao avancou')) {
      return _passkeyActionMessage(
        l10n,
        extractedData,
        fallback: l10n.errPasskeyLinkGuidance,
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
        extractedMessage != 'null' &&
        !_containsTechnicalTerms(extractedMessage)) {
      if (extractedMessage.contains(' ') || extractedMessage.length < 40) {
        return extractedMessage;
      }
    }

    if (_containsTechnicalTerms(codeOrMessage)) {
      return l10n.errUnexpected;
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

  static bool _containsTechnicalTerms(String value) {
    final lower = value.toLowerCase();
    return lower.contains('backend') ||
        lower.contains('serverexception') ||
        lower.contains('sovereignauthexception') ||
        lower.contains('dioexception') ||
        lower.contains('stack') ||
        lower.contains('payload') ||
        lower.contains('endpoint') ||
        lower.contains('/api/') ||
        lower.contains('dto') ||
        lower.contains('null pointer');
  }

  static String _passkeyActionMessage(
    AppLocalizations l10n,
    Map<String, dynamic>? data, {
    required String fallback,
  }) {
    final guidance = data?['guidance']?.toString().trim();
    if (l10n.localeName == 'pt' &&
        guidance != null &&
        guidance.isNotEmpty &&
        !_containsTechnicalTerms(guidance)) {
      return guidance;
    }

    return fallback;
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

  static String _normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll('-', '_');
  }
}
