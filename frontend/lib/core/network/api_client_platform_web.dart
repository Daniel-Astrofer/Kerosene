import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_route_policy.dart';

Future<void> initializeCookieSupport(Dio dio) async {}

void configureProxyRouting({
  required Dio dio,
  required Ref ref,
  required ApiClientRoutePolicy routePolicy,
  required String baseUrl,
  required bool shouldUseSocksProxy({
    required String baseUrl,
    required ApiClientRoutePolicy routePolicy,
    required bool torRunning,
  }),
}) {}
