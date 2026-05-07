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
  final String? credentialRef;
  final String deviceName;
  final String brand;
  final String model;
  final String serialNumber;
  final String deviceInstallId;
  final String platform;
  final String browser;
  final DateTime? firstAccessAt;
  final DateTime? lastAccessAt;
  final String status;
  final String relyingPartyId;
  final String originHost;
  final PasskeyCompatibilityStatus compatibilityStatus;
  final bool compatibleWithCurrentLogin;

  const PasskeyDevice({
    this.credentialRef,
    required this.deviceName,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.deviceInstallId = '',
    this.platform = '',
    this.browser = '',
    this.firstAccessAt,
    this.lastAccessAt,
    this.status = 'ACTIVE',
    this.relyingPartyId = '',
    this.originHost = '',
    this.compatibilityStatus = PasskeyCompatibilityStatus.unknown,
    this.compatibleWithCurrentLogin = false,
  });

  factory PasskeyDevice.fromJson(Map<String, dynamic> json) {
    return PasskeyDevice(
      credentialRef:
          (json['credentialRef'] ?? json['credentialId'])?.toString(),
      deviceName: (json['deviceName'] ?? 'Passkey').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      serialNumber: (json['serialNumber'] ?? '').toString(),
      deviceInstallId: (json['deviceInstallId'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      browser: (json['browser'] ?? '').toString(),
      firstAccessAt: _date(json['firstAccessAt']),
      lastAccessAt: _date(json['lastAccessAt']),
      status: (json['status'] ?? 'ACTIVE').toString(),
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
        credentialRef,
        deviceName,
        brand,
        model,
        serialNumber,
        deviceInstallId,
        platform,
        browser,
        firstAccessAt,
        lastAccessAt,
        status,
        relyingPartyId,
        originHost,
        compatibilityStatus,
        compatibleWithCurrentLogin,
      ];
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
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
