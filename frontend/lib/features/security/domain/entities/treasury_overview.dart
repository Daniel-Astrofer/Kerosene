import 'package:equatable/equatable.dart';

class TreasuryOverview extends Equatable {
  final double totalOnchainBtc;
  final double lightningNodeBtc;
  final double inboundLiquidityBtc;
  final double outboundLiquidityBtc;
  final double reservedOnchainBtc;
  final double reservedLightningBtc;
  final double availableOnchainBtc;
  final double availableLightningBtc;
  final bool lightningSendsAllowed;
  final String liquidityState;

  const TreasuryOverview({
    required this.totalOnchainBtc,
    required this.lightningNodeBtc,
    required this.inboundLiquidityBtc,
    required this.outboundLiquidityBtc,
    required this.reservedOnchainBtc,
    required this.reservedLightningBtc,
    required this.availableOnchainBtc,
    required this.availableLightningBtc,
    required this.lightningSendsAllowed,
    required this.liquidityState,
  });

  factory TreasuryOverview.fromJson(Map<String, dynamic> json) {
    return TreasuryOverview(
      totalOnchainBtc: (json['totalOnchainBtc'] as num?)?.toDouble() ?? 0,
      lightningNodeBtc: (json['lightningNodeBtc'] as num?)?.toDouble() ?? 0,
      inboundLiquidityBtc:
          (json['inboundLiquidityBtc'] as num?)?.toDouble() ?? 0,
      outboundLiquidityBtc:
          (json['outboundLiquidityBtc'] as num?)?.toDouble() ?? 0,
      reservedOnchainBtc: (json['reservedOnchainBtc'] as num?)?.toDouble() ?? 0,
      reservedLightningBtc:
          (json['reservedLightningBtc'] as num?)?.toDouble() ?? 0,
      availableOnchainBtc:
          (json['availableOnchainBtc'] as num?)?.toDouble() ?? 0,
      availableLightningBtc:
          (json['availableLightningBtc'] as num?)?.toDouble() ?? 0,
      lightningSendsAllowed: json['lightningSendsAllowed'] == true,
      liquidityState: json['liquidityState']?.toString() ?? 'UNKNOWN',
    );
  }

  @override
  List<Object?> get props => [
        totalOnchainBtc,
        lightningNodeBtc,
        inboundLiquidityBtc,
        outboundLiquidityBtc,
        reservedOnchainBtc,
        reservedLightningBtc,
        availableOnchainBtc,
        availableLightningBtc,
        lightningSendsAllowed,
        liquidityState,
      ];
}
