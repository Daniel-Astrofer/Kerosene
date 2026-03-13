import 'package:equatable/equatable.dart';

class UnsignedTransaction extends Equatable {
  final String rawTxHex;
  final String txId;
  final List<TransactionInput> inputs;
  final List<TransactionOutput> outputs;
  final double totalAmount;
  final int fee;
  final String fromAddress;
  final String toAddress;

  const UnsignedTransaction({
    required this.rawTxHex,
    required this.txId,
    required this.inputs,
    required this.outputs,
    required this.totalAmount,
    required this.fee,
    required this.fromAddress,
    required this.toAddress,
  });

  factory UnsignedTransaction.fromJson(Map<String, dynamic> json) {
    return UnsignedTransaction(
      rawTxHex: json['rawTxHex'] ?? '',
      txId: json['txId'] ?? '',
      inputs:
          (json['inputs'] as List?)
              ?.map((e) => TransactionInput.fromJson(e))
              .toList() ??
          [],
      outputs:
          (json['outputs'] as List?)
              ?.map((e) => TransactionOutput.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    rawTxHex,
    txId,
    inputs,
    outputs,
    totalAmount,
    fee,
    fromAddress,
    toAddress,
  ];
}

class TransactionInput extends Equatable {
  final String txid;
  final int vout;
  final double value;
  final String scriptPubKey;

  const TransactionInput({
    required this.txid,
    required this.vout,
    required this.value,
    required this.scriptPubKey,
  });

  factory TransactionInput.fromJson(Map<String, dynamic> json) {
    return TransactionInput(
      txid: json['txid'] ?? '',
      vout: (json['vout'] as num?)?.toInt() ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      scriptPubKey: json['scriptPubKey'] ?? '',
    );
  }

  @override
  List<Object?> get props => [txid, vout, value, scriptPubKey];
}

class TransactionOutput extends Equatable {
  final String address;
  final double value;

  const TransactionOutput({required this.address, required this.value});

  factory TransactionOutput.fromJson(Map<String, dynamic> json) {
    return TransactionOutput(
      address: json['address'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [address, value];
}
