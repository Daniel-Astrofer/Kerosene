import 'package:equatable/equatable.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';

/// Entidade PaymentLink — solicitação de recebimento Bitcoin.
class PaymentLink extends Equatable {
  final String id;
  final int userId;
  final String? sessionId;
  final double amountBtc;
  final double grossAmountBtc;
  final double depositFeeBtc;
  final double netAmountBtc;
  final String description;
  final String depositAddress;
  final String visibility;
  final String confirmationMode;
  final bool amountLocked;
  final String? referenceLabel;
  final Map<String, String> metadata;
  final String? destinationHash;
  final String? paymentUri;
  final bool locked;
  final String status;
  final String? txid;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String paymentRail;
  final String settlementStatus;
  final String? settlementReference;
  final bool terminal;
  final int confirmations;

  const PaymentLink({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.amountBtc,
    this.grossAmountBtc = 0,
    this.depositFeeBtc = 0,
    this.netAmountBtc = 0,
    required this.description,
    required this.depositAddress,
    this.visibility = 'PRIVATE',
    this.confirmationMode = 'USER_ACTION_REQUIRED',
    this.amountLocked = true,
    this.referenceLabel,
    this.metadata = const {},
    this.destinationHash,
    this.paymentUri,
    this.locked = false,
    required this.status,
    this.txid,
    this.expiresAt,
    this.createdAt,
    this.paidAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.paymentRail = 'ONCHAIN',
    this.settlementStatus = 'QUOTED',
    this.settlementReference,
    this.terminal = false,
    this.confirmations = 0,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCompleted => status == 'completed';
  bool get isVerifyingOnboarding => status == 'verifying_onboarding';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValidatingSettlement =>
      settlementStatus == 'VALIDATING' ||
      settlementStatus == 'QUORUM_SYNC' ||
      settlementStatus == 'EXECUTING';
  bool get hasObservedOnchainPayment =>
      isValidatingSettlement || (txid != null && txid!.trim().isNotEmpty);
  String get displayStatus {
    if (isValidatingSettlement) {
      return settlementStatus;
    }
    if (hasObservedOnchainPayment && isPending) {
      return 'DETECTED';
    }
    return status;
  }

  bool get isInternalPaymentRequest =>
      locked || (destinationHash != null && destinationHash!.isNotEmpty);

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    double amountBtc = (data['amountBtc'] as num?)?.toDouble() ?? 0;
    if (amountBtc == 0) {
      final amountSats = (data['amountSats'] as num?)?.toDouble() ??
          (data['receiverAmountSats'] as num?)?.toDouble() ??
          (data['grossAmountSats'] as num?)?.toDouble();
      if (amountSats != null && amountSats > 0) {
        amountBtc = amountSats / 100000000.0;
      }
    }
    if (amountBtc == 0 && data['amount'] is num) {
      amountBtc = (data['amount'] as num).toDouble();
    }
    final grossAmountBtc =
        (data['grossAmountBtc'] as num?)?.toDouble() ?? amountBtc;
    final depositFeeBtc = (data['depositFeeBtc'] as num?)?.toDouble() ?? 0;
    final netAmountBtc =
        (data['netAmountBtc'] as num?)?.toDouble() ?? amountBtc;

    final rawStatus = data['status']?.toString() ?? 'pending';
    final rawSettlementStatus =
        data['settlementStatus']?.toString().toUpperCase();
    final normalizedStatus = _normalizeStatus(
      rawStatus,
      txid: data['txid']?.toString() ?? data['blockchainTxid']?.toString(),
      settlementStatus: rawSettlementStatus,
    );
    final settlementStatus =
        rawSettlementStatus ?? _settlementStatusFor(normalizedStatus);

    return PaymentLink(
      id: data['id']?.toString() ??
          data['transactionId']?.toString() ??
          data['providerReference']?.toString() ??
          '',
      userId: (data['userId'] as num?)?.toInt() ?? 0,
      sessionId: data['sessionId']?.toString(),
      amountBtc: amountBtc,
      grossAmountBtc: grossAmountBtc,
      depositFeeBtc: depositFeeBtc,
      netAmountBtc: netAmountBtc,
      description:
          data['description']?.toString() ?? data['memo']?.toString() ?? '',
      depositAddress: data['depositAddress']?.toString() ??
          data['address']?.toString() ??
          data['activeAddress']?.toString() ??
          data['externalReference']?.toString() ??
          '',
      visibility: data['visibility']?.toString().toUpperCase() ?? 'PRIVATE',
      confirmationMode: data['confirmationMode']?.toString().toUpperCase() ??
          'USER_ACTION_REQUIRED',
      amountLocked: _parseBool(data['amountLocked'], fallback: true),
      referenceLabel: data['referenceLabel']?.toString(),
      metadata: _parseMetadata(data['metadata']),
      destinationHash: _readString(data, const [
        'destinationHash',
        'destination_hash',
        'addressHash',
        'address_hash',
        'walletHash',
        'wallet_hash',
      ]),
      paymentUri: data['paymentUri']?.toString(),
      locked: _parseBool(data['locked']),
      status: normalizedStatus,
      txid: data['txid']?.toString() ?? data['blockchainTxid']?.toString(),
      expiresAt: data['expiresAt'] != null
          ? DateTime.tryParse(data['expiresAt'].toString())
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
      paidAt: data['paidAt'] != null
          ? DateTime.tryParse(data['paidAt'].toString())
          : null,
      completedAt: data['completedAt'] != null
          ? DateTime.tryParse(data['completedAt'].toString())
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? DateTime.tryParse(data['cancelledAt'].toString())
          : null,
      cancelReason: data['cancelReason']?.toString(),
      paymentRail: data['paymentRail']?.toString().toUpperCase() ??
          data['rail']?.toString().toUpperCase() ??
          'ONCHAIN',
      settlementStatus: settlementStatus,
      settlementReference: data['settlementReference']?.toString(),
      terminal: _parseBool(
        data['terminal'],
        fallback: _terminalSettlementStatus(settlementStatus),
      ),
      confirmations: (data['confirmations'] as num?)?.toInt() ??
          (data['confirmationCount'] as num?)?.toInt() ??
          0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionId,
        amountBtc,
        grossAmountBtc,
        depositFeeBtc,
        netAmountBtc,
        description,
        depositAddress,
        visibility,
        confirmationMode,
        amountLocked,
        referenceLabel,
        metadata,
        destinationHash,
        paymentUri,
        locked,
        status,
        txid,
        expiresAt,
        createdAt,
        paidAt,
        completedAt,
        cancelledAt,
        cancelReason,
        paymentRail,
        settlementStatus,
        settlementReference,
        terminal,
        confirmations,
      ];

  /// Converte PaymentLink para Transaction para exibição no histórico unificado
  Transaction toTransaction() {
    final isOnchain = paymentRail.toUpperCase().contains('ONCHAIN') ||
        (depositAddress.trim().isNotEmpty && !isInternalPaymentRequest);
    final bool isCompleted = status == 'completed' ||
        terminal ||
        (!isOnchain && status == 'paid') ||
        (isOnchain && status == 'paid' && confirmations >= 3);
    final bool isFailed = status == 'cancelled' || isExpired;
    final transactionDescription = isCancelled
        ? 'Link de pagamento cancelado'
        : isExpired
            ? 'Link de pagamento expirado'
            : (description.isNotEmpty ? description : 'Link de Pagamento');

    return Transaction(
      id: "pl_$id",
      fromAddress: 'Rede Bitcoin',
      toAddress: depositAddress,
      amountSatoshis: (amountBtc * 100000000).round(),
      feeSatoshis: 0,
      status: isCompleted
          ? TransactionStatus.confirmed
          : isFailed
              ? TransactionStatus.failed
              : hasObservedOnchainPayment
                  ? TransactionStatus.confirming
                  : TransactionStatus.pending,
      type: TransactionType.receive,
      confirmations:
          isCompleted ? (confirmations > 0 ? confirmations : 3) : confirmations,
      timestamp: createdAt ?? DateTime.now(),
      description: transactionDescription,
      isInternal: false,
      blockchainTxid:
          txid == null || txid!.trim().isEmpty ? null : txid!.trim(),
    );
  }

  static String _settlementStatusFor(String status) {
    switch (status) {
      case 'pending':
        return 'QUOTED';
      case 'paid':
      case 'completed':
        return 'SETTLED';
      case 'expired':
        return 'EXPIRED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELED';
      case 'verifying_onboarding':
      case 'verifying_activation':
        return 'PROCESSING';
      default:
        return 'REQUIRES_RECONCILIATION';
    }
  }

  static String _normalizeStatus(
    String status, {
    String? txid,
    String? settlementStatus,
  }) {
    final normalized = status.trim().toUpperCase();
    final hasTxid = txid != null && txid.trim().isNotEmpty;
    if (settlementStatus == 'VALIDATING' ||
        settlementStatus == 'QUORUM_SYNC' ||
        settlementStatus == 'EXECUTING' ||
        (hasTxid &&
            (normalized == 'OPEN' ||
                normalized == 'ACTIVE' ||
                normalized == 'PENDING' ||
                normalized == 'CREATED'))) {
      return 'pending';
    }
    switch (normalized) {
      case 'ACTIVE':
      case 'PENDING':
      case 'CREATED':
      case 'IDENTIFIED':
        return 'pending';
      case 'SETTLED':
      case 'PAID':
        return 'paid';
      case 'COMPLETED':
      case 'CONFIRMED':
        return 'completed';
      case 'EXPIRED':
        return 'expired';
      case 'CANCELED':
      case 'CANCELLED':
        return 'cancelled';
      case 'FAILED':
        return 'failed';
      default:
        return normalized.toLowerCase();
    }
  }

  static bool _terminalSettlementStatus(String status) {
    return status == 'SETTLED' ||
        status == 'FAILED' ||
        status == 'CANCELED' ||
        status == 'EXPIRED';
  }

  static bool _parseBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.trim().toLowerCase() == 'true';
    }
    return fallback;
  }

  static Map<String, String> _parseMetadata(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value).map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }
    return const {};
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
