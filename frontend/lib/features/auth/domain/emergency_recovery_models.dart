class EmergencyRecoveryStartDraft {
  final String username;
  final String newPassphrase;
  final List<String> recoveryCodes;

  const EmergencyRecoveryStartDraft({
    required this.username,
    required this.newPassphrase,
    required this.recoveryCodes,
  });
}

class EmergencyRecoveryStartResult {
  final String recoverySessionId;
  final String otpUri;
  final String passkeyChallenge;
  final int expiresInSeconds;
  final int requiredRecoveryCodes;

  const EmergencyRecoveryStartResult({
    required this.recoverySessionId,
    required this.otpUri,
    required this.passkeyChallenge,
    required this.expiresInSeconds,
    required this.requiredRecoveryCodes,
  });

  factory EmergencyRecoveryStartResult.fromJson(Map<String, dynamic> json) {
    return EmergencyRecoveryStartResult(
      recoverySessionId: json['recoverySessionId']?.toString() ?? '',
      otpUri: json['otpUri']?.toString() ?? '',
      passkeyChallenge: json['passkeyChallenge']?.toString() ?? '',
      expiresInSeconds: _intFrom(json['expiresInSeconds']),
      requiredRecoveryCodes: _intFrom(json['requiredRecoveryCodes']),
    );
  }

  bool get isUsable =>
      recoverySessionId.isNotEmpty &&
      otpUri.isNotEmpty &&
      passkeyChallenge.isNotEmpty;
}

class EmergencyRecoveryFinishResult {
  final String username;
  final List<String> newBackupCodes;

  const EmergencyRecoveryFinishResult({
    required this.username,
    required this.newBackupCodes,
  });

  factory EmergencyRecoveryFinishResult.fromJson(Map<String, dynamic> json) {
    return EmergencyRecoveryFinishResult(
      username: json['username']?.toString() ?? '',
      newBackupCodes: _stringList(json['newBackupCodes']),
    );
  }
}

int _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}
