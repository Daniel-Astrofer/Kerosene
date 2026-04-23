import 'package:equatable/equatable.dart';

class SessionNotificationItem extends Equatable {
  static const severityInfo = 'info';
  static const severitySuccess = 'success';
  static const severityWarning = 'warning';
  static const severityError = 'error';

  static const kindSystemInfo = 'system_info';
  static const kindSecurityLoginDetected = 'security_login_detected';
  static const kindSecurityRecoveryCompleted = 'security_recovery_completed';
  static const kindAccountCreated = 'account_created';
  static const kindTransferReceived = 'transfer_received';
  static const kindTransferSent = 'transfer_sent';
  static const kindPaymentRequestCreated = 'payment_request_created';
  static const kindPaymentRequestPaid = 'payment_request_paid';
  static const kindDepositDetected = 'deposit_detected';
  static const kindDepositConfirmed = 'deposit_confirmed';
  static const kindPaymentSent = 'payment_sent';
  static const kindMiningStarted = 'mining_started';
  static const kindMiningCompleted = 'mining_completed';
  static const kindMiningCancelled = 'mining_cancelled';

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
  });

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
    );
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
      ];
}
