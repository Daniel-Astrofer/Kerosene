import 'package:equatable/equatable.dart';

class MiningRigOffer extends Equatable {
  final int id;
  final String rigCode;
  final String displayName;
  final String algorithm;
  final String hashUnit;
  final double availableHashrate;
  final double pricePerUnitDayBtc;
  final double projectedBtcYieldPerUnitDay;
  final int minRentalHours;
  final int maxRentalHours;
  final String provider;

  const MiningRigOffer({
    required this.id,
    required this.rigCode,
    required this.displayName,
    required this.algorithm,
    required this.hashUnit,
    required this.availableHashrate,
    required this.pricePerUnitDayBtc,
    required this.projectedBtcYieldPerUnitDay,
    required this.minRentalHours,
    required this.maxRentalHours,
    required this.provider,
  });

  factory MiningRigOffer.fromJson(Map<String, dynamic> json) {
    return MiningRigOffer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rigCode: json['rigCode']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      algorithm: json['algorithm']?.toString() ?? '',
      hashUnit: json['hashUnit']?.toString() ?? '',
      availableHashrate: (json['availableHashrate'] as num?)?.toDouble() ?? 0,
      pricePerUnitDayBtc: (json['pricePerUnitDayBtc'] as num?)?.toDouble() ?? 0,
      projectedBtcYieldPerUnitDay:
          (json['projectedBtcYieldPerUnitDay'] as num?)?.toDouble() ?? 0,
      minRentalHours: (json['minRentalHours'] as num?)?.toInt() ?? 1,
      maxRentalHours: (json['maxRentalHours'] as num?)?.toInt() ?? 168,
      provider: json['provider']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        rigCode,
        displayName,
        algorithm,
        hashUnit,
        availableHashrate,
        pricePerUnitDayBtc,
        projectedBtcYieldPerUnitDay,
        minRentalHours,
        maxRentalHours,
        provider,
      ];
}
