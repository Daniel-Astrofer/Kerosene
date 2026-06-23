import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class WalletRemoteDataSource {
  Future<Map<String, dynamic>> createWallet({
    required String name,
    String? xpub,
    String walletMode = 'KEROSENE',
  });

  Future<List<dynamic>> getWallets();

  // Wallet CRUD
  Future<Map<String, dynamic>> findWallet({required String name});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl(this.apiClient);

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String _kfeKind({
    required String walletMode,
    required String? xpub,
  }) {
    final normalizedMode = walletMode.trim().toUpperCase();
    final hasXpub = xpub != null && xpub.trim().isNotEmpty;
    if (normalizedMode == 'CUSTODIAL_ONCHAIN') {
      return 'CUSTODIAL_ONCHAIN';
    }
    if (normalizedMode == 'SELF_CUSTODY' || hasXpub) {
      return 'WATCH_ONLY';
    }
    return 'INTERNAL';
  }

  Map<String, dynamic> _kfeCreatePayload({
    required String name,
    required String? xpub,
    required String walletMode,
  }) {
    final normalizedXpub = xpub?.trim();
    final kind = _kfeKind(walletMode: walletMode, xpub: normalizedXpub);
    return {
      'kind': kind,
      'label': name.trim(),
      if (normalizedXpub != null && normalizedXpub.isNotEmpty)
        'xpub': normalizedXpub,
      'issueInitialAddress':
          normalizedXpub != null && normalizedXpub.isNotEmpty,
    };
  }

  @override
  Future<Map<String, dynamic>> createWallet({
    required String name,
    String? xpub,
    String walletMode = 'KEROSENE',
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.kfeWallets,
        data: _kfeCreatePayload(
          name: name,
          xpub: xpub,
          walletMode: walletMode,
        ),
        options: Options(contentType: 'application/json'),
      );
      final data = _parseMap(response.data);
      if (data.isEmpty) {
        throw ServerException(
          message: 'Resposta inesperada ao criar carteira.',
          errorCode: 'ERR_WALLET_CREATE_INVALID_RESPONSE',
          data: response.data,
        );
      }
      return data;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar carteira: $e');
    }
  }

  @override
  Future<List<dynamic>> getWallets() async {
    try {
      final response = await apiClient.get(AppConfig.kfeDashboard);
      final data = response.data;
      if (data is List) {
        return data;
      }
      final map = _parseMap(data);
      final wallets = map['wallets'];
      if (wallets is List) {
        return wallets;
      }
      throw ServerException(
        message: 'Resposta inesperada ao buscar carteiras.',
        errorCode: 'ERR_WALLET_LIST_INVALID_RESPONSE',
        data: data,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar carteiras: $e');
    }
  }

  // ==================== Wallet CRUD ====================

  @override
  Future<Map<String, dynamic>> findWallet({required String name}) async {
    try {
      final wallets = await getWallets();
      final normalizedName = name.trim();
      final wallet = wallets.whereType<Map>().map(_parseMap).firstWhere(
            (wallet) =>
                wallet['id']?.toString() == normalizedName ||
                wallet['walletId']?.toString() == normalizedName ||
                wallet['name']?.toString() == normalizedName ||
                wallet['walletName']?.toString() == normalizedName ||
                wallet['label']?.toString() == normalizedName,
            orElse: () => const {},
          );
      if (wallet.isNotEmpty) {
        return wallet;
      }
      throw const ValidationException(
        message: 'Carteira não encontrada.',
        statusCode: 404,
        errorCode: 'ERR_WALLET_NOT_FOUND',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar carteira: $e');
    }
  }
}
