import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/security/domain/entities/kfe_reserve_overview.dart';

import 'sovereignty_kfe_reserve_overview_card.dart';

class SovereigntyKfeReserveCopy {
  const SovereigntyKfeReserveCopy._();

  static const syncingOperationalTreasury =
      'Sincronizando tesouraria operacional...';
}

Widget buildKfeReserveLoadingCard({required BuildContext context}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            SovereigntyKfeReserveCopy.syncingOperationalTreasury,
            style: AppTypography.bodySmall.copyWith(color: AppColors.white70),
          ),
        ),
      ],
    ),
  );
}

Widget buildKfeReserveUnavailableCard({
  required BuildContext context,
  required String message,
  required SovereigntyCopy copy,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.18),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            KeroseneIcons.wallet,
            color: Theme.of(context).colorScheme.error,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy(
                  pt: 'Tesouraria indisponível',
                  en: 'Treasury unavailable',
                  es: 'Tesorería no disponible',
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String formatBtc(double value) => '${value.toStringAsFixed(8)} BTC';
String formatShortBtc(double value) => '${value.toStringAsFixed(4)} BTC';
String formatSignedBtc(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(8)} BTC';
}

double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool? asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

String liquidityStateLabel(String state) {
  switch (state.toUpperCase()) {
    case 'HEALTHY':
      return 'SAUDÁVEL';
    case 'LOW_LIQUIDITY':
      return 'BAIXA LIQUIDEZ';
    case 'BLOCKED':
      return 'BLOQUEADO';
    default:
      return state.toUpperCase();
  }
}

String liquidityStateSummary(KfeReserveOverview overview) {
  if (overview.lightningSendsAllowed) {
    return 'Liquidez operacional disponível para saques Lightning e reservas monitoradas.';
  }
  return 'Saques Lightning bloqueados até recomposição de liquidez operacional.';
}
