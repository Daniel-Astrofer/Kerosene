import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/services/sovereign_auth_service.dart';

class _InMemorySovereignKeyStore implements SovereignKeyStore {
  final Map<String, Uint8List> privateKeySeeds = {};
  final Map<String, Uint8List> publicKeys = {};
  final Map<String, Uint8List> credentialIds = {};
  final Map<String, int> signatureCounters = {};
  int saveCalls = 0;

  @override
  Future<void> saveKeyMaterial({
    required Uint8List privateKeySeed,
    required Uint8List publicKey,
    Uint8List? credentialId,
    String? subject,
  }) async {
    saveCalls++;
    final key = _key(subject);
    privateKeySeeds[key] = Uint8List.fromList(privateKeySeed);
    publicKeys[key] = Uint8List.fromList(publicKey);
    if (credentialId != null) {
      credentialIds[key] = Uint8List.fromList(credentialId);
    }
    signatureCounters[key] = 0;
  }

  @override
  Future<Uint8List?> readCredentialId({String? subject}) async {
    final credentialId = credentialIds[_key(subject)];
    if (credentialId == null) {
      return null;
    }
    return Uint8List.fromList(credentialId);
  }

  @override
  Future<Uint8List?> readPrivateKeySeed({String? subject}) async {
    final privateKeySeed = privateKeySeeds[_key(subject)];
    if (privateKeySeed == null) {
      return null;
    }
    return Uint8List.fromList(privateKeySeed);
  }

  @override
  Future<Uint8List?> readPublicKey({String? subject}) async {
    final publicKey = publicKeys[_key(subject)];
    if (publicKey == null) {
      return null;
    }
    return Uint8List.fromList(publicKey);
  }

  @override
  Future<int> nextSignatureCounter({String? subject}) async {
    final key = _key(subject);
    final next = (signatureCounters[key] ?? 0) + 1;
    signatureCounters[key] = next;
    return next;
  }

  String _key(String? subject) => subject ?? '';
}

class _SpyPresenceVerifier implements SovereignPresenceVerifier {
  int ensureCalls = 0;
  int verifyCalls = 0;
  String? lastReason;
  bool failEnsure = false;
  bool failVerify = false;

  @override
  Future<void> ensureLocalCredentialsAvailable() async {
    ensureCalls++;
    if (failEnsure) {
      throw const SovereignAuthException(
        code: SovereignAuthErrorCodes.noLocalCredentials,
        message: 'Local credentials are not configured.',
      );
    }
  }

  @override
  Future<void> verifyUserPresence({required String localizedReason}) async {
    verifyCalls++;
    lastReason = localizedReason;
    if (failVerify) {
      throw const SovereignAuthException(
        code: SovereignAuthErrorCodes.authCancelled,
        message: 'User cancelled authentication.',
      );
    }
  }
}

class _FixedDeviceNameProvider implements SovereignDeviceNameProvider {
  final String deviceName;

  const _FixedDeviceNameProvider(this.deviceName);

  @override
  Future<String> getDeviceName() async => deviceName;
}

void main() {
  late _InMemorySovereignKeyStore keyStore;
  late _SpyPresenceVerifier presenceVerifier;
  late SovereignAuthService service;

  setUp(() {
    keyStore = _InMemorySovereignKeyStore();
    presenceVerifier = _SpyPresenceVerifier();
    service = SovereignAuthService(
      keyStore: keyStore,
      presenceVerifier: presenceVerifier,
      deviceNameProvider: const _FixedDeviceNameProvider('Test Device'),
    );
  });

  group('SovereignAuthService', () {
    test('stores generated key material and exposes the saved public key',
        () async {
      final generatedPublicKey = await service.generateKeyPair();

      expect(presenceVerifier.ensureCalls, 1);
      expect(keyStore.saveCalls, 1);
      expect(keyStore.privateKeySeeds[''], isNotNull);
      expect(
        generatedPublicKey,
        orderedEquals(keyStore.publicKeys['']!),
      );
      expect(
        await service.getPublicKey(),
        orderedEquals(keyStore.publicKeys['']!),
      );
      expect(await service.hasRegisteredKey(), isTrue);
      expect(await service.getDeviceName(), 'Test Device');
    });

    test('stores generated key material independently per subject', () async {
      final firstCredentialId = Uint8List.fromList(List.filled(32, 1));
      final secondCredentialId = Uint8List.fromList(List.filled(32, 2));

      final firstKey = await service.generateKeyPair(
        subject: 'alice',
        credentialId: firstCredentialId,
      );
      final secondKey = await service.generateKeyPair(
        subject: 'bob',
        credentialId: secondCredentialId,
      );

      expect(firstKey, isNot(orderedEquals(secondKey)));
      expect(
        await service.getCredentialId(subject: 'alice'),
        orderedEquals(firstCredentialId),
      );
      expect(
        await service.getCredentialId(subject: 'bob'),
        orderedEquals(secondCredentialId),
      );
      expect(await service.hasRegisteredKey(subject: 'alice'), isTrue);
      expect(await service.hasRegisteredKey(subject: 'bob'), isTrue);
    });

    test('signs bytes using the stored seed after verifying user presence',
        () async {
      await service.generateKeyPair();

      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = await service.signBytes(payload);

      expect(presenceVerifier.verifyCalls, 1);
      expect(presenceVerifier.lastReason, isNotEmpty);
      expect(signature, isNotEmpty);
    });

    test('increments the signature counter through the injected store',
        () async {
      expect(await service.nextSignatureCounter(), 1);
      expect(await service.nextSignatureCounter(), 2);
      expect(keyStore.signatureCounters[''], 2);
    });

    test('throws a typed error when the challenge is not valid hex', () async {
      expect(
        () => service.signChallenge('zz-not-hex'),
        throwsA(
          isA<SovereignAuthException>().having(
            (error) => error.code,
            'code',
            SovereignAuthErrorCodes.invalidChallenge,
          ),
        ),
      );
    });

    test('throws a typed error when no key is registered on the device',
        () async {
      expect(
        () => service.signBytes(Uint8List.fromList([9, 9, 9])),
        throwsA(
          isA<SovereignAuthException>().having(
            (error) => error.code,
            'code',
            SovereignAuthErrorCodes.keyNotFound,
          ),
        ),
      );
    });
  });
}
