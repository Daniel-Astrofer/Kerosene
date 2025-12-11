import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';

abstract class WalletRemoteDataSource {
  Future<String> createWallet({
    required String name,
    required String passphrase,
    required String token,
  });

  Future<List<dynamic>> getWallets(String token);

  Future<Map<String, dynamic>> getLedger({
    required String walletName,
    required String token,
  });

  Future<List<dynamic>> getAllLedgers(String token);

  Future<Map<String, dynamic>> sendTransaction({
    required String sender,
    required String receiver,
    required double amount,
    required String context,
    required String token,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl(this.apiClient);

  Future<Map<String, String>> _getHeaders(String token) async {
    final securityHeaders = await DeviceHelper.getSecurityHeaders();
    return {...securityHeaders, 'Authorization': 'Bearer $token'};
  }

  @override
  Future<String> createWallet({
    required String name,
    required String passphrase,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        AppConfig.walletCreate,
        data: {'name': name, 'passphrase': passphrase},
        headers: headers,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } catch (e) {
      throw ServerException(message: 'Erro ao criar carteira: $e');
    }
  }

  @override
  Future<List<dynamic>> getWallets(String token) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.walletAll,
        headers: headers,
      );

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
        // Caso 1: Wrapper { "customData": [...] } ? (Pouco provável no schema genérico, mas possível)
        // Caso 2: Map de Wallets { "id1": {...}, "id2": {...} }
        // Se as chaves parecem IDs e os valores são Maps, deve ser Map de Wallets.
        // Se tem campos como 'name' ou 'passphrase' na raiz, é uma única wallet.

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

        // Fallback: Se não identificamos, retornamos vazio ou tentamos encapsular
        // Se estiver vazio o Map, retorna lista vazia
        if (data.isEmpty) return [];

        return [data];
      }

      return [];
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar carteiras: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getLedger({
    required String walletName,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.ledgerFind,
        queryParameters: {'walletName': walletName},
        headers: headers,
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar ledger: $e');
    }
  }

  @override
  Future<List<dynamic>> getAllLedgers(String token) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.ledgerAll,
        headers: headers,
      );
      return response.data is List ? response.data : [];
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar todos ledgers: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendTransaction({
    required String sender,
    required String receiver,
    required double amount,
    required String context,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': sender,
          'receiver': receiver,
          'amount': amount,
          'context': context,
        },
        headers: headers,
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'result': response.data};
    } catch (e) {
      throw ServerException(message: 'Erro ao enviar transação: $e');
    }
  }
}
