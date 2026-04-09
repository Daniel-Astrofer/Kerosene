class MempoolMiningDashboardData {
  final MempoolSnapshot mempool;
  final MempoolFees fees;
  final List<MempoolFeeBlock> feeBlocks;
  final DifficultyAdjustmentInfo difficulty;
  final List<MempoolBlock> blocks;
  final MiningHashrateSnapshot hashrate;
  final List<MiningPool> pools;
  final MiningRewardStats rewardStats;

  const MempoolMiningDashboardData({
    required this.mempool,
    required this.fees,
    required this.feeBlocks,
    required this.difficulty,
    required this.blocks,
    required this.hashrate,
    required this.pools,
    required this.rewardStats,
  });

  double get dailyRewardBtc => rewardStats.totalRewardSat / 100000000.0;
  double get mempoolVsizeMb => mempool.vsize / 1000000.0;
  double get totalFeesBtc => mempool.totalFee / 100000000.0;
}

class MempoolFees {
  final int fastestFee;
  final int halfHourFee;
  final int hourFee;
  final int economyFee;
  final int minimumFee;

  const MempoolFees({
    required this.fastestFee,
    required this.halfHourFee,
    required this.hourFee,
    required this.economyFee,
    required this.minimumFee,
  });

  factory MempoolFees.fromJson(Map<String, dynamic> json) {
    return MempoolFees(
      fastestFee: _intOf(json['fastestFee']),
      halfHourFee: _intOf(json['halfHourFee']),
      hourFee: _intOf(json['hourFee']),
      economyFee: _intOf(json['economyFee']),
      minimumFee: _intOf(json['minimumFee']),
    );
  }
}

class MempoolSnapshot {
  final int count;
  final int vsize;
  final int totalFee;
  final List<FeeHistogramBin> histogram;

  const MempoolSnapshot({
    required this.count,
    required this.vsize,
    required this.totalFee,
    required this.histogram,
  });

  factory MempoolSnapshot.fromJson(Map<String, dynamic> json) {
    return MempoolSnapshot(
      count: _intOf(json['count']),
      vsize: _intOf(json['vsize']),
      totalFee: _intOf(json['total_fee']),
      histogram: ((json['fee_histogram'] as List<dynamic>? ?? const [])
          .map(
            (entry) => FeeHistogramBin.fromList(
              (entry as List<dynamic>).cast<dynamic>(),
            ),
          )
          .toList()),
    );
  }
}

class FeeHistogramBin {
  final double feeRate;
  final int vsize;

  const FeeHistogramBin({
    required this.feeRate,
    required this.vsize,
  });

  factory FeeHistogramBin.fromList(List<dynamic> values) {
    return FeeHistogramBin(
      feeRate: _doubleOf(values.isNotEmpty ? values[0] : 0),
      vsize: _intOf(values.length > 1 ? values[1] : 0),
    );
  }
}

class MempoolFeeBlock {
  final int blockSize;
  final double blockVSize;
  final int txCount;
  final int totalFees;
  final double medianFee;
  final List<double> feeRange;

  const MempoolFeeBlock({
    required this.blockSize,
    required this.blockVSize,
    required this.txCount,
    required this.totalFees,
    required this.medianFee,
    required this.feeRange,
  });

  factory MempoolFeeBlock.fromJson(Map<String, dynamic> json) {
    return MempoolFeeBlock(
      blockSize: _intOf(json['blockSize']),
      blockVSize: _doubleOf(json['blockVSize']),
      txCount: _intOf(json['nTx']),
      totalFees: _intOf(json['totalFees']),
      medianFee: _doubleOf(json['medianFee']),
      feeRange: (json['feeRange'] as List<dynamic>? ?? const [])
          .map(_doubleOf)
          .toList(),
    );
  }
}

class DifficultyAdjustmentInfo {
  final double progressPercent;
  final double difficultyChange;
  final int estimatedRetargetDate;
  final int remainingBlocks;
  final int remainingTime;
  final double previousRetarget;
  final int previousTime;
  final int nextRetargetHeight;
  final double timeAvg;
  final double adjustedTimeAvg;
  final double expectedBlocks;

  const DifficultyAdjustmentInfo({
    required this.progressPercent,
    required this.difficultyChange,
    required this.estimatedRetargetDate,
    required this.remainingBlocks,
    required this.remainingTime,
    required this.previousRetarget,
    required this.previousTime,
    required this.nextRetargetHeight,
    required this.timeAvg,
    required this.adjustedTimeAvg,
    required this.expectedBlocks,
  });

