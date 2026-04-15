import 'package:equatable/equatable.dart';
import '../../../wallet/domain/entities/transaction.dart';

/// Entidade PaymentLink — link de pagamento Bitcoin
class PaymentLink extends Equatable {
  final String id;
  final int userId;
  final String? sessionId;
  final double amountBtc;
  final String description;
  final String depositAddress;
  final String? destinationHash;
  final String? paymentUri;
  final bool locked;
  final String status;
  final String? txid;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;

  const PaymentLink({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.amountBtc,
    required this.description,
    required this.depositAddress,
    this.destinationHash,
    this.paymentUri,
    this.locked = false,
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
  bool get isVerifyingOnboarding => status == 'verifying_onboarding';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isInternalPaymentRequest =>
      locked || (destinationHash != null && destinationHash!.isNotEmpty);
  bool get isOnboardingVoucher =>
      description.toUpperCase() == 'ONBOARDING_VOUCHER' ||
      amountBtc.toStringAsFixed(8) == '0.00022000';

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    double amountBtc = (data['amountBtc'] as num?)?.toDouble() ?? 0;
    if (amountBtc == 0 && data['amount'] is num) {
      amountBtc = (data['amount'] as num).toDouble();
    }

    final rawStatus = data['status']?.toString() ?? 'pending';

    return PaymentLink(
      id: data['id']?.toString() ?? '',
      userId: (data['userId'] as num?)?.toInt() ?? 0,
      sessionId: data['sessionId']?.toString(),
      amountBtc: amountBtc,
      description: data['description']?.toString() ?? '',
      depositAddress: data['depositAddress']?.toString() ??
          data['address']?.toString() ??
          '',
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
      status: rawStatus.toLowerCase(),
      txid: data['txid']?.toString(),
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
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionId,
        amountBtc,
        description,
        depositAddress,
        destinationHash,
        paymentUri,
        locked,
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
      status:
          isCompleted ? TransactionStatus.confirmed : TransactionStatus.pending,
      type: TransactionType.receive,
      confirmations: isCompleted ? 6 : 0,
      timestamp: createdAt ?? DateTime.now(),
      description: description.isNotEmpty ? description : "Link de Pagamento",
      isInternal: false,
    );
  }

  static bool _parseBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.trim().toLowerCase() == 'true';
    }
    return false;
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
