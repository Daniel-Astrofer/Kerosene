import 'package:equatable/equatable.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';

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
  final String invoiceId;
  final String blockchainTxid;
  final String paymentHash;
  final String invoiceData;
  final double expectedAmountBtc;
  final int confirmations;
  final DateTime? detectedAt;
  final DateTime? settledAt;
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
    required this.invoiceId,
    required this.blockchainTxid,
    required this.paymentHash,
    required this.invoiceData,
    required this.expectedAmountBtc,
    required this.confirmations,
    required this.detectedAt,
    required this.settledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.context,
  });

  bool get isLightning => network.toUpperCase() == 'LIGHTNING';
  bool get isOnchain => network.toUpperCase() == 'ONCHAIN';
  bool get isOutbound => transferType.toUpperCase() == 'OUTBOUND_PAYMENT';
  bool get isInboundInvoice => transferType.toUpperCase() == 'INBOUND_INVOICE';
  bool get isInboundTransfer =>
      transferType.toUpperCase() == 'ADDRESS_ISSUE' ||
      transferType.toUpperCase() == 'ONRAMP_PURCHASE' ||
      transferType.toUpperCase() == 'INBOUND_INVOICE';
  bool get hasDetectedOnchainTransaction =>
      blockchainTxid.trim().isNotEmpty || confirmations > 0;
  bool get canCancelPendingReceive =>
      isInboundTransfer &&
      status.toUpperCase() == 'PENDING' &&
      !hasDetectedOnchainTransaction;

  Transaction toTransaction() {
    final normalizedStatus = status.toUpperCase();
    final txStatus = switch (normalizedStatus) {
      'COMPLETED' ||
      'SETTLED' ||
      'CONFIRMED' ||
      'PAID' =>
        TransactionStatus.confirmed,
      'CANCELLED' || 'EXPIRED' || 'FAILED' => TransactionStatus.failed,
      _ => confirmations > 0
          ? TransactionStatus.confirming
          : TransactionStatus.pending,
    };
    final transactionId = [
      blockchainTxid,
      paymentHash,
      externalReference,
      invoiceId,
      id,
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => id);
    final displayAmountBtc =
        amountBtc.abs() > 0 ? amountBtc : expectedAmountBtc;
    return Transaction(
      id: transactionId,
      fromAddress: isOutbound ? walletName : '',
      toAddress: destination.isNotEmpty ? destination : walletName,
      amountSatoshis: (displayAmountBtc.abs() * 100000000).round(),
      feeSatoshis: (networkFeeBtc.abs() * 100000000).round(),
      status: txStatus,
      type: isOutbound ? TransactionType.withdrawal : TransactionType.deposit,
      confirmations: confirmations,
      timestamp: settledAt ?? detectedAt ?? createdAt ?? DateTime.now(),
      blockchainTxid: blockchainTxid.isNotEmpty ? blockchainTxid : null,
      externalReference:
          externalReference.isNotEmpty ? externalReference : null,
      invoiceId: invoiceId.isNotEmpty ? invoiceId : null,
      lightningInvoice: invoiceData.isNotEmpty ? invoiceData : null,
      paymentHash: paymentHash.isNotEmpty ? paymentHash : null,
      externalTransferId: id,
      externalTransferStatus: status,
      externalTransferType: transferType,
      description: context,
      isInternal: false,
      isLightning: isLightning,
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
      invoiceId: json['invoiceId']?.toString() ?? '',
      blockchainTxid: json['blockchainTxid']?.toString() ?? '',
      paymentHash: json['paymentHash']?.toString() ?? '',
      invoiceData: json['invoiceData']?.toString() ?? '',
      expectedAmountBtc: (json['expectedAmountBtc'] as num?)?.toDouble() ?? 0,
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
      detectedAt:
          DateTime.tryParse(json['detectedAt']?.toString() ?? '')?.toLocal(),
      settledAt:
          DateTime.tryParse(json['settledAt']?.toString() ?? '')?.toLocal(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal(),
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
        invoiceId,
        blockchainTxid,
        paymentHash,
        invoiceData,
        expectedAmountBtc,
        confirmations,
        detectedAt,
        settledAt,
        createdAt,
        updatedAt,
        context,
      ];
}
