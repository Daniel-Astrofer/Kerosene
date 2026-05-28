import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';

class AdminDataService {
  final ApiClient _api;

  AdminDataService(this._api);

  Future<Map<String, dynamic>> fetchAuditStats() async {
    return _fetchMap(AppConfig.auditStats, 'fetchAuditStats');
  }

  Future<Map<String, dynamic>> fetchAuditLatestRoot() async {
    return _fetchMap(AppConfig.auditMerkleLatestRoot, 'fetchAuditLatestRoot');
  }

  Future<List<Map<String, dynamic>>> fetchAuditHistory() async {
    return _fetchList(AppConfig.auditMerkleHistory, 'fetchAuditHistory');
  }

  Future<Map<String, double>> fetchBtcPrice() async {
    try {
      final response = await _api.get('/api/economy/btc-price');
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data);
        return {
          'btcUsd': (data['btcUsd'] as num?)?.toDouble() ?? 0,
          'btcBrl': (data['btcBrl'] as num?)?.toDouble() ?? 0,
          'usdBrl': (data['usdBrl'] as num?)?.toDouble() ?? 0,
        };
      }
      throw _invalidResponse('fetchBtcPrice', response.data);
    } catch (e) {
      _throwAdminFailure('fetchBtcPrice', e);
    }
  }

  Future<Map<String, dynamic>> fetchSovereigntyStatus() async {
    return _fetchMap(AppConfig.sovereigntyStatus, 'fetchSovereigntyStatus');
  }

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    return _fetchMap(AppConfig.authMe, 'fetchCurrentUser');
  }

  Future<Map<String, dynamic>> fetchOperationsOverview() async {
    return _fetchMap(
      AppConfig.adminOperationsOverview,
      'fetchOperationsOverview',
    );
  }

  Future<Map<String, dynamic>> fetchOperationalHealth() async {
    return _fetchMap(AppConfig.adminOperationsHealth, 'fetchOperationalHealth');
  }

  Future<Map<String, dynamic>> fetchBlockchainMonitor() async {
    return _fetchMap(
      AppConfig.adminOperationsBlockchain,
      'fetchBlockchainMonitor',
    );
  }

  Future<Map<String, dynamic>> fetchLightningMonitor() async {
    return _fetchMap(
      AppConfig.adminOperationsLightning,
      'fetchLightningMonitor',
    );
  }

  Future<Map<String, dynamic>> fetchVaultRaftHealth() async {
    return _fetchMap(
        AppConfig.adminOperationsVaultRaft, 'fetchVaultRaftHealth');
  }

  Future<Map<String, dynamic>> fetchReleaseSnapshot() async {
    return _fetchMap(AppConfig.adminOperationsRelease, 'fetchReleaseSnapshot');
  }

  Future<Map<String, dynamic>> fetchMobileRelease() async {
    return _fetchMap(AppConfig.adminOperationsMobile, 'fetchMobileRelease');
  }

  Future<Map<String, dynamic>> fetchOperationalMetrics() async {
    return _fetchMap(
        AppConfig.adminOperationsMetrics, 'fetchOperationalMetrics');
  }

  Future<List<Map<String, dynamic>>> fetchOperationalLogs() async {
    return _fetchList(
      AppConfig.adminOperationsLogs,
      'fetchOperationalLogs',
      queryParameters: {'limit': 50},
    );
  }

  Future<List<Map<String, dynamic>>> fetchAuthenticatedMobileDevices() async {
    try {
      final response = await _api.get(AppConfig.authPasskeyDevices);
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final devices = data['devices'];
        if (devices is List) {
          return devices
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      throw _invalidResponse('fetchAuthenticatedMobileDevices', response.data);
    } catch (e) {
      _throwAdminFailure('fetchAuthenticatedMobileDevices', e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminDevices() async {
    return _fetchList(AppConfig.authAdminDevices, 'fetchAdminDevices');
  }

  Future<void> blockAdminDevice(String deviceId) async {
    await _postDeviceAction(AppConfig.authAdminDeviceBlock(deviceId));
  }

  Future<void> revokeAdminDevice(String deviceId) async {
    await _postDeviceAction(AppConfig.authAdminDeviceRevoke(deviceId));
  }

  Future<void> blockAuthenticatedMobileDevice(String deviceInstallId) async {
    await _postDeviceAction(AppConfig.authPasskeyDeviceBlock(deviceInstallId));
  }

  Future<void> revokeAuthenticatedMobileDevice(String deviceInstallId) async {
    await _postDeviceAction(AppConfig.authPasskeyDeviceRevoke(deviceInstallId));
  }

  Future<void> _postDeviceAction(String path) async {
    try {
      await _api.post(path);
    } catch (e) {
      _throwAdminFailure('deviceAction', e);
    }
  }

  Future<Map<String, dynamic>> _fetchMap(String path, String operation) async {
    try {
      final response = await _api.get(path);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      throw _invalidResponse(operation, response.data);
    } catch (e) {
      _throwAdminFailure(operation, e);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    String path,
    String operation, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _api.get(path, queryParameters: queryParameters);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw _invalidResponse(operation, response.data);
    } catch (e) {
      _throwAdminFailure(operation, e);
    }
  }

  ServerException _invalidResponse(String operation, Object? data) {
    return ServerException(
      message: 'Resposta inesperada do backend administrativo.',
      errorCode: 'ERR_ADMIN_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }

  Never _throwAdminFailure(String operation, Object error) {
    _logAdminError(operation, error);
    if (error is AppException) throw error;
    throw ServerException(
      message: 'Falha ao executar operação administrativa.',
      errorCode: 'ERR_ADMIN_${operation.toUpperCase()}',
      data: error.toString(),
    );
  }

  void _logAdminError(String operation, Object error) {
    if (error is AppException) {
      debugPrint(
        'AdminDataService.$operation failed: ${error.runtimeType}'
        '${error.statusCode != null ? ' status=${error.statusCode}' : ''}'
        '${error.errorCode != null ? ' code=${error.errorCode}' : ''}',
      );
      return;
    }
    debugPrint('AdminDataService.$operation failed: ${error.runtimeType}');
  }
}

final adminDataServiceProvider = Provider<AdminDataService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminDataService(apiClient);
});
