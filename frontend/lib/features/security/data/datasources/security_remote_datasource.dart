import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/account_security_profile.dart';

abstract class SecurityRemoteDataSource {
  Future<Map<String, dynamic>> getSovereigntyStatus();
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
}

class SecurityRemoteDataSourceImpl implements SecurityRemoteDataSource {
  final ApiClient apiClient;

  SecurityRemoteDataSourceImpl(this.apiClient);

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
      final response = await apiClient.get(AppConfig.authSecurityProfile);
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
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao atualizar perfil de segurança da conta: $e',
      );
    }
  }
}
