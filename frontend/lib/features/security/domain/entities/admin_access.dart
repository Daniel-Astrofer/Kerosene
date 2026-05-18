import 'package:equatable/equatable.dart';

class AdminKeyStatus extends Equatable {
  final bool configured;
  final String status;
  final String fingerprint;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  const AdminKeyStatus({
    this.configured = false,
    this.status = 'MISSING',
    this.fingerprint = '',
    this.createdAt,
    this.revokedAt,
  });

  factory AdminKeyStatus.fromJson(Map<String, dynamic> json) {
    return AdminKeyStatus(
      configured: json['configured'] == true,
      status: (json['status'] ?? 'MISSING').toString(),
      fingerprint: (json['fingerprint'] ?? '').toString(),
      createdAt: _date(json['createdAt']),
      revokedAt: _date(json['revokedAt']),
    );
  }

  @override
  List<Object?> get props =>
      [configured, status, fingerprint, createdAt, revokedAt];
}

class AdminAccessAttempt extends Equatable {
  final String attemptId;
  final String status;
  final String deviceId;
  final String deviceName;
  final String browser;
  final String userAgent;
  final String ipFingerprint;
  final DateTime? requestedAt;
  final DateTime? expiresAt;

  const AdminAccessAttempt({
    required this.attemptId,
    this.status = 'PENDING',
    this.deviceId = '',
    this.deviceName = '',
    this.browser = '',
    this.userAgent = '',
    this.ipFingerprint = '',
    this.requestedAt,
    this.expiresAt,
  });

  factory AdminAccessAttempt.fromJson(Map<String, dynamic> json) {
    return AdminAccessAttempt(
      attemptId: (json['attemptId'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      browser: (json['browser'] ?? '').toString(),
      userAgent: (json['userAgent'] ?? '').toString(),
      ipFingerprint: (json['ipFingerprint'] ?? '').toString(),
      requestedAt: _date(json['requestedAt']),
      expiresAt: _date(json['expiresAt']),
    );
  }

  @override
  List<Object?> get props => [
        attemptId,
        status,
        deviceId,
        deviceName,
        browser,
        userAgent,
        ipFingerprint,
        requestedAt,
        expiresAt,
      ];
}

class AdminAuthenticatedDevice extends Equatable {
  final String deviceId;
  final String deviceName;
  final String browser;
  final String userAgent;
  final String status;
  final DateTime? firstAccessAt;
  final DateTime? lastAccessAt;

  const AdminAuthenticatedDevice({
    required this.deviceId,
    this.deviceName = '',
    this.browser = '',
    this.userAgent = '',
    this.status = 'PENDING',
    this.firstAccessAt,
    this.lastAccessAt,
  });

  factory AdminAuthenticatedDevice.fromJson(Map<String, dynamic> json) {
    return AdminAuthenticatedDevice(
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      browser: (json['browser'] ?? '').toString(),
      userAgent: (json['userAgent'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      firstAccessAt: _date(json['firstAccessAt']),
      lastAccessAt: _date(json['lastAccessAt']),
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        browser,
        userAgent,
        status,
        firstAccessAt,
        lastAccessAt,
      ];
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
