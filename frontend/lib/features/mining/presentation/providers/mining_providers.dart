import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/mempool_api_client_provider.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/data/services/mempool_service.dart';
import 'package:teste/main.dart'; // To access sharedPreferencesProvider

final mempoolServiceProvider = Provider<MempoolService>((ref) {
  return MempoolService(ref.watch(mempoolApiClientProvider));
});

final mempoolMiningDashboardProvider =
    FutureProvider.autoDispose<MempoolMiningDashboardData>((ref) async {
  return ref.watch(mempoolServiceProvider).fetchDashboard();
});

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
