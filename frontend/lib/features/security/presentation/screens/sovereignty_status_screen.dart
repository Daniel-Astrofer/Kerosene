import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../domain/entities/security_status.dart';
import '../../domain/entities/treasury_overview.dart';
import '../providers/security_provider.dart';

class SovereigntyStatusScreen extends ConsumerStatefulWidget {
  const SovereigntyStatusScreen({super.key});

  @override
  ConsumerState<SovereigntyStatusScreen> createState() =>
      _SovereigntyStatusScreenState();
}

class _SovereigntyStatusScreenState
    extends ConsumerState<SovereigntyStatusScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.invalidate(sovereigntyStatusProvider);
      ref.invalidate(treasuryOverviewProvider);
      ref.invalidate(auditStatsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _copy({
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

  Future<void> _refreshStatus() async {
    HapticFeedback.selectionClick();
    ref.invalidate(sovereigntyStatusProvider);
    ref.invalidate(treasuryOverviewProvider);
    ref.invalidate(auditStatsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  bool _allSignalsHealthy(SecurityStatus status) {
    return status.hardwareAttestation['status'] == 'VERIFIED' &&
        status.networkConsensus['status'] == 'ACTIVE' &&
        status.ledgerIntegrity['status'] == 'VALID' &&
        status.memoryProtection['status'] == 'LOCKED';
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sovereigntyStatusProvider);
    final treasuryOverviewAsync = ref.watch(treasuryOverviewProvider);
    final auditStatsAsync = ref.watch(auditStatsProvider);

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: ColoredBox(
        color: authenticatedSurfaceBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: statusAsync.when(
                  data: (status) => _buildContent(
                    status,
                    treasuryOverviewAsync,
                    auditStatsAsync,
                  ),
                  loading: _buildLoadingState,
                  error: (error, _) => _buildErrorState(error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.sovereigntyStatusTitle,
                  style: AppTypography.buttonText.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.6,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _copy(
                    pt: 'Leitura operacional atualizada automaticamente a cada 12 segundos',
                    en: 'Operational readout automatically refreshed every 12 seconds',
                    es: 'Lectura operativa actualizada automaticamente cada 12 segundos',
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _refreshStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _copy(pt: 'Atualizar', en: 'Refresh', es: 'Actualizar'),
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    SecurityStatus status,
    AsyncValue<TreasuryOverview> treasuryOverviewAsync,
    AsyncValue<Map<String, dynamic>> auditStatsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshStatus,
      color: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildExecutiveSummary(status),
          const SizedBox(height: 16),
          _buildSignalStrip(status),
          const SizedBox(height: 16),
          _buildTreasuryOverviewCard(treasuryOverviewAsync),
          const SizedBox(height: 16),
          _buildTreasuryCard(status, auditStatsAsync),
          const SizedBox(height: 24),
          _buildTpmCard(status.hardwareAttestation),
          const SizedBox(height: 16),
          _buildQuorumCard(status.networkConsensus),
          const SizedBox(height: 16),
          _buildMerkleCard(status.ledgerIntegrity),
          const SizedBox(height: 16),
          _buildMemoryCard(status.memoryProtection),
          const SizedBox(height: 16),
          _buildUptimeCard(status.serverUptimeSeconds),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(SecurityStatus status) {
    final allGood = _allSignalsHealthy(status);
    final primaryColor =
        allGood ? AppColors.success : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: allGood ? 0.18 : 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  allGood
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allGood
                          ? _copy(
                              pt: 'Operação íntegra',
                              en: 'Operational integrity confirmed',
                              es: 'Integridad operativa confirmada',
                            )
                          : _copy(
                              pt: 'Atenção operacional necessária',
                              en: 'Operational attention required',
                              es: 'Se requiere atención operativa',
                            ),
                      style: AppTypography.h3.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      allGood
                          ? _copy(
                              pt: 'Hardware, consenso, integridade do ledger e proteção de memória estão consistentes nesta leitura.',
                              en: 'Hardware, consensus, ledger integrity, and memory protection are consistent in this readout.',
                              es: 'Hardware, consenso, integridad del ledger y protección de memoria están consistentes en esta lectura.',
                            )
                          : _copy(
                              pt: 'Um ou mais sinais não estão no estado ideal. Revise os blocos abaixo antes de tratar esta leitura como saudável.',
                              en: 'One or more signals are not in the ideal state. Review the blocks below before treating this readout as healthy.',
                              es: 'Una o más señales no están en el estado ideal. Revisa los bloques de abajo antes de tratar esta lectura como saludable.',
                            ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                label: context.tr.hardwareAttestation,
                value: status.hardwareAttestation['status'] ?? 'UNKNOWN',
                ok: status.hardwareAttestation['status'] == 'VERIFIED',
              ),
              _SummaryPill(
                label: context.tr.networkConsensus,
                value: status.networkConsensus['status'] ?? 'OFFLINE',
                ok: status.networkConsensus['status'] == 'ACTIVE',
              ),
              _SummaryPill(
                label: context.tr.ledgerIntegrity,
                value: status.ledgerIntegrity['status'] ?? 'INVALID',
                ok: status.ledgerIntegrity['status'] == 'VALID',
              ),
              _SummaryPill(
                label: context.tr.memoryProtection,
                value: status.memoryProtection['status'] ?? 'UNLOCKED',
                ok: status.memoryProtection['status'] == 'LOCKED',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStrip(SecurityStatus status) {
    final tpmChecks = status.hardwareAttestation['totalChecks'] ?? 0;
    final activeNodes = status.networkConsensus['activeNodes'] ?? 0;
    final totalNodes = status.networkConsensus['totalNodes'] ?? 0;
    final ledgerCount = status.ledgerIntegrity['ledgerCount'] ?? 0;
    final diskPersistence = status.memoryProtection['diskPersistence'] == true;
    final quorumLabel =
        _copy(pt: 'Confirmações', en: 'Confirmations', es: 'Confirmaciones');
    final ledgerLabel = _copy(pt: 'Ledger', en: 'Ledger', es: 'Ledger');

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: _copy(
                  pt: 'Verificações',
                  en: 'Checks',
                  es: 'Verificaciones',
                ),
                value: '$tpmChecks',
                detail: _copy(
                  pt: 'Total de atestações',
                  en: 'Total attestations',
                  es: 'Total de atestaciones',
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: quorumLabel,
                value: '$activeNodes/$totalNodes',
                detail: _copy(
                  pt: 'Confirmações ativas',
                  en: 'Active confirmations',
                  es: 'Confirmaciones activas',
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: ledgerLabel,
                value: '$ledgerCount',
                detail: _copy(
                  pt: 'Carteiras auditadas',
                  en: 'Wallets audited',
                  es: 'Carteras auditadas',
                ),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: _copy(
                  pt: 'Persistência',
                  en: 'Persistence',
                  es: 'Persistencia',
                ),
                value: diskPersistence
                    ? _copy(pt: 'Disco', en: 'Disk', es: 'Disco')
                    : _copy(pt: 'Memória', en: 'Memory', es: 'Memoria'),
                detail: diskPersistence
                    ? _copy(
                        pt: 'Risco elevado',
                        en: 'Higher risk',
                        es: 'Riesgo mayor',
                      )
                    : _copy(
                        pt: 'Sem gravação',
                        en: 'No disk write',
                        es: 'Sin escritura en disco',
                      ),
                accentColor: diskPersistence
                    ? Theme.of(context).colorScheme.error
                    : AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTpmCard(Map<String, dynamic> tpm) {
    final verified = tpm['status'] == 'VERIFIED';
    final chipSubtitle = (tpm['chip'] ?? 'Secure Element').toString();
    final pcrQuoteHashLabel = 'PCR Quote Hash';
    final chipLabel = _copy(pt: 'Chip', en: 'Chip', es: 'Chip');
    final chipValue = (tpm['chip'] ?? 'Generic TPM').toString();

    return _SecurityCard(
      icon: Icons.memory_rounded,
      title: context.tr.hardwareAttestation,
      subtitle: chipSubtitle,
      statusOk: verified,
      statusLabel: tpm['status'] ?? 'UNKNOWN',
      rows: [
        _Row(
          label: _copy(
            pt: 'Última validação',
            en: 'Last validation',
            es: 'Última validación',
          ),
          value: '${tpm['lastValidatedSecondsAgo'] ?? 0}s',
          isHighlight: (tpm['lastValidatedSecondsAgo'] ?? 99) < 12,
        ),
        _Row(
          label: _copy(
            pt: 'Verificações totais',
            en: 'Total checks',
            es: 'Verificaciones totales',
          ),
          value: '${tpm['totalChecks'] ?? 0}',
        ),
        _Row(
          label: pcrQuoteHashLabel,
          value: tpm['quoteHash'] ?? '0x...',
          isMono: true,
        ),
        _Row(
          label: chipLabel,
          value: chipValue,
        ),
      ],
    );
  }

  Widget _buildTreasuryCard(
    SecurityStatus status,
    AsyncValue<Map<String, dynamic>> auditStatsAsync,
  ) {
    return auditStatsAsync.when(
      loading: _buildTreasuryLoadingCard,
      error: (error, _) => _buildTreasuryUnavailableCard(error.toString()),
      data: (stats) {
        if (stats.isEmpty) {
          return _buildTreasuryUnavailableCard(
            _copy(
              pt: 'A auditoria financeira ainda não retornou métricas para esta leitura.',
              en: 'Financial audit has not returned metrics for this readout yet.',
              es: 'La auditoría financiera todavía no devolvió métricas para esta lectura.',
            ),
          );
        }
        return _buildTreasurySnapshot(status, stats);
      },
    );
  }

  Widget _buildTreasuryLoadingCard() {
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
              _copy(
                pt: 'Consolidando tesouraria, liquidez Lightning e reservas auditadas.',
                en: 'Consolidating treasury, Lightning liquidity, and audited reserves.',
                es: 'Consolidando tesorería, liquidez Lightning y reservas auditadas.',
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryOverviewCard(
    AsyncValue<TreasuryOverview> treasuryOverviewAsync,
  ) {
    return treasuryOverviewAsync.when(
      loading: _buildTreasuryLoadingCard,
      error: (error, _) => _buildTreasuryUnavailableCard(error.toString()),
      data: (overview) {
        final liquidityHealthy = overview.lightningSendsAllowed;
        final liquidityColor = liquidityHealthy
            ? AppColors.success
            : Theme.of(context).colorScheme.error;
        final liquidityLabel = _liquidityStateLabel(overview.liquidityState);
        final liquiditySummary = _liquidityStateSummary(overview);

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
                      Icons.account_balance_wallet_rounded,
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
                          _copy(
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
                          _copy(
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
                  _SummaryPill(
                    label: _copy(
                      pt: 'Saques LN',
                      en: 'LN sends',
                      es: 'Envíos LN',
                    ),
                    value: overview.lightningSendsAllowed
                        ? _copy(
                            pt: 'Liberados', en: 'Allowed', es: 'Permitidos')
                        : _copy(
                            pt: 'Bloqueados', en: 'Blocked', es: 'Bloqueados'),
                    ok: overview.lightningSendsAllowed,
                  ),
                  _SummaryPill(
                    label: _copy(
                      pt: 'Disponível LN',
                      en: 'LN available',
                      es: 'LN disponible',
                    ),
                    value: _formatShortBtc(overview.availableLightningBtc),
                    ok: overview.availableLightningBtc > 0,
                  ),
                  _SummaryPill(
                    label: _copy(
                      pt: 'Reserva on-chain',
                      en: 'On-chain reserve',
                      es: 'Reserva on-chain',
                    ),
                    value: _formatShortBtc(overview.availableOnchainBtc),
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
                        child: _MetricCard(
                          label: _copy(
                            pt: 'Custódia on-chain',
                            en: 'On-chain custody',
                            es: 'Custodia on-chain',
                          ),
                          value: _formatBtc(overview.totalOnchainBtc),
                          detail: _copy(
                            pt: 'BTC sob controle direto da tesouraria',
                            en: 'BTC directly controlled by treasury',
                            es: 'BTC bajo control directo de la tesorería',
                          ),
                          accentColor: AppColors.secondary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _MetricCard(
                          label: _copy(
                            pt: 'Saldo Lightning',
                            en: 'Lightning balance',
                            es: 'Saldo Lightning',
                          ),
                          value: _formatBtc(overview.lightningNodeBtc),
                          detail: _copy(
                            pt: 'Saldo total disponível para operações Lightning',
                            en: 'Total balance available for Lightning activity',
                            es: 'Saldo total disponible para operaciones Lightning',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _MetricCard(
                          label: _copy(
                            pt: 'Liquidez para envio',
                            en: 'Send liquidity',
                            es: 'Liquidez para envio',
                          ),
                          value: _formatBtc(overview.outboundLiquidityBtc),
                          detail: _copy(
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
                        child: _MetricCard(
                          label: _copy(
                            pt: 'Liquidez para recebimento',
                            en: 'Receive liquidity',
                            es: 'Liquidez para recepcion',
                          ),
                          value: _formatBtc(overview.inboundLiquidityBtc),
                          detail: _copy(
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
              _TreasuryDetailRow(
                label: _copy(
                  pt: 'Reservado em saques on-chain',
                  en: 'Reserved in on-chain outflows',
                  es: 'Reservado en salidas on-chain',
                ),
                value: _formatBtc(overview.reservedOnchainBtc),
              ),
              const SizedBox(height: 10),
              _TreasuryDetailRow(
                label: _copy(
                  pt: 'Reservado em pagamentos Lightning',
                  en: 'Reserved in Lightning payments',
                  es: 'Reservado en pagos Lightning',
                ),
                value: _formatBtc(overview.reservedLightningBtc),
              ),
              const SizedBox(height: 10),
              _TreasuryDetailRow(
                label: _copy(
                  pt: 'Disponível on-chain',
                  en: 'Available on-chain',
                  es: 'Disponible on-chain',
                ),
                value: _formatBtc(overview.availableOnchainBtc),
                highlight: overview.availableOnchainBtc > 0,
              ),
              const SizedBox(height: 10),
              _TreasuryDetailRow(
                label: _copy(
                  pt: 'Disponível Lightning',
                  en: 'Available Lightning',
                  es: 'Disponible Lightning',
                ),
                value: _formatBtc(overview.availableLightningBtc),
                highlight: overview.availableLightningBtc > 0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreasuryUnavailableCard(String message) {
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
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
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
                  _copy(
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
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasurySnapshot(
    SecurityStatus status,
    Map<String, dynamic> stats,
  ) {
    final liability = _asDouble(stats['liability_to_users']);
    final profitPending = _asDouble(stats['platform_profit_pending']);
    final onchainBalance = _asDouble(stats['actual_onchain_balance']);
    final lightningBalance = _asDouble(stats['actual_lightning_balance']);
    final walletXpubBalance = _asDouble(stats['actual_wallet_xpub_balance']);
    final treasuryXpubBalance =
        _asDouble(stats['actual_treasury_xpub_balance']);
    final totalAssets = _asDouble(stats['actual_total_assets']);
    final buffer = totalAssets - liability;

    final networkConsensus = status.networkConsensus;
    final activeNodes = (networkConsensus['activeNodes'] as num?)?.toInt() ?? 0;
    final totalNodes = (networkConsensus['totalNodes'] as num?)?.toInt() ?? 0;
    final requiredNodes =
        (networkConsensus['requiredNodes'] as num?)?.toInt() ?? 0;
    final failStopMode = networkConsensus['failStopMode'] == true;

    final isSolvent =
        _asBool(stats['is_solvent']) ?? (onchainBalance >= liability);
    final quorumHealthy =
        !failStopMode && totalNodes > 0 && activeNodes >= requiredNodes;
    final statusOk = isSolvent && quorumHealthy;
    final statusColor =
        statusOk ? AppColors.success : Theme.of(context).colorScheme.error;
    final statusLabel = failStopMode
        ? _copy(
            pt: 'SAÍDAS PAUSADAS',
            en: 'OUTFLOWS PAUSED',
            es: 'SALIDAS PAUSADAS',
          )
        : (isSolvent
            ? _copy(pt: 'SOLVENTE', en: 'SOLVENT', es: 'SOLVENTE')
            : _copy(pt: 'RISCO', en: 'RISK', es: 'RIESGO'));

    final summary = failStopMode
        ? _copy(
            pt: 'As saídas foram pausadas por segurança até que as confirmações voltem ao nível mínimo. A liquidez segue visível.',
            en: 'Outflows are paused for safety until confirmations return to the minimum level. Liquidity remains visible.',
            es: 'Las salidas estan pausadas por seguridad hasta que las confirmaciones vuelvan al nivel minimo. La liquidez sigue visible.',
          )
        : statusOk
            ? _copy(
                pt: 'Ativos auditados cobrem o passivo e a operação mantém margem para on-chain, Lightning e coleta segregada de lucro.',
                en: 'Audited assets cover liabilities and the operation retains margin for on-chain, Lightning, and segregated profit collection.',
                es: 'Los activos auditados cubren el pasivo y la operación mantiene margen para on-chain, Lightning y recolección segregada de ganancias.',
              )
            : _copy(
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
                  Icons.account_balance_wallet_rounded,
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
                      _copy(
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
                      _copy(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              _SummaryPill(
                label: context.tr.securityTreasuryBuffer,
                value: _formatSignedBtc(buffer),
                ok: buffer >= 0,
              ),
              _SummaryPill(
                label: context.tr.securityTreasuryConfirmations,
                value: '$activeNodes/$totalNodes',
                ok: quorumHealthy,
              ),
              _SummaryPill(
                label: context.tr.securityTreasuryLightning,
                value: _formatShortBtc(lightningBalance),
                ok: lightningBalance > 0,
              ),
              _SummaryPill(
                label: context.tr.securityTreasuryProfit,
                value: _formatShortBtc(profitPending),
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
                    child: _MetricCard(
                      label: _copy(
                        pt: 'Ativos totais',
                        en: 'Total assets',
                        es: 'Activos totales',
                      ),
                      value: _formatBtc(totalAssets),
                      detail: _copy(
                        pt: 'Reservas auditadas',
                        en: 'Audited reserves',
                        es: 'Reservas auditadas',
                      ),
                      accentColor: statusColor,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: _copy(
                        pt: 'Passivo',
                        en: 'Liability',
                        es: 'Pasivo',
                      ),
                      value: _formatBtc(liability),
                      detail: _copy(
                        pt: 'Saldo devido a usuários',
                        en: 'Balance owed to users',
                        es: 'Saldo adeudado a usuarios',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: _copy(
                        pt: 'On-chain',
                        en: 'On-chain',
                        es: 'On-chain',
                      ),
                      value: _formatBtc(onchainBalance),
                      detail: _copy(
                        pt: 'Reservas acompanhadas',
                        en: 'Tracked reserves',
                        es: 'Reservas acompanadas',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(
                      label: _copy(
                        pt: 'Liquidez Lightning',
                        en: 'Lightning liquidity',
                        es: 'Liquidez Lightning',
                      ),
                      value: _formatBtc(lightningBalance),
                      detail: _copy(
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
          _TreasuryDetailRow(
            label: _copy(
              pt: 'Carteiras frias acompanhadas',
              en: 'Watched cold wallets',
              es: 'Billeteras frias acompanadas',
            ),
            value: _formatBtc(walletXpubBalance),
          ),
          const SizedBox(height: 10),
          _TreasuryDetailRow(
            label: _copy(
              pt: 'Cofre principal acompanhado',
              en: 'Tracked main vault',
              es: 'Boveda principal acompanada',
            ),
            value: _formatBtc(treasuryXpubBalance),
          ),
          const SizedBox(height: 10),
          _TreasuryDetailRow(
            label: _copy(
              pt: 'Lucro segregado pendente',
              en: 'Pending segregated profit',
              es: 'Ganancia segregada pendiente',
            ),
            value: _formatBtc(profitPending),
          ),
          const SizedBox(height: 10),
          _TreasuryDetailRow(
            label: _copy(
              pt: 'Pressão operacional',
              en: 'Operational pressure',
              es: 'Presión operativa',
            ),
            value: failStopMode
                ? _copy(
                    pt: 'Saídas pausadas por segurança',
                    en: 'Outflows paused for safety',
                    es: 'Salidas pausadas por seguridad',
                  )
                : _copy(
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

  Widget _buildQuorumCard(Map<String, dynamic> quorum) {
    final active = quorum['status'] == 'ACTIVE';
    final activeNodes = quorum['activeNodes'] ?? 0;
    final totalNodes = quorum['totalNodes'] ?? 3;
    final quorumLabel =
        _copy(pt: 'Confirmações', en: 'Confirmations', es: 'Confirmaciones');
    final algorithmLabel = _copy(pt: 'Regra', en: 'Rule', es: 'Regla');
    final jurisdictions = (quorum['jurisdictions'] as List<dynamic>?)
            ?.map((entry) => entry.toString())
            .toList() ??
        <String>[];

    return _SecurityCard(
      icon: Icons.hub_rounded,
      title: context.tr.networkConsensus,
      subtitle:
          '$activeNodes/$totalNodes ${_copy(pt: 'confirmações ativas', en: 'active confirmations', es: 'confirmaciones activas')}',
      statusOk: active,
      statusLabel: active
          ? _copy(pt: 'Ativo', en: 'Active', es: 'Activo')
          : _copy(
              pt: 'Atenção necessária',
              en: 'Needs attention',
              es: 'Requiere atención',
            ),
      rows: [
        _Row(
          label: quorumLabel,
          value: '$activeNodes/$totalNodes',
          isHighlight: activeNodes == totalNodes,
        ),
        _Row(
          label: algorithmLabel,
          value: _copy(
            pt: 'Confirmação distribuída',
            en: 'Distributed approval',
            es: 'Aprobación distribuida',
          ),
        ),
        for (int i = 0; i < jurisdictions.length; i++)
          _Row(
            label:
                '${_copy(pt: 'Jurisdição', en: 'Jurisdiction', es: 'Jurisdicción')} ${i + 1}',
            value: jurisdictions[i],
          ),
      ],
      extraWidget: _buildNodeDots(
        jurisdictions: jurisdictions,
        activeNodes: activeNodes,
        totalNodes: totalNodes,
      ),
    );
  }

  Widget _buildNodeDots({
    required List<String> jurisdictions,
    required int activeNodes,
    required int totalNodes,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(totalNodes, (index) {
          final active = index < activeNodes;
          final label = jurisdictions.length > index
              ? jurisdictions[index].substring(
                  0,
                  jurisdictions[index].length < 3
                      ? jurisdictions[index].length
                      : 3,
                )
              : 'N${index + 1}';

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == totalNodes - 1 ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: (active
                          ? AppColors.success
                          : Theme.of(context).colorScheme.error)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (active
                            ? AppColors.success
                            : Theme.of(context).colorScheme.error)
                        .withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      active
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: active
                          ? AppColors.success
                          : Theme.of(context).colorScheme.error,
                      size: 14,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMerkleCard(Map<String, dynamic> merkle) {
    final status = merkle['status'] ?? 'INVALID';
    final subtitle = 'Merkle Tree (SHA-256)';

    return _SecurityCard(
      icon: Icons.account_tree_rounded,
      title: context.tr.ledgerIntegrity,
      subtitle: subtitle,
      statusOk: status == 'VALID',
      statusLabel: status,
      rows: [
        if (merkle['lastRootHash'] != null)
          _Row(
            label:
                _copy(pt: 'Raiz Merkle', en: 'Merkle root', es: 'Raíz Merkle'),
            value: merkle['lastRootHash'].toString(),
            isMono: true,
          ),
        if (merkle['computedAt'] != null)
          _Row(
            label: _copy(
                pt: 'Computado em', en: 'Computed at', es: 'Calculado en'),
            value: _formatDate(merkle['computedAt'].toString()),
          ),
        if (merkle['ledgerCount'] != null)
          _Row(
            label: _copy(
              pt: 'Carteiras auditadas',
              en: 'Wallets audited',
              es: 'Carteras auditadas',
            ),
            value: '${merkle['ledgerCount']}',
            isHighlight: true,
          ),
      ],
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory) {
    final status = memory['status'] ?? 'UNLOCKED';
    final subtitle = (memory['shardLocation'] ?? 'Unknown location').toString();
    final mechanismLabel =
        _copy(pt: 'Mecanismo', en: 'Mechanism', es: 'Mecanismo');

    return _SecurityCard(
      icon: Icons.lock_rounded,
      title: context.tr.memoryProtection,
      subtitle: subtitle,
      statusOk: status == 'LOCKED',
      statusLabel: status,
      rows: [
        _Row(
          label: mechanismLabel,
          value: memory['mechanism'] ?? 'None',
        ),
        _Row(
          label: _copy(
            pt: 'Local do shard',
            en: 'Shard location',
            es: 'Ubicación del shard',
          ),
          value: memory['shardLocation'] ?? 'Global Cluster',
        ),
        _Row(
          label: _copy(
            pt: 'Persistência em disco',
            en: 'Disk persistence',
            es: 'Persistencia en disco',
          ),
          value: memory['diskPersistence'] == true
              ? _copy(pt: 'Ativa', en: 'Enabled', es: 'Activa')
              : _copy(pt: 'Desativada', en: 'Disabled', es: 'Desactivada'),
          isHighlight: memory['diskPersistence'] == false,
        ),
      ],
    );
  }

  Widget _buildUptimeCard(int uptimeSeconds) {
    final hours = uptimeSeconds ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    final seconds = uptimeSeconds % 60;
    final uptime =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.serverUptime,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _copy(
                    pt: 'Disponibilidade acumulada do serviço',
                    en: 'Accumulated service availability',
                    es: 'Disponibilidad acumulada del servicio',
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
          Text(
            uptime,
            style: AppTypography.number.copyWith(
              fontFamily: AppTypography.numericFontFamily,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        _copy(
          pt: 'Painel atualizado automaticamente. Puxe a tela para forçar uma nova leitura.',
          en: 'Panel refreshes automatically. Pull the screen to force a new readout.',
          es: 'El panel se actualiza automáticamente. Desliza para forzar una nueva lectura.',
        ),
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: AppColors.white50,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _copy(
              pt: 'Coletando sinais de soberania',
              en: 'Collecting sovereignty signals',
              es: 'Recolectando señales de soberanía',
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 16),
              Text(
                _copy(
                  pt: 'Leitura indisponível',
                  en: 'Readout unavailable',
                  es: 'Lectura no disponible',
                ),
                style: AppTypography.h3.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _copy(
                  pt: 'Não foi possível alcançar o serviço de atestação neste momento.',
                  en: 'The attestation service could not be reached at this time.',
                  es: 'No fue posible alcanzar el servicio de atestación en este momento.',
                ),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.white50,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _refreshStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    _copy(
                      pt: 'Tentar novamente',
                      en: 'Try again',
                      es: 'Intentar de nuevo',
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  String _formatBtc(double value) => '${value.toStringAsFixed(8)} BTC';

  String _formatShortBtc(double value) => '${value.toStringAsFixed(4)} BTC';

  String _formatSignedBtc(double value) {
    final sign = value > 0
        ? '+'
        : value < 0
            ? '-'
            : '';
    return '$sign${value.abs().toStringAsFixed(8)} BTC';
  }

  String _liquidityStateLabel(String state) {
    switch (state.trim().toUpperCase()) {
      case 'HEALTHY':
        return 'HEALTHY';
      case 'REBALANCE_REQUIRED':
        return 'REBALANCE';
      case 'BLOCKED_ONCHAIN_RESERVE':
        return 'BLOCKED';
      default:
        return state.trim().isEmpty ? 'UNKNOWN' : state.trim().toUpperCase();
    }
  }

  String _liquidityStateSummary(TreasuryOverview overview) {
    switch (overview.liquidityState.trim().toUpperCase()) {
      case 'HEALTHY':
        return _copy(
          pt: 'A reserva Bitcoin cobre a liquidez Lightning disponível para envio e os pagamentos podem seguir normalmente.',
          en: 'Bitcoin reserves cover available Lightning send liquidity, so payments can continue normally.',
          es: 'La reserva Bitcoin cubre la liquidez Lightning disponible para envio y los pagos pueden continuar normalmente.',
        );
      case 'REBALANCE_REQUIRED':
        return _copy(
          pt: 'A reserva está íntegra, mas a liquidez Lightning precisa de ajuste antes de ampliar o volume.',
          en: 'Reserves are intact, but Lightning liquidity needs adjustment before volume increases.',
          es: 'Las reservas estan integras, pero la liquidez Lightning necesita ajuste antes de aumentar el volumen.',
        );
      case 'BLOCKED_ONCHAIN_RESERVE':
        return _copy(
          pt: 'Os pagamentos Lightning foram pausados até que a reserva Bitcoin volte ao nível necessário.',
          en: 'Lightning sends are paused until Bitcoin reserves return to the required level.',
          es: 'Los pagos Lightning estan pausados hasta que la reserva Bitcoin vuelva al nivel necesario.',
        );
      default:
        return _copy(
          pt: 'Não conseguimos classificar a liquidez agora. Revise as reservas antes de continuar.',
          en: 'We could not classify liquidity right now. Review reserves before continuing.',
          es: 'No pudimos clasificar la liquidez ahora. Revisa las reservas antes de continuar.',
        );
    }
  }
}

class _Row {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isMono;

  const _Row({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isMono = false,
  });
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color? accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent =
        accentColor ?? Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: resolvedAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasuryDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TreasuryDetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white70,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: highlight
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool statusOk;
  final String statusLabel;
  final List<_Row> rows;
  final Widget? extraWidget;

  const _SecurityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusOk,
    required this.statusLabel,
    required this.rows,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        statusOk ? AppColors.success : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(18),
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: (row.isMono
                            ? AppTypography.technicalMono(
                                textStyle: AppTypography.caption,
                              )
                            : AppTypography.bodySmall)
                        .copyWith(
                      color: row.isHighlight
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (rows.last != row) const SizedBox(height: 10),
          ],
          if (extraWidget != null) extraWidget!,
        ],
      ),
    );
  }
}
