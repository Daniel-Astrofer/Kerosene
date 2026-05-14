import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:teste/core/network/api_client_route_policy.dart';
import 'package:teste/core/services/tor_service.dart';

Future<void> initializeCookieSupport(Dio dio) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${appDocDir.path}/.cookies/'),
  );
  dio.interceptors.add(CookieManager(cookieJar));
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

  if (!shouldProxy) {
    debugPrint('🌐 ApiClient: Using clearnet for $baseUrl');
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
