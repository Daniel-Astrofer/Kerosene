import 'package:equatable/equatable.dart';

enum MiningAllocationStatus { active, completed, cancelled, unknown }

MiningAllocationStatus miningAllocationStatusFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'ACTIVE':
      return MiningAllocationStatus.active;
    case 'COMPLETED':
      return MiningAllocationStatus.completed;
    case 'CANCELLED':
      return MiningAllocationStatus.cancelled;
    default:
      return MiningAllocationStatus.unknown;
  }
}

class MiningAllocation extends Equatable {
  final String id;
  final int rigId;
  final String rigName;
  final String walletName;
  final String algorithm;
  final double allocatedHashrate;
  final String hashUnit;
  final int durationHours;
  final double rentalCostBtc;
  final double projectedGrossYieldBtc;
  final double projectedNetYieldBtc;
  final double? refundedAmountBtc;
  final MiningAllocationStatus status;
  final String providerRentalReference;
  final String payoutAddress;
  final String poolUrl;
  final String workerName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? settledAt;

  const MiningAllocation({
    required this.id,
    required this.rigId,
    required this.rigName,
    required this.walletName,
    required this.algorithm,
    required this.allocatedHashrate,
    required this.hashUnit,
    required this.durationHours,
    required this.rentalCostBtc,
    required this.projectedGrossYieldBtc,
    required this.projectedNetYieldBtc,
    required this.refundedAmountBtc,
    required this.status,
    required this.providerRentalReference,
    required this.payoutAddress,
    required this.poolUrl,
    required this.workerName,
    required this.startsAt,
    required this.endsAt,
    required this.settledAt,
  });

  bool get isActive => status == MiningAllocationStatus.active;
  bool get isCompleted => status == MiningAllocationStatus.completed;
  bool get isCancelled => status == MiningAllocationStatus.cancelled;

  factory MiningAllocation.fromJson(Map<String, dynamic> json) {
    return MiningAllocation(
      id: json['id']?.toString() ?? '',
      rigId: (json['rigId'] as num?)?.toInt() ?? 0,
      rigName: json['rigName']?.toString() ?? '',
      walletName: json['walletName']?.toString() ?? '',
      algorithm: json['algorithm']?.toString() ?? '',
      allocatedHashrate: (json['allocatedHashrate'] as num?)?.toDouble() ?? 0,
      hashUnit: json['hashUnit']?.toString() ?? '',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      rentalCostBtc: (json['rentalCostBtc'] as num?)?.toDouble() ?? 0,
      projectedGrossYieldBtc:
          (json['projectedGrossYieldBtc'] as num?)?.toDouble() ?? 0,
      projectedNetYieldBtc:
          (json['projectedNetYieldBtc'] as num?)?.toDouble() ?? 0,
      refundedAmountBtc: (json['refundedAmountBtc'] as num?)?.toDouble(),
      status: miningAllocationStatusFromApi(json['status']?.toString()),
      providerRentalReference:
          json['providerRentalReference']?.toString() ?? '',
      payoutAddress: json['payoutAddress']?.toString() ?? '',
      poolUrl: json['poolUrl']?.toString() ?? '',
      workerName: json['workerName']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? '')?.toLocal(),
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? '')?.toLocal(),
      settledAt:
          DateTime.tryParse(json['settledAt']?.toString() ?? '')?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        rigId,
        rigName,
        walletName,
        algorithm,
        allocatedHashrate,
        hashUnit,
        durationHours,
        rentalCostBtc,
        projectedGrossYieldBtc,
        projectedNetYieldBtc,
        refundedAmountBtc,
        status,
        providerRentalReference,
        payoutAddress,
        poolUrl,
        workerName,
        startsAt,
        endsAt,
        settledAt,
      ];
}
