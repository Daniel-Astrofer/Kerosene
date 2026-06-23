import 'package:equatable/equatable.dart';
import 'dart:convert';

class SessionNotificationItem extends Equatable {
  static const severityInfo = 'info';
  static const severitySuccess = 'success';
  static const severityWarning = 'warning';
  static const severityError = 'error';

  static const kindSystemInfo = 'system_info';
  static const kindSecurityLoginDetected = 'security_login_detected';
  static const kindSecurityAdminAccessAttempt = 'security_admin_access_attempt';
  static const kindSecurityRecoveryCompleted = 'security_recovery_completed';
  static const kindAccountCreated = 'account_created';
  static const kindTransferReceived = 'transfer_received';
  static const kindTransferSent = 'transfer_sent';
  static const kindPaymentRequestCreated = 'payment_request_created';
  static const kindPaymentRequestPaid = 'payment_request_paid';
  static const kindDepositDetected = 'deposit_detected';
  static const kindDepositConfirmed = 'deposit_confirmed';
  static const kindPaymentSent = 'payment_sent';
  static const kindMarketAlert = 'market_alert';
  static const kindBackgroundAlertsSetup = 'background_alerts_setup';

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String kind;
  final String severity;
  final String? deeplink;
  final String? entityType;
  final String? entityId;
  final Map<String, String> metadata;
  final bool read;

  const SessionNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.kind = kindSystemInfo,
    this.severity = severityInfo,
    this.deeplink,
    this.entityType,
    this.entityId,
    this.metadata = const {},
    this.read = false,
  });

  factory SessionNotificationItem.fromJson(Map<String, dynamic> json) {
    return SessionNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      timestamp: _parseDateTime(
            json['timestamp'] ?? json['createdAt'],
          ) ??
          DateTime.now(),
      kind: json['kind']?.toString() ?? kindSystemInfo,
      severity: json['severity']?.toString() ?? severityInfo,
      deeplink: json['deeplink']?.toString(),
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      metadata: _parseMetadata(json['metadata']),
      read: json['read'] == true || json['isRead'] == true,
    );
  }

  String get dedupeKey {
    final explicitDedupe = metadata['dedupeKey'];
    if (explicitDedupe != null && explicitDedupe.trim().isNotEmpty) {
      return explicitDedupe.trim();
    }

    if (entityType != null &&
        entityType!.isNotEmpty &&
        entityId != null &&
        entityId!.isNotEmpty) {
      return '$kind|$entityType|$entityId';
    }
    return id;
  }

  bool get isActionable => deeplink != null && deeplink!.trim().isNotEmpty;
  bool get canSyncRead => int.tryParse(id) != null;

  SessionNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    String? kind,
    String? severity,
    String? deeplink,
    String? entityType,
    String? entityId,
    Map<String, String>? metadata,
    bool? read,
  }) {
    return SessionNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      kind: kind ?? this.kind,
      severity: severity ?? this.severity,
      deeplink: deeplink ?? this.deeplink,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      metadata: metadata ?? this.metadata,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'kind': kind,
      'severity': severity,
      'deeplink': deeplink,
      'entityType': entityType,
      'entityId': entityId,
      'metadata': metadata,
      'read': read,
    };
  }

  static Map<String, String> _parseMetadata(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value).map(
        (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
      );
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded).map(
            (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
          );
        }
      } catch (_) {}
    }

    return const {};
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        timestamp,
        kind,
        severity,
        deeplink,
        entityType,
        entityId,
        metadata.toString(),
        read,
      ];
}
