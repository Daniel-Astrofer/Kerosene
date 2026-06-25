import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/network/api_client_route_policy.dart';
import 'package:kerosene/core/providers/tor_providers.dart';
import 'package:kerosene/core/services/tor_network_bootstrap.dart';
import 'package:kerosene/core/services/tor_service.dart';

bool _isLoopbackUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  final host = uri?.host.toLowerCase();
  return host == '127.0.0.1' || host == 'localhost' || host == '::1';
}

Future<void> initializeCookieSupport(Dio dio) async {
  dio.interceptors.add(CookieManager(CookieJar()));
}

Future<void> ensureNetworkReady({
  required Ref ref,
  required ApiClientRoutePolicy routePolicy,
  required String baseUrl,
}) async {
  final torService = ref.read(torServiceProvider);
  final bootstrapped = AppConfig.isTorEnabled && torService.isRunning;

  if (!bootstrapped) {
    final started = await bootstrapTorNetwork(
      torService: torService,
      updateApiUrl: (url) {
        ref.read(torApiUrlProvider.notifier).updateUrl(url);
      },
    );

    if (!started) {
      throw const NetworkException(
        message:
            'A rede Tor ainda não está pronta. Nenhuma requisição foi enviada.',
      );
    }
  }
}

void configureProxyRouting({
  required Dio dio,
  required Ref ref,
  required ApiClientRoutePolicy routePolicy,
  required String baseUrl,
  required bool Function({
    required String baseUrl,
    required ApiClientRoutePolicy routePolicy,
    required bool torRunning,
  }) shouldUseSocksProxy,
}) {
  final torService = ref.read(torServiceProvider);
  final shouldProxy = shouldUseSocksProxy(
    baseUrl: baseUrl,
    routePolicy: routePolicy,
    torRunning: torService.isRunning,
  );
  final routingMode = shouldProxy ? 'socks:${torService.socksPort}' : 'direct';
  if (dio.options.extra['_keroseneRoutingMode'] == routingMode) {
    return;
  }
  dio.options.extra['_keroseneRoutingMode'] = routingMode;

  if (!shouldProxy) {
    if (AppConfig.isTorEnabled && _isLoopbackUrl(baseUrl)) {
      debugPrint('🧅 ApiClient: Using local Tor relay for $baseUrl');
    } else {
      debugPrint('🌐 ApiClient: Using direct route for $baseUrl');
    }
    return;
  }

  final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
  adapter.createHttpClient = () {
    final client = HttpClient();
    final settings = [
      ProxySettings(InternetAddress.loopbackIPv4, torService.socksPort),
    ];
    SocksTCPClient.assignToHttpClient(client, settings);
    return client;
  };

  debugPrint(
    '🧅 ApiClient: Configured SOCKS5 proxy for $baseUrl on port ${torService.socksPort}',
  );
}
