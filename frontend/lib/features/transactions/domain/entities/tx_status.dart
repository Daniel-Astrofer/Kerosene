import 'package:equatable/equatable.dart';

/// Status de uma transação Bitcoin na blockchain
class TxStatus extends Equatable {
  final String txid;
  final String status;
  final int feeSatoshis;
  final double amountReceived;

  const TxStatus({
    required this.txid,
    required this.status,
    required this.feeSatoshis,
    required this.amountReceived,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isBroadcasted => status == 'broadcasted';

  factory TxStatus.fromJson(Map<String, dynamic> json) {
    return TxStatus(
      txid: json['txid']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      feeSatoshis: (json['feeSatoshis'] as num?)?.toInt() ?? 0,
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [txid, status, feeSatoshis, amountReceived];
}
