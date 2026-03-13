import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show apiClientProvider;

// ─── Model ───────────────────────────────────────────────────────────────────

class SovereigntyStatus {
  final TpmStatus tpm;
  final QuorumStatus quorum;
  final MerkleStatus merkle;
  final MemoryStatus memory;
  final int uptimeSeconds;

  const SovereigntyStatus({
    required this.tpm,
    required this.quorum,
    required this.merkle,
    required this.memory,
    required this.uptimeSeconds,
  });
}

class TpmStatus {
  final bool verified;
  final String chip;
  final int lastValidatedSecondsAgo;
  final int totalChecks;
  final String quoteHash;

  const TpmStatus({
    required this.verified,
    required this.chip,
    required this.lastValidatedSecondsAgo,
    required this.totalChecks,
    required this.quoteHash,
  });
}

class QuorumStatus {
  final bool active;
  final int activeNodes;
  final int totalNodes;
  final List<String> jurisdictions;
  final String algorithm;

  const QuorumStatus({
    required this.active,
    required this.activeNodes,
    required this.totalNodes,
    required this.jurisdictions,
    required this.algorithm,
  });
}

class MerkleStatus {
  final String status;
  final String? lastRootHash;
  final String? computedAt;
  final int? ledgerCount;

  const MerkleStatus({
    required this.status,
    this.lastRootHash,
    this.computedAt,
    this.ledgerCount,
  });
}

class MemoryStatus {
  final String status;
  final String mechanism;
  final String shardLocation;
  final bool diskPersistence;

