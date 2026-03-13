import 'package:equatable/equatable.dart';

/// Estimativa de taxa de transação Bitcoin
class FeeEstimate extends Equatable {
  final double fastSatPerByte;
  final double standardSatPerByte;
  final double slowSatPerByte;
  final double estimatedFastBtc;
  final double estimatedStandardBtc;
  final double estimatedSlowBtc;
  final double amountReceived;
  final double totalToSend;

  const FeeEstimate({
    required this.fastSatPerByte,
    required this.standardSatPerByte,
    required this.slowSatPerByte,
    required this.estimatedFastBtc,
    required this.estimatedStandardBtc,
    required this.estimatedSlowBtc,
    required this.amountReceived,
    required this.totalToSend,
  });

  factory FeeEstimate.fromJson(Map<String, dynamic> json) {
    return FeeEstimate(
      fastSatPerByte: (json['fastSatPerByte'] as num?)?.toDouble() ?? 0,
      standardSatPerByte: (json['standardSatPerByte'] as num?)?.toDouble() ?? 0,
      slowSatPerByte: (json['slowSatPerByte'] as num?)?.toDouble() ?? 0,
      estimatedFastBtc: (json['estimatedFastBtc'] as num?)?.toDouble() ?? 0,
      estimatedStandardBtc:
          (json['estimatedStandardBtc'] as num?)?.toDouble() ?? 0,
      estimatedSlowBtc: (json['estimatedSlowBtc'] as num?)?.toDouble() ?? 0,
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0,
      totalToSend: (json['totalToSend'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    fastSatPerByte,
    standardSatPerByte,
    slowSatPerByte,
    estimatedFastBtc,
    estimatedStandardBtc,
    estimatedSlowBtc,
    amountReceived,
    totalToSend,
  ];
}
