import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class WalletRemoteDataSource {
  Future<String> createWallet({
    required String name,
    required String passphrase,
  });

  Future<List<dynamic>> getWallets();

  Future<Map<String, dynamic>> getLedger({required String walletName});

  Future<List<dynamic>> getAllLedgers();

  Future<Map<String, dynamic>> sendTransaction({
    required String sender,
    required String receiver,
    required double amount,
    required String context,
  });

  // Wallet CRUD
  Future<Map<String, dynamic>> findWallet({required String name});

  Future<String> updateWallet({required String name, required String newName});

  Future<String> deleteWallet({
    required String name,
    required String passphrase,
  });

  // Ledger
  Future<double> getBalance({required String walletName});

  Future<String> deleteLedger({required String walletName});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl(this.apiClient);

  @override
  Future<String> createWallet({
    required String name,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.walletCreate,
        data: {'name': name, 'passphrase': passphrase},
        options: Options(responseType: ResponseType.plain),
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

      var data = response.data;

      // Se for string, tenta parsear como JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        bool isSingleWallet =
            data.containsKey('name') ||
            data.containsKey('passphrase') ||
            data.containsKey('walletName');

        if (isSingleWallet) {
          return [data];
        }

        // Tenta retornar os valores se forem objetos (Map de Wallets)
        final values = data.values;
        if (values.isNotEmpty && values.first is Map) {
          return values.toList();
        }

        if (data.isEmpty) return [];

        return [data];
      }

      return [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar carteiras: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getLedger({required String walletName}) async {
    try {
      // Fallback: Use getAllLedgers and filter locally since /ledger/find is removed
      final all = await getAllLedgers();
      final entry = all.firstWhere(
        (e) =>
            e is Map &&
            (e['walletName'] == walletName || e['name'] == walletName),
        orElse: () => null,
      );

      if (entry != null && entry is Map<String, dynamic>) {
        return entry;
      }
      return {};
      /*
      final response = await apiClient.get(
        AppConfig.ledgerFind,
        queryParameters: {'walletName': walletName},
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
      */
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar ledger: $e');
    }
  }

  @override
  Future<List<dynamic>> getAllLedgers() async {
    try {
      final response = await apiClient.get(AppConfig.ledgerAll);
      return response.data is List ? response.data : [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar todos ledgers: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendTransaction({
    required String sender,
    required String receiver,
    required double amount,
    required String context,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'sender': sender,
        'receiver': receiver,
        'amount': amount,
        'context': context,
      };

      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: payload,
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'result': response.data};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar transação: $e');
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
  }) async {
    try {
      final response = await apiClient.put(
        AppConfig.walletUpdate,
        data: {'name': name, 'newName': newName},
        options: Options(responseType: ResponseType.plain),
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
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao deletar carteira: $e');
    }
  }

  // ==================== Ledger ====================

  @override
  Future<double> getBalance({required String walletName}) async {
    try {
      final response = await apiClient.get(
        AppConfig.ledgerBalance,
        queryParameters: {'walletName': walletName},
        options: Options(responseType: ResponseType.plain),
      );
      return double.tryParse(response.data.toString().trim()) ?? 0;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar saldo: $e');
    }
  }

  @override
  Future<String> deleteLedger({required String walletName}) async {
    try {
      final response = await apiClient.delete(
        AppConfig.ledgerDelete,
        queryParameters: {'walletName': walletName},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao deletar ledger: $e');
    }
  }
}
