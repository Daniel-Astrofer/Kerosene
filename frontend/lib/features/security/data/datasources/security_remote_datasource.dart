import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../../domain/entities/account_security_profile.dart';
import '../../domain/entities/admin_access.dart';

abstract class SecurityRemoteDataSource {
  Future<Map<String, dynamic>> getSovereigntyStatus();
  Future<Map<String, dynamic>> getTreasuryOverview();
  Future<bool> pingSovereignty();
  Future<void> sendTelemetry(Map<String, dynamic> data);
  Future<Map<String, dynamic>> reattest();

  // Audit Endpoints
  Future<Map<String, dynamic>> getAuditStats();
  Future<Map<String, dynamic>> getAuditSiphon();
  Future<Map<String, dynamic>> getLatestMerkleRoot();
  Future<List<dynamic>> getMerkleHistory();
  Future<Map<String, dynamic>> triggerAudit();

  Future<Map<String, dynamic>> getAccountSecurityProfile();
  Future<Map<String, dynamic>> updateAccountSecurityProfile(
    AccountSecurityProfile profile,
  );
  Future<Map<String, dynamic>> getAppPinStatus();
  Future<Map<String, dynamic>> configureAppPin({
    required bool enabled,
    String? pin,
    String? currentPin,
    String? totpCode,
  });
  Future<Map<String, dynamic>> verifyAppPin({
    required String pin,
  });
  Future<Map<String, dynamic>> getAdminKeyStatus();
  Future<Map<String, dynamic>> createAdminKey({
    required String keyMaterialHash,
    required String deviceInstallId,
  });
  Future<Map<String, dynamic>> revokeAdminKey();
  Future<List<AdminAccessAttempt>> getPendingAdminAttempts();
  Future<AdminAccessAttempt> decideAdminAttempt({
    required String attemptId,
    required bool approve,
  });
  Future<List<AdminAuthenticatedDevice>> getAdminDevices();
  Future<void> blockAdminDevice(String deviceId);
  Future<void> revokeAdminDevice(String deviceId);
}

class SecurityRemoteDataSourceImpl implements SecurityRemoteDataSource {
  final ApiClient apiClient;

  SecurityRemoteDataSourceImpl(this.apiClient);

  Future<Map<String, String>> _deviceHeaders() async {
    final deviceHash = await DeviceHelper.getDeviceHash();
    return {
      'X-Device-Hash': deviceHash,
    };
  }

  @override
  Future<Map<String, dynamic>> getSovereigntyStatus() async {
    try {
      final response = await apiClient.get(AppConfig.sovereigntyStatus);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar status de soberania: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTreasuryOverview() async {
    try {
      final response = await apiClient.get(AppConfig.treasuryOverview);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Erro ao buscar overview da tesouraria: $e');
    }
  }

  @override
  Future<bool> pingSovereignty() async {
    try {
      final response = await apiClient.get(AppConfig.sovereigntyPing);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> sendTelemetry(Map<String, dynamic> data) async {
    try {
      await apiClient.post(AppConfig.sovereigntyTelemetry, data: data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar telemetria: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> reattest() async {
    try {
      final response = await apiClient.post(AppConfig.sovereigntyReattest);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao solicitar reatestação: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final response = await apiClient.get(AppConfig.auditStats);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Erro ao buscar estatísticas de auditoria: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAuditSiphon() async {
    try {
      final response = await apiClient.get(AppConfig.auditSiphon);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar dados do siphon: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getLatestMerkleRoot() async {
    try {
      final response = await apiClient.get(AppConfig.auditMerkleLatestRoot);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar última raiz Merkle: $e');
    }
  }

  @override
  Future<List<dynamic>> getMerkleHistory() async {
    try {
      final response = await apiClient.get(AppConfig.auditMerkleHistory);
      return response.data is List ? response.data : [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar histórico Merkle: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> triggerAudit() async {
    try {
      final response = await apiClient.post(AppConfig.auditMerkleTrigger);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao disparar auditoria: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAccountSecurityProfile() async {
    try {
      final response = await apiClient.get(
        AppConfig.authSecurityProfile,
        headers: await _deviceHeaders(),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao obter perfil de segurança da conta: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateAccountSecurityProfile(
    AccountSecurityProfile profile,
  ) async {
    try {
      final response = await apiClient.put(
        AppConfig.authSecurityProfile,
        data: profile.toUpdateJson(),
        headers: await _deviceHeaders(),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao atualizar perfil de segurança da conta: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAppPinStatus() async {
    try {
      final response = await apiClient.get(
        AppConfig.authAppPin,
        headers: await _deviceHeaders(),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao consultar status do PIN do aplicativo: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> configureAppPin({
    required bool enabled,
    String? pin,
    String? currentPin,
    String? totpCode,
  }) async {
    try {
      final response = await apiClient.put(
        AppConfig.authAppPin,
        headers: await _deviceHeaders(),
        data: {
          'enabled': enabled,
          if (pin != null) 'pin': pin,
          if (currentPin != null) 'currentPin': currentPin,
          if (totpCode != null) 'totpCode': totpCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao atualizar PIN do aplicativo: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> verifyAppPin({
    required String pin,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authAppPinVerify,
        headers: await _deviceHeaders(),
        data: {
          'pin': pin,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao validar PIN do aplicativo: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAdminKeyStatus() async {
    final response = await apiClient.get(AppConfig.authAdminKey);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createAdminKey({
    required String keyMaterialHash,
    required String deviceInstallId,
  }) async {
    final response = await apiClient.post(
      AppConfig.authAdminKey,
      data: {
        'keyMaterialHash': keyMaterialHash,
        'deviceInstallId': deviceInstallId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> revokeAdminKey() async {
    final response = await apiClient.delete(AppConfig.authAdminKey);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<AdminAccessAttempt>> getPendingAdminAttempts() async {
    final response = await apiClient.get(AppConfig.authAdminPendingAttempts);
    final body = response.data;
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => AdminAccessAttempt.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    throw ServerException(
      message: 'Resposta inesperada ao carregar tentativas admin.',
      errorCode: 'ERR_ADMIN_ATTEMPTS_INVALID_RESPONSE',
      data: body,
    );
  }

  @override
  Future<AdminAccessAttempt> decideAdminAttempt({
    required String attemptId,
    required bool approve,
  }) async {
    final response = await apiClient.post(
      AppConfig.authAdminAttemptDecision(attemptId),
      data: {'decision': approve ? 'APPROVE' : 'BLOCK'},
    );
    return AdminAccessAttempt.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<AdminAuthenticatedDevice>> getAdminDevices() async {
    final response = await apiClient.get(AppConfig.authAdminDevices);
    final body = response.data;
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => AdminAuthenticatedDevice.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    throw ServerException(
      message: 'Resposta inesperada ao carregar dispositivos admin.',
      errorCode: 'ERR_ADMIN_DEVICES_INVALID_RESPONSE',
      data: body,
    );
  }

  @override
  Future<void> blockAdminDevice(String deviceId) async {
    await apiClient.post(AppConfig.authAdminDeviceBlock(deviceId));
  }

  @override
  Future<void> revokeAdminDevice(String deviceId) async {
    await apiClient.post(AppConfig.authAdminDeviceRevoke(deviceId));
  }
}
