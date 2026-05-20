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
    try {
      final response = await _api.get(AppConfig.auditMerkleHistory);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      _logAdminError('fetchAuditHistory', e);
      return [];
    }
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
      return {'btcUsd': 0, 'btcBrl': 0, 'usdBrl': 0};
    } catch (e) {
      _logAdminError('fetchBtcPrice', e);
      return {'btcUsd': 0, 'btcBrl': 0, 'usdBrl': 0};
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
    try {
      final response = await _api.get(
        AppConfig.adminOperationsLogs,
        queryParameters: {'limit': 50},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      _logAdminError('fetchOperationalLogs', e);
      return [];
    }
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
      return [];
    } catch (e) {
      _logAdminError('fetchAuthenticatedMobileDevices', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminDevices() async {
    try {
      final response = await _api.get(AppConfig.authAdminDevices);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      _logAdminError('fetchAdminDevices', e);
      return [];
    }
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
      _logAdminError('deviceAction', e);
    }
  }

  Future<Map<String, dynamic>> _fetchMap(String path, String operation) async {
    try {
      final response = await _api.get(path);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      _logAdminError(operation, e);
      return {};
    }
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
