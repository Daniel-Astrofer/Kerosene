import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../domain/entities/security_status.dart';
import '../../domain/entities/kfe_reserve_overview.dart';
import '../providers/security_provider.dart';
import 'package:kerosene/design_system/icons.dart';
import 'sovereignty_status_components.dart';
import 'sovereignty_footer.dart';
import 'sovereignty_tpm_card.dart';
import 'sovereignty_kfe_reserve_overview_card.dart';
import 'sovereignty_kfe_reserve_snapshot_card.dart';

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
      ref.invalidate(kfeReserveOverviewProvider);
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
    ref.invalidate(kfeReserveOverviewProvider);
    ref.invalidate(auditStatsProvider);
    await Future<void>.delayed(KeroseneMotion.medium);
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
    final kfeReserveOverviewAsync = ref.watch(kfeReserveOverviewProvider);
    final auditStatsAsync = ref.watch(auditStatsProvider);

    return Scaffold(
      backgroundColor: KeroseneBrandTokens.backgroundSoft,
      body: ColoredBox(
        color: KeroseneBrandTokens.backgroundSoft,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: statusAsync.when(
                  data: (status) => _buildContent(
                    status,
                    kfeReserveOverviewAsync,
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
                KeroseneIcons.back,
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
                    KeroseneIcons.refresh,
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
    AsyncValue<KfeReserveOverview> kfeReserveOverviewAsync,
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
          _buildKfeReserveOverviewCard(kfeReserveOverviewAsync),
          const SizedBox(height: 16),
          _buildKfeReserveCard(status, auditStatsAsync),
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
                  allGood ? KeroseneIcons.verified : KeroseneIcons.warning,
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
              SummaryPill(
                label: context.tr.hardwareAttestation,
                value: status.hardwareAttestation['status'] ?? 'UNKNOWN',
                ok: status.hardwareAttestation['status'] == 'VERIFIED',
              ),
              SummaryPill(
                label: context.tr.networkConsensus,
                value: status.networkConsensus['status'] ?? 'OFFLINE',
                ok: status.networkConsensus['status'] == 'ACTIVE',
              ),
              SummaryPill(
                label: context.tr.ledgerIntegrity,
                value: status.ledgerIntegrity['status'] ?? 'INVALID',
                ok: status.ledgerIntegrity['status'] == 'VALID',
              ),
              SummaryPill(
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
              child: SecurityMetricCard(
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
              child: SecurityMetricCard(
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
              child: SecurityMetricCard(
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
              child: SecurityMetricCard(
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
    return buildTpmCard(
      context: context,
      tpm: tpm,
      copy: _copy,
    );
  }

  Widget _buildKfeReserveCard(
    SecurityStatus status,
    AsyncValue<Map<String, dynamic>> auditStatsAsync,
  ) {
    return auditStatsAsync.when(
      loading: _buildKfeReserveLoadingCard,
      error: (error, _) => _buildKfeReserveUnavailableCard(error.toString()),
      data: (stats) {
        if (stats.isEmpty) {
          return _buildKfeReserveUnavailableCard(
            _copy(
              pt: 'A auditoria financeira ainda não retornou métricas para esta leitura.',
              en: 'Financial audit has not returned metrics for this readout yet.',
              es: 'La auditoría financiera todavía no devolvió métricas para esta lectura.',
            ),
          );
        }
        return _buildKfeReserveSnapshot(status, stats);
      },
    );
  }

  Widget _buildKfeReserveLoadingCard() {
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

  Widget _buildKfeReserveOverviewCard(
    AsyncValue<KfeReserveOverview> kfeReserveOverviewAsync,
  ) {
    return buildKfeReserveOverviewCard(
      context: context,
      overviewAsync: kfeReserveOverviewAsync,
      copy: _copy,
    );
  }

  Widget _buildKfeReserveUnavailableCard(String message) {
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

  Widget _buildKfeReserveSnapshot(
    SecurityStatus status,
    Map<String, dynamic> stats,
  ) {
    return buildKfeReserveSnapshotCard(
      context: context,
      status: status,
      stats: stats,
      copy: _copy,
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

    return SecurityStatusCard(
      icon: KeroseneIcons.hub,
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
        SecurityInfoRow(
          label: quorumLabel,
          value: '$activeNodes/$totalNodes',
          isHighlight: activeNodes == totalNodes,
        ),
        SecurityInfoRow(
          label: algorithmLabel,
          value: _copy(
            pt: 'Confirmação distribuída',
            en: 'Distributed approval',
            es: 'Aprobación distribuida',
          ),
        ),
        for (int i = 0; i < jurisdictions.length; i++)
          SecurityInfoRow(
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
                      active ? KeroseneIcons.success : KeroseneIcons.cancel,
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

    return SecurityStatusCard(
      icon: KeroseneIcons.network,
      title: context.tr.ledgerIntegrity,
      subtitle: subtitle,
      statusOk: status == 'VALID',
      statusLabel: status,
      rows: [
        if (merkle['lastRootHash'] != null)
          SecurityInfoRow(
            label:
                _copy(pt: 'Raiz Merkle', en: 'Merkle root', es: 'Raíz Merkle'),
            value: merkle['lastRootHash'].toString(),
            isMono: true,
          ),
        if (merkle['computedAt'] != null)
          SecurityInfoRow(
            label: _copy(
                pt: 'Computado em', en: 'Computed at', es: 'Calculado en'),
            value: _formatDate(merkle['computedAt'].toString()),
          ),
        if (merkle['ledgerCount'] != null)
          SecurityInfoRow(
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

    return SecurityStatusCard(
      icon: KeroseneIcons.lock,
      title: context.tr.memoryProtection,
      subtitle: subtitle,
      statusOk: status == 'LOCKED',
      statusLabel: status,
      rows: [
        SecurityInfoRow(
          label: mechanismLabel,
          value: memory['mechanism'] ?? 'None',
        ),
        SecurityInfoRow(
          label: _copy(
            pt: 'Local do shard',
            en: 'Shard location',
            es: 'Ubicación del shard',
          ),
          value: memory['shardLocation'] ?? 'Global Cluster',
        ),
        SecurityInfoRow(
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
              KeroseneIcons.schedule,
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

  Widget _buildFooter() =>
      buildSovereigntyFooter(context: context, copy: _copy);

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
                KeroseneIcons.cloudOff,
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
}
