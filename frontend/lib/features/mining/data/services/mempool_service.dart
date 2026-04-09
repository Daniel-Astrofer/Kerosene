import 'package:teste/core/network/api_client.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';

class MempoolService {
  final ApiClient _client;

  MempoolService(this._client);

  MempoolMiningDashboardData? _lastValidData;

  Future<MempoolMiningDashboardData> fetchDashboard() async {
    final futures = [
      _getSafeJson('/mempool'),
      _getSafeJson('/v1/fees/recommended'),
      _getSafeJson('/v1/fees/mempool-blocks'),
      _getSafeJson('/v1/difficulty-adjustment'),
      _getSafeJson('/blocks'),
      _getSafeJson('/v1/mining/hashrate/3d'),
      _getSafeJson('/v1/mining/pools/1w'),
      _getSafeJson('/v1/mining/reward-stats/144'),
    ];

    final results = await Future.wait(futures);

    // If critical endpoints fail (mempool and fees), we might want to throw
    // but the requirement is to allow partial rendering.
    // For now, if we have a previous valid cache, use it for missing values.

    final poolsResponse = results[6] as Map<String, dynamic>?;

    final newData = MempoolMiningDashboardData(
      mempool: results[0] != null
          ? MempoolSnapshot.fromJson(results[0] as Map<String, dynamic>)
          : _lastValidData?.mempool ??
              const MempoolSnapshot(
                count: 0,
                vsize: 0,
                totalFee: 0,
                histogram: [],
              ),
      fees: results[1] != null
          ? MempoolFees.fromJson(results[1] as Map<String, dynamic>)
          : _lastValidData?.fees ??
              const MempoolFees(
                fastestFee: 0,
                halfHourFee: 0,
                hourFee: 0,
                economyFee: 0,
                minimumFee: 0,
              ),
      feeBlocks: results[2] != null
          ? (results[2] as List<dynamic>)
              .map((item) =>
                  MempoolFeeBlock.fromJson(item as Map<String, dynamic>))
              .toList()
          : _lastValidData?.feeBlocks ?? const [],
      difficulty: results[3] != null
          ? DifficultyAdjustmentInfo.fromJson(
              results[3] as Map<String, dynamic>,
            )
          : _lastValidData?.difficulty ??
              const DifficultyAdjustmentInfo(
                progressPercent: 0,
                difficultyChange: 0,
                estimatedRetargetDate: 0,
                remainingBlocks: 0,
                remainingTime: 0,
                previousRetarget: 0,
                previousTime: 0,
                nextRetargetHeight: 0,
                timeAvg: 0,
                adjustedTimeAvg: 0,
                expectedBlocks: 0,
              ),
      blocks: results[4] != null
          ? (results[4] as List<dynamic>)
              .map((item) => MempoolBlock.fromJson(item as Map<String, dynamic>))
              .toList()
          : _lastValidData?.blocks ?? const [],
      hashrate: results[5] != null
          ? MiningHashrateSnapshot.fromJson(
              results[5] as Map<String, dynamic>,
            )
          : _lastValidData?.hashrate ??
              const MiningHashrateSnapshot(
                hashrates: [],
                currentHashrate: 0,
                currentDifficulty: 0,
              ),
      pools: poolsResponse != null
          ? (poolsResponse['pools'] as List<dynamic>? ?? const [])
              .map((item) => MiningPool.fromJson(item as Map<String, dynamic>))
              .toList()
          : _lastValidData?.pools ?? const [],
      rewardStats: results[7] != null
          ? MiningRewardStats.fromJson(
              results[7] as Map<String, dynamic>,
            )
          : _lastValidData?.rewardStats ??
              const MiningRewardStats(
                startBlock: 0,
                endBlock: 0,
                totalRewardSat: 0,
                totalFeeSat: 0,
                totalTx: 0,
              ),
    );

    _lastValidData = newData;
    return newData;
  }

  Future<dynamic> _getSafeJson(String path) async {
    try {
      final response = await _client.get(path);
      return response.data;
    } catch (e) {
      // Log error but don't crash the whole flow
      print('Error fetching $path: $e');
      return null;
    }
  }
}
