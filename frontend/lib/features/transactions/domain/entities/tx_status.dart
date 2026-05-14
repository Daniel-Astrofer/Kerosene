import 'package:equatable/equatable.dart';

/// Status de uma transação Bitcoin na blockchain
class TxStatus extends Equatable {
  final String txid;
  final String status;
  final int feeSatoshis;
  final double amountReceived;
  final String sender;
  final String receiver;
  final String? context;

  /// Mensagem retornada pelo servidor (sucesso ou erro)
  final String? message;

  const TxStatus({
    required this.txid,
    required this.status,
    required this.feeSatoshis,
    required this.amountReceived,
    this.sender = '',
    this.receiver = '',
    this.context,
    this.message,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isBroadcasted => status == 'broadcasted' || status == 'accepted';

  factory TxStatus.fromJson(Map<String, dynamic> json) {
    // Handle the nested 'data' object returned by /ledger/transaction
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final senderField = [data['sender'], data['from'], data['fromAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    final receiverField = [data['receiver'], data['to'], data['toAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    return TxStatus(
      txid: data['txid']?.toString() ?? data['id']?.toString() ?? '',
      status: data['status']?.toString() ?? 'confirmed',
      feeSatoshis: (data['feeSatoshis'] as num?)?.toInt() ?? 0,
      amountReceived:
          (data['amount'] as num?)?.toDouble() ??
          (data['amountReceived'] as num?)?.toDouble() ??
          0,
      sender: senderField ?? '',
      receiver: receiverField ?? '',
      context: data['context']?.toString() ?? data['description']?.toString(),
      message: json['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    txid,
    status,
    feeSatoshis,
    amountReceived,
    sender,
    receiver,
    context,
    message,
  ];
}
