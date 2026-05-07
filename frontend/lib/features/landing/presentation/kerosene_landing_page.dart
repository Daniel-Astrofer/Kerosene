import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/landing/data/public_site_service.dart';
import 'package:teste/features/web_admin/theme/admin_colors.dart';

const _ink = Color(0xFF060607);
const _panel = Color(0xFF111113);
const _panelSoft = Color(0xFF171512);
const _gold = Color(0xFFD6A33A);
const _amber = Color(0xFFFFC25A);
const _bronze = Color(0xFF8A5A24);
const _line = Color(0xFF31281A);
const _muted = Color(0xFFA59B8A);

class KeroseneLandingPage extends ConsumerStatefulWidget {
  final bool focusDownload;

  const KeroseneLandingPage({super.key, this.focusDownload = false});

  @override
  ConsumerState<KeroseneLandingPage> createState() =>
      _KeroseneLandingPageState();
}

class _KeroseneLandingPageState extends ConsumerState<KeroseneLandingPage> {
  final _privacyKey = GlobalKey();
  final _bitcoinKey = GlobalKey();
  final _businessKey = GlobalKey();
  final _downloadKey = GlobalKey();
  final _statusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusDownload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollTo(_downloadKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobileAsync = ref.watch(publicMobileDownloadProvider);
    final readyAsync = ref.watch(publicReadinessProvider);
    final releaseAsync = ref.watch(publicReleaseProvider);
    final readiness = readyAsync.asData?.value;
    final release = releaseAsync.asData?.value;
    final statusLabel = _statusLabel(readiness);

    return Scaffold(
      backgroundColor: _ink,
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroSection(
                statusLabel: statusLabel,
                onPrivacy: () => _scrollTo(_privacyKey),
                onBitcoin: () => _scrollTo(_bitcoinKey),
                onBusiness: () => _scrollTo(_businessKey),
                onDownload: () => _scrollTo(_downloadKey),
                onStatus: () => _scrollTo(_statusKey),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionBand(
                key: _privacyKey,
                child: const _LedgerSection(),
              ),
            ),
            const SliverToBoxAdapter(child: _ArchitectureSection()),
            SliverToBoxAdapter(
              child: _SectionBand(
                key: _bitcoinKey,
                elevated: true,
                child: const _BitcoinSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionBand(
                key: _businessKey,
                child: const _EnterpriseSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: _DownloadSection(
                key: _downloadKey,
                mobile: mobileAsync.asData?.value,
                loading: mobileAsync.isLoading,
              ),
            ),
            SliverToBoxAdapter(
              child: _StatusSection(
                key: _statusKey,
                readiness: readiness,
                release: release,
                loading: readyAsync.isLoading || releaseAsync.isLoading,
              ),
            ),
            SliverToBoxAdapter(
              child: _FinalCtaSection(statusLabel: statusLabel),
            ),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }
}

class KerosenePublicStatusPage extends ConsumerWidget {
  const KerosenePublicStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readyAsync = ref.watch(publicReadinessProvider);
    final releaseAsync = ref.watch(publicReleaseProvider);

    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: const Text('Status publico Kerosene'),
        actions: [
          IconButton(
            tooltip: 'Baixar app',
            onPressed: () => Navigator.of(context).pushNamed('/download'),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Terminal empresas',
            onPressed: () => Navigator.of(context).pushNamed('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicReadinessProvider);
          ref.invalidate(publicReleaseProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: _StatusDetails(
                readiness: readyAsync.asData?.value,
                release: releaseAsync.asData?.value,
                loading: readyAsync.isLoading || releaseAsync.isLoading,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String statusLabel;
  final VoidCallback onPrivacy;
  final VoidCallback onBitcoin;
  final VoidCallback onBusiness;
  final VoidCallback onDownload;
  final VoidCallback onStatus;

  const _HeroSection({
    required this.statusLabel,
    required this.onPrivacy,
    required this.onBitcoin,
    required this.onBusiness,
    required this.onDownload,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    final reduceMotion = _reduceMotion(context);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OnionCircuitPainter(progress: reduceMotion ? 0 : 1),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: compact ? Alignment.topCenter : Alignment.centerRight,
                radius: 1.1,
                colors: const [
                  Color(0x663D2A0D),
                  Color(0x220F0D09),
                  _ink,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 820 : 780),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 54,
                compact ? 18 : 26,
                compact ? 18 : 54,
                compact ? 54 : 66,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopNav(
                    statusLabel: statusLabel,
                    onHome: () => Navigator.of(context).pushNamed('/'),
                    onPrivacy: onPrivacy,
                    onBitcoin: onBitcoin,
                    onBusiness: onBusiness,
                    onDownload: onDownload,
                    onStatus: onStatus,
                  ),
                  const SizedBox(height: 58),
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeroCopy(),
                        const SizedBox(height: 34),
                        const _DeviceProofStage(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          flex: 6,
                          child: _HeroCopy(),
                        ),
                        const SizedBox(width: 42),
                        Expanded(
                          flex: 5,
                          child: _DeviceProofStage(statusLabel: statusLabel),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;

    return _Reveal(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _Badge('Historico no mobile'),
                _Badge('Historico privado'),
                _Badge('Integridade verificavel'),
                _Badge('Hash sequencial'),
                _Badge('Onion-first'),
                _Badge('On-chain + Lightning'),
                _Badge('Release verificavel'),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Bitcoin privado.\nHistorico no seu celular.\nIntegridade provada por hash.',
              style: TextStyle(
                fontFamily: 'SpaceGroteskVariable',
                fontSize: compact ? 43 : 74,
                fontWeight: FontWeight.w800,
                height: 0.98,
                letterSpacing: 0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'A Kerosene permite usar Bitcoin on-chain e Lightning por uma infraestrutura Onion-first. O historico legivel fica no seu mobile; a infraestrutura mantem uma janela operacional curta e comprovacoes minimas de integridade.',
              style: TextStyle(
                fontFamily: 'HubotSans',
                fontSize: compact ? 17 : 20,
                height: 1.55,
                letterSpacing: 0,
                color: _muted,
              ),
            ),
            const SizedBox(height: 18),
            const _PromiseLine(
              'Seu historico fica no seu app. A infraestrutura mantem somente comprovacoes minimas para integridade e operacao.',
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PremiumButton(
                  icon: Icons.download_outlined,
                  label: 'Baixar app mobile',
                  filled: true,
                  onPressed: () => Navigator.of(context).pushNamed('/download'),
                ),
                _PremiumButton(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Acessar terminal empresas',
                  onPressed: () => Navigator.of(context).pushNamed('/admin'),
                ),
                _PremiumButton(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Ver status publico',
                  onPressed: () => Navigator.of(context).pushNamed('/status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final String statusLabel;
  final VoidCallback onHome;
  final VoidCallback onPrivacy;
  final VoidCallback onBitcoin;
  final VoidCallback onBusiness;
  final VoidCallback onDownload;
  final VoidCallback onStatus;

  const _TopNav({
    required this.statusLabel,
    required this.onHome,
    required this.onPrivacy,
    required this.onBitcoin,
    required this.onBusiness,
    required this.onDownload,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final links = [
          ('Inicio', onHome),
          ('Privacidade', onPrivacy),
          ('Bitcoin', onBitcoin),
          ('Empresas', onBusiness),
          ('Download', onDownload),
          ('Status', onStatus),
        ];

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? constraints.maxWidth : 210,
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo/kerosene-logo.png',
                    width: 34,
                    height: 34,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_fire_department,
                      color: _amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'KEROSENE',
                    style: TextStyle(
                      fontFamily: 'SpaceGroteskVariable',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width:
                  compact ? constraints.maxWidth : constraints.maxWidth - 226,
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...links.map(
                    (link) => TextButton(
                      onPressed: link.$2,
                      child: Text(link.$1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(label: statusLabel),
                  _SmallNavButton(
                    label: 'Baixar app',
                    icon: Icons.download_outlined,
                    onPressed: onDownload,
                  ),
                  _SmallNavButton(
                    label: 'Terminal empresas',
                    icon: Icons.admin_panel_settings_outlined,
                    onPressed: () => Navigator.of(context).pushNamed('/admin'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeviceProofStage extends StatelessWidget {
  final String statusLabel;

  const _DeviceProofStage({this.statusLabel = 'Operacional'});

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: const Duration(milliseconds: 160),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -18,
              top: 36,
              bottom: 34,
              left: 110,
              child: const _HashChainVisual(),
            ),
            const _PhoneMockup(),
            Positioned(
              right: 0,
              bottom: -8,
              child: _ProofConsole(statusLabel: statusLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 254,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFF3E3320)),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.14),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: AspectRatio(
          aspectRatio: 9 / 18.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/HOMESCREEN.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const ColoredBox(color: _panel),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    border: Border.all(color: _gold.withValues(alpha: 0.28)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LocalTransactionHistory',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          color: _amber,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Historico criptografado no dispositivo. Dados operacionais temporarios expiram automaticamente.',
                        style: TextStyle(
                          fontFamily: 'HubotSans',
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofConsole extends StatelessWidget {
  final String statusLabel;

  const _ProofConsole({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.94),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 16, color: _amber),
              const SizedBox(width: 8),
              Text(
                'integrity terminal',
                style: _mono(11, _muted),
              ),
              const Spacer(),
              _StatusDot(online: statusLabel == 'Operacional'),
            ],
          ),
          const SizedBox(height: 14),
          const _ConsoleRow('prevHash', 'a83f...21c0'),
          const _ConsoleRow('currentHash', 'd91b...8fa4'),
          const _ConsoleRow('merkleRoot', 'f04e...b712'),
          const _ConsoleRow('dados temporarios', 'expiram automaticamente'),
        ],
      ),
    );
  }
}

class _LedgerSection extends StatelessWidget {
  const _LedgerSection();

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow('Privacidade por definicao'),
          const _SectionTitle('Ledger nao e historico'),
          const SizedBox(height: 14),
          const _SectionLead(
            'Na Kerosene, ledger nao significa extrato armazenado. A Kerosene nao guarda seu historico de transacoes como extrato permanente: o ledger e uma cadeia de hashes e uma janela operacional curta. Ele permite verificar consistencia sem transformar sua vida financeira em banco de dados.',
          ),
          const SizedBox(height: 28),
          const _PromiseLine(
            'Hash sequencial para auditoria, nao historico legivel. Depois da janela operacional, o historico duravel pertence ao app mobile.',
          ),
          const SizedBox(height: 28),
          const _ValueGrid(
            items: [
              _ValueItem(
                icon: Icons.layers_clear_outlined,
                title: 'Sem dados financeiros duraveis',
                body:
                    'Descricao, nota, categoria e linha do tempo permanente pertencem ao seu app.',
              ),
              _ValueItem(
                icon: Icons.phone_iphone,
                title: 'Historico no mobile',
                body:
                    'Seu extrato fica no app, persistido localmente com criptografia.',
              ),
              _ValueItem(
                icon: Icons.link_outlined,
                title: 'Hash sequencial',
                body:
                    'Comprovantes de integridade demonstram ordem e consistencia sem expor detalhes financeiros.',
              ),
              _ValueItem(
                icon: Icons.account_tree_outlined,
                title: 'Merkle root',
                body:
                    'Raizes de auditoria resumem estado verificavel sem abrir uma timeline de usuario.',
              ),
              _ValueItem(
                icon: Icons.verified_user_outlined,
                title: 'Auditoria de integridade',
                body:
                    'A auditoria preserva integridade sem virar extrato financeiro permanente.',
              ),
              _ValueItem(
                icon: Icons.timer_outlined,
                title: 'Retencao 24h',
                body:
                    'A janela legivel e operacional e efemera. A persistencia duravel fica no dispositivo.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _MerkleCard(),
        ],
      ),
    );
  }
}

class _ArchitectureSection extends StatelessWidget {
  const _ArchitectureSection();

  @override
  Widget build(BuildContext context) {
    return _SectionBand(
      elevated: true,
      child: _Reveal(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final copy = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionEyebrow('Arquitetura local-first'),
                _SectionTitle('Privacidade por arquitetura'),
                SizedBox(height: 14),
                _SectionLead(
                  'O que e experiencia do usuario fica no dispositivo. O que e integridade vira hash.',
                ),
                SizedBox(height: 24),
                _ProofList(
                  items: [
                    ('App Mobile', 'historico local criptografado'),
                    ('Tor local', 'acesso Onion-first'),
                    ('Acesso privado', 'servico Onion-first'),
                    ('Kerosene', 'comprovacoes e estados minimos'),
                    ('Bitcoin Core/LND', 'on-chain e Lightning monitorados'),
                  ],
                ),
              ],
            );
            const diagram = _ArchitectureDiagram();
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 28),
                  diagram,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 44),
                Expanded(child: diagram),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArchitectureDiagram extends StatelessWidget {
  const _ArchitectureDiagram();

  @override
  Widget build(BuildContext context) {
    final nodes = const [
      ('App Mobile', 'dados e historico'),
      ('Tor local', 'circuito privado'),
      ('Hidden Service', 'Onion-first'),
      ('Kerosene', 'estado temporario'),
      ('Hash-chain', 'integridade'),
      ('Bitcoin Core/LND', 'settlement'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < nodes.length; i++) ...[
            _DiagramNode(title: nodes[i].$1, subtitle: nodes[i].$2),
            if (i != nodes.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.keyboard_arrow_down, color: _amber),
              ),
          ],
        ],
      ),
    );
  }
}

class _BitcoinSection extends StatelessWidget {
  const _BitcoinSection();

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow('Bitcoin sem extrato centralizado'),
          const _SectionTitle(
              'Receba Bitcoin sem criar um extrato centralizado'),
          const SizedBox(height: 14),
          const _SectionLead(
            'On-chain e Lightning com privacidade por arquitetura. Confirmacoes sao monitoradas, payment links operam por janela tecnica e a integridade e provada por hash.',
          ),
          const SizedBox(height: 28),
          const _ValueGrid(
            items: [
              _ValueItem(
                icon: Icons.currency_bitcoin,
                title: 'On-chain',
                body:
                    'Enderecos e confirmacoes existem para liquidacao; exposicao em painel deve ser truncada ou fingerprint.',
              ),
              _ValueItem(
                icon: Icons.flash_on_outlined,
                title: 'Lightning',
                body:
                    'Invoices e pagamentos com estado tecnico minimo, sem transformar cada evento em timeline pessoal.',
              ),
              _ValueItem(
                icon: Icons.qr_code_2_outlined,
                title: 'Payment links',
                body:
                    'Links operacionais com status de liquidacao, nao rascunhos de perfil financeiro permanente.',
              ),
              _ValueItem(
                icon: Icons.lock_outline,
                title: 'Historico local',
                body:
                    'Dados sensiveis ficam com o usuario: preferencias, rotulos, notas e descricoes humanas pertencem ao app mobile.',
              ),
              _ValueItem(
                icon: Icons.check_circle_outline,
                title: 'Confirmacoes',
                body:
                    'A Kerosene acompanha o status necessario para concluir e sincronizar a operacao.',
              ),
              _ValueItem(
                icon: Icons.fingerprint,
                title: 'Integridade por hash',
                body:
                    'A consistencia e verificavel sem armazenar sua vida financeira.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnterpriseSection extends StatelessWidget {
  const _EnterpriseSection();

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionEyebrow('Terminal operacional'),
              const _SectionTitle(
                  'Empresas operam infraestrutura, nao usuarios'),
              const SizedBox(height: 14),
              const _SectionLead(
                'O terminal empresarial mostra saude dos servicos, blockchain monitor, Lightning, Vault/Raft, release attestation, logs saneados e raizes de integridade. Ele nao mostra historico pessoal de usuarios.',
              ),
              const SizedBox(height: 24),
              _PremiumButton(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Entrar no terminal empresas',
                filled: true,
                onPressed: () => Navigator.of(context).pushNamed('/admin'),
              ),
            ],
          );
          const terminal = _EnterpriseTerminal();
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 28),
                terminal,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 44),
              const Expanded(child: terminal),
            ],
          );
        },
      ),
    );
  }
}

class _EnterpriseTerminal extends StatelessWidget {
  const _EnterpriseTerminal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: _amber, size: 18),
              const SizedBox(width: 8),
              Text('admin.ops', style: _mono(12, Colors.white)),
              const Spacer(),
              const _StatusDot(online: true),
            ],
          ),
          const SizedBox(height: 18),
          const _ConsoleRow('bitcoin.core', 'altura, fila, pruned'),
          const _ConsoleRow('lnd', 'peers, canais, sync'),
          const _ConsoleRow('cofre', 'confirmacoes, saude'),
          const _ConsoleRow('release', 'manifest + digest'),
          const _ConsoleRow('ledger.root', 'merkleRoot only'),
          const Divider(color: _line, height: 26),
          Text(
            'Sem saldo individual. Sem nome de usuario. Sem endereco completo. Sem dados financeiros permanentes.',
            style: _body(13, _muted),
          ),
        ],
      ),
    );
  }
}

class _DownloadSection extends StatelessWidget {
  final Map<String, dynamic>? mobile;
  final bool loading;

  const _DownloadSection({
    super.key,
    required this.mobile,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final artifacts = (mobile?['artifacts'] as Map?) ?? const {};
    final android = (artifacts['android'] as Map?) ?? const {};
    final ios = (artifacts['ios'] as Map?) ?? const {};
    final changelog = (mobile?['changelog'] as List?)?.cast<dynamic>() ?? [];

    return _SectionBand(
      elevated: true,
      child: _Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionEyebrow('Download verificavel'),
            const _SectionTitle(
                'Baixe, verifique o hash e mantenha seu historico no seu dispositivo.'),
            const SizedBox(height: 14),
            const _SectionLead(
              'O app mobile e a fonte duravel do historico legivel. Confira SHA-256 e assinatura antes de instalar.',
            ),
            const SizedBox(height: 28),
            if (loading)
              const _SkeletonBlock(height: 180)
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ArtifactCard(
                    platform: 'Android',
                    icon: Icons.android,
                    version: '${mobile?['version'] ?? '1.0.0'}',
                    buildNumber: '${mobile?['buildNumber'] ?? '1'}',
                    url: '${android['url'] ?? ''}',
                    sha256: '${android['sha256'] ?? ''}',
                    signature: '${android['signingCertificateSha256'] ?? ''}',
                  ),
                  if ('${ios['url'] ?? ''}'.isNotEmpty ||
                      '${ios['sha256'] ?? ''}'.isNotEmpty)
                    _ArtifactCard(
                      platform: 'iOS',
                      icon: Icons.phone_iphone,
                      version: '${mobile?['version'] ?? '1.0.0'}',
                      buildNumber: '${mobile?['buildNumber'] ?? '1'}',
                      url: '${ios['url'] ?? ''}',
                      sha256: '${ios['sha256'] ?? ''}',
                      signature: '${ios['signingCertificateSha256'] ?? ''}',
                    ),
                ],
              ),
            const SizedBox(height: 22),
            _IntegrityNotice(
              text:
                  '${mobile?['integrityInstructions'] ?? 'Confira o SHA-256 antes de instalar artefatos fora da loja.'}',
            ),
            if (changelog.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Changelog', style: _title(20)),
              const SizedBox(height: 10),
              ...changelog.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text('- $item', style: _body(14, _muted)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final Map<String, dynamic>? readiness;
  final Map<String, dynamic>? release;
  final bool loading;

  const _StatusSection({
    super.key,
    required this.readiness,
    required this.release,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionBand(
      child: _Reveal(
        child: _StatusDetails(
          readiness: readiness,
          release: release,
          loading: loading,
        ),
      ),
    );
  }
}

class _StatusDetails extends StatelessWidget {
  final Map<String, dynamic>? readiness;
  final Map<String, dynamic>? release;
  final bool loading;

  const _StatusDetails({
    required this.readiness,
    required this.release,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final checks = (readiness?['checks'] as Map?) ?? const {};
    final status = _statusLabel(readiness);
    final authorized = release?['authorized'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionEyebrow('Status publico'),
        const _SectionTitle('Estado publico sem segredos'),
        const SizedBox(height: 14),
        const _SectionLead(
          'Readiness e release sao publicados sem stack trace, configuracao sensivel ou tokens. Estado degradado aparece como sinal operacional, nao como dump interno.',
        ),
        const SizedBox(height: 28),
        if (loading)
          const _SkeletonBlock(height: 220)
        else
          _ValueGrid(
            items: [
              _ValueItem(
                icon: Icons.monitor_heart_outlined,
                title: 'Status geral',
                body: status,
              ),
              _ValueItem(
                icon: Icons.verified_user_outlined,
                title: 'Release',
                body:
                    '${release?['version'] ?? 'unknown'} - ${authorized ? 'authorized' : release?['reason'] ?? 'pending'}',
              ),
              _ValueItem(
                icon: Icons.commit_outlined,
                title: 'Build',
                body:
                    'commit ${_short(release?['gitCommit'])} / image ${_short(release?['imageDigest'])}',
              ),
              _ValueItem(
                icon: Icons.fingerprint,
                title: 'Integridade',
                body:
                    '${release?['manifestDigest'] ?? 'manifest absent'} / code ${_short(release?['codeHash'])}',
              ),
              _ValueItem(
                icon: Icons.dns_outlined,
                title: 'Servico',
                body: '${readiness?['service'] ?? 'kerosene'}',
              ),
              _ValueItem(
                icon: Icons.public,
                title: 'Regiao',
                body: '${readiness?['region'] ?? 'DEV'}',
              ),
            ],
          ),
        if (checks.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: checks.entries.map((entry) {
              final value = entry.value is Map
                  ? Map<String, dynamic>.from(entry.value as Map)
                  : <String, dynamic>{};
              return _CheckPill(
                label: entry.key.toString(),
                status: '${value['status'] ?? 'UNKNOWN'}',
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  final String statusLabel;

  const _FinalCtaSection({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_panelSoft, _ink],
        ),
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              final copy = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Use Bitcoin sem entregar seu historico.'),
                  SizedBox(height: 14),
                  _SectionLead(
                    'Kerosene foi feita para operar Bitcoin com acesso Onion, historico local e integridade verificavel por hash.',
                  ),
                ],
              );
              final actions = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PremiumButton(
                    icon: Icons.download_outlined,
                    label: 'Baixar app',
                    filled: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/download'),
                  ),
                  _PremiumButton(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Terminal empresas',
                    onPressed: () => Navigator.of(context).pushNamed('/admin'),
                  ),
                  _PremiumButton(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Ver status: $statusLabel',
                    onPressed: () => Navigator.of(context).pushNamed('/status'),
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: 26),
                    actions,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 38),
                  Flexible(child: actions),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  final String platform;
  final IconData icon;
  final String version;
  final String buildNumber;
  final String url;
  final String sha256;
  final String signature;

  const _ArtifactCard({
    required this.platform,
    required this.icon,
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.sha256,
    required this.signature,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _glassDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _amber),
                const SizedBox(width: 10),
                Text(platform, style: _title(20)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Versao $version (build $buildNumber)',
                style: _body(14, Colors.white)),
            const SizedBox(height: 12),
            SelectableText(
              url.isEmpty ? 'Link aguardando publicacao' : url,
              style: _mono(11, _muted),
            ),
            const SizedBox(height: 12),
            SelectableText(
              sha256.isEmpty ? 'SHA-256 nao publicado' : 'SHA-256 $sha256',
              style: _mono(11, _amber),
            ),
            const SizedBox(height: 8),
            SelectableText(
              signature.isEmpty
                  ? 'Assinatura nao publicada'
                  : 'Assinatura $signature',
              style: _mono(11, _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueGrid extends StatelessWidget {
  final List<_ValueItem> items;

  const _ValueGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720
            ? 1
            : constraints.maxWidth < 1040
                ? 2
                : 3;
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              items.map((item) => SizedBox(width: width, child: item)).toList(),
        );
      },
    );
  }
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ValueItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _amber, size: 26),
          const SizedBox(height: 18),
          Text(title, style: _title(18)),
          const SizedBox(height: 10),
          Text(body, style: _body(14, _muted)),
        ],
      ),
    );
  }
}

class _HashChainVisual extends StatefulWidget {
  const _HashChainVisual();

  @override
  State<_HashChainVisual> createState() => _HashChainVisualState();
}

class _HashChainVisualState extends State<_HashChainVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _HashChainPainter(progress: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MerkleMini extends StatefulWidget {
  const _MerkleMini();

  @override
  State<_MerkleMini> createState() => _MerkleMiniState();
}

class _MerkleMiniState extends State<_MerkleMini>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MerklePainter(progress: _controller.value),
          child: const SizedBox(height: 140),
        );
      },
    );
  }
}

class _HashChainPainter extends CustomPainter {
  final double progress;

