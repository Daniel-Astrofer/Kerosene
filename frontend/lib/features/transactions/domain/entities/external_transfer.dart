import 'package:equatable/equatable.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

class ExternalTransfer extends Equatable {
  final String id;
  final String network;
  final String transferType;
  final String status;
  final String provider;
  final String walletName;
  final String destination;
  final double amountBtc;
  final double networkFeeBtc;
  final double platformFeeBtc;
  final double totalDebitedBtc;
  final String externalReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String context;

  const ExternalTransfer({
    required this.id,
    required this.network,
    required this.transferType,
    required this.status,
    required this.provider,
    required this.walletName,
    required this.destination,
    required this.amountBtc,
    required this.networkFeeBtc,
    required this.platformFeeBtc,
    required this.totalDebitedBtc,
    required this.externalReference,
    required this.createdAt,
    required this.updatedAt,
    required this.context,
  });

  bool get isLightning => network.toUpperCase() == 'LIGHTNING';
  bool get isOnchain => network.toUpperCase() == 'ONCHAIN';
  bool get isOutbound => transferType.toUpperCase() == 'OUTBOUND_PAYMENT';
  bool get isInboundInvoice => transferType.toUpperCase() == 'INBOUND_INVOICE';

  Transaction toTransaction() {
    final normalizedStatus = status.toUpperCase();
    final txStatus = switch (normalizedStatus) {
      'COMPLETED' || 'SETTLED' => TransactionStatus.confirmed,
      'CANCELLED' => TransactionStatus.failed,
      _ => TransactionStatus.pending,
    };
    return Transaction(
      id: externalReference.isNotEmpty ? externalReference : id,
      fromAddress: isOutbound ? walletName : 'Rede Bitcoin',
      toAddress: destination.isNotEmpty ? destination : walletName,
      amountSatoshis: (amountBtc.abs() * 100000000).round(),
      feeSatoshis: (networkFeeBtc.abs() * 100000000).round(),
      status: txStatus,
      type: isOutbound ? TransactionType.withdrawal : TransactionType.deposit,
      confirmations: 0,
      timestamp: createdAt ?? DateTime.now(),
      blockchainTxid: externalReference.isNotEmpty ? externalReference : null,
      description: context,
      isInternal: false,
    );
  }

  factory ExternalTransfer.fromJson(Map<String, dynamic> json) {
    return ExternalTransfer(
      id: json['id']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      transferType: json['transferType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      provider: json['provider']?.toString() ?? '',
      walletName: json['walletName']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      amountBtc: (json['amountBtc'] as num?)?.toDouble() ?? 0,
      networkFeeBtc: (json['networkFeeBtc'] as num?)?.toDouble() ?? 0,
      platformFeeBtc: (json['platformFeeBtc'] as num?)?.toDouble() ?? 0,
      totalDebitedBtc: (json['totalDebitedBtc'] as num?)?.toDouble() ?? 0,
      externalReference: json['externalReference']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
          ?.toLocal(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
          ?.toLocal(),
      context: json['context']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        network,
        transferType,
        status,
        provider,
        walletName,
        destination,
        amountBtc,
        networkFeeBtc,
        platformFeeBtc,
        totalDebitedBtc,
        externalReference,
        createdAt,
        updatedAt,
        context,
      ];
}
