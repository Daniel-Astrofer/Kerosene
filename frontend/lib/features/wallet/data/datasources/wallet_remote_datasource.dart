import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class WalletRemoteDataSource {
  Future<String> createWallet({
    required String name,
    required String passphrase,
    String accountSecurity = 'STANDARD',
    String? xpub,
    String walletMode = 'KEROSENE',
  });

  Future<List<dynamic>> getWallets();

  // Wallet CRUD
  Future<Map<String, dynamic>> findWallet({required String name});

  Future<String> updateWallet({
    required String name,
    required String newName,
    required String passphrase,
  });

  Future<String> deleteWallet({
    required String name,
    required String passphrase,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String> createWallet({
    required String name,
    required String passphrase,
    String accountSecurity = 'STANDARD',
    String? xpub,
    String walletMode = 'KEROSENE',
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.walletCreate,
        data: {
          'name': name,
          'passphrase': passphrase,
          'accountSecurity': accountSecurity,
          'xpub': xpub,
          'walletMode': walletMode,
        },
        options: Options(contentType: 'application/json'),
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar carteira: $e');
    }
  }

  @override
  Future<List<dynamic>> getWallets() async {
    try {
      final response = await apiClient.get(AppConfig.walletAll);
      final data = response.data;
      if (data is List) {
        return data;
      }
      return [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar carteiras: $e');
    }
  }

  // ==================== Wallet CRUD ====================

  @override
  Future<Map<String, dynamic>> findWallet({required String name}) async {
    try {
      final response = await apiClient.get(
        AppConfig.walletFind,
        queryParameters: {'name': name},
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar carteira: $e');
    }
  }

  @override
  Future<String> updateWallet({
    required String name,
    required String newName,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.put(
        AppConfig.walletUpdate,
        data: {'name': name, 'newName': newName, 'passphrase': passphrase},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao atualizar carteira: $e');
    }
  }

  @override
  Future<String> deleteWallet({
    required String name,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.delete(
        AppConfig.walletDelete,
        data: {'name': name, 'passphrase': passphrase},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao deletar carteira: $e');
    }
  }
}
