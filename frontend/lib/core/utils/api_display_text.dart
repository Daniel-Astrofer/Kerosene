import 'package:flutter/widgets.dart';
import 'package:teste/core/l10n/l10n_extension.dart';

class ApiDisplayText {
  const ApiDisplayText._();

  static String status(BuildContext context, Object? raw) {
    final l10n = context.tr;
    final value = _normalize(raw);
    return switch (value) {
      'ACTIVE' ||
      'READY' ||
      'ONLINE' ||
      'UP' ||
      'VALID' ||
      'VERIFIED' =>
        l10n.apiDisplayActive,
      'PENDING' || 'WAITING' || 'QUEUED' => l10n.apiDisplayWaiting,
      'PROCESSING' ||
      'IN_PROGRESS' ||
      'VERIFYING' ||
      'VERIFYING_ONBOARDING' =>
        l10n.apiDisplayBeingChecked,
      'DETECTED' || 'MEMPOOL' || 'MEMPOOL_SEEN' => l10n.apiDisplayDetected,
      'CONFIRMING' => l10n.apiDisplayConfirming,
      'CONFIRMED' ||
      'COMPLETED' ||
      'CONCLUDED' ||
      'PAID' ||
      'SETTLED' =>
        l10n.apiDisplayCompleted,
      'EXPIRED' => l10n.apiDisplayExpired,
      'CANCELLED' || 'CANCELED' => l10n.apiDisplayCancelled,
      'FAILED' || 'ERROR' || 'INVALID' => l10n.apiDisplayNotCompleted,
      'BLOCKED' ||
      'DISABLED' ||
      'LOCKED' ||
      'FAILED_SAFE' =>
        l10n.apiDisplayProtected,
      'UNLOCKED' => l10n.apiDisplayAvailable,
      'OFFLINE' || 'DOWN' => l10n.apiDisplayUnavailable,
      'HEALTHY' => l10n.apiDisplayHealthy,
      'DEGRADED' ||
      'REBALANCE_REQUIRED' ||
      'BLOCKED_ONCHAIN_RESERVE' =>
        l10n.apiDisplayNeedsAttention,
      'USER_ACTION_REQUIRED' => l10n.apiDisplayActionNeeded,
      'AUTO_RESOLUTION_PENDING' => l10n.apiDisplayInReview,
      _ => l10n.apiDisplayBeingTracked,
    };
  }

  static String action(BuildContext context, Object? raw) {
    final l10n = context.tr;
    final value = _normalize(raw);
    return switch (value) {
      'AUTO_COMPLETE' || 'AUTO_RESOLUTION' => l10n.apiDisplayAutomatic,
      'USER_ACTION_REQUIRED' => l10n.apiDisplayManualConfirmation,
      'HIDDEN' => l10n.apiDisplayPrivate,
      'PUBLIC' => l10n.apiDisplayShareable,
      _ => status(context, raw),
    };
  }

  static String walletCustody(BuildContext context, Object? raw) {
    final l10n = context.tr;
    final value = _normalize(raw);
    return switch (value) {
      'WATCH_ONLY' || 'SELF_CUSTODY' => l10n.apiDisplayWatchedColdWallet,
      'KEROSENE_CUSTODIAL' ||
      'CUSTODIAL' ||
      'INTERNAL_CARD' =>
        l10n.apiDisplayKeroseneCard,
      _ => l10n.apiDisplayBitcoinWallet,
    };
  }

  static String securityFactor(BuildContext context, Object? raw) {
    final l10n = context.tr;
    final value = _normalize(raw);
    return switch (value) {
      'PASSKEY' => l10n.apiDisplayDeviceKey,
      'TOTP' => l10n.apiDisplayAuthenticatorCode,
      'PASSPHRASE' || 'PASSWORD' => l10n.apiDisplayAccessPassword,
      'SLIP39_SHARES' || 'RECOVERY_CODES' => l10n.apiDisplayRecoveryCodes,
      _ => l10n.apiDisplaySecureConfirmation,
    };
  }

  static String message(BuildContext context, Object? raw) {
    final l10n = context.tr;
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') {
      return l10n.apiDisplayGenericActionError;
    }

    final lower = text.toLowerCase();
    if (lower.contains('lightning unavailable') ||
        lower.contains('lightning indispon')) {
      return l10n.apiDisplayLightningUnavailable;
    }
    if (lower.contains('deposit') &&
        lower.contains('address') &&
        (lower.contains('not returned') || lower.contains('não retorn'))) {
      return l10n.apiDisplayDepositAddressCreateFailed;
    }
    if (lower.contains('challenge') || lower.contains('passkey')) {
      return l10n.apiDisplaySecureConfirmationStartFailed;
    }
    if (_containsTechnicalTerms(text)) {
      return l10n.apiDisplayGenericActionError;
    }

    final cleaned = text
        .replaceFirst('ServerException:', '')
        .replaceFirst('Exception:', '')
        .replaceFirst('Erro:', '')
        .trim();
    return cleaned.isEmpty ? l10n.apiDisplayGenericActionError : cleaned;
  }

  static bool _containsTechnicalTerms(String value) {
    final lower = value.toLowerCase();
    return lower.contains('server') ||
        lower.contains('servidor') ||
        lower.contains('backend') ||
        lower.contains('api') ||
        lower.contains('endpoint') ||
        lower.contains('payload') ||
        lower.contains('dto') ||
        lower.contains('statuscode') ||
        lower.contains('status code') ||
        lower.contains('status_code') ||
        lower.contains('errorcode') ||
        lower.contains('http 4') ||
        lower.contains('http 5') ||
        lower.contains('error_code') ||
        RegExp(r'\b[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+\b').hasMatch(value) ||
        lower.contains('stack') ||
        lower.contains('exception') ||
        lower.contains('null pointer') ||
        lower.contains('/api/');
  }

  static String _normalize(Object? raw) {
    return raw?.toString().trim().toUpperCase().replaceAll('-', '_') ?? '';
  }
}
