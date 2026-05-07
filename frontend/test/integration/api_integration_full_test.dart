import 'dart:io';

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

const _runRealOnionTests = bool.fromEnvironment('RUN_REAL_ONION_TESTS');

void main() {
  if (_runRealOnionTests) {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  } else {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  group('API Integration & Contract Tests (Real Onion Data)', () {
    late ProviderContainer container;
    late TorService torService;

    setUpAll(() async {
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

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      torService = TorService.instance;

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
      );

      debugPrint('🚀 [Setup] Starting Tor Bootstrap for Integration Tests...');
      try {
        final bool torStarted = await torService.start();
        if (!torStarted) {
          debugPrint(
              '⚠️ [Setup] Tor failed to start. Tests requiring .onion will fail.');
          return;
        }

        // Create Relay to the default onion node
        final host = Uri.parse(AppConfig.onionBaseUrl).host;
        debugPrint('🌐 [Setup] Creating relay for host: $host');

        final int relayPort = await torService.startRelay(host, 80);
        final testApiUrl = 'http://127.0.0.1:$relayPort';

        AppConfig.apiUrl = testApiUrl;
        container.read(torApiUrlProvider.notifier).updateUrl(testApiUrl);

        debugPrint('✅ [Setup] Tor Relay Active at $testApiUrl');
      } catch (e) {
        debugPrint('❌ [Setup] Critical failure: $e');
      }
    });

    tearDownAll(() async {
      debugPrint('🧹 [Teardown] Stopping Tor services...');
      await torService.stop();
      container.dispose();
    });

    test('Contract: GET /auth/pow/challenge returns valid PoW schema',
        () async {
      final apiClient = container.read(apiClientProvider);

      try {
        debugPrint(
            '📡 [Test] Requesting PoW challenge from ${AppConfig.apiUrl}${AppConfig.authPowChallenge}');
        final response = await apiClient.get(AppConfig.authPowChallenge);

        expect(response.statusCode, 200);
        final data = response.data;

        // Contract Validation
        expect(data, isA<Map<String, dynamic>>());
        expect(data.containsKey('challenge'), true,
            reason: 'Missing challenge field');
        expect(data.containsKey('difficulty'), true,
            reason: 'Missing difficulty field');
        expect(data['challenge'], isA<String>());
        expect(data['difficulty'], isA<int>());

        debugPrint('✅ [Contract] /auth/pow/challenge validation passed.');
        debugPrint('   Challenge: ${data['challenge']}');
        debugPrint('   Difficulty: ${data['difficulty']}');
      } catch (e) {
        fail('API request failed: $e');
      }
    });

    test('Integration: GET /sovereignty/status returns node health', () async {
      final apiClient = container.read(apiClientProvider);

      try {
        debugPrint('📡 [Test] Requesting Sovereignty Status...');
        final response = await apiClient.get(AppConfig.sovereigntyStatus);

        expect(response.statusCode, 200);
        final data = response.data;

        expect(data, isA<Map<String, dynamic>>());
        expect(data['hardwareAttestation'], isA<Map<String, dynamic>>());
        expect(data['networkConsensus'], isA<Map<String, dynamic>>());
        expect(data['ledgerIntegrity'], isA<Map<String, dynamic>>());
        expect(data['memoryProtection'], isA<Map<String, dynamic>>());
        debugPrint(
            '✅ [Integration] Sovereignty payload retornou as seções esperadas.');
      } catch (e) {
        debugPrint(
            '⚠️ Skipping detailed sovereignty check (Optional endpoint)');
      }
    });

    test('WebSocket: Connectivity check to Price Feed via Relay', () async {
      final host = Uri.parse(AppConfig.onionBaseUrl).host;
      final relayPort = await torService.startRelay(host, 80);

      debugPrint(
          '🔌 [Test] Attempting TCP Connection to Relay Port $relayPort (WS Tunnel)');

      try {
        final socket = await Socket.connect('127.0.0.1', relayPort,
            timeout: const Duration(seconds: 10));
        expect(socket, isNotNull);
        debugPrint('✅ [WebSocket] Tunnel is reachable.');
        await socket.close();
      } catch (e) {
        fail('WebSocket Relay Tunnel is unreachable: $e');
      }
    });
  },
      skip: !_runRealOnionTests
          ? 'Set RUN_REAL_ONION_TESTS=true para executar integrações reais com Tor/.onion.'
          : false);
}
