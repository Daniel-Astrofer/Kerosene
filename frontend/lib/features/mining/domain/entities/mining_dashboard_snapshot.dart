import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class MiningDashboardSnapshot extends Equatable {
  final MiningNetworkSnapshot network;
  final MiningFeeMarketSnapshot feeMarket;
  final MiningMempoolSnapshot mempool;
  final List<MiningProjectedBlockSnapshot> projectedBlocks;
  final List<MiningBlockSnapshot> recentBlocks;
  final List<MiningHashratePointSnapshot> hashrateTimeline;
  final List<MiningPoolSnapshot> dominantPools;
  final MiningRewardWindowSnapshot rewardWindow;
  final DateTime fetchedAt;

  const MiningDashboardSnapshot({
    required this.network,
    required this.feeMarket,
    required this.mempool,
    required this.projectedBlocks,
    required this.recentBlocks,
    required this.hashrateTimeline,
    required this.dominantPools,
    required this.rewardWindow,
    required this.fetchedAt,
  });

  int get currentHeight {
    if (recentBlocks.isNotEmpty) {
      return recentBlocks.first.height;
    }
    return math.max(0, network.nextRetargetHeight - network.remainingBlocks);
  }

  double get averageBlockIntervalSeconds {
    if (recentBlocks.length < 2) {
      return network.averageBlockIntervalSeconds;
    }

    final ordered = List<MiningBlockSnapshot>.from(recentBlocks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final newest = ordered.first.timestamp;
    final oldest = ordered.last.timestamp;
    final elapsedSeconds = newest.difference(oldest).inSeconds.abs();
    final sampleCount = math.max(1, ordered.length - 1);

    if (elapsedSeconds <= 0) {
      return network.averageBlockIntervalSeconds;
    }

    return elapsedSeconds / sampleCount;
  }

  double get throughputTransactionsPerSecond {
    final visibleBlocks = recentBlocks.take(6).toList(growable: false);
    if (visibleBlocks.isEmpty) {
      return 0;
    }

    final totalTransactions = visibleBlocks.fold<int>(
      0,
      (sum, block) => sum + block.txCount,
    );
    final observedSeconds = math.max(
      1.0,
      averageBlockIntervalSeconds * visibleBlocks.length,
    );

    return totalTransactions / observedSeconds;
  }

  double get recentAverageWeightRatio {
    if (recentBlocks.isEmpty) {
      return 0;
    }

    final total = recentBlocks.fold<double>(
      0,
      (sum, block) => sum + block.weightRatio,
    );
    return total / recentBlocks.length;
  }

  @override
  List<Object?> get props => [
        network,
        feeMarket,
        mempool,
        projectedBlocks,
        recentBlocks,
        hashrateTimeline,
        dominantPools,
        rewardWindow,
        fetchedAt,
      ];
}

class MiningNetworkSnapshot extends Equatable {
  final double currentHashrate;
  final double currentDifficulty;
  final double difficultyChangePercent;
  final double retargetProgressPercent;
  final int remainingBlocks;
  final int nextRetargetHeight;
  final DateTime? estimatedRetargetAt;
  final double averageBlockIntervalSeconds;
  final double adjustedBlockIntervalSeconds;
  final double expectedBlocks;

  const MiningNetworkSnapshot({
    required this.currentHashrate,
    required this.currentDifficulty,
    required this.difficultyChangePercent,
    required this.retargetProgressPercent,
    required this.remainingBlocks,
    required this.nextRetargetHeight,
    required this.estimatedRetargetAt,
    required this.averageBlockIntervalSeconds,
    required this.adjustedBlockIntervalSeconds,
    required this.expectedBlocks,
  });

  @override
  List<Object?> get props => [
        currentHashrate,
        currentDifficulty,
        difficultyChangePercent,
        retargetProgressPercent,
        remainingBlocks,
        nextRetargetHeight,
        estimatedRetargetAt,
        averageBlockIntervalSeconds,
        adjustedBlockIntervalSeconds,
        expectedBlocks,
      ];
}

class MiningFeeMarketSnapshot extends Equatable {
  final int priorityFee;
  final int expressFee;
  final int standardFee;
  final int economyFee;
  final int floorFee;

  const MiningFeeMarketSnapshot({
    required this.priorityFee,
    required this.expressFee,
    required this.standardFee,
    required this.economyFee,
    required this.floorFee,
  });

  int get spread => priorityFee - floorFee;

  @override
  List<Object?> get props => [
        priorityFee,
        expressFee,
        standardFee,
        economyFee,
        floorFee,
      ];
}

class MiningMempoolSnapshot extends Equatable {
  final int pendingTransactions;
  final int virtualSize;
  final int totalFeesSat;
  final List<MiningHistogramBin> histogram;

  const MiningMempoolSnapshot({
    required this.pendingTransactions,
    required this.virtualSize,
    required this.totalFeesSat,
    required this.histogram,
  });

  double get virtualSizeMb => virtualSize / 1000000.0;

  double get totalFeesBtc => totalFeesSat / 100000000.0;

  double get loadInBlocks => virtualSize / 1000000.0;

  @override
  List<Object?> get props => [
        pendingTransactions,
        virtualSize,
        totalFeesSat,
        histogram,
      ];
}

class MiningHistogramBin extends Equatable {
  final double feeRate;
  final int virtualSize;

  const MiningHistogramBin({
    required this.feeRate,
    required this.virtualSize,
  });

  @override
  List<Object?> get props => [feeRate, virtualSize];
}

class MiningProjectedBlockSnapshot extends Equatable {
  final int index;
  final int txCount;
  final int blockSize;
  final double blockVirtualSize;
  final int totalFeesSat;
  final double medianFeeRate;
  final double minFeeRate;
  final double maxFeeRate;

  const MiningProjectedBlockSnapshot({
    required this.index,
    required this.txCount,
    required this.blockSize,
    required this.blockVirtualSize,
    required this.totalFeesSat,
    required this.medianFeeRate,
    required this.minFeeRate,
    required this.maxFeeRate,
  });

  double get utilization => (blockVirtualSize / 1000000.0).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        index,
        txCount,
        blockSize,
        blockVirtualSize,
        totalFeesSat,
        medianFeeRate,
        minFeeRate,
        maxFeeRate,
      ];
}

