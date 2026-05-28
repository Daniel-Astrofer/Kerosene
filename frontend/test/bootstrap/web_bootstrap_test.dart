import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/bootstrap/web_bootstrap.dart';
import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/providers/tor_providers.dart';

void main() {
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
