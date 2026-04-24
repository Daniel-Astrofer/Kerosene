import 'package:equatable/equatable.dart';

enum PasskeyCompatibilityStatus { compatible, incompatible, unknown }

PasskeyCompatibilityStatus passkeyCompatibilityStatusFromApi(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'COMPATIBLE':
      return PasskeyCompatibilityStatus.compatible;
    case 'INCOMPATIBLE':
      return PasskeyCompatibilityStatus.incompatible;
    default:
      return PasskeyCompatibilityStatus.unknown;
  }
}

class PasskeyDevice extends Equatable {
  final String? credentialId;
  final String deviceName;
  final String relyingPartyId;
  final String originHost;
  final PasskeyCompatibilityStatus compatibilityStatus;
  final bool compatibleWithCurrentLogin;

  const PasskeyDevice({
    this.credentialId,
    required this.deviceName,
    this.relyingPartyId = '',
    this.originHost = '',
    this.compatibilityStatus = PasskeyCompatibilityStatus.unknown,
    this.compatibleWithCurrentLogin = false,
  });

  factory PasskeyDevice.fromJson(Map<String, dynamic> json) {
    return PasskeyDevice(
      credentialId: json['credentialId']?.toString(),
      deviceName: (json['deviceName'] ?? 'Passkey').toString(),
      relyingPartyId: (json['relyingPartyId'] ?? '').toString(),
      originHost: (json['originHost'] ?? '').toString(),
      compatibilityStatus: passkeyCompatibilityStatusFromApi(
        json['compatibilityStatus']?.toString(),
      ),
      compatibleWithCurrentLogin: json['compatibleWithCurrentLogin'] == true,
    );
  }

  @override
  List<Object?> get props => [
        credentialId,
        deviceName,
        relyingPartyId,
        originHost,
        compatibilityStatus,
        compatibleWithCurrentLogin,
      ];
}

class PasskeyInventory extends Equatable {
  final bool passkeyRegistered;
  final bool compatibleForCurrentLogin;
  final bool legacyCredentialsPresent;
  final String currentRelyingPartyId;
  final String currentHost;
  final List<PasskeyDevice> devices;

  const PasskeyInventory({
    this.passkeyRegistered = false,
    this.compatibleForCurrentLogin = false,
    this.legacyCredentialsPresent = false,
    this.currentRelyingPartyId = '',
    this.currentHost = '',
    this.devices = const [],
  });

  factory PasskeyInventory.fromJson(Map<String, dynamic> json) {
    final devicesRaw = json['devices'];
    return PasskeyInventory(
      passkeyRegistered: json['passkeyRegistered'] == true,
      compatibleForCurrentLogin: json['compatibleForCurrentLogin'] == true,
      legacyCredentialsPresent: json['legacyCredentialsPresent'] == true,
      currentRelyingPartyId: (json['currentRelyingPartyId'] ?? '').toString(),
      currentHost: (json['currentHost'] ?? '').toString(),
      devices: devicesRaw is List
          ? devicesRaw
              .whereType<Map>()
              .map((item) => PasskeyDevice.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  bool get hasKnownDevices => devices.isNotEmpty;

  @override
  List<Object?> get props => [
        passkeyRegistered,
        compatibleForCurrentLogin,
        legacyCredentialsPresent,
        currentRelyingPartyId,
        currentHost,
        devices,
      ];
}
