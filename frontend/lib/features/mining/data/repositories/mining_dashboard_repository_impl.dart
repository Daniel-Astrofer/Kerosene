import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/data/services/mempool_service.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/domain/repositories/mining_dashboard_repository.dart';

class MiningDashboardRepositoryImpl implements MiningDashboardRepository {
  final MempoolService _mempoolService;

  MiningDashboardSnapshot? _cachedSnapshot;

  MiningDashboardRepositoryImpl(this._mempoolService);

  @override
  MiningDashboardSnapshot? get cachedSnapshot => _cachedSnapshot;

  @override
  Future<MiningDashboardSnapshot> fetchSnapshot() async {
    final data = await _mempoolService.fetchDashboard();

    final snapshot = MiningDashboardSnapshot(
      network: MiningNetworkSnapshot(
        currentHashrate: data.hashrate.currentHashrate,
        currentDifficulty: data.hashrate.currentDifficulty > 0
            ? data.hashrate.currentDifficulty
            : (data.blocks.isNotEmpty ? data.blocks.first.difficulty : 0),
        difficultyChangePercent: data.difficulty.difficultyChange,
        retargetProgressPercent: data.difficulty.progressPercent,
        remainingBlocks: data.difficulty.remainingBlocks,
        nextRetargetHeight: data.difficulty.nextRetargetHeight,
        estimatedRetargetAt: data.difficulty.estimatedRetargetDate > 0
            ? DateTime.fromMillisecondsSinceEpoch(
                data.difficulty.estimatedRetargetDate,
              )
            : null,
        averageBlockIntervalSeconds: _resolveAverageBlockInterval(data),
        adjustedBlockIntervalSeconds: _resolveAdjustedBlockInterval(data),
        expectedBlocks: data.difficulty.expectedBlocks,
      ),
      feeMarket: MiningFeeMarketSnapshot(
        priorityFee: data.fees.fastestFee,
        expressFee: data.fees.halfHourFee,
        standardFee: data.fees.hourFee,
        economyFee: data.fees.economyFee,
        floorFee: data.fees.minimumFee,
      ),
      mempool: MiningMempoolSnapshot(
        pendingTransactions: data.mempool.count,
        virtualSize: data.mempool.vsize,
        totalFeesSat: data.mempool.totalFee,
        histogram: data.mempool.histogram
            .map(
              (bin) => MiningHistogramBin(
                feeRate: bin.feeRate,
                virtualSize: bin.vsize,
              ),
            )
            .toList(growable: false),
      ),
      projectedBlocks: data.feeBlocks.asMap().entries.map((entry) {
        final block = entry.value;

        return MiningProjectedBlockSnapshot(
          index: entry.key,
          txCount: block.txCount,
          blockSize: block.blockSize,
          blockVirtualSize: block.blockVSize,
          totalFeesSat: block.totalFees,
          medianFeeRate: block.medianFee,
          minFeeRate: _minFee(block),
          maxFeeRate: _maxFee(block),
        );
      }).toList(growable: false),
      recentBlocks: data.blocks.map((block) {
        return MiningBlockSnapshot(
          id: block.id,
          height: block.height,
          timestamp: DateTime.fromMillisecondsSinceEpoch(block.timestamp * 1000),
          txCount: block.txCount,
          sizeBytes: block.size,
          weight: block.weight,
          difficulty: block.difficulty,
          medianFeeRate: block.medianFee,
          totalFeesSat: block.totalFees,
          rewardSat: block.reward,
          poolName: block.poolName,
          poolSlug: block.poolSlug,
        );
      }).toList(growable: false),
      hashrateTimeline: data.hashrate.hashrates.map((point) {
        return MiningHashratePointSnapshot(
          timestamp: DateTime.fromMillisecondsSinceEpoch(point.timestamp * 1000),
          hashrate: point.avgHashrate,
        );
      }).toList(growable: false),
      dominantPools: data.pools.map((pool) {
        return MiningPoolSnapshot(
          name: pool.name,
          link: pool.link,
          blockCount: pool.blockCount,
          rank: pool.rank,
          emptyBlocks: pool.emptyBlocks,
          slug: pool.slug,
          averageMatchRate: pool.avgMatchRate,
          feeDeltaLabel: pool.avgFeeDelta,
        );
      }).toList(growable: false),
      rewardWindow: MiningRewardWindowSnapshot(
        startBlock: data.rewardStats.startBlock,
        endBlock: data.rewardStats.endBlock,
        totalRewardSat: data.rewardStats.totalRewardSat,
        totalFeeSat: data.rewardStats.totalFeeSat,
        totalTransactions: data.rewardStats.totalTx,
      ),
      fetchedAt: DateTime.now(),
    );

    _cachedSnapshot = snapshot;
    return snapshot;
  }

  double _resolveAverageBlockInterval(MempoolMiningDashboardData data) {
    final raw = data.difficulty.timeAvg;
    if (raw <= 0) {
      return 600;
    }
    return raw > 100 ? raw : raw * 60;
  }

  double _resolveAdjustedBlockInterval(MempoolMiningDashboardData data) {
    final raw = data.difficulty.adjustedTimeAvg;
    if (raw <= 0) {
      return _resolveAverageBlockInterval(data);
    }
    return raw > 100 ? raw : raw * 60;
  }

  double _minFee(MempoolFeeBlock block) {
    if (block.feeRange.isEmpty) {
      return block.medianFee;
    }
    return block.feeRange.reduce((left, right) => left < right ? left : right);
  }

  double _maxFee(MempoolFeeBlock block) {
    if (block.feeRange.isEmpty) {
      return block.medianFee;
    }
    return block.feeRange.reduce((left, right) => left > right ? left : right);
  }
}
