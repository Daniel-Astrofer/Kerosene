import 'dart:math' as math;

import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';

enum MiningCongestionLevel {
  calm,
  elevated,
  busy,
  saturated,
}

class MiningDashboardViewData {
  final MiningDashboardSnapshot snapshot;

  const MiningDashboardViewData(this.snapshot);

  double get mempoolDepthInBlocks => snapshot.mempool.loadInBlocks;

  double get weightedProjectedUtilization {
    if (snapshot.projectedBlocks.isEmpty) {
      return snapshot.recentAverageWeightRatio;
    }

    final visible = snapshot.projectedBlocks.take(4).toList(growable: false);
    final total =
        visible.fold<double>(0, (sum, block) => sum + block.utilization);
    return total / visible.length;
  }

  double get priorityToFloorRatio {
    final floor = math.max(1, snapshot.feeMarket.floorFee);
    return snapshot.feeMarket.priorityFee / floor;
  }

  MiningCongestionLevel get congestionLevel {
    if (mempoolDepthInBlocks >= 5.0 ||
        snapshot.feeMarket.priorityFee >= 80 ||
        priorityToFloorRatio >= 6) {
      return MiningCongestionLevel.saturated;
    }

    if (mempoolDepthInBlocks >= 3.0 ||
        snapshot.feeMarket.priorityFee >= 45 ||
        priorityToFloorRatio >= 4) {
      return MiningCongestionLevel.busy;
    }

    if (mempoolDepthInBlocks >= 1.5 ||
        snapshot.feeMarket.priorityFee >= 20 ||
        priorityToFloorRatio >= 2.5) {
      return MiningCongestionLevel.elevated;
    }

    return MiningCongestionLevel.calm;
  }

  String get congestionLabel {
    switch (congestionLevel) {
      case MiningCongestionLevel.calm:
        return 'Fluxo estável';
      case MiningCongestionLevel.elevated:
        return 'Pressão moderada';
      case MiningCongestionLevel.busy:
        return 'Mempool pressionada';
      case MiningCongestionLevel.saturated:
        return 'Congestionamento alto';
    }
  }

  String get congestionSupportLabel {
    final depth = mempoolDepthInBlocks.toStringAsFixed(1);
    switch (congestionLevel) {
      case MiningCongestionLevel.calm:
        return 'Fila abaixo de $depth blocos virtuais.';
      case MiningCongestionLevel.elevated:
        return 'A fila já ocupa ~$depth blocos e exige seleção de taxa.';
      case MiningCongestionLevel.busy:
        return 'Mais de $depth blocos competindo por inclusão imediata.';
      case MiningCongestionLevel.saturated:
        return 'A fila ultrapassa $depth blocos e as taxas disparam.';
    }
  }

  double get congestionScore {
    final feeScore = (snapshot.feeMarket.priorityFee / 120).clamp(0.0, 1.0);
    final depthScore = (mempoolDepthInBlocks / 6).clamp(0.0, 1.0);
    final utilizationScore = weightedProjectedUtilization.clamp(0.0, 1.0);

    return (feeScore * 0.42) + (depthScore * 0.38) + (utilizationScore * 0.20);
  }

  double get feeSpreadRatio {
    final floor = math.max(1, snapshot.feeMarket.floorFee);
    return snapshot.feeMarket.spread / floor;
  }

  bool get hasWideFeeSpread => snapshot.feeMarket.spread >= 25;

  double get nextBlockMinimumFee {
    if (snapshot.projectedBlocks.isEmpty) {
      return snapshot.feeMarket.floorFee.toDouble();
    }
    return snapshot.projectedBlocks.first.minFeeRate;
  }

  double get nextBlockMedianFee {
    if (snapshot.projectedBlocks.isEmpty) {
      return snapshot.feeMarket.standardFee.toDouble();
    }
    return snapshot.projectedBlocks.first.medianFeeRate;
  }

  double get nextBlockMaximumFee {
    if (snapshot.projectedBlocks.isEmpty) {
      return snapshot.feeMarket.priorityFee.toDouble();
    }
    return snapshot.projectedBlocks.first.maxFeeRate;
  }

  int get projectedFastLaneWindowMinutes {
    final visibleBlocks =
        math.max(1, math.min(snapshot.projectedBlocks.length, 3));
    return ((snapshot.averageBlockIntervalSeconds / 60) * visibleBlocks)
        .round();
  }

  double get feeSharePercent => snapshot.rewardWindow.feeSharePercent;

  double get averageRewardPerBlockBtc {
    final observedBlocks = math.max(1, snapshot.rewardWindow.observedBlocks);
    final totalSats = snapshot.rewardWindow.totalRewardSat +
        snapshot.rewardWindow.totalFeeSat;
    return (totalSats / observedBlocks) / 100000000.0;
  }

  double get miningRevenueRunRateBtcPerDay {
    final intervalSeconds = math.max(1.0, snapshot.averageBlockIntervalSeconds);
    final projectedBlocksPerDay = 86400.0 / intervalSeconds;
    return averageRewardPerBlockBtc * projectedBlocksPerDay;
  }

  double get latestHashrateDeltaPercent {
    if (snapshot.hashrateTimeline.length < 2) {
      return 0;
    }

    final latest = snapshot.hashrateTimeline.last.hashrate;
    final previous = snapshot
        .hashrateTimeline[snapshot.hashrateTimeline.length - 2].hashrate;
    if (previous == 0) {
      return 0;
    }

    return ((latest - previous) / previous) * 100;
  }

  double get leadingPoolSharePercent {
    if (snapshot.dominantPools.isEmpty) {
      return 0;
    }

    final total = snapshot.dominantPools.fold<int>(
      0,
      (sum, pool) => sum + pool.blockCount,
    );
    if (total == 0) {
      return 0;
    }

    return (snapshot.dominantPools.first.blockCount / total) * 100;
  }

  String get liveNarrative {
    final blockTimeMinutes =
        (snapshot.averageBlockIntervalSeconds / 60).toStringAsFixed(1);
    switch (congestionLevel) {
      case MiningCongestionLevel.calm:
        return 'Blocos fechando em ~$blockTimeMinutes min com fila bem distribuida.';
      case MiningCongestionLevel.elevated:
        return 'A janela prioritária apertou, mas a fila segue absorvível.';
      case MiningCongestionLevel.busy:
        return 'Seleção por taxa está pesada e a competição já afeta a inclusão.';
      case MiningCongestionLevel.saturated:
        return 'A rede está em modo de disputa intensa por espaço em bloco.';
    }
  }
}
