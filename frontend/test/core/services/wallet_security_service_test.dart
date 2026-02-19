import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:teste/core/services/wallet_security_service.dart';

// Generate Mocks
@GenerateMocks([FlutterSecureStorage, LocalAuthentication])
import 'wallet_security_service_test.mocks.dart';

void main() {
  late WalletSecurityService service;
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    service = WalletSecurityService(
      storage: mockStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('WalletSecurityService', () {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    test('saveMnemonic should call secure storage write', () async {
      when(
        mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        ),
      ).thenAnswer((_) async => null);

      final result = await service.saveMnemonic(mnemonic);

      expect(result, true);
      verify(
        mockStorage.write(
          key: 'secure_mnemonic',
          value: mnemonic,
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        ),
      ).called(1);
    });

    test('authenticateAndGetMnemonic returns mnemonic on success', () async {
      // Mock biometrics available
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

      // Mock auth success
      when(
        mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ),
      ).thenAnswer((_) async => true);

      // Mock storage read
      when(
        mockStorage.read(
          key: anyNamed('key'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        ),
      ).thenAnswer((_) async => mnemonic);

      final result = await service.authenticateAndGetMnemonic();

      expect(result, mnemonic);
    });

    test('authenticateAndGetMnemonic returns null on auth failure', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

      // Mock auth failure
      when(
        mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ),
      ).thenAnswer((_) async => false);

      final result = await service.authenticateAndGetMnemonic();

      expect(result, null);
      verifyNever(mockStorage.read(key: any, iOptions: any, aOptions: any));
    });

    // Test for signTransaction would require correct blockchain_utils mocking or just testing logic
    // Since signTransaction uses static/external libs for logic, we can test it if we trust the libs.
    // However, Bip32Slip10Secp256k1 logic is hard to mock without dependency injection for the factory.
    // We will skip testing signTransaction in unit tests for now or do a basic integration test if possible.
  });
}
