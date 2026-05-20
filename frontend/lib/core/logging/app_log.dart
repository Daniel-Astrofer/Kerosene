String sanitizeLogMessage(Object? message) {
  var sanitized = '$message';

  final replacements = <RegExp, String>{
    RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false):
        'Bearer [REDACTED]',
    RegExp(r'\b(token|secret|challenge)=([^\s&]+)', caseSensitive: false):
        r'$1=[REDACTED]',
    RegExp(r'\bmnemonic=[^\n]+?(?=\s(?:secret|token|challenge)=|$)',
        caseSensitive: false): 'mnemonic=[REDACTED]',
    RegExp(r'otpauth://[^\s]+', caseSensitive: false): '[REDACTED]',
    RegExp(r'\bbc1[a-z0-9]{20,90}\b', caseSensitive: false): 'bc1...[REDACTED]',
    RegExp(r'\bln(?:bc|tb|bcrt)[a-z0-9]{20,}\b', caseSensitive: false):
        'lnbc...[REDACTED]',
  };

  for (final entry in replacements.entries) {
    sanitized = sanitized.replaceAllMapped(
      entry.key,
      (match) => entry.value.replaceAllMapped(
        RegExp(r'\$(\d+)'),
        (group) => match.group(int.parse(group.group(1)!)) ?? '',
      ),
    );
  }

  return sanitized;
}

void appLog(Object? message) {
  // Keep logging opt-in and sanitized at the boundary.
  // ignore: avoid_print
  print(sanitizeLogMessage(message));
}
