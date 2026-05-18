import 'package:equatable/equatable.dart';

class AppPinStatus extends Equatable {
  final bool enabled;
  final bool configured;
  final bool locked;
  final int failedAttempts;
  final int remainingAttempts;
  final int maxAttempts;
  final int minPinLength;
  final int maxPinLength;
  final bool resettableWithTotp;
  final bool deviceScoped;
  final DateTime? lockedUntil;
  final DateTime? lastVerifiedAt;
  final DateTime? updatedAt;

  const AppPinStatus({
    this.enabled = false,
    this.configured = false,
    this.locked = false,
    this.failedAttempts = 0,
    this.remainingAttempts = 0,
    this.maxAttempts = 5,
    this.minPinLength = 4,
    this.maxPinLength = 8,
    this.resettableWithTotp = false,
    this.deviceScoped = true,
    this.lockedUntil,
    this.lastVerifiedAt,
    this.updatedAt,
  });

  factory AppPinStatus.fromJson(Map<String, dynamic> json) {
    return AppPinStatus(
      enabled: json['enabled'] == true,
      configured: json['configured'] == true,
      locked: json['locked'] == true,
      failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 5,
      minPinLength: (json['minPinLength'] as num?)?.toInt() ?? 4,
      maxPinLength: (json['maxPinLength'] as num?)?.toInt() ?? 8,
      resettableWithTotp: json['resettableWithTotp'] == true,
      deviceScoped: json['deviceScoped'] != false,
      lockedUntil: _parseDateTime(json['lockedUntil']),
      lastVerifiedAt: _parseDateTime(json['lastVerifiedAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Duration get remainingLockDuration {
    final until = lockedUntil;
    if (until == null) {
      return Duration.zero;
    }
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  AppPinStatus copyWith({
    bool? enabled,
    bool? configured,
    bool? locked,
    int? failedAttempts,
    int? remainingAttempts,
    int? maxAttempts,
    int? minPinLength,
    int? maxPinLength,
    bool? resettableWithTotp,
    bool? deviceScoped,
    DateTime? lockedUntil,
    DateTime? lastVerifiedAt,
    DateTime? updatedAt,
  }) {
    return AppPinStatus(
      enabled: enabled ?? this.enabled,
      configured: configured ?? this.configured,
      locked: locked ?? this.locked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      minPinLength: minPinLength ?? this.minPinLength,
      maxPinLength: maxPinLength ?? this.maxPinLength,
      resettableWithTotp: resettableWithTotp ?? this.resettableWithTotp,
      deviceScoped: deviceScoped ?? this.deviceScoped,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
        enabled,
        configured,
        locked,
        failedAttempts,
        remainingAttempts,
        maxAttempts,
        minPinLength,
        maxPinLength,
        resettableWithTotp,
        deviceScoped,
        lockedUntil,
        lastVerifiedAt,
        updatedAt,
      ];
}
