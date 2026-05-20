import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/core/services/passkey_service.dart';
import 'package:teste/core/network/mempool_api_client_provider.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/data/models/mempool_transaction_models.dart';
import 'package:teste/features/mining/data/services/mining_marketplace_service.dart';
import 'package:teste/features/mining/data/services/mempool_service.dart';
import 'package:teste/features/mining/domain/entities/mining_allocation.dart';
import 'package:teste/features/mining/domain/entities/mining_rig_offer.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/core/providers/shared_preferences_provider.dart';

final mempoolServiceProvider = Provider<MempoolService>((ref) {
  return MempoolService(ref.watch(mempoolApiClientProvider));
});

final miningMarketplaceServiceProvider = Provider<MiningMarketplaceService>((
  ref,
) {
  return MiningMarketplaceService(ref.watch(apiClientProvider));
});

final mempoolMiningDashboardProvider =
    FutureProvider.autoDispose<MempoolMiningDashboardData>((ref) async {
  return ref.watch(mempoolServiceProvider).fetchDashboard();
});

final mempoolTransactionSummaryProvider =
    FutureProvider.autoDispose.family<MempoolTransactionSummary?, String>((
  ref,
  txid,
) async {
  return ref.watch(mempoolServiceProvider).fetchTransactionSummary(txid);
});

final miningRigOffersProvider =
    FutureProvider<List<MiningRigOffer>>((ref) async {
  final rigs = await ref.watch(miningMarketplaceServiceProvider).getRigOffers();
  final sorted = List<MiningRigOffer>.from(rigs)
    ..sort((a, b) => a.pricePerUnitDayBtc.compareTo(b.pricePerUnitDayBtc));
  return sorted;
});

