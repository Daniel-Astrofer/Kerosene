import 'package:equatable/equatable.dart';

/// Status de uma transação Bitcoin na blockchain
class TxStatus extends Equatable {
  final String txid;
  final String status;
  final int feeSatoshis;
  final double amountReceived;
  final double networkFeeBtc;
  final double platformFeeBtc;
  final double totalDebitedBtc;
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
    this.networkFeeBtc = 0,
    this.platformFeeBtc = 0,
    this.totalDebitedBtc = 0,
    this.sender = '',
    this.receiver = '',
    this.context,
    this.message,
  });

  bool get isConfirmed => const {
        'confirmed',
        'completed',
        'settled',
        'paid',
      }.contains(status.toLowerCase());
  bool get isBroadcasted => const {
        'broadcasted',
        'accepted',
        'pending',
      }.contains(status.toLowerCase());

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
      txid: data['txid']?.toString() ??
          data['externalReference']?.toString() ??
          data['id']?.toString() ??
          '',
      status: data['status']?.toString() ?? 'confirmed',
      feeSatoshis: (data['feeSatoshis'] as num?)?.toInt() ??
          (((data['networkFeeBtc'] as num?)?.toDouble() ?? 0) * 100000000)
              .round(),
      amountReceived: (data['amount'] as num?)?.toDouble() ??
          (data['amountReceived'] as num?)?.toDouble() ??
          (data['amountBtc'] as num?)?.toDouble() ??
          0,
      networkFeeBtc: (data['networkFeeBtc'] as num?)?.toDouble() ?? 0,
      platformFeeBtc: (data['platformFeeBtc'] as num?)?.toDouble() ?? 0,
      totalDebitedBtc: (data['totalDebitedBtc'] as num?)?.toDouble() ?? 0,
      sender: senderField ?? data['walletName']?.toString() ?? '',
      receiver: receiverField ??
          data['destination']?.toString() ??
          data['paymentRequest']?.toString() ??
          '',
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
        networkFeeBtc,
        platformFeeBtc,
        totalDebitedBtc,
        sender,
        receiver,
        context,
        message,
      ];
}
