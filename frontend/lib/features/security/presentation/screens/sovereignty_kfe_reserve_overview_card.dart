import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/security/domain/entities/kfe_reserve_overview.dart';

import 'sovereignty_status_components.dart';
import 'sovereignty_kfe_reserve_helpers.dart';

typedef SovereigntyCopy = String Function(
    {required String pt, required String en, required String es});

Widget buildKfeReserveOverviewCard({
  required BuildContext context,
  required AsyncValue<KfeReserveOverview> overviewAsync,
  required SovereigntyCopy copy,
}) {
  return overviewAsync.when(
    loading: () => buildKfeReserveLoadingCard(context: context),
    error: (error, _) => buildKfeReserveUnavailableCard(
        context: context, message: error.toString(), copy: copy),
    data: (overview) {
      final liquidityHealthy = overview.lightningSendsAllowed;
      final liquidityColor = liquidityHealthy
          ? AppColors.success
          : Theme.of(context).colorScheme.error;
      final liquidityLabel = liquidityStateLabel(overview.liquidityState);
      final liquiditySummary = liquidityStateSummary(overview);

      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: liquidityColor.withValues(alpha: 0.18),
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
                    color: liquidityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    KeroseneIcons.wallet,
                    color: liquidityColor,
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
                          pt: 'Tesouraria operacional',
                          en: 'Operational treasury',
                          es: 'Tesorería operativa',
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        copy(
                          pt: 'Leitura ao vivo de reservas on-chain, liquidez Lightning e fundos reservados por saídas ainda pendentes.',
                          en: 'Live readout of on-chain reserves, Lightning liquidity, and funds reserved by pending outflows.',
                          es: 'Lectura en vivo de reservas on-chain, liquidez Lightning y fondos reservados por salidas aún pendientes.',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: liquidityColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: liquidityColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    liquidityLabel,
                    style: AppTypography.caption.copyWith(
                      color: liquidityColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              liquiditySummary,
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
                  label: copy(
                    pt: 'Saques LN',
                    en: 'LN sends',
                    es: 'Envíos LN',
                  ),
                  value: overview.lightningSendsAllowed
                      ? copy(pt: 'Liberados', en: 'Allowed', es: 'Permitidos')
                      : copy(pt: 'Bloqueados', en: 'Blocked', es: 'Bloqueados'),
                  ok: overview.lightningSendsAllowed,
                ),
                SummaryPill(
                  label: copy(
                    pt: 'Disponível LN',
                    en: 'LN available',
                    es: 'LN disponible',
                  ),
                  value: formatShortBtc(overview.availableLightningBtc),
                  ok: overview.availableLightningBtc > 0,
                ),
                SummaryPill(
                  label: copy(
                    pt: 'Reserva on-chain',
                    en: 'On-chain reserve',
                    es: 'Reserva on-chain',
                  ),
                  value: formatShortBtc(overview.availableOnchainBtc),
                  ok: overview.availableOnchainBtc > 0,
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
                          pt: 'Custódia on-chain',
                          en: 'On-chain custody',
                          es: 'Custodia on-chain',
                        ),
                        value: formatBtc(overview.totalOnchainBtc),
                        detail: copy(
                          pt: 'BTC sob controle direto da tesouraria',
                          en: 'BTC directly controlled by treasury',
                          es: 'BTC bajo control directo de la tesorería',
                        ),
                        accentColor: AppColors.secondary,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: SecurityMetricCard(
                        label: copy(
                          pt: 'Saldo Lightning',
                          en: 'Lightning balance',
                          es: 'Saldo Lightning',
                        ),
                        value: formatBtc(overview.lightningNodeBtc),
                        detail: copy(
                          pt: 'Saldo total disponível para operações Lightning',
                          en: 'Total balance available for Lightning activity',
                          es: 'Saldo total disponible para operaciones Lightning',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: SecurityMetricCard(
                        label: copy(
                          pt: 'Liquidez para envio',
                          en: 'Send liquidity',
                          es: 'Liquidez para envio',
                        ),
                        value: formatBtc(overview.outboundLiquidityBtc),
                        detail: copy(
                          pt: 'Capacidade de saída disponível para pagamentos LN',
                          en: 'Available capacity for Lightning payments',
                          es: 'Capacidad disponible para pagos Lightning',
                        ),
                        accentColor: overview.lightningSendsAllowed
                            ? AppColors.success
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: SecurityMetricCard(
                        label: copy(
                          pt: 'Liquidez para recebimento',
                          en: 'Receive liquidity',
                          es: 'Liquidez para recepcion',
                        ),
                        value: formatBtc(overview.inboundLiquidityBtc),
                        detail: copy(
                          pt: 'Capacidade de recebimento Lightning observada',
                          en: 'Observed Lightning receive capacity',
                          es: 'Capacidad observada de recepcion Lightning',
                        ),
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
                pt: 'Reservado em saques on-chain',
                en: 'Reserved in on-chain outflows',
                es: 'Reservado en salidas on-chain',
              ),
              value: formatBtc(overview.reservedOnchainBtc),
            ),
            const SizedBox(height: 10),
            KfeReserveDetailRow(
              label: copy(
                pt: 'Reservado em pagamentos Lightning',
                en: 'Reserved in Lightning payments',
                es: 'Reservado en pagos Lightning',
              ),
              value: formatBtc(overview.reservedLightningBtc),
            ),
            const SizedBox(height: 10),
            KfeReserveDetailRow(
              label: copy(
                pt: 'Disponível on-chain',
                en: 'Available on-chain',
                es: 'Disponible on-chain',
              ),
              value: formatBtc(overview.availableOnchainBtc),
              highlight: overview.availableOnchainBtc > 0,
            ),
            const SizedBox(height: 10),
            KfeReserveDetailRow(
              label: copy(
                pt: 'Disponível Lightning',
                en: 'Available Lightning',
                es: 'Disponible Lightning',
              ),
              value: formatBtc(overview.availableLightningBtc),
              highlight: overview.availableLightningBtc > 0,
            ),
          ],
        ),
      );
    },
  );
}
