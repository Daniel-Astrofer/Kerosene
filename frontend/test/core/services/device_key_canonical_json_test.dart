import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/services/device_key_service.dart';

void main() {
  test('canonical JSON matches backend fixed vector', () {
    final canonical = DeviceKeyService().canonicalJsonForTesting({
      'version': 1,
      'username': 'alice',
      'type': 'REGISTER_DEVICE_KEY',
      'sessionId': 'signup-session-1',
      'publicKeySha256': 'If4x36FUomFia_hUBG_SJxt77UtqvkWqWId-9H-XIbk',
      'onionServiceId': 'kerosene-device',
      'issuedAtEpochSeconds': 1234567890,
      'deviceInstallId': 'device-install-0001',
      'credentialId': 'PLgXnnKy4uLf-5HloFqIqTOTkE41AY1uQaBevvikXCg',
      'counter': 1,
      'challengeId': '11111111-2222-3333-4444-555555555555',
      'challenge': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'algorithm': 'Ed25519',
    });

    expect(
      canonical,
      '{"algorithm":"Ed25519","challenge":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","challengeId":"11111111-2222-3333-4444-555555555555","counter":1,"credentialId":"PLgXnnKy4uLf-5HloFqIqTOTkE41AY1uQaBevvikXCg","deviceInstallId":"device-install-0001","issuedAtEpochSeconds":1234567890,"onionServiceId":"kerosene-device","publicKeySha256":"If4x36FUomFia_hUBG_SJxt77UtqvkWqWId-9H-XIbk","sessionId":"signup-session-1","type":"REGISTER_DEVICE_KEY","username":"alice","version":1}',
    );
  });
}
