import 'package:equatable/equatable.dart';

class DeviceToken extends Equatable {
  final String id;
  final String platform;
  final String tokenRef;
  final String deviceRef;
  final String appVersion;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;
  final bool active;

  const DeviceToken({
    required this.id,
    required this.platform,
    required this.tokenRef,
    required this.deviceRef,
    required this.appVersion,
    this.createdAt,
    this.lastSeenAt,
    this.revokedAt,
    this.active = false,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: (json['id'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      tokenRef: (json['tokenRef'] ?? '').toString(),
      deviceRef: (json['deviceRef'] ?? '').toString(),
      appVersion: (json['appVersion'] ?? '').toString(),
      createdAt: _date(json['createdAt']),
      lastSeenAt: _date(json['lastSeenAt']),
      revokedAt: _date(json['revokedAt']),
      active: json['active'] == true,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
        id,
        platform,
        tokenRef,
        deviceRef,
        appVersion,
        createdAt,
        lastSeenAt,
        revokedAt,
        active,
      ];
}
