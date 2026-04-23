import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/bootstrap/web_bootstrap.dart';
import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/providers/tor_providers.dart';

void main() {
  test('configureResolvedApiUrl aligns apiUrl, activeNodeUrl and provider', () {
    final previousApiUrl = AppConfig.apiUrl;
    final previousActiveNodeUrl = AppConfig.activeNodeUrl;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() {
      AppConfig.apiUrl = previousApiUrl;
      AppConfig.activeNodeUrl = previousActiveNodeUrl;
    });

    configureResolvedApiUrl(container, 'http://localhost:8080');

    expect(AppConfig.apiUrl, 'http://localhost:8080');
    expect(AppConfig.activeNodeUrl, 'http://localhost:8080');
    expect(container.read(torApiUrlProvider), 'http://localhost:8080');
    expect(AppConfig.effectivePasskeyRpId, 'localhost');
  });
}
