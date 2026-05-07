import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_provider.dart';

final publicMobileDownloadProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(apiClientProvider).get(
        '/api/public/mobile-download',
      );
  if (response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }
  return <String, dynamic>{};
});

final publicReadinessProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/health/ready');
  if (response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }
  return <String, dynamic>{};
});

final publicReleaseProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/system/release');
  if (response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }
  return <String, dynamic>{};
});
