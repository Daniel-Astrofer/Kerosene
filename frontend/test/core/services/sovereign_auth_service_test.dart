import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/services/sovereign_auth_service.dart';

class _InMemorySovereignKeyStore implements SovereignKeyStore {
  Uint8List? privateKeySeed;
  Uint8List? publicKey;
  int signatureCounter = 0;
  int saveCalls = 0;

  @override
  Future<void> saveKeyMaterial({
    required Uint8List privateKeySeed,
    required Uint8List publicKey,
  }) async {
    saveCalls++;
    this.privateKeySeed = Uint8List.fromList(privateKeySeed);
    this.publicKey = Uint8List.fromList(publicKey);
    signatureCounter = 0;
  }

  @override
  Future<Uint8List?> readPrivateKeySeed() async {
    if (privateKeySeed == null) {
      return null;
    }
    return Uint8List.fromList(privateKeySeed!);
  }

  @override
  Future<Uint8List?> readPublicKey() async {
    if (publicKey == null) {
      return null;
    }
    return Uint8List.fromList(publicKey!);
  }

  @override
  Future<int> nextSignatureCounter() async {
    signatureCounter++;
    return signatureCounter;
  }
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
      expect(keyStore.privateKeySeed, isNotNull);
      expect(
        generatedPublicKey,
        orderedEquals(keyStore.publicKey!),
      );
      expect(
        await service.getPublicKey(),
        orderedEquals(keyStore.publicKey!),
      );
      expect(await service.hasRegisteredKey(), isTrue);
      expect(await service.getDeviceName(), 'Test Device');
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
      expect(keyStore.signatureCounter, 2);
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
