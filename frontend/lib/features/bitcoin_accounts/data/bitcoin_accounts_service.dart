import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import 'bitcoin_account_models.dart';

export 'bitcoin_account_models.dart';

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
  });

  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  });

  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  });

  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  );

  Future<ReceivingRequestView> getReceiveStatus(String requestId);
}

class RemoteBitcoinAccountsService implements BitcoinAccountsService {
  const RemoteBitcoinAccountsService(this._api);

  final ApiClient _api;

  @override
  Future<List<BitcoinAccount>> listAccounts() async {
    final response = await _api.get(AppConfig.bitcoinAccounts);
    return _requireList(
      response.data,
      operation: 'listAccounts',
    ).map(BitcoinAccount.fromJson).toList();
  }

  @override
  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountsInternalCard,
      data: {
        'label': label,
        'riskTier': _riskTierForDailyLimit(dailyLimitSats),
      },
    );
    return BitcoinAccount.fromJson(
      _requireMap(response.data, operation: 'createInternalCard'),
    );
  }

  @override
  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountsColdWallet,
      data: {
        'label': label,
        'xpub': xpub,
        'fingerprint': fingerprint,
        'derivationPath': derivationPath,
        'scriptPolicy': scriptPolicy,
      },
    );
    return BitcoinAccount.fromJson(
      _requireMap(response.data, operation: 'importColdWallet'),
    );
  }

  @override
  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountReceiveRequests(accountId),
      data: {
        if (amountSats != null) 'amountSats': amountSats,
        'expiry': expiry,
        'oneTime': oneTime,
      },
    );
    return ReceivingRequestView.fromJson(
      _requireMap(response.data, operation: 'createReceiveRequest'),
      fallbackAccountId: accountId,
    );
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    final response = await _api.get(
      AppConfig.bitcoinReceiveRequestStatus(requestId),
    );
    return ReceivingRequestView.fromJson(
      _requireMap(response.data, operation: 'getReceiveStatus'),
    );
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    throw const ServerException(
      message:
          'O backend ainda não expõe a listagem real de solicitações de recebimento por conta.',
      errorCode: 'ERR_BITCOIN_RECEIVE_REQUEST_HISTORY_UNAVAILABLE',
    );
  }

  static String _riskTierForDailyLimit(int dailyLimitSats) {
    if (dailyLimitSats >= 50000000) return 'GOLD';
    if (dailyLimitSats >= 10000000) return 'SILVER';
    return 'BRONZE';
  }

  static Map<String, dynamic> _requireMap(
    Object? data, {
    required String operation,
  }) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerException(
      message: 'Resposta inesperada do backend Bitcoin.',
      errorCode: 'ERR_BITCOIN_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }

  static List<Map<String, dynamic>> _requireList(
    Object? data, {
    required String operation,
  }) {
    if (data is List) {
      return data
          .map((item) => _requireMap(item, operation: operation))
          .toList();
    }
    throw ServerException(
      message: 'Resposta inesperada do backend Bitcoin.',
      errorCode: 'ERR_BITCOIN_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }
}