class MiningBlockSnapshot extends Equatable {
  final String id;
  final int height;
  final DateTime timestamp;
  final int txCount;
  final int sizeBytes;
  final int weight;
  final double difficulty;
  final double? medianFeeRate;
  final int? totalFeesSat;
  final int? rewardSat;
  final String? poolName;
  final String? poolSlug;

  const MiningBlockSnapshot({
    required this.id,
    required this.height,
    required this.timestamp,
    required this.txCount,
    required this.sizeBytes,
    required this.weight,
    required this.difficulty,
    required this.medianFeeRate,
    required this.totalFeesSat,
    required this.rewardSat,
    required this.poolName,
    required this.poolSlug,
  });

  double get weightRatio => (weight / 4000000.0).clamp(0.0, 1.0);

  double get sizeMb => sizeBytes / 1000000.0;

  @override
  List<Object?> get props => [
        id,
        height,
        timestamp,
        txCount,
        sizeBytes,
        weight,
        difficulty,
        medianFeeRate,
        totalFeesSat,
        rewardSat,
        poolName,
        poolSlug,
      ];
}

class MiningHashratePointSnapshot extends Equatable {
  final DateTime timestamp;
  final double hashrate;

  const MiningHashratePointSnapshot({
    required this.timestamp,
    required this.hashrate,
  });

  @override
  List<Object?> get props => [timestamp, hashrate];
}

class MiningPoolSnapshot extends Equatable {
  final String name;
  final String link;
  final int blockCount;
  final int rank;
  final int emptyBlocks;
  final String slug;
  final double averageMatchRate;
  final String feeDeltaLabel;

  const MiningPoolSnapshot({
    required this.name,
    required this.link,
    required this.blockCount,
    required this.rank,
    required this.emptyBlocks,
    required this.slug,
    required this.averageMatchRate,
    required this.feeDeltaLabel,
  });

  @override
  List<Object?> get props => [
        name,
        link,
        blockCount,
        rank,
        emptyBlocks,
        slug,
        averageMatchRate,
        feeDeltaLabel,
      ];
}

class MiningRewardWindowSnapshot extends Equatable {
  final int startBlock;
  final int endBlock;
  final int totalRewardSat;
  final int totalFeeSat;
  final int totalTransactions;

  const MiningRewardWindowSnapshot({
    required this.startBlock,
    required this.endBlock,
    required this.totalRewardSat,
    required this.totalFeeSat,
    required this.totalTransactions,
  });

  int get observedBlocks => math.max(1, endBlock - startBlock + 1);

  double get feeSharePercent {
    if (totalRewardSat <= 0) {
      return 0;
    }
    return (totalFeeSat / totalRewardSat) * 100;
  }

  @override
  List<Object?> get props => [
        startBlock,
        endBlock,
        totalRewardSat,
        totalFeeSat,
        totalTransactions,
      ];
}
