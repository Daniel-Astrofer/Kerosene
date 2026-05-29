import 'package:flutter/material.dart';
import 'package:kerosene/core/presentation/widgets/app_notification_surface.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';

class NotificationVisuals {
  final AppNotificationTone tone;
  final IconData icon;
  final String categoryLabel;

  const NotificationVisuals({
    required this.tone,
    required this.icon,
    required this.categoryLabel,
  });
}

NotificationVisuals resolveNotificationVisuals(
  BuildContext context,
  SessionNotificationItem item,
) {
  switch (item.kind) {
    case SessionNotificationItem.kindSecurityLoginDetected:
      return NotificationVisuals(
        tone: AppNotificationTone.warning,
        icon: Icons.shield_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Segurança',
          en: 'Security',
          es: 'Seguridad',
        ),
      );
    case SessionNotificationItem.kindSecurityAdminAccessAttempt:
      return NotificationVisuals(
        tone: AppNotificationTone.warning,
        icon: Icons.admin_panel_settings_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Segurança',
          en: 'Security',
          es: 'Seguridad',
        ),
      );
    case SessionNotificationItem.kindSecurityRecoveryCompleted:
      return NotificationVisuals(
        tone: AppNotificationTone.warning,
        icon: Icons.key_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Recuperação',
          en: 'Recovery',
          es: 'Recuperación',
        ),
      );
    case SessionNotificationItem.kindAccountCreated:
      return NotificationVisuals(
        tone: _toneForSeverity(item.severity),
        icon: Icons.person_add_alt_1_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Conta',
          en: 'Account',
          es: 'Cuenta',
        ),
      );
    case SessionNotificationItem.kindTransferReceived:
      return NotificationVisuals(
        tone: AppNotificationTone.success,
        icon: Icons.south_west,
        categoryLabel: _copy(
          context,
          pt: 'Recebido',
          en: 'Received',
          es: 'Recibido',
        ),
      );
    case SessionNotificationItem.kindTransferSent:
      return NotificationVisuals(
        tone: _toneForSeverity(item.severity),
        icon: Icons.north_east,
        categoryLabel: _copy(
          context,
          pt: 'Enviado',
          en: 'Sent',
          es: 'Enviado',
        ),
      );
    case SessionNotificationItem.kindPaymentRequestCreated:
      return NotificationVisuals(
        tone: AppNotificationTone.info,
        icon: Icons.receipt_long_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Link',
          en: 'Payment link',
          es: 'Link',
        ),
      );
    case SessionNotificationItem.kindPaymentRequestPaid:
      return NotificationVisuals(
        tone: AppNotificationTone.success,
        icon: Icons.verified_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Liquidado',
          en: 'Paid',
          es: 'Liquidado',
        ),
      );
    case SessionNotificationItem.kindDepositDetected:
      return NotificationVisuals(
        tone: AppNotificationTone.info,
        icon: Icons.downloading_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Depósito',
          en: 'Deposit',
          es: 'Depósito',
        ),
      );
    case SessionNotificationItem.kindDepositConfirmed:
      return NotificationVisuals(
        tone: AppNotificationTone.success,
        icon: Icons.account_balance_wallet_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Confirmado',
          en: 'Confirmed',
          es: 'Confirmado',
        ),
      );
    case SessionNotificationItem.kindPaymentSent:
      return NotificationVisuals(
        tone: _toneForSeverity(item.severity),
        icon: Icons.send_outlined,
        categoryLabel: _copy(
          context,
          pt: 'Pagamento',
          en: 'Payment',
          es: 'Pago',
        ),
      );
    default:
      final tone = _toneForSeverity(item.severity);
      return NotificationVisuals(
        tone: tone,
        icon: AppNotificationStyle.iconFor(tone),
        categoryLabel: _copy(
          context,
          pt: 'Sistema',
          en: 'System',
          es: 'Sistema',
        ),
      );
  }
}

String buildNotificationFooterLabel(
  BuildContext context,
  SessionNotificationItem item,
  String timeLabel,
) {
  final visuals = resolveNotificationVisuals(context, item);
  return '${visuals.categoryLabel} • $timeLabel';
}

AppNotificationTone _toneForSeverity(String severity) {
  switch (severity) {
    case SessionNotificationItem.severitySuccess:
      return AppNotificationTone.success;
    case SessionNotificationItem.severityWarning:
      return AppNotificationTone.warning;
    case SessionNotificationItem.severityError:
      return AppNotificationTone.error;
    case SessionNotificationItem.severityInfo:
    default:
      return AppNotificationTone.info;
  }
}

String _copy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}
