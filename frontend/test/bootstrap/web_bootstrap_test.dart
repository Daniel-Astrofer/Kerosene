import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/bootstrap/web_bootstrap.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/providers/tor_providers.dart';

void main() {
  test('resolveApiUrlForWeb reads trusted runtime config on loopback',
      () async {
    final resolved = await resolveApiUrlForWeb(
      browserUri: Uri.parse('http://localhost:3001/admin'),
      runtimeConfigReader: (configUri) async {
        expect(
          configUri.toString(),
          'http://localhost:3001/kerosene-runtime-config.json',
        );
        return {'apiUrl': 'http://localhost:8080/'};
      },
      apiHealthProbe: (_) async => false,
    );

    expect(resolved, 'http://localhost:8080');
  });

  test('resolveApiUrlForWeb ignores untrusted runtime config host', () async {
    final resolved = await resolveApiUrlForWeb(
      browserUri: Uri.parse('http://localhost:3001/admin'),
      runtimeConfigReader: (_) async => {'apiUrl': 'https://api.example.com'},
      apiHealthProbe: (_) async => false,
    );

    expect(resolved, 'http://localhost:3001');
  });

  test('resolveApiUrlForWeb probes known local backend ports', () async {
    final probes = <String>[];
    final resolved = await resolveApiUrlForWeb(
      browserUri: Uri.parse('http://localhost:3001/admin'),
      runtimeConfigReader: (_) async => null,
      apiHealthProbe: (healthUri) async {
        probes.add(healthUri.toString());
        return healthUri.toString() == 'http://localhost:8080/health/ready';
      },
    );

    expect(resolved, 'http://localhost:8080');
    expect(probes.first, 'http://localhost:3001/health/ready');
    expect(probes, contains('http://localhost:8080/health/ready'));
  });

  test('localApiCandidateOrigins stays on loopback hosts', () {
    final origins =
        localApiCandidateOrigins(Uri.parse('http://localhost:3001/admin'));

    expect(origins, contains('http://localhost:3001'));
    expect(origins, contains('http://localhost:8080'));
    expect(origins, contains('http://127.0.0.1:8080'));
    expect(
        origins.every((origin) =>
            origin.contains('localhost') || origin.contains('127.0.0.1')),
        isTrue);
  });

  test('configureResolvedApiUrl aligns apiUrl, activeNodeUrl and provider', () {
    final previousApiUrl = AppConfig.apiUrl;
    final previousActiveNodeUrl = AppConfig.activeNodeUrl;
    final previousTorEnabled = AppConfig.isTorEnabled;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() {
      AppConfig.apiUrl = previousApiUrl;
      AppConfig.activeNodeUrl = previousActiveNodeUrl;
      AppConfig.isTorEnabled = previousTorEnabled;
    });

    configureResolvedApiUrl(container, 'http://localhost:8080');

    expect(AppConfig.apiUrl, 'http://localhost:8080');
    expect(AppConfig.activeNodeUrl, 'http://localhost:8080');
    expect(AppConfig.isTorEnabled, isFalse);
    expect(container.read(torApiUrlProvider), 'http://localhost:8080');
    expect(AppConfig.effectivePasskeyRpId, 'kerosene-device');
  });

  test('configureResolvedApiUrl marks onion API routes as Tor-enabled', () {
    final previousApiUrl = AppConfig.apiUrl;
    final previousActiveNodeUrl = AppConfig.activeNodeUrl;
    final previousTorEnabled = AppConfig.isTorEnabled;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() {
      AppConfig.apiUrl = previousApiUrl;
      AppConfig.activeNodeUrl = previousActiveNodeUrl;
      AppConfig.isTorEnabled = previousTorEnabled;
    });

    configureResolvedApiUrl(container, 'http://abc123.onion');

    expect(AppConfig.apiUrl, 'http://abc123.onion');
    expect(AppConfig.activeNodeUrl, 'http://abc123.onion');
    expect(AppConfig.isTorEnabled, isTrue);
    expect(container.read(torApiUrlProvider), 'http://abc123.onion');
    expect(AppConfig.effectivePasskeyRpId, 'kerosene-device');
  });

  test('pure application address resolves to public landing', () {
    expect(resolveWebInitialRoute('/'), '/');
    expect(resolveWebInitialRoute(''), '/');
    expect(resolveWebInitialRoute('/qualquer-rota-publica'), '/');
  });

  test('admin address is the only route that resolves to admin shell', () {
    expect(resolveWebInitialRoute('/admin'), '/admin');
    expect(resolveWebInitialRoute('/admin/operations'), '/admin');
    expect(resolveWebInitialRoute('/download'), '/download');
    expect(resolveWebInitialRoute('/status'), '/status');
  });
}
