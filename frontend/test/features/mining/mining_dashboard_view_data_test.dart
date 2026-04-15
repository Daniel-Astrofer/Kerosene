import 'package:flutter_test/flutter_test.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/presentation/models/mining_dashboard_view_data.dart';

void main() {
  group('MiningDashboardViewData', () {
    test('marks the mempool as saturated when depth and fees are high', () {
      final snapshot = _snapshot(
        priorityFee: 96,
        floorFee: 12,
        mempoolVsize: 6200000,
      );

      final viewData = MiningDashboardViewData(snapshot);

      expect(viewData.congestionLevel, MiningCongestionLevel.saturated);
      expect(viewData.congestionScore, greaterThan(0.75));
      expect(viewData.hasWideFeeSpread, isTrue);
    });

    test('keeps the mempool calm when queue depth and fees are low', () {
      final snapshot = _snapshot(
        priorityFee: 9,
        floorFee: 4,
        mempoolVsize: 700000,
      );

      final viewData = MiningDashboardViewData(snapshot);

      expect(viewData.congestionLevel, MiningCongestionLevel.calm);
      expect(viewData.congestionScore, lessThan(0.35));
      expect(viewData.projectedFastLaneWindowMinutes, greaterThan(0));
    });

    test(
        'projects mining revenue run-rate from reward window and block cadence',
        () {
      final snapshot = _snapshot(
        priorityFee: 18,
        floorFee: 6,
        mempoolVsize: 1400000,
      );

      final viewData = MiningDashboardViewData(snapshot);

      expect(viewData.averageRewardPerBlockBtc, closeTo(3.4791, 0.001));
      expect(viewData.miningRevenueRunRateBtcPerDay, closeTo(455.45, 0.2));
    });
  });
}

MiningDashboardSnapshot _snapshot({
  required int priorityFee,
  required int floorFee,
  required int mempoolVsize,
}) {
  return MiningDashboardSnapshot(
    network: MiningNetworkSnapshot(
      currentHashrate: 620000000000000000,
      currentDifficulty: 95,
      difficultyChangePercent: 2.6,
      retargetProgressPercent: 61,
      remainingBlocks: 780,
      nextRetargetHeight: 900000,
      estimatedRetargetAt: DateTime(2026, 4, 20),
      averageBlockIntervalSeconds: 620,
      adjustedBlockIntervalSeconds: 610,
      expectedBlocks: 144,
    ),
    feeMarket: MiningFeeMarketSnapshot(
      priorityFee: priorityFee,
      expressFee: (priorityFee * 0.7).round(),
      standardFee: (priorityFee * 0.45).round(),
      economyFee: (priorityFee * 0.2).round(),
      floorFee: floorFee,
    ),
    mempool: MiningMempoolSnapshot(
      pendingTransactions: 124000,
      virtualSize: mempoolVsize,
      totalFeesSat: 920000000,
      histogram: const [
        MiningHistogramBin(feeRate: 6, virtualSize: 120000),
        MiningHistogramBin(feeRate: 18, virtualSize: 240000),
        MiningHistogramBin(feeRate: 42, virtualSize: 420000),
        MiningHistogramBin(feeRate: 88, virtualSize: 360000),
      ],
    ),
    projectedBlocks: const [
      MiningProjectedBlockSnapshot(
        index: 0,
        txCount: 2400,
        blockSize: 1540000,
        blockVirtualSize: 990000,
        totalFeesSat: 14500000,
        medianFeeRate: 68,
        minFeeRate: 34,
        maxFeeRate: 120,
      ),
      MiningProjectedBlockSnapshot(
        index: 1,
        txCount: 2100,
        blockSize: 1490000,
        blockVirtualSize: 950000,
        totalFeesSat: 13200000,
        medianFeeRate: 44,
        minFeeRate: 16,
        maxFeeRate: 92,
      ),
    ],
    recentBlocks: [
      MiningBlockSnapshot(
        id: 'block-2',
        height: 899999,
        timestamp: DateTime(2026, 4, 15, 12, 0),
        txCount: 1820,
        sizeBytes: 1450000,
        weight: 3920000,
        difficulty: 95,
        medianFeeRate: 48,
        totalFeesSat: 13000000,
        rewardSat: 312500000,
        poolName: 'Ocean',
        poolSlug: 'ocean',
      ),
      MiningBlockSnapshot(
        id: 'block-1',
        height: 899998,
        timestamp: DateTime(2026, 4, 15, 11, 49),
        txCount: 1670,
        sizeBytes: 1400000,
        weight: 3860000,
        difficulty: 95,
        medianFeeRate: 36,
        totalFeesSat: 11800000,
        rewardSat: 312500000,
        poolName: 'Foundry',
        poolSlug: 'foundry',
      ),
    ],
    hashrateTimeline: [
      MiningHashratePointSnapshot(
        timestamp: DateTime(2026, 4, 15, 10, 0),
        hashrate: 610000000000000000,
      ),
      MiningHashratePointSnapshot(
        timestamp: DateTime(2026, 4, 15, 11, 0),
        hashrate: 618000000000000000,
      ),
      MiningHashratePointSnapshot(
        timestamp: DateTime(2026, 4, 15, 12, 0),
        hashrate: 624000000000000000,
      ),
    ],
    dominantPools: const [
      MiningPoolSnapshot(
        name: 'Foundry',
        link: '',
        blockCount: 42,
        rank: 1,
        emptyBlocks: 1,
        slug: 'foundry',
        averageMatchRate: 97.2,
        feeDeltaLabel: '+0.4%',
      ),
      MiningPoolSnapshot(
        name: 'Ocean',
        link: '',
        blockCount: 21,
        rank: 2,
        emptyBlocks: 0,
        slug: 'ocean',
        averageMatchRate: 96.1,
        feeDeltaLabel: '+0.2%',
      ),
    ],
    rewardWindow: const MiningRewardWindowSnapshot(
      startBlock: 899856,
      endBlock: 899999,
      totalRewardSat: 45000000000,
      totalFeeSat: 5100000000,
      totalTransactions: 220000,
    ),
    fetchedAt: DateTime(2026, 4, 15, 12, 1),
  );
}
