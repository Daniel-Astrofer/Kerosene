import 'package:flutter/material.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

class FinancialStatusMeta {
  final LocalizedCopy label;
  final Color color;
  final IconData icon;

  const FinancialStatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class FinancialStatusBadge extends StatelessWidget {
  final FinancialStatusMeta meta;
  final bool compact;

  const FinancialStatusBadge({
    super.key,
    required this.meta,
    this.compact = false,
  });

  static const Color pendingColor = Color(0xFFFBBF24);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF38BDF8);

  static FinancialStatusMeta paymentLink(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Paid',
            pt: 'Pago',
            es: 'Pagado',
          ),
          color: successColor,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'COMPLETED':
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Completed',
            pt: 'Concluido',
            es: 'Completado',
          ),
          color: successColor,
          icon: Icons.verified_rounded,
        );
      case 'EXPIRED':
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Expired',
            pt: 'Expirado',
            es: 'Expirado',
          ),
          color: errorColor,
          icon: Icons.cancel_outlined,
        );
      case 'CANCELLED':
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Cancelled',
            pt: 'Cancelado',
            es: 'Cancelado',
          ),
          color: errorColor,
          icon: Icons.block_rounded,
        );
      case 'VERIFYING_ONBOARDING':
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Verifying',
            pt: 'Verificando',
            es: 'Verificando',
          ),
          color: infoColor,
          icon: Icons.sync_rounded,
        );
      case 'PENDING':
      default:
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Pending',
            pt: 'Aguardando',
            es: 'Pendiente',
          ),
          color: pendingColor,
          icon: Icons.schedule_rounded,
        );
    }
  }

  static FinancialStatusMeta transaction(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Completed',
            pt: 'Concluido',
            es: 'Completado',
          ),
          color: successColor,
          icon: Icons.verified_rounded,
        );
      case TransactionStatus.confirming:
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Confirming',
            pt: 'Confirmando',
            es: 'Confirmando',
          ),
          color: pendingColor,
          icon: Icons.sync_rounded,
        );
      case TransactionStatus.failed:
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Failed',
            pt: 'Falhou',
            es: 'Fallo',
          ),
          color: errorColor,
          icon: Icons.error_outline_rounded,
        );
      case TransactionStatus.pending:
        return const FinancialStatusMeta(
          label: LocalizedCopy(
            en: 'Pending',
            pt: 'Aguardando',
            es: 'Pendiente',
          ),
          color: pendingColor,
          icon: Icons.schedule_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderTone = Color.lerp(monoBorderStrongColor, meta.color, 0.08) ??
        monoBorderStrongColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: borderTone,
        showShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: compact ? 14 : 16, color: monoTextColor),
          SizedBox(width: compact ? 6 : 8),
          Text(
            meta.label.resolve(context),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}
