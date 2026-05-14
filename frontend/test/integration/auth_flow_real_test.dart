import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/core/providers/tor_providers.dart';
import 'package:teste/core/services/tor_service.dart';
import 'package:teste/main.dart' show sharedPreferencesProvider;
import 'package:uuid/uuid.dart';
import 'totp_utils.dart';

const _runRealOnionTests = bool.fromEnvironment('RUN_REAL_ONION_TESTS');

// Helper de PoW
String solvePoW(String challenge) {
  int nonce = 0;
  const prefix = '0000';
  while (true) {
    final input = '$challenge$nonce';
    final digest = crypto.sha256.convert(utf8.encode(input));
    final hash = digest.toString();
    if (hash.startsWith(prefix)) {
      return nonce.toString();
    }
    nonce++;
    if (nonce > 1000000) break;
  }
  return nonce.toString();
}

void main() {
  if (_runRealOnionTests) {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  } else {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  group('Full Auth Integration: PoW -> Signup -> TOTP -> Login -> JWT', () {
    late ProviderContainer container;
    late TorService torService;
    final String testUsername = 'test_${const Uuid().v4().substring(0, 8)}';
    final String testPassphrase = 'Password123!';
    String? totpSecret;
    String? preAuthToken;
    String? finalJwt;

    setUpAll(() async {
      // 2. Mock Path Provider (for Cookies)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        },
      );

      // 3. Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      torService = TorService.instance;

      container = ProviderContainer(
        overrides: [
          // IMPORTANT: Re-declaring the exact provider from main.dart to override it
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
      );

      debugPrint('🚀 [Setup] Initializing Tor Relay (Port 9999)...');
      final host = Uri.parse(AppConfig.onionBaseUrl).host;
      int relayPort;
      try {
        // Try standard relay first (port 9050 fallback in TorService)
        relayPort = await torService.startRelay(host, 80);
      } catch (e) {
        debugPrint(
            '⚠️ [Setup] TorService.startRelay failed, using manual relay on port 9999...');
        relayPort = await _manualStartRelay(9999, host, 80);
      }

      final testApiUrl = 'http://127.0.0.1:$relayPort';
      AppConfig.apiUrl = testApiUrl;
      container.read(torApiUrlProvider.notifier).updateUrl(testApiUrl);
      debugPrint('✅ [Setup] API Ready at $testApiUrl');
    });

    tearDownAll(() async {
      await torService.stop();
      container.dispose();
    });

    test('Step 1-3: Signup & PoW', () async {
      final apiClient = container.read(apiClientProvider);

      debugPrint('📡 [Auth] Requesting PoW Challenge...');
      final challengeRes = await apiClient.get(AppConfig.authPowChallenge);
      final challenge = challengeRes.data['challenge'];

      debugPrint('🧠 [Auth] Solving PoW...');
      final nonce = solvePoW(challenge);

      debugPrint('📝 [Auth] Signup for: $testUsername');
      final signupRes = await apiClient.post(
        AppConfig.authSignup,
        data: {
          'username': testUsername,
          'passphrase': testPassphrase,
          'accountSecurity': 'standard',
          'challenge': challenge,
          'nonce': nonce,
        },
      );

      expect(signupRes.statusCode, anyOf([200, 201]));
      final body = signupRes.data;

      final otpUri =
          body['otpUri'] ?? body['qrCodeUri'] ?? body['data']?['otpUri'];
      if (otpUri != null) {
        totpSecret = Uri.tryParse(otpUri.toString())?.queryParameters['secret'];
      }
      totpSecret ??= body['totpSecret'] ?? body['data']?['totpSecret'];

      debugPrint(
          '✅ [Auth] Signup successful. TOTP Secret: ${totpSecret?.substring(0, 4)}...');
      expect(totpSecret, isNotNull);
    });

    test('Step 4: Verify Signup TOTP', () async {
      final apiClient = container.read(apiClientProvider);
      expect(totpSecret, isNotNull);

      final code = TotpGenerator.generate(totpSecret!);
      debugPrint('🔢 [Auth] Verifying signup TOTP code.');

      final verifyRes = await apiClient.post(
        AppConfig.authSignupVerify,
        data: {
          'username': testUsername,
          'totpCode': code,
        },
      );

      expect(verifyRes.statusCode, 200);
      debugPrint('✅ [Auth] Account Verified.');
    });

    test('Step 5: Login & preAuthToken', () async {
      final apiClient = container.read(apiClientProvider);

      debugPrint('🔑 [Auth] Login attempt...');
      final loginRes = await apiClient.post(
        AppConfig.authLogin,
        data: {
          'username': testUsername,
          'passphrase': testPassphrase,
        },
      );

      expect(loginRes.statusCode, 202);
      preAuthToken = loginRes.data.toString();
      debugPrint('✅ [Auth] Login Accepted. PreAuthToken received.');
    });

    test('Step 6: Final Login Verify (TOTP)', () async {
      final apiClient = container.read(apiClientProvider);
      expect(totpSecret, isNotNull);
      expect(preAuthToken, isNotNull);

      final code = TotpGenerator.generate(totpSecret!);
      debugPrint('🔢 [Auth] Verifying login TOTP code.');

      final finalVerifyRes = await apiClient.post(
        AppConfig.authLoginVerify,
        data: {
          'username': testUsername,
          'totpCode': code,
          'preAuthToken': preAuthToken,
        },
      );

      expect(finalVerifyRes.statusCode, 200);

      final raw = finalVerifyRes.data.toString();
      finalJwt = raw.contains(' ') ? raw.split(' ').last : raw;

      debugPrint('✅ [Auth] Final session credential obtained.');
    });

    test('Step 7: Profile Access Check', () async {
      final apiClient = container.read(apiClientProvider);
      expect(finalJwt, isNotNull);

      debugPrint('👤 [Auth] Accessing /auth/me...');
      final meRes = await apiClient.get(
        AppConfig.authMe,
        options: Options(headers: {'Authorization': 'Bearer $finalJwt'}),
      );

      expect(meRes.statusCode, 200);
      expect(meRes.data['username'], testUsername);
      debugPrint(
          '🎉 [Auth] Profile matched! User is authenticated as ${meRes.data['username']}');
    });
  },
      skip: !_runRealOnionTests
          ? 'Set RUN_REAL_ONION_TESTS=true para executar integrações reais com Tor/.onion.'
          : false);
}

/// Manual SOCKS5 Relay tunnel for test environment
Future<int> _manualStartRelay(
    int socksPort, String targetHost, int targetPort) async {
  final relayServer = await ServerSocket.bind('127.0.0.1', 0);
  final relayPort = relayServer.port;

  relayServer.listen((clientSocket) async {
    try {
      final torSocket = await Socket.connect('127.0.0.1', socksPort);
      torSocket.add([0x05, 0x01, 0x00]);
      await torSocket.flush();

      final domainBytes = utf8.encode(targetHost);
      final request = [
        0x05,
        0x01,
        0x00,
        0x03,
        domainBytes.length,
        ...domainBytes,
        (targetPort >> 8) & 0xFF,
        targetPort & 0xFF
      ];
      torSocket.add(request);
      await torSocket.flush();

      clientSocket.listen((d) => torSocket.add(d),
          onDone: () => torSocket.destroy());
      torSocket.listen((d) => clientSocket.add(d),
          onDone: () => clientSocket.destroy());
    } catch (e) {
      clientSocket.destroy();
    }
  });
  return relayPort;
}
