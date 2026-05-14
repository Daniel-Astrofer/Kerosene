import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/providers/network_status_provider.dart';
import 'package:teste/features/mining/data/repositories/mining_dashboard_repository_impl.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/domain/repositories/mining_dashboard_repository.dart';
import 'package:teste/features/mining/presentation/models/mining_dashboard_view_data.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';

enum MiningSyncPhase {
  initialLoading,
  live,
  refreshing,
  stale,
  degraded,
  reconnecting,
  offline,
  error,
  empty,
}

enum MiningRefreshReason {
  bootstrap,
  polling,
  manual,
  networkRecovered,
}

class MiningDashboardState extends Equatable {
  final MiningDashboardSnapshot? snapshot;
  final MiningSyncPhase phase;
  final DateTime? lastUpdatedAt;
  final DateTime? lastSuccessfulSyncAt;
  final Set<int> highlightedHeights;
  final String? errorMessage;

  const MiningDashboardState({
    this.snapshot,
    this.phase = MiningSyncPhase.initialLoading,
    this.lastUpdatedAt,
    this.lastSuccessfulSyncAt,
    this.highlightedHeights = const <int>{},
    this.errorMessage,
  });

  bool get hasSnapshot => snapshot != null;

  MiningDashboardState copyWith({
    MiningDashboardSnapshot? snapshot,
    MiningSyncPhase? phase,
    DateTime? lastUpdatedAt,
    DateTime? lastSuccessfulSyncAt,
    Set<int>? highlightedHeights,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MiningDashboardState(
      snapshot: snapshot ?? this.snapshot,
      phase: phase ?? this.phase,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      highlightedHeights: highlightedHeights ?? this.highlightedHeights,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        snapshot,
        phase,
        lastUpdatedAt,
        lastSuccessfulSyncAt,
        highlightedHeights,
        errorMessage,
      ];
}

class MiningSyncMeta extends Equatable {
  final MiningSyncPhase phase;
  final DateTime? lastUpdatedAt;
  final DateTime? lastSuccessfulSyncAt;
  final String? errorMessage;

  const MiningSyncMeta({
    required this.phase,
    required this.lastUpdatedAt,
    required this.lastSuccessfulSyncAt,
    required this.errorMessage,
  });

  bool get isLive => phase == MiningSyncPhase.live;

  bool get hasWarning => phase == MiningSyncPhase.degraded ||
      phase == MiningSyncPhase.reconnecting ||
      phase == MiningSyncPhase.stale ||
      phase == MiningSyncPhase.offline ||
      phase == MiningSyncPhase.error;

  @override
  List<Object?> get props => [
        phase,
        lastUpdatedAt,
        lastSuccessfulSyncAt,
        errorMessage,
      ];
}

final miningDashboardRepositoryProvider = Provider.autoDispose<MiningDashboardRepository>((
  ref,
) {
  return MiningDashboardRepositoryImpl(ref.watch(mempoolServiceProvider));
});

final miningDashboardControllerProvider =
    NotifierProvider.autoDispose<MiningDashboardController, MiningDashboardState>(
  MiningDashboardController.new,
);

final miningSnapshotProvider = Provider.autoDispose<MiningDashboardSnapshot?>((ref) {
  return ref.watch(
    miningDashboardControllerProvider.select((state) => state.snapshot),
  );
});

final miningDashboardViewDataProvider = Provider.autoDispose<MiningDashboardViewData?>((
  ref,
) {
  final snapshot = ref.watch(miningSnapshotProvider);
  if (snapshot == null) {
    return null;
  }
  return MiningDashboardViewData(snapshot);
});

final miningSyncMetaProvider = Provider.autoDispose<MiningSyncMeta>((ref) {
  return MiningSyncMeta(
    phase: ref.watch(
      miningDashboardControllerProvider.select((state) => state.phase),
    ),
    lastUpdatedAt: ref.watch(
      miningDashboardControllerProvider.select((state) => state.lastUpdatedAt),
    ),
    lastSuccessfulSyncAt: ref.watch(
      miningDashboardControllerProvider.select(
        (state) => state.lastSuccessfulSyncAt,
      ),
    ),
    errorMessage: ref.watch(
      miningDashboardControllerProvider.select((state) => state.errorMessage),
    ),
  );
});

final miningHighlightedHeightsProvider = Provider.autoDispose<Set<int>>((ref) {
  return ref.watch(
    miningDashboardControllerProvider.select(
      (state) => state.highlightedHeights,
    ),
  );
});

class MiningDashboardController extends Notifier<MiningDashboardState> {
  static const Duration _steadyPollInterval = Duration(seconds: 12);
  static const Duration _staleThreshold = Duration(seconds: 32);
  static const Duration _highlightDuration = Duration(seconds: 10);

  Timer? _pollTimer;
  Timer? _staleTimer;
  Timer? _highlightTimer;
  bool _isRefreshing = false;
  int _failureCount = 0;

  late final MiningDashboardRepository _repository;

  @override
  MiningDashboardState build() {
    _repository = ref.watch(miningDashboardRepositoryProvider);

    ref.onDispose(() {
      _pollTimer?.cancel();
      _staleTimer?.cancel();
      _highlightTimer?.cancel();
    });

    ref.listen<bool>(networkStatusProvider, (previous, next) {
      if (next == false) {
        state = state.copyWith(
          phase: state.hasSnapshot
              ? MiningSyncPhase.reconnecting
              : MiningSyncPhase.offline,
        );
        return;
      }

      if (previous == false && next == true) {
        unawaited(refresh(reason: MiningRefreshReason.networkRecovered));
      }
    });

    _staleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshStaleness();
    });

    scheduleMicrotask(() {
      unawaited(refresh(reason: MiningRefreshReason.bootstrap));
    });

    final cachedSnapshot = _repository.cachedSnapshot;
    if (cachedSnapshot != null) {
      return MiningDashboardState(
        snapshot: cachedSnapshot,
        phase: MiningSyncPhase.refreshing,
        lastUpdatedAt: cachedSnapshot.fetchedAt,
        lastSuccessfulSyncAt: cachedSnapshot.fetchedAt,
      );
    }

    return const MiningDashboardState();
  }

