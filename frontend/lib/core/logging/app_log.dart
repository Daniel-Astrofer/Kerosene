import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Installs one logging policy for the whole app.
///
/// Release builds never write diagnostic logs. Debug/profile logs are sanitized
/// before they reach platform log sinks.
void configureAppLogging() {
  debugPrint = (String? message, {int? wrapWidth}) {
    if (kReleaseMode || !AppConfig.enableLogs) {
      return;
    }

    final sanitized = sanitizeLogMessage(message ?? '');
    if (sanitized.trim().isEmpty) {
      return;
    }

    debugPrintThrottled(sanitized, wrapWidth: wrapWidth);
  };
}

@visibleForTesting
String sanitizeLogMessage(String message) {
  var sanitized = message;

  sanitized = sanitized.replaceAllMapped(
    RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
    (_) => 'Bearer [REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'\b(token|jwt|preAuthToken|refreshToken|sessionId|secret|totpSecret|totpCode|mnemonic|seed|passphrase|confirmationPassphrase|challenge)\b\s*[:=]\s*[^,\s}\]]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}=[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'(secret=)[^&\s]+', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'\bbc1[ac-hj-np-z02-9]{20,}\b', caseSensitive: false),
    (_) => 'bc1...[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'\blnbc[0-9a-z]{20,}\b', caseSensitive: false),
    (_) => 'lnbc...[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'\b[0-9a-f]{48,}\b', caseSensitive: false),
    (_) => '[HEX_REDACTED]',
  );

  return sanitized;
}