  _HashChainPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _gold.withValues(alpha: 0.22)
      ..strokeWidth = 1.4;
    final glow = Paint()
      ..color = _amber.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final fill = Paint()..color = _panel;
    final active = Paint()..color = _amber;
    final border = Paint()
      ..color = _gold.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final nodes = List.generate(5, (i) {
      final x = size.width * (0.18 + i * 0.16);
      final y = size.height * (0.20 + (i.isEven ? 0.08 : 0.34));
      return Offset(x, y);
    });
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], line);
    }
    final lit = (progress * nodes.length).floor() % nodes.length;
    for (var i = 0; i < nodes.length; i++) {
      final r = i == lit ? 17.0 : 13.0;
      canvas.drawCircle(nodes[i], r + 6, glow);
      canvas.drawCircle(nodes[i], r, fill);
      canvas.drawCircle(nodes[i], r, border);
      canvas.drawCircle(nodes[i], 3.5, i == lit ? active : border);
    }
  }

  @override
  bool shouldRepaint(covariant _HashChainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MerklePainter extends CustomPainter {
  final double progress;

  _MerklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _gold.withValues(alpha: 0.25 + progress * 0.2)
      ..strokeWidth = 1.2;
    final node = Paint()..color = _panel;
    final border = Paint()
      ..color = _amber.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final points = [
      Offset(size.width * 0.18, size.height * 0.78),
      Offset(size.width * 0.38, size.height * 0.78),
      Offset(size.width * 0.62, size.height * 0.78),
      Offset(size.width * 0.82, size.height * 0.78),
      Offset(size.width * 0.28, size.height * 0.45),
      Offset(size.width * 0.72, size.height * 0.45),
      Offset(size.width * 0.50, size.height * 0.16),
    ];
    final edges = const [
      [0, 4],
      [1, 4],
      [2, 5],
      [3, 5],
      [4, 6],
      [5, 6],
    ];
    for (final edge in edges) {
      canvas.drawLine(points[edge[0]], points[edge[1]], line);
    }
    for (var i = 0; i < points.length; i++) {
      final radius = i == 6 ? 15.0 : 11.0;
      canvas.drawCircle(points[i], radius, node);
      canvas.drawCircle(points[i], radius, border);
    }
  }

  @override
  bool shouldRepaint(covariant _MerklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _OnionCircuitPainter extends CustomPainter {
  final double progress;

  const _OnionCircuitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.78, size.height * 0.2);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(center, 80.0 + i * 54, paint);
    }
    final pathPaint = Paint()
      ..color = _bronze.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.18 + i * 0.11);
      final path = Path()
        ..moveTo(size.width * 0.05, y)
        ..cubicTo(
          size.width * 0.28,
          y - 30,
          size.width * 0.46,
          y + 42,
          size.width * 0.94,
          y - 8,
        );
      canvas.drawPath(path, pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnionCircuitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MerkleCard extends StatelessWidget {
  const _MerkleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConsoleRow('eventDigest', 'sha256:12ac...09ef'),
          _ConsoleRow('commitment', 'c7e1...a301'),
          _ConsoleRow('root', 'merkleRoot'),
          SizedBox(height: 14),
          _MerkleMini(),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 32,
            runSpacing: 18,
            alignment: WrapAlignment.spaceBetween,
            children: const [
              _FooterColumn(
                title: 'Kerosene',
                rows: [
                  'Bitcoin privado',
                  'Historico no mobile',
                  'Onion-first',
                ],
              ),
              _FooterColumn(
                title: 'Integridade',
                rows: [
                  'Historico privado',
                  'Historico privado',
                  'Hash sequencial',
                  'Merkle root',
                ],
              ),
              _FooterColumn(
                title: 'Operacao',
                rows: [
                  'Terminal empresas',
                  'Status publico',
                  'Release verificavel',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> rows;

  const _FooterColumn({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _title(16)),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(row, style: _body(13, _muted)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBand extends StatelessWidget {
  final Widget child;
  final bool elevated;

  const _SectionBand({
    super.key,
    required this.child,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: elevated ? const Color(0xFF0B0A08) : _ink,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        border: Border.all(color: _gold.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: _mono(11, _amber)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final online = label == 'Operacional';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: online
            ? AdminColors.positive.withValues(alpha: 0.10)
            : AdminColors.warning.withValues(alpha: 0.10),
        border: Border.all(
          color: online
              ? AdminColors.positive.withValues(alpha: 0.35)
              : AdminColors.warning.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(online: online),
          const SizedBox(width: 7),
          Text(label, style: _mono(11, online ? AdminColors.positive : _amber)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool online;

  const _StatusDot({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: online ? AdminColors.positive : AdminColors.warning,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (online ? AdminColors.positive : AdminColors.warning)
                .withValues(alpha: 0.36),
            blurRadius: _reduceMotion(context) ? 0 : 10,
          ),
        ],
      ),
    );
  }
}

class _SmallNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SmallNavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: _gold.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _PremiumButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? Color.lerp(_gold, _amber, _hover ? 0.4 : 0.0)!
        : Colors.transparent;
    final fg = widget.filled ? Colors.black : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _hover && !_reduceMotion(context) ? 1.025 : 1,
        child: TextButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 18),
          label: Text(widget.label, overflow: TextOverflow.ellipsis),
          style: TextButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            side: BorderSide(
              color: widget.filled ? _gold : _gold.withValues(alpha: 0.42),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: 'HubotSans',
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromiseLine extends StatelessWidget {
  final String text;

  const _PromiseLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.07),
        border: Border(
            left: BorderSide(color: _amber.withValues(alpha: 0.72), width: 3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: _body(14, Colors.white)),
    );
  }
}

class _ProofList extends StatelessWidget {
  final List<(String, String)> items;

  const _ProofList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: _amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: _body(14, _muted),
                        children: [
                          TextSpan(
                            text: '${item.$1}: ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: item.$2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DiagramNode extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DiagramNode({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.hexagon_outlined, color: _amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _title(15)),
                const SizedBox(height: 3),
                Text(subtitle, style: _mono(11, _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConsoleRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: _mono(10, _muted))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: _mono(10, Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  final String label;
  final String status;

  const _CheckPill({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final ok = status.toUpperCase() == 'UP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: ok ? AdminColors.positive : _gold),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $status',
          style: _mono(11, ok ? AdminColors.positive : _amber)),
    );
  }
}

class _IntegrityNotice extends StatelessWidget {
  final String text;

  const _IntegrityNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panelSoft,
        border: Border.all(color: _gold.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_outlined, color: _amber, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _body(14, _muted))),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;

  const _SkeletonBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: _reduceMotion(context) ? 0.25 : 0.78),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(_panel, _panelSoft, value),
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _Reveal extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  final String text;

  const _SectionEyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: _mono(12, _amber).copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGroteskVariable',
        fontSize: compact ? 34 : 48,
        fontWeight: FontWeight.w800,
        height: 1.06,
        letterSpacing: 0,
        color: Colors.white,
      ),
    );
  }
}

class _SectionLead extends StatelessWidget {
  final String text;

  const _SectionLead(this.text);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Text(text, style: _body(17, _muted)),
    );
  }
}

BoxDecoration _glassDecoration() {
  return BoxDecoration(
    color: _panel.withValues(alpha: 0.88),
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 22,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

TextStyle _title(double size) {
  return TextStyle(
    fontFamily: 'SpaceGroteskVariable',
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.16,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle _body(double size, Color color) {
  return TextStyle(
    fontFamily: 'HubotSans',
    fontSize: size,
    height: 1.5,
    letterSpacing: 0,
    color: color,
  );
}

TextStyle _mono(double size, Color color) {
  return TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: size,
    height: 1.35,
    letterSpacing: 0,
    color: color,
  );
}

String _statusLabel(Map<String, dynamic>? status) {
  final value = status?['status']?.toString().toUpperCase();
  if (value == 'UP') return 'Operacional';
  if (value == 'DEGRADED') return 'Degradado';
  if (value == 'DOWN') return 'Indisponivel';
  return 'Verificando';
}

String _short(Object? value) {
  final text = value?.toString() ?? 'unknown';
  if (text.length <= 14) return text;
  if (text.startsWith('sha256:') && text.length > 21) {
    return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
  }
  return '${text.substring(0, 10)}...';
}

bool _reduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return media?.disableAnimations == true ||
      media?.accessibleNavigation == true;
}
