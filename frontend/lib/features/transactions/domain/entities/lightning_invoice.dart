import 'package:equatable/equatable.dart';

class LightningInvoice extends Equatable {
  final String transferId;
  final String walletName;
  final String paymentRequest;
  final String paymentHash;
  final String lightningAddress;
  final double amountBtc;
  final String provider;
  final DateTime? expiresAt;
  final String status;

  const LightningInvoice({
    required this.transferId,
    required this.walletName,
    required this.paymentRequest,
    required this.paymentHash,
    required this.lightningAddress,
    required this.amountBtc,
    required this.provider,
    required this.expiresAt,
    required this.status,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toLocal());

  Duration get remaining {
    if (expiresAt == null) {
      return Duration.zero;
    }
    final diff = expiresAt!.difference(DateTime.now().toLocal());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory LightningInvoice.fromJson(Map<String, dynamic> json) {
    return LightningInvoice(
      transferId: json['transferId']?.toString() ?? '',
      walletName: json['walletName']?.toString() ?? '',
      paymentRequest: json['paymentRequest']?.toString() ?? '',
      paymentHash: json['paymentHash']?.toString() ?? '',
      lightningAddress: json['lightningAddress']?.toString() ?? '',
      amountBtc: (json['amountBtc'] as num?)?.toDouble() ?? 0,
      provider: json['provider']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')
          ?.toLocal(),
      status: json['status']?.toString() ?? 'PENDING',
    );
  }

  @override
  List<Object?> get props => [
        transferId,
        walletName,
        paymentRequest,
        paymentHash,
        lightningAddress,
        amountBtc,
        provider,
        expiresAt,
        status,
      ];
}
