import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/security/domain/entities/security_status.dart';

import 'sovereignty_kfe_reserve_helpers.dart';
import 'sovereignty_kfe_reserve_overview_card.dart';
import 'sovereignty_status_components.dart';

Widget buildKfeReserveSnapshotCard({
  required BuildContext context,
  required SecurityStatus status,
  required Map<String, dynamic> stats,
  required SovereigntyCopy copy,
}) {
  final liability = asDouble(stats['liability_to_users']);
  final profitPending = asDouble(stats['platform_profit_pending']);
  final onchainBalance = asDouble(stats['actual_onchain_balance']);
  final lightningBalance = asDouble(stats['actual_lightning_balance']);
  final walletXpubBalance = asDouble(stats['actual_wallet_xpub_balance']);
  final treasuryXpubBalance = asDouble(stats['actual_treasury_xpub_balance']);
  final totalAssets = asDouble(stats['actual_total_assets']);
  final buffer = totalAssets - liability;

  final networkConsensus = status.networkConsensus;
  final activeNodes = (networkConsensus['activeNodes'] as num?)?.toInt() ?? 0;
  final totalNodes = (networkConsensus['totalNodes'] as num?)?.toInt() ?? 0;
  final requiredNodes =
      (networkConsensus['requiredNodes'] as num?)?.toInt() ?? 0;
  final failStopMode = networkConsensus['failStopMode'] == true;

  final isSolvent =
      asBool(stats['is_solvent']) ?? (onchainBalance >= liability);
  final quorumHealthy =
      !failStopMode && totalNodes > 0 && activeNodes >= requiredNodes;
  final statusOk = isSolvent && quorumHealthy;
  final statusColor =
      statusOk ? AppColors.success : Theme.of(context).colorScheme.error;
  final statusLabel = failStopMode
      ? copy(
          pt: 'SAÍDAS PAUSADAS',
          en: 'OUTFLOWS PAUSED',
          es: 'SALIDAS PAUSADAS',
        )
      : (isSolvent
          ? copy(pt: 'SOLVENTE', en: 'SOLVENT', es: 'SOLVENTE')
          : copy(pt: 'RISCO', en: 'RISK', es: 'RIESGO'));

  final summary = failStopMode
      ? copy(
          pt: 'As saídas foram pausadas por segurança até que as confirmações voltem ao nível mínimo. A liquidez segue visível.',
          en: 'Outflows are paused for safety until confirmations return to the minimum level. Liquidity remains visible.',
          es: 'Las salidas estan pausadas por seguridad hasta que las confirmaciones vuelvan al nivel minimo. La liquidez sigue visible.',
        )
      : statusOk
          ? copy(
              pt: 'Ativos auditados cobrem o passivo e a operação mantém margem para on-chain, Lightning e coleta segregada de lucro.',
              en: 'Audited assets cover liabilities and the operation retains margin for on-chain, Lightning, and segregated profit collection.',
              es: 'Los activos auditados cubren el pasivo y la operación mantiene margen para on-chain, Lightning y recolección segregada de ganancias.',
            )
          : copy(
              pt: 'Há atenção necessária entre saldo, liquidez ou confirmações. Revise as reservas antes de ampliar a exposição.',
              en: 'Balance, liquidity, or confirmations need attention. Review reserves before increasing exposure.',
              es: 'Saldo, liquidez o confirmaciones requieren atencion. Revisa las reservas antes de aumentar la exposicion.',
            );

  return Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: statusColor.withValues(alpha: statusOk ? 0.16 : 0.22),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                KeroseneIcons.wallet,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy(
                      pt: 'Tesouraria & Reservas',
                      en: 'Treasury & Reserves',
                      es: 'Tesorería y Reservas',
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy(
                      pt: 'Leitura financeira auditada de passivo, fundos on-chain, liquidez Lightning e lucro segregado.',
                      en: 'Audited financial readout of liabilities, on-chain funds, Lightning liquidity, and segregated profit.',
                      es: 'Lectura financiera auditada de pasivo, fondos on-chain, liquidez Lightning y ganancia segregada.',
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                statusLabel,
                style: AppTypography.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          summary,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SummaryPill(
              label: context.tr.securityTreasuryBuffer,
              value: formatSignedBtc(buffer),
              ok: buffer >= 0,
            ),
            SummaryPill(
              label: context.tr.securityTreasuryConfirmations,
              value: '$activeNodes/$totalNodes',
              ok: quorumHealthy,
            ),
            SummaryPill(
              label: context.tr.securityTreasuryLightning,
              value: formatShortBtc(lightningBalance),
              ok: lightningBalance > 0,
            ),
            SummaryPill(
              label: context.tr.securityTreasuryProfit,
              value: formatShortBtc(profitPending),
              ok: profitPending >= 0,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final itemWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: SecurityMetricCard(
                    label: copy(
                      pt: 'Ativos totais',
                      en: 'Total assets',
                      es: 'Activos totales',
                    ),
                    value: formatBtc(totalAssets),
                    detail: copy(
                      pt: 'Reservas auditadas',
                      en: 'Audited reserves',
                      es: 'Reservas auditadas',
                    ),
                    accentColor: statusColor,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: SecurityMetricCard(
                    label: copy(
                      pt: 'Passivo',
                      en: 'Liability',
                      es: 'Pasivo',
                    ),
                    value: formatBtc(liability),
                    detail: copy(
                      pt: 'Saldo devido a usuários',
                      en: 'Balance owed to users',
                      es: 'Saldo adeudado a usuarios',
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: SecurityMetricCard(
                    label: copy(
                      pt: 'On-chain',
                      en: 'On-chain',
                      es: 'On-chain',
                    ),
                    value: formatBtc(onchainBalance),
                    detail: copy(
                      pt: 'Reservas acompanhadas',
                      en: 'Tracked reserves',
                      es: 'Reservas acompanadas',
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: SecurityMetricCard(
                    label: copy(
                      pt: 'Liquidez Lightning',
                      en: 'Lightning liquidity',
                      es: 'Liquidez Lightning',
                    ),
                    value: formatBtc(lightningBalance),
                    detail: copy(
                      pt: 'Capacidade operacional',
                      en: 'Operational capacity',
                      es: 'Capacidad operativa',
                    ),
                    accentColor: lightningBalance > 0
                        ? AppColors.success
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const Divider(color: AppColors.surfaceLight, height: 1),
        const SizedBox(height: 16),
        KfeReserveDetailRow(
          label: copy(
            pt: 'Carteiras frias acompanhadas',
            en: 'Watched cold wallets',
            es: 'Billeteras frias acompanadas',
          ),
          value: formatBtc(walletXpubBalance),
        ),
        const SizedBox(height: 10),
        KfeReserveDetailRow(
          label: copy(
            pt: 'Cofre principal acompanhado',
            en: 'Tracked main vault',
            es: 'Boveda principal acompanada',
          ),
          value: formatBtc(treasuryXpubBalance),
        ),
        const SizedBox(height: 10),
        KfeReserveDetailRow(
          label: copy(
            pt: 'Lucro segregado pendente',
            en: 'Pending segregated profit',
            es: 'Ganancia segregada pendiente',
          ),
          value: formatBtc(profitPending),
        ),
        const SizedBox(height: 10),
        KfeReserveDetailRow(
          label: copy(
            pt: 'Pressão operacional',
            en: 'Operational pressure',
            es: 'Presión operativa',
          ),
          value: failStopMode
              ? copy(
                  pt: 'Saídas pausadas por segurança',
                  en: 'Outflows paused for safety',
                  es: 'Salidas pausadas por seguridad',
                )
              : copy(
                  pt: 'Confirmações $activeNodes/$totalNodes ativas • mínimo $requiredNodes',
                  en: 'Confirmations $activeNodes/$totalNodes active • minimum $requiredNodes',
                  es: 'Confirmaciones $activeNodes/$totalNodes activas • minimo $requiredNodes',
                ),
          highlight: quorumHealthy,
        ),
      ],
    ),
  );
}