final miningAllocationsProvider =
    FutureProvider<List<MiningAllocation>>((ref) async {
  final allocations =
      await ref.watch(miningMarketplaceServiceProvider).getAllocations();
  final sorted = List<MiningAllocation>.from(allocations)
    ..sort((a, b) {
      final left = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  return sorted;
});

final miningAllocationDetailProvider =
    FutureProvider.family<MiningAllocation, String>((ref, allocationId) async {
  return ref
      .watch(miningMarketplaceServiceProvider)
      .getAllocation(allocationId);
});

class MiningMarketplaceActionState {
  final bool isLoading;
  final String? error;
  final MiningAllocation? allocation;

  const MiningMarketplaceActionState({
    this.isLoading = false,
    this.error,
    this.allocation,
  });
}

class MiningMarketplaceActionNotifier
    extends Notifier<MiningMarketplaceActionState> {
  late MiningMarketplaceService _service;

  @override
  MiningMarketplaceActionState build() {
    _service = ref.watch(miningMarketplaceServiceProvider);
    return const MiningMarketplaceActionState();
  }

  Future<MiningAllocation?> createAllocation({
    required String walletName,
    required int rigId,
    double? requestedHashrate,
    double? budgetBtc,
    required int durationHours,
    required String payoutAddress,
    required String poolUrl,
    required String workerName,
    required String totpCode,
    String? confirmationPassphrase,
    String? passkeyAssertionResponseJson,
  }) async {
    state = const MiningMarketplaceActionState(isLoading: true);
    try {
      final allocation = await _service.createAllocation(
        walletName: walletName,
        rigId: rigId,
        requestedHashrate: requestedHashrate,
        budgetBtc: budgetBtc,
        durationHours: durationHours,
        payoutAddress: payoutAddress,
        poolUrl: poolUrl,
        workerName: workerName,
        totpCode: totpCode,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionResponseJson: passkeyAssertionResponseJson,
      );
      ref.invalidate(miningAllocationsProvider);
      await ref.read(walletProvider.notifier).refresh();
      state = MiningMarketplaceActionState(allocation: allocation);
      return allocation;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
        try {
          final challenge = _extractPasskeyChallenge(e);
          if (challenge == null) {
            throw StateError(
              'Não conseguimos iniciar a confirmação segura. Tente novamente.',
            );
          }

          final assertionJson = await _buildPasskeyAssertionJson(challenge);
          final allocation = await _service.createAllocation(
            walletName: walletName,
            rigId: rigId,
            requestedHashrate: requestedHashrate,
            budgetBtc: budgetBtc,
            durationHours: durationHours,
            payoutAddress: payoutAddress,
            poolUrl: poolUrl,
            workerName: workerName,
            totpCode: totpCode,
            confirmationPassphrase: confirmationPassphrase,
            passkeyAssertionResponseJson: assertionJson,
          );
          ref.invalidate(miningAllocationsProvider);
          await ref.read(walletProvider.notifier).refresh();
          state = MiningMarketplaceActionState(allocation: allocation);
          return allocation;
        } catch (signErr) {
          debugPrint('Mining allocation secure confirmation failed.');
          state = MiningMarketplaceActionState(error: signErr.toString());
          return null;
        }
      }
      state = MiningMarketplaceActionState(error: errorStr);
      return null;
    }
  }

  Future<MiningAllocation?> cancelAllocation(String allocationId) async {
    state = const MiningMarketplaceActionState(isLoading: true);
    try {
      final allocation = await _service.cancelAllocation(allocationId);
      ref.invalidate(miningAllocationsProvider);
      await ref.read(walletProvider.notifier).refresh();
      state = MiningMarketplaceActionState(allocation: allocation);
      return allocation;
    } catch (e) {
      state = MiningMarketplaceActionState(error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const MiningMarketplaceActionState();
  }
}

final miningMarketplaceActionProvider = NotifierProvider<
    MiningMarketplaceActionNotifier, MiningMarketplaceActionState>(
  MiningMarketplaceActionNotifier.new,
);

enum MiningOperationStatus {
  idle,
  active,
  completed,
}

class MiningOperationState {
  final double targetBtc;
  final int durationHours;
  final double contractedHashrateTh;
  final int startedAtEpochMs;

  const MiningOperationState({
    this.targetBtc = 0,
    this.durationHours = 0,
    this.contractedHashrateTh = 0,
    this.startedAtEpochMs = 0,
  });

  MiningOperationStatus get status {
    if (targetBtc <= 0 ||
        durationHours <= 0 ||
        contractedHashrateTh <= 0 ||
        startedAtEpochMs <= 0) {
      return MiningOperationStatus.idle;
    }

    if (isExpired) {
      return MiningOperationStatus.completed;
    }

    return MiningOperationStatus.active;
  }

  bool get isActive => status == MiningOperationStatus.active;

  bool get isExpired {
    if (startedAtEpochMs <= 0 || durationHours <= 0) return false;
    final endsAtMs = startedAtEpochMs + (durationHours * 3600 * 1000);
    return DateTime.now().millisecondsSinceEpoch >= endsAtMs;
  }

  DateTime? get startedAt => startedAtEpochMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(startedAtEpochMs)
      : null;

  DateTime? get endsAt => startedAt?.add(Duration(hours: durationHours));

  double progressAt(DateTime now) {
    if (targetBtc <= 0 || startedAt == null || endsAt == null) {
      return 0;
    }

    final total = endsAt!.difference(startedAt!).inMilliseconds;
    if (total <= 0) {
      return 1.0;
    }

    final elapsed = now.millisecondsSinceEpoch - startedAtEpochMs;
    final progress = elapsed / total;
    if (progress.isNaN) {
      return 0;
    }
    return progress.clamp(0.0, 1.0);
  }

  double minedBalanceAt(DateTime now) {
    return targetBtc * progressAt(now);
  }

  Duration remainingAt(DateTime now) {
    if (startedAtEpochMs <= 0 || endsAt == null) {
      return Duration.zero;
    }
    final remaining = endsAt!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  MiningOperationState copyWith({
    double? targetBtc,
    int? durationHours,
    double? contractedHashrateTh,
    int? startedAtEpochMs,
  }) {
    return MiningOperationState(
      targetBtc: targetBtc ?? this.targetBtc,
      durationHours: durationHours ?? this.durationHours,
      contractedHashrateTh: contractedHashrateTh ?? this.contractedHashrateTh,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
    );
  }
}

class MiningOperationNotifier extends Notifier<MiningOperationState> {
  static const _targetKey = 'mining_target_btc';
  static const _durationKey = 'mining_duration_hours';
  static const _hashrateKey = 'mining_hashrate_th';
  static const _startedAtKey = 'mining_started_at_ms';

  @override
  MiningOperationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return MiningOperationState(
      targetBtc: prefs.getDouble(_targetKey) ?? 0,
      durationHours: prefs.getInt(_durationKey) ?? 0,
      contractedHashrateTh: prefs.getDouble(_hashrateKey) ?? 0,
      startedAtEpochMs: prefs.getInt(_startedAtKey) ?? 0,
    );
  }

  Future<void> startOperation({
    required double targetBtc,
    required int durationHours,
    required double contractedHashrateTh,
  }) async {
    final nextState = MiningOperationState(
      targetBtc: targetBtc,
      durationHours: durationHours,
      contractedHashrateTh: contractedHashrateTh,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    state = nextState;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_targetKey, nextState.targetBtc);
    await prefs.setInt(_durationKey, nextState.durationHours);
    await prefs.setDouble(_hashrateKey, nextState.contractedHashrateTh);
    await prefs.setInt(_startedAtKey, nextState.startedAtEpochMs);
  }

  Future<void> clearOperation() async {
    state = const MiningOperationState();

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_targetKey);
    await prefs.remove(_durationKey);
    await prefs.remove(_hashrateKey);
    await prefs.remove(_startedAtKey);
  }
}

final miningOperationProvider =
    NotifierProvider<MiningOperationNotifier, MiningOperationState>(
  MiningOperationNotifier.new,
);

String? _extractPasskeyChallenge(Object error) {
  const marker = 'PASSKEY_CHALLENGE_REQUIRED:';
  final rawError = error.toString().trim();
  final candidates = <String>[rawError];

  try {
    final decoded = jsonDecode(rawError);
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim();
      final nestedError = decoded['error']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        candidates.insert(0, message);
      }

      if (nestedError != null && nestedError.isNotEmpty) {
        candidates.add(nestedError);
      }
    }
  } catch (_) {}

  final hexPattern = RegExp(
    '${RegExp.escape(marker)}([0-9a-fA-F]+)',
  );

  for (final candidate in candidates) {
    final hexMatch = hexPattern.firstMatch(candidate);
    if (hexMatch != null) {
      return hexMatch.group(1);
    }

    final markerIndex = candidate.indexOf(marker);
    if (markerIndex < 0) {
      continue;
    }

    var challenge = candidate.substring(markerIndex + marker.length).trim();
    challenge = challenge.replaceFirst(RegExp(r"""^['"]+"""), '');
    challenge = challenge.replaceFirst(RegExp(r"""['",}\]\s]+$"""), '');

    if (challenge.isNotEmpty) {
      return challenge;
    }
  }

  return null;
}

Future<String> _buildPasskeyAssertionJson(String challenge) async {
  final credential = await PasskeyService.instance.authenticate(
    challengeHex: challenge,
    username: 'mining',
  );
  return jsonEncode(credential);
}
