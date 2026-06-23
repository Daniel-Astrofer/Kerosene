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
    // Handle nested legacy data and direct KFE transaction responses.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final senderField = [data['sender'], data['from'], data['fromAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    final receiverField = [data['receiver'], data['to'], data['toAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);
    final networkFeeSats = (data['networkFeeSats'] as num?)?.toInt();
    final keroseneFeeSats = (data['keroseneFeeSats'] as num?)?.toInt() ?? 0;
    final receiverAmountSats = (data['receiverAmountSats'] as num?)?.toInt();
    final totalDebitSats = (data['totalDebitSats'] as num?)?.toInt();

    return TxStatus(
      txid: data['txid']?.toString() ??
          data['blockchainTxid']?.toString() ??
          data['externalReference']?.toString() ??
          data['id']?.toString() ??
          '',
      status: data['status']?.toString() ?? 'confirmed',
      feeSatoshis: (data['feeSatoshis'] as num?)?.toInt() ??
          (networkFeeSats == null ? null : networkFeeSats + keroseneFeeSats) ??
          (((data['networkFeeBtc'] as num?)?.toDouble() ?? 0) * 100000000)
              .round(),
      amountReceived: receiverAmountSats == null
          ? ((data['amount'] as num?)?.toDouble() ??
              (data['amountReceived'] as num?)?.toDouble() ??
              (data['amountBtc'] as num?)?.toDouble() ??
              0)
          : receiverAmountSats / 100000000.0,
      networkFeeBtc: networkFeeSats == null
          ? ((data['networkFeeBtc'] as num?)?.toDouble() ?? 0)
          : networkFeeSats / 100000000.0,
      platformFeeBtc: keroseneFeeSats == 0
          ? ((data['platformFeeBtc'] as num?)?.toDouble() ?? 0)
          : keroseneFeeSats / 100000000.0,
      totalDebitedBtc: totalDebitSats == null
          ? ((data['totalDebitedBtc'] as num?)?.toDouble() ?? 0)
          : totalDebitSats / 100000000.0,
      sender: senderField ??
          data['sourceWalletId']?.toString() ??
          data['walletName']?.toString() ??
          '',
      receiver: receiverField ??
          data['destinationWalletId']?.toString() ??
          data['destination']?.toString() ??
          data['paymentRequest']?.toString() ??
          data['externalReference']?.toString() ??
          '',
      context: data['context']?.toString() ??
          data['description']?.toString() ??
          data['memo']?.toString(),
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
