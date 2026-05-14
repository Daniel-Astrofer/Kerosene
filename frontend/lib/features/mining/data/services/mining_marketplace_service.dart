import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/errors/exceptions.dart';
import 'package:teste/core/network/api_client.dart';
import 'package:teste/features/mining/domain/entities/mining_allocation.dart';
import 'package:teste/features/mining/domain/entities/mining_rig_offer.dart';

class MiningMarketplaceService {
  final ApiClient apiClient;

  const MiningMarketplaceService(this.apiClient);

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<List<MiningRigOffer>> getRigOffers() async {
    try {
      final response = await apiClient.get(AppConfig.miningRigs);
      return _parseList(response.data).map(MiningRigOffer.fromJson).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao carregar rigs de mineração: $e');
    }
  }

  Future<MiningAllocation> createAllocation({
    required String walletName,
    required int rigId,
    double? requestedHashrate,
    double? budgetBtc,
    required int durationHours,
    required String payoutAddress,
    required String poolUrl,
    required String workerName,
    required String totpCode,
    String? passkeyAssertionResponseJson,
    String? confirmationPassphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.miningAllocations,
        data: {
          'walletName': walletName,
          'rigId': rigId,
          'requestedHashrate': requestedHashrate,
          'budgetBtc': budgetBtc,
          'durationHours': durationHours,
          'payoutAddress': payoutAddress,
          'poolUrl': poolUrl,
          'workerName': workerName,
          'totpCode': totpCode,
          if (passkeyAssertionResponseJson != null)
            'passkeyAssertionResponseJSON': passkeyAssertionResponseJson,
          if (confirmationPassphrase != null)
            'confirmationPassphrase': confirmationPassphrase,
        },
      );
      return MiningAllocation.fromJson(_parseMap(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar alocação de mineração: $e');
    }
  }

  Future<List<MiningAllocation>> getAllocations() async {
    try {
      final response = await apiClient.get(AppConfig.miningAllocations);
      return _parseList(response.data).map(MiningAllocation.fromJson).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao carregar alocações de mineração: $e',
      );
    }
  }

  Future<MiningAllocation> getAllocation(String allocationId) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.miningAllocations}/$allocationId',
      );
      return MiningAllocation.fromJson(_parseMap(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao consultar alocação de mineração: $e',
      );
    }
  }

  Future<MiningAllocation> cancelAllocation(String allocationId) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.miningAllocations}/$allocationId/cancel',
      );
      return MiningAllocation.fromJson(_parseMap(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao cancelar alocação de mineração: $e',
      );
    }
  }
}
