// ignore_for_file: depend_on_referenced_packages

import 'package:kerosene/features/auth/domain/emergency_recovery_models.dart';
import 'package:test/test.dart';

void main() {
  test('EmergencyRecoveryStartResult parses backend response', () {
    final result = EmergencyRecoveryStartResult.fromJson(const {
      'recoverySessionId': 'session-1',
      'otpUri': 'otpauth://totp/Kerosene:user',
      'passkeyChallenge':
          '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
      'expiresInSeconds': 600,
      'requiredRecoveryCodes': 3,
    });

    expect(result.recoverySessionId, 'session-1');
    expect(result.isUsable, isTrue);
    expect(result.expiresInSeconds, 600);
    expect(result.requiredRecoveryCodes, 3);
  });

  test('EmergencyRecoveryFinishResult keeps new backup codes', () {
    final result = EmergencyRecoveryFinishResult.fromJson(const {
      'username': 'satoshi',
      'newBackupCodes': ['12345678', '87654321', '00001111'],
    });

    expect(result.username, 'satoshi');
    expect(result.newBackupCodes, ['12345678', '87654321', '00001111']);
  });
}
