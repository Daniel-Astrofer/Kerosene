import 'package:equatable/equatable.dart';

/// Entidade Deposit — registro de depósito Bitcoin
class Deposit extends Equatable {
  final int id;
  final int userId;
  final String txid;
  final String fromAddress;
  final String toAddress;
  final double amountBtc;
  final int confirmations;
  final String status;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const Deposit({
    required this.id,
    required this.userId,
    required this.txid,
    required this.fromAddress,
    required this.toAddress,
    required this.amountBtc,
    required this.confirmations,
    required this.status,
    this.createdAt,
    this.confirmedAt,
  });

  bool get isCredited => status == 'credited';
  bool get isConfirmed => status == 'confirmed';

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      txid: json['txid']?.toString() ?? '',
      fromAddress: json['fromAddress']?.toString() ?? '',
      toAddress: json['toAddress']?.toString() ?? '',
      amountBtc: (json['amountBtc'] as num?)?.toDouble() ?? 0,
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    txid,
    fromAddress,
    toAddress,
    amountBtc,
    confirmations,
    status,
    createdAt,
    confirmedAt,
  ];
}