  const MemoryStatus({
    required this.status,
    required this.mechanism,
    required this.shardLocation,
    required this.diskPersistence,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final sovereigntyProvider = FutureProvider.autoDispose<SovereigntyStatus>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/sovereignty/status');
  final data = response.data as Map<String, dynamic>;

  final tpmData = data['hardwareAttestation'] as Map<String, dynamic>;
  final quorumData = data['networkConsensus'] as Map<String, dynamic>;
  final merkleData = data['ledgerIntegrity'] as Map<String, dynamic>;
  final memoryData = data['memoryProtection'] as Map<String, dynamic>;

  return SovereigntyStatus(
    tpm: TpmStatus(
      verified: tpmData['status'] == 'VERIFIED',
      chip: tpmData['chip'] as String,
      lastValidatedSecondsAgo: tpmData['lastValidatedSecondsAgo'] as int,
      totalChecks: (tpmData['totalChecks'] as num).toInt(),
      quoteHash: tpmData['quoteHash'] as String,
    ),
    quorum: QuorumStatus(
      active: quorumData['status'] == 'ACTIVE',
      activeNodes: quorumData['activeNodes'] as int,
      totalNodes: quorumData['totalNodes'] as int,
      jurisdictions: (quorumData['jurisdictions'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      algorithm: quorumData['consensusAlgorithm'] as String,
    ),
    merkle: MerkleStatus(
      status: merkleData['status'] as String,
      lastRootHash: merkleData['lastRootHash'] as String?,
      computedAt: merkleData['computedAt'] as String?,
      ledgerCount: (merkleData['ledgerCount'] as num?)?.toInt(),
    ),
    memory: MemoryStatus(
      status: memoryData['status'] as String,
      mechanism: memoryData['mechanism'] as String,
      shardLocation: memoryData['shardLocation'] as String,
      diskPersistence: memoryData['diskPersistence'] as bool,
    ),
    uptimeSeconds: (data['serverUptimeSeconds'] as num).toInt(),
  );
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class SovereigntyStatusScreen extends ConsumerStatefulWidget {
  const SovereigntyStatusScreen({super.key});

  @override
  ConsumerState<SovereigntyStatusScreen> createState() =>
      _SovereigntyStatusScreenState();
}

class _SovereigntyStatusScreenState
    extends ConsumerState<SovereigntyStatusScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _scanController;
  Timer? _refreshTimer;

  static const _green = Color(0xFF00FF94);
  static const _red = Color(0xFFFF4444);
  static const _bg = Color(0xFF050508);
  static const _cardBg = Color(0xFF0D0D14);
  static const _border = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Auto-refresh every 12s to stay live
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.invalidate(sovereigntyProvider);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sovereigntyProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildGridBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: statusAsync.when(
                    data: (status) => _buildContent(status),
                    loading: () => _buildLoadingState(),
                    error: (e, _) => _buildErrorState(e.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GridScanPainter(_scanController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOVEREIGNTY STATUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Text(
                  'LIVE ATTESTATION REPORT',
                  style: TextStyle(
                    color: _green.withValues(
                      alpha: 0.4 + 0.4 * _pulseController.value,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.invalidate(sovereigntyProvider),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _green.withValues(
                    alpha: 0.05 + 0.05 * _pulseController.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _green.withValues(
                      alpha: 0.2 + 0.1 * _pulseController.value,
                    ),
                  ),
                ),
                child: Icon(Icons.refresh_rounded, color: _green, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SovereigntyStatus status) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        _buildOverallBadge(status),
        const SizedBox(height: 20),
        _buildTpmCard(status.tpm),
        const SizedBox(height: 12),
        _buildQuorumCard(status.quorum),
        const SizedBox(height: 12),
        _buildMerkleCard(status.merkle),
        const SizedBox(height: 12),
        _buildMemoryCard(status.memory),
        const SizedBox(height: 12),
        _buildUptimeCard(status.uptimeSeconds),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    );
  }

  Widget _buildOverallBadge(SovereigntyStatus status) {
    final allGood =
        status.tpm.verified &&
        status.quorum.active &&
        status.merkle.status == 'VALID' &&
        status.memory.status == 'LOCKED';

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allGood
                ? [
                    _green.withValues(alpha: 0.08),
                    _green.withValues(alpha: 0.03),
                  ]
                : [_red.withValues(alpha: 0.08), _red.withValues(alpha: 0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (allGood ? _green : _red).withValues(
              alpha: 0.3 + 0.1 * _pulseController.value,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (allGood ? _green : _red).withValues(alpha: 0.15),
                border: Border.all(
                  color: (allGood ? _green : _red).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                allGood ? Icons.verified_rounded : Icons.warning_rounded,
                color: allGood ? _green : _red,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allGood ? 'SISTEMA SOBERANO' : 'ALERTA DE INTEGRIDADE',
                    style: TextStyle(
                      color: allGood ? _green : _red,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allGood
                        ? 'Todas as camadas de segurança operacionais.'
                        : 'Verifique os indicadores abaixo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTpmCard(TpmStatus tpm) {
    return _SecurityCard(
      icon: Icons.memory_rounded,
      title: 'HARDWARE ATTESTATION',
      subtitle: tpm.chip,
      statusOk: tpm.verified,
      statusLabel: tpm.verified ? 'VERIFIED' : 'COMPROMISED',
      pulseController: _pulseController,
      rows: [
        _Row(
          label: 'Última validação',
          value: '${tpm.lastValidatedSecondsAgo}s atrás',
          isHighlight: tpm.lastValidatedSecondsAgo < 12,
        ),
        _Row(label: 'Verificações totais', value: '${tpm.totalChecks}'),
        _Row(label: 'PCR Quote Hash', value: tpm.quoteHash, isMono: true),
        _Row(label: 'Chip', value: tpm.chip),
      ],
    );
  }

  Widget _buildQuorumCard(QuorumStatus quorum) {
    return _SecurityCard(
      icon: Icons.hub_rounded,
      title: 'CONSENSO DE REDE',
      subtitle: '${quorum.activeNodes}/${quorum.totalNodes} nós ativos',
      statusOk: quorum.active,
      statusLabel: quorum.active ? 'ACTIVE' : 'OFFLINE',
      pulseController: _pulseController,
      rows: [
        _Row(
          label: 'Quórum',
          value: '${quorum.activeNodes}/${quorum.totalNodes} nós',
          isHighlight: true,
        ),
        _Row(label: 'Algoritmo', value: quorum.algorithm),
        for (int i = 0; i < quorum.jurisdictions.length; i++)
          _Row(label: 'Jurisdição ${i + 1}', value: quorum.jurisdictions[i]),
      ],
      extraWidget: _buildNodeDots(quorum),
    );
  }

  Widget _buildNodeDots(QuorumStatus quorum) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(quorum.totalNodes, (i) {
          final active = i < quorum.activeNodes;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < quorum.totalNodes - 1 ? 8 : 0,
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: active
                        ? _green.withValues(
                            alpha: 0.08 + 0.04 * _pulseController.value,
                          )
                        : _red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? _green.withValues(
                              alpha: 0.3 + 0.1 * _pulseController.value,
                            )
                          : _red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? Icons.circle : Icons.cancel,
                          color: active ? _green : _red,
                          size: 10,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quorum.jurisdictions.length > i
                              ? quorum.jurisdictions[i]
                                    .substring(0, 3)
                                    .toUpperCase()
                              : 'N${i + 1}',
                          style: TextStyle(
                            color: (active ? _green : _red).withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMerkleCard(MerkleStatus merkle) {
    final ok = merkle.status == 'VALID';
    return _SecurityCard(
      icon: Icons.account_tree_rounded,
      title: 'INTEGRIDADE DO LEDGER',
      subtitle: 'Árvore de Merkle (SHA-256)',
      statusOk: ok,
      statusLabel: merkle.status,
      pulseController: _pulseController,
      rows: [
        if (merkle.lastRootHash != null)
          _Row(label: 'Raiz Merkle', value: merkle.lastRootHash!, isMono: true),
        if (merkle.computedAt != null)
          _Row(label: 'Computado em', value: _formatDate(merkle.computedAt!)),
        if (merkle.ledgerCount != null)
          _Row(
            label: 'Carteiras auditadas',
            value: '${merkle.ledgerCount}',
            isHighlight: true,
          ),
      ],
    );
  }

  Widget _buildMemoryCard(MemoryStatus memory) {
    return _SecurityCard(
      icon: Icons.lock_rounded,
      title: 'PROTEÇÃO DE MEMÓRIA',
      subtitle: memory.shardLocation,
      statusOk: memory.status == 'LOCKED',
      statusLabel: memory.status,
      pulseController: _pulseController,
      rows: [
        _Row(label: 'Mecanismo', value: memory.mechanism),
        _Row(label: 'Shard location', value: memory.shardLocation),
        _Row(
          label: 'Persistência em disco',
          value: memory.diskPersistence ? 'SIM ⚠️' : 'NÃO ✓',
          isHighlight: !memory.diskPersistence,
        ),
      ],
    );
  }

  Widget _buildUptimeCard(int uptimeSeconds) {
    final h = uptimeSeconds ~/ 3600;
    final m = (uptimeSeconds % 3600) ~/ 60;
    final s = uptimeSeconds % 60;
    final uptimeStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Uptime do servidor',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            uptimeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Relatório gerado em tempo real · Atualização automática a cada 12s',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) => Transform.rotate(
              angle: _scanController.value * 2 * pi,
              child: child,
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _green.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(Icons.radar_rounded, color: _green, size: 22),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ANALISANDO SOBERANIA…',
            style: TextStyle(
              color: _green.withValues(alpha: 0.7),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: _red.withValues(alpha: 0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'ENDPOINT INACESSÍVEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível alcançar o servidor de atestação.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => ref.invalidate(sovereigntyProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _green.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TENTAR NOVAMENTE',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Reusable Security Card ─────────────────────────────────────────────────

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

class _SecurityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool statusOk;
  final String statusLabel;
  final AnimationController pulseController;
  final List<_Row> rows;
  final Widget? extraWidget;

  static const _green = Color(0xFF00FF94);
  static const _red = Color(0xFFFF4444);
  static const _cardBg = Color(0xFF0D0D14);
  static const _border = Color(0xFF1A1A2E);

  const _SecurityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusOk,
    required this.statusLabel,
    required this.pulseController,
    required this.rows,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusOk ? _green : _red;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusOk
                ? color.withValues(alpha: 0.15 + 0.05 * pulseController.value)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (statusOk ? _green : _red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusOk ? _green : _red, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (statusOk ? _green : _red).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (statusOk ? _green : _red).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusOk ? _green : _red,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            Row(
              children: [
                Text(
                  row.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: row.isHighlight ? _green : Colors.white,
                      fontSize: row.isMono ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: row.isMono ? 'monospace' : null,
                      letterSpacing: row.isMono ? 0.5 : 0,
                    ),
                  ),
                ),
              ],
            ),
            if (rows.last != row) const SizedBox(height: 8),
          ],
          if (extraWidget != null) extraWidget!,
        ],
      ),
    );
  }
}

// ─── Background Painter ──────────────────────────────────────────────────────

class _GridScanPainter extends CustomPainter {
  final double progress;
  _GridScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF94).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Scan line
    final scanY = progress * size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00FF94).withOpacity(0.06),
          const Color(0xFF00FF94).withOpacity(0.1),
          const Color(0xFF00FF94).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, size.width, 80), scanPaint);
  }

  @override
  bool shouldRepaint(_GridScanPainter old) => old.progress != progress;
}
