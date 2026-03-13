import 'package:equatable/equatable.dart';
import '../../../wallet/domain/entities/transaction.dart';

/// Entidade PaymentLink — link de pagamento Bitcoin
class PaymentLink extends Equatable {
  final String id;
  final int userId;
  final double amountBtc;
  final String description;
  final String depositAddress;
  final String status;
  final String? txid;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;

  const PaymentLink({
    required this.id,
    required this.userId,
    required this.amountBtc,
    required this.description,
    required this.depositAddress,
    required this.status,
    this.txid,
    this.expiresAt,
    this.createdAt,
    this.paidAt,
    this.completedAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCompleted => status == 'completed';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    return PaymentLink(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      amountBtc: (json['amountBtc'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      depositAddress: json['depositAddress']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      txid: json['txid']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amountBtc,
    description,
    depositAddress,
    status,
    txid,
    expiresAt,
    createdAt,
    paidAt,
    completedAt,
  ];

  /// Converte PaymentLink para Transaction para exibição no histórico unificado
  Transaction toTransaction() {
    final bool isCompleted = status == 'completed' || status == 'paid';
    return Transaction(
      id: "pl_$id",
      fromAddress: 'Rede Bitcoin',
      toAddress: depositAddress,
      amountSatoshis: (amountBtc * 100000000).round(),
      feeSatoshis: 0,
      status: isCompleted
          ? TransactionStatus.confirmed
          : TransactionStatus.pending,
      type: TransactionType.receive,
      confirmations: isCompleted ? 6 : 0,
      timestamp: createdAt ?? DateTime.now(),
      description: description.isNotEmpty ? description : "Link de Pagamento",
      isInternal: false,
    );
  }
}