  factory DifficultyAdjustmentInfo.fromJson(Map<String, dynamic> json) {
    return DifficultyAdjustmentInfo(
      progressPercent: _doubleOf(json['progressPercent']),
      difficultyChange: _doubleOf(json['difficultyChange']),
      estimatedRetargetDate: _intOf(json['estimatedRetargetDate']),
      remainingBlocks: _intOf(json['remainingBlocks']),
      remainingTime: _intOf(json['remainingTime']),
      previousRetarget: _doubleOf(json['previousRetarget']),
      previousTime: _intOf(json['previousTime']),
      nextRetargetHeight: _intOf(json['nextRetargetHeight']),
      timeAvg: _doubleOf(json['timeAvg']),
      adjustedTimeAvg: _doubleOf(json['adjustedTimeAvg']),
      expectedBlocks: _doubleOf(json['expectedBlocks']),
    );
  }
}

class MempoolBlock {
  final String id;
  final int height;
  final int timestamp;
  final int txCount;
  final int size;
  final int weight;
  final double difficulty;

  const MempoolBlock({
    required this.id,
    required this.height,
    required this.timestamp,
    required this.txCount,
    required this.size,
    required this.weight,
    required this.difficulty,
  });

  factory MempoolBlock.fromJson(Map<String, dynamic> json) {
    return MempoolBlock(
      id: (json['id'] ?? '').toString(),
      height: _intOf(json['height']),
      timestamp: _intOf(json['timestamp']),
      txCount: _intOf(json['tx_count']),
      size: _intOf(json['size']),
      weight: _intOf(json['weight']),
      difficulty: _doubleOf(json['difficulty']),
    );
  }
}

class MiningHashrateSnapshot {
  final List<MiningHashratePoint> hashrates;
  final double currentHashrate;
  final double currentDifficulty;

  const MiningHashrateSnapshot({
    required this.hashrates,
    required this.currentHashrate,
    required this.currentDifficulty,
  });

  factory MiningHashrateSnapshot.fromJson(Map<String, dynamic> json) {
    return MiningHashrateSnapshot(
      hashrates: ((json['hashrates'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MiningHashratePoint.fromJson(
              (entry as Map<String, dynamic>),
            ),
          )
          .toList()),
      currentHashrate: _doubleOf(json['currentHashrate']),
      currentDifficulty: _doubleOf(json['currentDifficulty']),
    );
  }
}

class MiningHashratePoint {
  final int timestamp;
  final double avgHashrate;

  const MiningHashratePoint({
    required this.timestamp,
    required this.avgHashrate,
  });

  factory MiningHashratePoint.fromJson(Map<String, dynamic> json) {
    return MiningHashratePoint(
      timestamp: _intOf(json['timestamp']),
      avgHashrate: _doubleOf(json['avgHashrate']),
    );
  }
}

class MiningPool {
  final String name;
  final String link;
  final int blockCount;
  final int rank;
  final int emptyBlocks;
  final String slug;
  final double avgMatchRate;
  final String avgFeeDelta;

  const MiningPool({
    required this.name,
    required this.link,
    required this.blockCount,
    required this.rank,
    required this.emptyBlocks,
    required this.slug,
    required this.avgMatchRate,
    required this.avgFeeDelta,
  });

  factory MiningPool.fromJson(Map<String, dynamic> json) {
    return MiningPool(
      name: (json['name'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      blockCount: _intOf(json['blockCount']),
      rank: _intOf(json['rank']),
      emptyBlocks: _intOf(json['emptyBlocks']),
      slug: (json['slug'] ?? '').toString(),
      avgMatchRate: _doubleOf(json['avgMatchRate']),
      avgFeeDelta: (json['avgFeeDelta'] ?? '').toString(),
    );
  }
}

class MiningRewardStats {
  final int startBlock;
  final int endBlock;
  final int totalRewardSat;
  final int totalFeeSat;
  final int totalTx;

  const MiningRewardStats({
    required this.startBlock,
    required this.endBlock,
    required this.totalRewardSat,
    required this.totalFeeSat,
    required this.totalTx,
  });

  factory MiningRewardStats.fromJson(Map<String, dynamic> json) {
    return MiningRewardStats(
      startBlock: _intOf(json['startBlock']),
      endBlock: _intOf(json['endBlock']),
      totalRewardSat: _intOf(json['totalReward']),
      totalFeeSat: _intOf(json['totalFee']),
      totalTx: _intOf(json['totalTx']),
    );
  }
}

int _intOf(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  }
  return 0;
}

double _doubleOf(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
