import 'dart:convert';

import 'package:dio/dio.dart' show Options;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class LedgerRemoteDataSource {
  /// Retrieves all ledger accounts associated with the user's wallets.
  Future<List<dynamic>> getAllLedgers();

  /// Retrieves a specific ledger account.
  Future<Map<String, dynamic>> findLedger({required String walletName});

  /// Gets the current balance of a specific wallet.
  Future<double> getBalance({required String walletName});

  /// Retrieves paginated transaction history.
  Future<List<dynamic>> getHistory({int page = 0, int size = 50});

  /// Processes an internal funds transfer between users.
  Future<Map<String, dynamic>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    required String idempotencyKey,
    required int requestTimestamp,
  });
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  final ApiClient apiClient;

  LedgerRemoteDataSourceImpl(this.apiClient);

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    return const [];
  }

  Future<Map<String, dynamic>> _getDashboard() async {
    final response = await apiClient.get(AppConfig.kfeDashboard);
    return _parseMap(response.data);
  }

  List<Map<String, dynamic>> _dashboardWallets(Map<String, dynamic> dashboard) {
    return _parseList(dashboard['wallets'])
        .whereType<Map>()
        .map(_parseMap)
        .toList();
  }

  Map<String, dynamic> _walletLedgerPayload(Map<String, dynamic> wallet) {
    final spendable = wallet['spendable'] != false;
    final sats = spendable
        ? wallet['availableSats']
        : (wallet['observedSats'] ?? wallet['availableSats']);
    return {
      'id': wallet['walletId'] ?? wallet['id'],
      'walletName': wallet['label'] ?? wallet['walletName'] ?? wallet['name'],
      'balance': _satsToBtc(sats),
      'availableSats': wallet['availableSats'],
      'observedSats': wallet['observedSats'],
      'status': wallet['status'],
      'kind': wallet['kind'],
    };
  }

  List<Map<String, dynamic>> _dashboardStatement(
    Map<String, dynamic> dashboard,
  ) {
    return _parseList(dashboard['recentStatement'])
        .whereType<Map>()
        .map(_statementPayload)
        .toList();
  }

  Map<String, dynamic> _statementPayload(Map<dynamic, dynamic> rawItem) {
    final item = _parseMap(rawItem);
    final payloadJson = item['displayPayloadJson']?.toString();
    Map<String, dynamic> payload = {};
    if (payloadJson != null && payloadJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payloadJson);
        payload = _parseMap(decoded);
      } catch (_) {}
    }
    return {
      ...payload,
      'id': payload['transactionId'] ?? item['transactionId'] ?? item['id'],
      'transactionId': payload['transactionId'] ?? item['transactionId'],
      'walletId': item['walletId'],
      'createdAt': item['createdAt'],
      'timestamp': item['createdAt'],
      'expiresAt': item['expiresAt'],
    };
  }

  double _satsToBtc(Object? value) {
    final sats = value is num ? value.toInt() : int.tryParse('$value');
    return (sats ?? 0) / 100000000.0;
  }

  int _btcToSats(double value) => (value * 100000000).round();

  bool _matchesWallet(Map<String, dynamic> wallet, String value) {
    final normalized = value.trim();
    return [
      wallet['id'],
      wallet['walletId'],
      wallet['walletName'],
      wallet['name'],
      wallet['label'],
    ].any((candidate) => candidate?.toString() == normalized);
  }

  @override
  Future<List<dynamic>> getAllLedgers() async {
    try {
      final dashboard = await _getDashboard();
      return _dashboardWallets(dashboard).map(_walletLedgerPayload).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar todos ledgers: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> findLedger({required String walletName}) async {
    try {
      final dashboard = await _getDashboard();
      final wallet = _dashboardWallets(dashboard).firstWhere(
        (wallet) => _matchesWallet(wallet, walletName),
        orElse: () => const {},
      );
      if (wallet.isNotEmpty) {
        return _walletLedgerPayload(wallet);
      }
      throw const ValidationException(
        message: 'Conta financeira não encontrada.',
        statusCode: 404,
        errorCode: 'ERR_LEDGER_NOT_FOUND',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar ledger: $e');
    }
  }

  @override
  Future<double> getBalance({required String walletName}) async {
    try {
      final ledger = await findLedger(walletName: walletName);
      return (ledger['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar saldo: $e');
    }
  }

  @override
  Future<List<dynamic>> getHistory({int page = 0, int size = 50}) async {
    try {
      final dashboard = await _getDashboard();
      final statement = _dashboardStatement(dashboard);
      final offset = page * size;
      return statement.skip(offset).take(size).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar histórico: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    required String idempotencyKey,
    required int requestTimestamp,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.kfeTransactions,
        data: {
          'idempotencyKey': idempotencyKey,
          'rail': 'INTERNAL',
          'direction': 'INTERNAL',
          'sourceWalletId': senderWalletName,
          'destinationWalletId': receiverWalletName,
          'amountSats': _btcToSats(amount),
          'networkFeeSats': 0,
          'memo': 'transfer',
        },
        options: Options(headers: {
          'X-Idempotency-Key': idempotencyKey,
        }),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'result': response.data};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar transação interna: $e');
    }
  }

}
