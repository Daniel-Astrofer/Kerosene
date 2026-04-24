import 'package:equatable/equatable.dart';

class OnchainAddressAllocation extends Equatable {
  final String walletName;
  final String onchainAddress;
  final String network;
  final String provider;
  final String externalWalletReference;
  final String walletMode;
  final String transferId;
  final String transferStatus;
  final int confirmations;
  final int requiredConfirmations;
  final String blockchainTxid;

  const OnchainAddressAllocation({
    required this.walletName,
    required this.onchainAddress,
    required this.network,
    required this.provider,
    required this.externalWalletReference,
    required this.walletMode,
    required this.transferId,
    required this.transferStatus,
    required this.confirmations,
    required this.requiredConfirmations,
    required this.blockchainTxid,
  });

  bool get hasTransferId => transferId.trim().isNotEmpty;
  bool get isSelfCustody => walletMode.trim().toUpperCase() == 'SELF_CUSTODY';

  factory OnchainAddressAllocation.fromJson(Map<String, dynamic> json) {
    return OnchainAddressAllocation(
      walletName: json['walletName']?.toString() ?? '',
      onchainAddress: json['onchainAddress']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      externalWalletReference:
          json['externalWalletReference']?.toString() ?? '',
      walletMode: json['walletMode']?.toString() ?? 'KEROSENE',
      transferId: json['transferId']?.toString() ?? '',
      transferStatus: json['transferStatus']?.toString() ?? 'PENDING',
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
      requiredConfirmations:
          (json['requiredConfirmations'] as num?)?.toInt() ?? 3,
      blockchainTxid: json['blockchainTxid']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        walletName,
        onchainAddress,
        network,
        provider,
        externalWalletReference,
        walletMode,
        transferId,
        transferStatus,
        confirmations,
        requiredConfirmations,
        blockchainTxid,
      ];
}
