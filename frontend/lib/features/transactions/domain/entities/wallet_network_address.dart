import 'package:equatable/equatable.dart';

class WalletNetworkAddress extends Equatable {
  final String walletName;
  final String onchainAddress;
  final String lightningAddress;
  final String network;
  final String provider;
  final String externalWalletReference;
  final String walletMode;
  final bool lightningEnabled;
  final String lightningUnavailableReason;

  const WalletNetworkAddress({
    required this.walletName,
    required this.onchainAddress,
    required this.lightningAddress,
    required this.network,
    required this.provider,
    required this.externalWalletReference,
    required this.walletMode,
    required this.lightningEnabled,
    required this.lightningUnavailableReason,
  });

  bool get hasOnchainAddress => onchainAddress.trim().isNotEmpty;
  bool get hasLightningAddress => lightningAddress.trim().isNotEmpty;
  bool get isSelfCustody =>
      walletMode.trim().toUpperCase() == 'SELF_CUSTODY';

  factory WalletNetworkAddress.fromJson(Map<String, dynamic> json) {
    return WalletNetworkAddress(
      walletName: json['walletName']?.toString() ?? '',
      onchainAddress: json['onchainAddress']?.toString() ?? '',
      lightningAddress: json['lightningAddress']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      externalWalletReference:
          json['externalWalletReference']?.toString() ?? '',
      walletMode: json['walletMode']?.toString() ?? 'KEROSENE',
      lightningEnabled: json['lightningEnabled'] == true,
      lightningUnavailableReason:
          json['lightningUnavailableReason']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        walletName,
        onchainAddress,
        lightningAddress,
        network,
        provider,
        externalWalletReference,
        walletMode,
        lightningEnabled,
        lightningUnavailableReason,
      ];
}