  Future<void> refresh({
    MiningRefreshReason reason = MiningRefreshReason.manual,
  }) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _pollTimer?.cancel();

    final hadSnapshot = state.hasSnapshot;
    state = state.copyWith(
      phase: _phaseWhileRefreshing(reason, hadSnapshot),
      clearError: true,
    );

    try {
      final previousHeights = state.snapshot?.recentBlocks
              .map((block) => block.height)
              .toSet() ??
          const <int>{};
      final snapshot = await _repository.fetchSnapshot();
      final newHeights = snapshot.recentBlocks
          .where((block) => !previousHeights.contains(block.height))
          .map((block) => block.height)
          .toSet();

      _failureCount = 0;
      _queueHighlightReset(newHeights);
      state = state.copyWith(
        snapshot: snapshot,
        phase: snapshot.recentBlocks.isEmpty
            ? MiningSyncPhase.empty
            : MiningSyncPhase.live,
        lastUpdatedAt: snapshot.fetchedAt,
        lastSuccessfulSyncAt: snapshot.fetchedAt,
        highlightedHeights: newHeights,
        clearError: true,
      );
    } catch (error) {
      _failureCount += 1;
      final isOnline = ref.read(networkStatusProvider);

      state = state.copyWith(
        phase: _phaseOnFailure(hasSnapshot: hadSnapshot, isOnline: isOnline),
        errorMessage: error.toString(),
        highlightedHeights: const <int>{},
      );
    } finally {
      _isRefreshing = false;
      _scheduleNextPoll();
      _refreshStaleness();
    }
  }

  MiningSyncPhase _phaseWhileRefreshing(
    MiningRefreshReason reason,
    bool hadSnapshot,
  ) {
    if (!hadSnapshot) {
      return MiningSyncPhase.initialLoading;
    }

    switch (reason) {
      case MiningRefreshReason.networkRecovered:
        return MiningSyncPhase.reconnecting;
      case MiningRefreshReason.bootstrap:
      case MiningRefreshReason.manual:
      case MiningRefreshReason.polling:
        return MiningSyncPhase.refreshing;
    }
  }

  MiningSyncPhase _phaseOnFailure({
    required bool hasSnapshot,
    required bool isOnline,
  }) {
    if (!hasSnapshot) {
      return isOnline ? MiningSyncPhase.error : MiningSyncPhase.offline;
    }

    return isOnline ? MiningSyncPhase.degraded : MiningSyncPhase.reconnecting;
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    final seconds = _failureCount == 0
        ? _steadyPollInterval.inSeconds
        : math.min(60, 8 * (_failureCount + 1));

    _pollTimer = Timer(Duration(seconds: seconds), () {
      unawaited(refresh(reason: MiningRefreshReason.polling));
    });
  }

  void _refreshStaleness() {
    final lastSuccess = state.lastSuccessfulSyncAt;
    if (lastSuccess == null) {
      return;
    }

    final currentPhase = state.phase;
    final shouldMarkStale = DateTime.now().difference(lastSuccess) > _staleThreshold;
    if (shouldMarkStale && currentPhase == MiningSyncPhase.live) {
      state = state.copyWith(phase: MiningSyncPhase.stale);
      return;
    }

    if (!shouldMarkStale && currentPhase == MiningSyncPhase.stale) {
      state = state.copyWith(phase: MiningSyncPhase.live);
    }
  }

  void _queueHighlightReset(Set<int> highlightedHeights) {
    _highlightTimer?.cancel();
    if (highlightedHeights.isEmpty) {
      return;
    }

    _highlightTimer = Timer(_highlightDuration, () {
      state = state.copyWith(highlightedHeights: const <int>{});
    });
  }
}
