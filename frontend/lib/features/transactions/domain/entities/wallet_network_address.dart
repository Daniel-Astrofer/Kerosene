import 'package:equatable/equatable.dart';

class WalletNetworkAddress extends Equatable {
  final String walletName;
  final String onchainAddress;
  final String lightningAddress;
  final String provider;
  final String externalWalletReference;

  const WalletNetworkAddress({
    required this.walletName,
    required this.onchainAddress,
    required this.lightningAddress,
    required this.provider,
    required this.externalWalletReference,
  });

  bool get hasOnchainAddress => onchainAddress.trim().isNotEmpty;
  bool get hasLightningAddress => lightningAddress.trim().isNotEmpty;

  factory WalletNetworkAddress.fromJson(Map<String, dynamic> json) {
    return WalletNetworkAddress(
      walletName: json['walletName']?.toString() ?? '',
      onchainAddress: json['onchainAddress']?.toString() ?? '',
      lightningAddress: json['lightningAddress']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      externalWalletReference:
          json['externalWalletReference']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        walletName,
        onchainAddress,
        lightningAddress,
        provider,
        externalWalletReference,
      ];
}
