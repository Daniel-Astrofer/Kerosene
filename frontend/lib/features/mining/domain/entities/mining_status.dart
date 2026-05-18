import 'package:equatable/equatable.dart';

class MiningBlock extends Equatable {
  final String id;
  final int height;
  final int timestamp;
  final int txCount;
  final int size;
  final int weight;
  final double medianFee;
  final bool isProjected;
  final String? poolName;

  const MiningBlock({
    required this.id,
    required this.height,
    required this.timestamp,
    required this.txCount,
    required this.size,
    required this.weight,
    required this.medianFee,
    this.isProjected = false,
    this.poolName,
  });

  double get fullness => (weight / 4000000.0).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [id, height, timestamp, txCount, isProjected];
}

class NetworkMetrics extends Equatable {
  final double currentHashrate;
  final double difficultyChange;
  final int remainingBlocksToRetarget;
  final double progressToRetarget;
  final int currentHeight;

  const NetworkMetrics({
    required this.currentHashrate,
    required this.difficultyChange,
    required this.remainingBlocksToRetarget,
    required this.progressToRetarget,
    required this.currentHeight,
  });

  @override
  List<Object?> get props => [currentHashrate, difficultyChange, currentHeight];
}
