import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/domain/entities/passkey_inventory.dart';

void main() {
  group('AccountSecurityProfile', () {
    test('parses nested passkey inventory from backend profile', () {
      final profile = AccountSecurityProfile.fromJson({
        'accountSecurity': 'PASSKEY',
        'multisigThreshold': 2,
        'passkeyAvailable': true,
        'passkeyEnabledForTransactions': true,
        'requiredFactors': ['PASSKEY'],
        'passkeys': {
          'passkeyRegistered': true,
          'compatibleForCurrentLogin': false,
          'legacyCredentialsPresent': true,
          'currentRelyingPartyId': 'app.kerosene.test',
          'currentHost': 'app.kerosene.test',
          'devices': [
            {
              'credentialId': 'cred-123',
              'deviceName': 'Pixel 9',
              'relyingPartyId': 'app.kerosene.test',
              'originHost': 'app.kerosene.test',
              'compatibilityStatus': 'INCOMPATIBLE',
              'compatibleWithCurrentLogin': false,
            },
          ],
        },
      });

      expect(profile.mode, AccountSecurityMode.passkey);
      expect(profile.passkeyAvailable, isTrue);
      expect(profile.passkeyEnabledForTransactions, isTrue);
      expect(profile.passkeys, isNotNull);
      expect(profile.passkeys!.passkeyRegistered, isTrue);
      expect(profile.passkeys!.compatibleForCurrentLogin, isFalse);
      expect(profile.passkeys!.legacyCredentialsPresent, isTrue);
      expect(profile.passkeys!.currentHost, 'app.kerosene.test');
      expect(profile.passkeys!.devices, hasLength(1));
      expect(profile.passkeys!.devices.first.deviceName, 'Pixel 9');
      expect(
        profile.passkeys!.devices.first.compatibilityStatus,
        PasskeyCompatibilityStatus.incompatible,
      );
    });
  });
}
