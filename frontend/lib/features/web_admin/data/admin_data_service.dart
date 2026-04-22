import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/errors/exceptions.dart';
import '../../transactions/domain/entities/external_transfer.dart';
import '../../transactions/domain/entities/payment_link.dart';
import '../../transactions/domain/entities/deposit.dart';
import '../../wallet/domain/entities/wallet.dart';
import '../../wallet/domain/entities/transaction.dart';

/// Enterprise data service that aggregates real API data for the web admin panel.
/// No mocks — every KPI is derived from live endpoint data.
class AdminDataService {
  final ApiClient _api;

  AdminDataService(this._api);

  // ─── Wallets ────────────────────────────────────
  Future<List<Wallet>> fetchWallets() async {
    try {
      final response = await _api.get(AppConfig.walletAll);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Wallet.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('AdminDataService.fetchWallets error: $e');
      return [];
    }
  }

  Future<double> fetchWalletBalance(String walletName) async {
    try {
      final response = await _api.get(
        AppConfig.ledgerBalance,
        queryParameters: {'walletName': walletName},
      );
      return double.tryParse(response.data.toString().trim()) ?? 0;
    } catch (e) {
      debugPrint('AdminDataService.fetchWalletBalance error: $e');
      return 0;
    }
  }

  // ─── Ledger History ─────────────────────────────
  Future<List<Transaction>> fetchLedgerHistory({
    int page = 0,
    int size = 200,
  }) async {
    try {
      final response = await _api.get(
        AppConfig.ledgerHistory,
        queryParameters: {'page': page, 'size': size},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Transaction.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('AdminDataService.fetchLedgerHistory error: $e');
      return [];
    }
  }

  // ─── External Transfers (on-chain + lightning) ──
  Future<List<ExternalTransfer>> fetchExternalTransfers() async {
    try {
      final response = await _api.get(AppConfig.transactionsNetworkTransfers);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => ExternalTransfer.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('AdminDataService.fetchExternalTransfers error: $e');
      return [];
    }
  }

  // ─── Payment Links ─────────────────────────────
  Future<List<PaymentLink>> fetchPaymentLinks() async {
    try {
      final response = await _api.get(AppConfig.transactionsPaymentLinksList);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentLink.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is AppException && e.statusCode == 403) return [];
      debugPrint('AdminDataService.fetchPaymentLinks error: $e');
      return [];
    }
  }

  // ─── Deposits ──────────────────────────────────
  Future<List<Deposit>> fetchDeposits() async {
    try {
      final response = await _api.get(AppConfig.transactionsDeposits);
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Deposit.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('AdminDataService.fetchDeposits error: $e');
      return [];
    }
  }

  // ─── Audit ─────────────────────────────────────
  Future<Map<String, dynamic>> fetchAuditStats() async {
    try {
      final response = await _api.get(AppConfig.auditStats);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      debugPrint('AdminDataService.fetchAuditStats error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchAuditLatestRoot() async {
    try {
      final response = await _api.get(AppConfig.auditMerkleLatestRoot);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      debugPrint('AdminDataService.fetchAuditLatestRoot error: $e');
      return {};
    }
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
      debugPrint('AdminDataService.fetchAuditHistory error: $e');
      return [];
    }
  }

  // ─── BTC Price ─────────────────────────────────
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
      debugPrint('AdminDataService.fetchBtcPrice error: $e');
      return {'btcUsd': 0, 'btcBrl': 0, 'usdBrl': 0};
    }
  }

  // ─── Sovereignty Status ────────────────────────
  Future<Map<String, dynamic>> fetchSovereigntyStatus() async {
    try {
      final response = await _api.get(AppConfig.sovereigntyStatus);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      debugPrint('AdminDataService.fetchSovereigntyStatus error: $e');
      return {};
    }
  }

  // ─── User Profile ─────────────────────────────
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    try {
      final response = await _api.get(AppConfig.authMe);
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      debugPrint('AdminDataService.fetchCurrentUser error: $e');
      return {};
    }
  }
}

/// Provider
final adminDataServiceProvider = Provider<AdminDataService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminDataService(apiClient);
});
