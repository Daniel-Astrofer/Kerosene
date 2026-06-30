import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/services/passkey_service.dart';
import 'package:kerosene/core/services/sovereign_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePasskeyCryptographyService implements PasskeyCryptographyService {
  final Uint8List publicKey;
  Uint8List? credentialId;
  String? lastSubject;
  int counter = 0;

  _FakePasskeyCryptographyService({
    required this.publicKey,
  });

  @override
  Future<Uint8List> generateKeyPair({
    String? subject,
    Uint8List? credentialId,
  }) async {
    lastSubject = subject;
    this.credentialId = credentialId;
    return publicKey;
  }

  @override
  Future<Uint8List?> getCredentialId({String? subject}) async {
    lastSubject = subject;
    return credentialId;
  }

  @override
  Future<Uint8List?> getPublicKey({String? subject}) async {
    lastSubject = subject;
    return publicKey;
  }

  @override
  Future<bool> hasRegisteredKey({String? subject}) async {
    lastSubject = subject;
    return true;
  }

  @override
  Future<String> getDeviceName() async => 'Test Device';

  @override
  Future<int> nextSignatureCounter({String? subject}) async {
    lastSubject = subject;
    counter++;
    return counter;
  }

  @override
  Future<Uint8List> signBytes(
    Uint8List data, {
    String? localizedReason,
    String? subject,
  }) async {
    lastSubject = subject;
    return Uint8List.fromList(List<int>.generate(64, (index) => index));
  }

  @override
  Future<String> signChallenge(String hexChallenge, {String? subject}) async {
    lastSubject = subject;
    return base64Encode(Uint8List.fromList([1, 2, 3]));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('PasskeyService', () {
    test('registers and authenticates with a persisted credential id',
        () async {
      final publicKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final crypto = _FakePasskeyCryptographyService(publicKey: publicKey);
      final service = PasskeyService(cryptographyService: crypto);

      final registration = await service.register(
        challengeHex: 'a' * 64,
        username: ' Alice ',
      );
      final registeredCredentialId =
          base64Decode(registration['credentialId'] as String);

      expect(registeredCredentialId, isNot(orderedEquals(publicKey)));
      expect(registeredCredentialId, orderedEquals(crypto.credentialId!));

      final authentication = await service.authenticate(
        challengeHex: 'b' * 64,
        username: 'ALICE',
      );

      expect(
        base64Decode(authentication['credentialId'] as String),
        orderedEquals(registeredCredentialId),
      );
      expect(crypto.lastSubject, 'alice');
    });

    test('falls back to public key as credential id for legacy storage',
        () async {
      final publicKey = Uint8List.fromList(List<int>.filled(32, 7));
      final crypto = _FakePasskeyCryptographyService(publicKey: publicKey);
      final service = PasskeyService(cryptographyService: crypto);

      final authentication = await service.authenticate(
        challengeHex: 'c' * 64,
        username: 'kerosene',
      );

      expect(
        base64Decode(authentication['credentialId'] as String),
        orderedEquals(publicKey),
      );
    });
  });
}
