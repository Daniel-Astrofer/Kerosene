// ignore_for_file: unused_element, unused_field, unused_element_parameter

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/landing/data/public_site_service.dart';
import 'package:teste/l10n/l10n_extension.dart';

const _ink = Color(0xFF000000);
const _surface = Color(0xFF131313);
const _panel = Color(0x99101010);
const _panelSoft = Color(0xFF201F1F);
const _line = Color(0xFF353534);
const _muted = Color(0xFFD5C4AB);
const _faint = Color(0xFF9E8F78);
const _gold = Color(0xFFFFB800);
const _goldSoft = Color(0xFFFFDCA1);
const _green = Color(0xFF00E274);
const _contentMaxWidth = 1280.0;

class KeroseneLandingPage extends ConsumerStatefulWidget {
  final bool focusDownload;

  const KeroseneLandingPage({super.key, this.focusDownload = false});

  @override
  ConsumerState<KeroseneLandingPage> createState() =>
      _KeroseneLandingPageState();
}

class _KeroseneLandingPageState extends ConsumerState<KeroseneLandingPage> {
  final _productKey = GlobalKey();
  final _securityKey = GlobalKey();
  final _businessKey = GlobalKey();
  final _infrastructureKey = GlobalKey();
  final _faqKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusDownload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_faqKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyAsync = ref.watch(publicReadinessProvider);
    final statusLabel = _statusLabel(context, readyAsync.asData?.value);

    return Scaffold(
      backgroundColor: _ink,
      body: SelectionArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _LandingBackdropPainter(),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroSection(
                    statusLabel: statusLabel,
                    onCreateAccount: _openCreateAccount,
                    onBusinessPanel: _openBusinessPanel,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionShell(
                    key: _productKey,
                    topPadding: 16,
                    child: _ProductSection(onCreateAccount: _openCreateAccount),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionShell(
                    key: _businessKey,
                    topPadding: 14,
                    child: const _AudienceSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionShell(
                    key: _securityKey,
                    topPadding: 26,
                    child: const _ArchitectureSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionShell(
                    key: _faqKey,
                    topPadding: 22,
                    bottomPadding: 30,
                    child: _FinalCta(
                      onCreateAccount: _openCreateAccount,
                      onBusinessPanel: _openBusinessPanel,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _Footer(statusLabel: statusLabel)),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopNav(
                onProduct: () => _scrollTo(_productKey),
                onSecurity: () => _scrollTo(_securityKey),
                onBusiness: () => _scrollTo(_businessKey),
                onInfrastructure: () => _scrollTo(_securityKey),
                onFaq: () => _scrollTo(_faqKey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateAccount() {
    Navigator.of(context).pushNamed('/download');
  }

  void _openBusinessPanel() {
    Navigator.of(context).pushNamed('/admin');
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
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
    final readiness = readyAsync.asData?.value;
    final release = releaseAsync.asData?.value;

    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: Text(context.tr.landingStatusPageTitle),
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
                readiness: readiness,
                release: release,
                loading: readyAsync.isLoading || releaseAsync.isLoading,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final VoidCallback onProduct;
  final VoidCallback onSecurity;
  final VoidCallback onBusiness;
  final VoidCallback onInfrastructure;
  final VoidCallback onFaq;

  const _TopNav({
    required this.onProduct,
    required this.onSecurity,
    required this.onBusiness,
    required this.onInfrastructure,
    required this.onFaq,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.84),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 940;
                final navItems = [
                  (context.tr.landingNavProduct, onProduct),
                  (context.tr.landingNavSecurity, onSecurity),
                  (context.tr.landingNavBusiness, onBusiness),
                  (context.tr.landingNavInfrastructure, onInfrastructure),
                  (context.tr.landingNavFaq, onFaq),
                ];

                return Wrap(
                  spacing: compact ? 14 : 40,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _BrandMark(label: context.tr.appTitle),
                    if (!compact)
                      Wrap(
                        spacing: 38,
                        children: navItems
                            .map(
                              (item) => _NavTextButton(
                                label: item.$1,
                                onPressed: item.$2,
                              ),
                            )
                            .toList(),
                      )
                    else
                      SizedBox(
                        width: constraints.maxWidth,
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: navItems
                              .map(
                                (item) => _NavTextButton(
                                  label: item.$1,
                                  onPressed: item.$2,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _LandingButton(
                          label: context.tr.landingLoginAction,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/admin'),
                        ),
                        _LandingButton(
                          label: context.tr.landingCreateAccountAction,
                          filled: true,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/download'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String statusLabel;
  final VoidCallback onCreateAccount;
  final VoidCallback onBusinessPanel;

  const _HeroSection({
    required this.statusLabel,
    required this.onCreateAccount,
    required this.onBusinessPanel,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      topPadding: 128,
      bottomPadding: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EyebrowPill(
                icon: LucideIcons.shieldCheck,
                label: 'BITCOIN INFRAESTRUTURA PRIVADA',
              ),
              const SizedBox(height: 26),
              RichText(
                text: TextSpan(
                  style: _displayStyle(context, compact ? 48 : 72),
                  children: const [
                    TextSpan(text: 'Seu banco Bitcoin.\n'),
                    TextSpan(
                      text: 'Privado. Anônimo. Global.',
                      style: TextStyle(
                        color: _gold,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Text(
                  'A Kerosene torna o Bitcoin mais seguro e útil para indivíduos e empresas, com privacidade absoluta, transparência operacional e controle real dos seus ativos sob a rede Tor.',
                  style: _bodyStyle(compact ? 18 : 19),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _LandingButton(
                    label: context.tr.landingCreateAccountAction,
                    filled: true,
                    large: true,
                    onPressed: onCreateAccount,
                  ),
                  _LandingButton(
                    label: context.tr.landingBusinessPanelAction,
                    large: true,
                    onPressed: onBusinessPanel,
                  ),
                ],
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AvatarStack(),
                  const SizedBox(width: 16),
                  Text.rich(
                    TextSpan(
                      text: 'Acesse via Tor: ',
                      children: const [
                        TextSpan(
                          text: 'kerosene66...onion',
                          style: TextStyle(color: _gold),
                        ),
                      ],
                    ),
                    style: _monoStyle(_muted),
                  ),
                ],
              ),
            ],
          );

          final stage = _HeroVaultStage(statusLabel: statusLabel);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 52),
                Center(child: stage),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 13, child: copy),
              const SizedBox(width: 80),
              Expanded(
                flex: 9,
                child: Align(alignment: Alignment.topCenter, child: stage),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final VoidCallback onCreateAccount;

  const _ProductSection({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CenteredTitle(text: 'O que a Kerosene faz'),
        const SizedBox(height: 10),
        Container(width: 48, height: 4, color: _gold),
        const SizedBox(height: 40),
        _CardGrid(items: _productCards(context), minCardWidth: 340),
      ],
    );
  }
}

class _AudienceSection extends StatelessWidget {
  const _AudienceSection();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final people = _AudienceColumn(
              title: 'Para Indivíduos',
              subtitle:
                  'Soberania financeira simplificada. Sem perguntas, sem fronteiras.',
              items: const [
                _AudienceItem('Privacidade Diária',
                    'Transações indetectáveis para sua segurança pessoal.'),
                _AudienceItem('Carteira Segura',
                    'Custódia com padrão institucional no seu celular.'),
                _AudienceItem('No-KYC por Design',
                    'Nós não sabemos quem você é, e é assim que deve ser.'),
              ],
              visual: const _PhoneImagePanel(),
            );
            final business = _AudienceColumn(
              title: 'Para Empresas',
              subtitle:
                  'Infraestrutura robusta para operações corporativas globais.',
              items: const [
                _AudienceItem('Modo Administrativo via Tor',
                    'Painel web completo para equipes, acessível apenas por rotas seguras.'),
                _AudienceItem('Gestão Multisig',
                    'Controle hierárquico de gastos e aprovações de transações.'),
                _AudienceItem('Supervisão de Liquidez',
                    'Monitoramento em tempo real de fluxos e reservas.'),
              ],
              visual: const _ApiAccessCard(),
              icon: LucideIcons.badgeCheck,
            );

            if (compact) {
              return Column(
                children: [
                  people,
                  const SizedBox(height: 44),
                  business,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: people),
                const SizedBox(width: 64),
                Expanded(child: business),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArchitectureSection extends StatelessWidget {
  const _ArchitectureSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arquitetura de Segurança',
          style: _sectionTitleStyle(context, 38),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Tecnologia de ponta para cenários sensíveis.',
            style: _bodyStyle(17),
          ),
        ),
        const SizedBox(height: 34),
        _ArchitectureRail(items: _architectureCards(context)),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.landingSecurityTitle,
          style: _sectionTitleStyle(context, 38),
        ),
        const SizedBox(height: 22),
        _CardGrid(items: _securityCards(context), minCardWidth: 310),
      ],
    );
  }
}

class _FinalCta extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onBusinessPanel;

  const _FinalCta({
    required this.onCreateAccount,
    required this.onBusinessPanel,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(64, 60, 64, 58),
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: _displayStyle(context, compact ? 38 : 58),
                  children: const [
                    TextSpan(text: 'Mais controle. Menos exposição.\n'),
                    TextSpan(
                      text: 'Mais previsibilidade.',
                      style: TextStyle(color: _gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'A Kerosene é a infraestrutura financeira definitiva para quem exige privacidade absoluta sobre seu capital Bitcoin.',
                  textAlign: TextAlign.center,
                  style: _bodyStyle(18),
                ),
              ),
              const SizedBox(height: 34),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _LandingButton(
                    label: 'Começar Agora',
                    filled: true,
                    onPressed: onCreateAccount,
                  ),
                  _LandingButton(
                    label: 'Falar com Consultor',
                    onPressed: onBusinessPanel,
                  ),
                ],
              ),
            ],
          );
          return copy;
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String statusLabel;

  const _Footer({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(48, 26, 48, 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Wrap(
            spacing: 38,
            runSpacing: 22,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 30,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _BrandMark(label: context.tr.appTitle, compact: true),
                  Text(context.tr.landingFooterRights,
                      style: _smallStyle(_faint)),
                ],
              ),
              Wrap(
                spacing: 56,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.tr.privacyPolicy, style: _smallStyle(_muted)),
                  Text(context.tr.landingNavSecurity,
                      style: _smallStyle(_muted)),
                  Text(context.tr.landingNavBusiness,
                      style: _smallStyle(_muted)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.tr.landingFooterStatus,
                          style: _smallStyle(_muted)),
                      const SizedBox(width: 14),
                      _StatusDot(
                          online:
                              statusLabel == context.tr.landingStatusOnline),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
    final authorized = release?['authorized'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr.landingStatusPageTitle,
            style: _sectionTitleStyle(context, 42)),
        const SizedBox(height: 14),
        Text(context.tr.landingStatusPageSubtitle, style: _bodyStyle(17)),
        const SizedBox(height: 28),
        if (loading)
          const _SkeletonBlock(height: 220)
        else
          _CardGrid(
            minCardWidth: 300,
            items: [
              _LandingCardData(
                icon: LucideIcons.activity,
                title: context.tr.landingFooterStatus,
                body: _statusLabel(context, readiness),
              ),
              _LandingCardData(
                icon: LucideIcons.badgeCheck,
                title: context.tr.landingStatusRelease,
                body:
                    '${release?['version'] ?? context.tr.landingStatusUnknown} - ${authorized ? context.tr.landingStatusAuthorized : release?['reason'] ?? context.tr.pending}',
              ),
              _LandingCardData(
                icon: LucideIcons.server,
                title: context.tr.landingStatusService,
                body: '${readiness?['service'] ?? context.tr.appTitle}',
              ),
              _LandingCardData(
                icon: LucideIcons.globe2,
                title: context.tr.landingStatusRegion,
                body:
                    '${readiness?['region'] ?? context.tr.landingStatusUnknown}',
              ),
              _LandingCardData(
                icon: LucideIcons.fingerprint,
                title: context.tr.landingStatusBuild,
                body: _short(
                    release?['gitCommit'], context.tr.landingStatusUnknown),
              ),
              _LandingCardData(
                icon: LucideIcons.fileCheck2,
                title: context.tr.landingStatusManifest,
                body: _short(release?['manifestDigest'],
                    context.tr.landingStatusUnknown),
              ),
            ],
          ),
        if (checks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: checks.entries.map((entry) {
              final value = entry.value is Map
                  ? Map<String, dynamic>.from(entry.value as Map)
                  : <String, dynamic>{};
              return _CheckPill(
                label: entry.key.toString(),
                status: '${value['status'] ?? context.tr.landingStatusUnknown}',
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String label;
  final bool compact;

  const _BrandMark({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/kerosene-logo.png',
          width: compact ? 34 : 44,
          height: compact ? 34 : 44,
          fit: BoxFit.contain,
        ),
        SizedBox(width: compact ? 12 : 18),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: compact ? 15 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _EyebrowPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EyebrowPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Text(label, style: _monoStyle(_muted)),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF353534), Color(0xFF2A2A2A), Color(0xFF1C1B1B)];
    return SizedBox(
      width: 70,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 19,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroVaultStage extends StatelessWidget {
  final String statusLabel;

  const _HeroVaultStage({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: AspectRatio(
        aspectRatio: 0.9,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.18),
                      blurRadius: 110,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF242424), Color(0xFF050505)],
                    ),
                  ),
                  child: CustomPaint(painter: const _VaultPainter()),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _GlassPanel(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('STATUS DA REDE', style: _monoStyle(_gold)),
                          const SizedBox(height: 6),
                          Text(
                            statusLabel == context.tr.landingStatusOnline
                                ? '100% On-chain & Tor'
                                : 'On-chain & Tor',
                            style: _cardTitleStyle(20),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.network, color: _gold, size: 38),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneStage extends StatelessWidget {
  final String statusLabel;

  const _PhoneStage({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 44,
            child: Container(
              width: 420,
              height: 660,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          _PhoneMockup(statusLabel: statusLabel),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final String statusLabel;

  const _PhoneMockup({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030405),
        borderRadius: BorderRadius.circular(66),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.28), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.64),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -12,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(56),
        child: AspectRatio(
          aspectRatio: 465 / 1114,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/HOMESCREEN.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 116,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 26,
                bottom: 28,
                child: _StatusDot(
                    online: statusLabel == context.tr.landingStatusOnline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFeatureStrip extends StatelessWidget {
  final List<_LandingCardData> items;

  const _HeroFeatureStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 52,
      runSpacing: 28,
      children: items.map((item) {
        return SizedBox(
          width: 270,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIcon(icon: item.icon, size: 52),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: _cardTitleStyle(15)),
                    const SizedBox(height: 5),
                    Text(item.body,
                        style: _smallStyle(_muted).copyWith(height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<_LandingCardData> items;
  final double minCardWidth;

  const _CardGrid({
    required this.items,
    this.minCardWidth = 390,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(1, constraints.maxWidth ~/ minCardWidth);
        final spacing = 18.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _FeatureCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _LandingCardData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(32),
      borderColor: data.highlighted ? _gold.withValues(alpha: 0.72) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIcon(icon: data.icon, active: data.highlighted),
          const SizedBox(height: 24),
          Text(data.title, style: _cardTitleStyle(22)),
          const SizedBox(height: 12),
          Text(data.body, style: _bodyStyle(16)),
        ],
      ),
    );
  }
}

class _AudienceItem {
  final String title;
  final String body;

  const _AudienceItem(this.title, this.body);
}

class _AudienceColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_AudienceItem> items;
  final Widget visual;
  final IconData icon;

  const _AudienceColumn({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.visual,
    this.icon = LucideIcons.checkCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _displayStyle(context, 48)),
        const SizedBox(height: 14),
        Text(subtitle, style: _bodyStyle(18)),
        const SizedBox(height: 34),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: _gold, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: _cardTitleStyle(16)),
                      const SizedBox(height: 4),
                      Text(item.body, style: _smallStyle(_muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        visual,
      ],
    );
  }
}

class _PhoneImagePanel extends StatelessWidget {
  const _PhoneImagePanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF191919), Color(0xFF050505)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.72,
              child: Image.asset(
                'assets/images/HOMESCREEN.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiAccessCard extends StatelessWidget {
  const _ApiAccessCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(32),
      borderColor: _gold.withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API ACCESS', style: _monoStyle(_gold)),
          const SizedBox(height: 16),
          Text(
            'Documentação técnica disponível via portal de desenvolvedores em rede Onion.',
            style: _bodyStyle(16).copyWith(color: Colors.white),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.67,
              minHeight: 8,
              backgroundColor: const Color(0xFF353534),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;

  const _AudienceCard({
    required this.icon,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 38),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _cardTitleStyle(20)),
                const SizedBox(height: 12),
                ...bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.check,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(bullet, style: _bodyStyle(15))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchitectureRail extends StatelessWidget {
  final List<_LandingCardData> items;

  const _ArchitectureRail({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final columns = constraints.maxWidth < 560 ? 1 : 4;
        final width =
            compact ? 210.0 : (constraints.maxWidth - 3 * 18) / columns;
        final content = Wrap(
          spacing: 18,
          runSpacing: 18,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _ArchitectureCard(data: item),
                ),
              )
              .toList(),
        );

        if (compact && constraints.maxWidth >= 560) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }
        return content;
      },
    );
  }
}

class _ArchitectureCard extends StatelessWidget {
  final _LandingCardData data;

  const _ArchitectureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      borderColor: data.highlighted ? _gold : null,
      child: SizedBox(
        height: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon,
                color: data.highlighted ? _gold : Colors.white, size: 32),
            const Spacer(),
            Text(data.title, style: _cardTitleStyle(16)),
            const SizedBox(height: 8),
            Text(data.body, style: _smallStyle(_muted).copyWith(height: 1.32)),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;

  const _RoundIcon({
    required this.icon,
    this.active = false,
    this.size = 62,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: active ? 0.11 : 0.045),
        border: Border.all(
          color: active
              ? _gold.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child:
          Icon(icon, color: active ? _gold : Colors.white, size: size * 0.44),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _SquareIcon({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: active ? _gold : const Color(0xFF353534),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Icon(icon, color: active ? const Color(0xFF131313) : Colors.white),
    );
  }
}

class _LandingButton extends StatefulWidget {
  final String label;
  final bool filled;
  final bool large;
  final VoidCallback onPressed;

  const _LandingButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.large = false,
  });

  @override
  State<_LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<_LandingButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.filled ? _gold : Colors.transparent;
    final foreground = widget.filled ? const Color(0xFF6B4C00) : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _hover && !_reduceMotion(context) ? 1.018 : 1,
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 40 : 34,
              vertical: widget.large ? 21 : 18,
            ),
            side: BorderSide(
              color:
                  widget.filled ? _gold : Colors.white.withValues(alpha: 0.18),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: widget.large ? 17 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavTextButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}

class _CenteredTitle extends StatelessWidget {
  final String text;

  const _CenteredTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: _sectionTitleStyle(context, 36),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  final double topPadding;
  final double bottomPadding;

  const _SectionShell({
    super.key,
    required this.child,
    this.topPadding = 54,
    this.bottomPadding = 28,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        topPadding,
        compact ? 20 : 48,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

class _CtaMapMark extends StatelessWidget {
  const _CtaMapMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CtaMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool online;

  const _StatusDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? _green : _gold;
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: _reduceMotion(context) ? 0 : 12,
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
        color: _surface,
        border: Border.all(color: ok ? _green.withValues(alpha: 0.5) : _gold),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $status', style: _smallStyle(ok ? _green : _gold)),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;

  const _SkeletonBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.22, end: _reduceMotion(context) ? 0.22 : 0.72),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(_surface, _panelSoft, value),
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _LandingBackdropPainter extends CustomPainter {
  const _LandingBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = _ink);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.42, -0.78),
        radius: 0.88,
        colors: [
          const Color(0xFF283849).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final leftGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.78, 0.02),
        radius: 0.7,
        colors: [
          const Color(0xFF0D2A32).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, leftGlow);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var i = 0; i < 34; i++) {
      final y = size.height * (i / 34);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + math.sin(i) * 12), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VaultPainter extends CustomPainter {
  const _VaultPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF050505));

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.06, -0.08),
        radius: 0.78,
        colors: [
          _gold.withValues(alpha: 0.26),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final center = Offset(size.width * 0.52, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.31;
    final metal = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF383838),
          Color(0xFF111111),
          Color(0xFF030303),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius, metal);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, radius * (0.48 + i * 0.18), stroke);
    }

    final goldStroke = Paint()
      ..color = _gold.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.22;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.82;
      canvas.drawLine(start, end, goldStroke);
    }

    final handlePaint = Paint()
      ..color = const Color(0xFF050505)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.18, handlePaint);
    canvas.drawCircle(center, radius * 0.1, Paint()..color = _gold);

    final serverPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 0; x < 7; x++) {
      final left = size.width * (0.06 + x * 0.13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height * 0.08, 24, size.height * 0.76),
          const Radius.circular(6),
        ),
        serverPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArchitectureConnectorPainter extends CustomPainter {
  const _ArchitectureConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.06, 12)
      ..quadraticBezierTo(size.width * 0.18, 0, size.width * 0.30, 18)
      ..quadraticBezierTo(size.width * 0.50, 48, size.width * 0.72, 18)
      ..quadraticBezierTo(size.width * 0.88, -2, size.width * 0.95, 18);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CtaMapPainter extends CustomPainter {
  const _CtaMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (var x = 0; x < 44; x++) {
      for (var y = 0; y < 22; y++) {
        if ((x + y) % 3 == 0 && x > y * 0.45 && x < 42 - y * 0.18) {
          canvas.drawCircle(
            Offset(size.width * (0.06 + x / 50), size.height * (0.18 + y / 34)),
            1.3,
            dotPaint,
          );
        }
      }
    }

    final markPaint = Paint()
      ..color = _gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width * 0.75;
    final cy = size.height * 0.52;
    final k = Path()
      ..moveTo(cx - 46, cy - 60)
      ..lineTo(cx - 46, cy + 58)
      ..moveTo(cx - 16, cy - 10)
      ..lineTo(cx + 58, cy - 68)
      ..moveTo(cx - 12, cy + 2)
      ..lineTo(cx + 64, cy + 64)
      ..moveTo(cx + 8, cy - 10)
      ..lineTo(cx + 38, cy + 36)
      ..moveTo(cx + 24, cy - 26)
      ..lineTo(cx + 74, cy + 12);
    canvas.drawPath(k, markPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LandingCardData {
  final IconData icon;
  final String title;
  final String body;
  final bool highlighted;

  const _LandingCardData({
    required this.icon,
    required this.title,
    required this.body,
    this.highlighted = false,
  });
}

List<_LandingCardData> _heroFeatureItems(BuildContext context) {
  return [
    _LandingCardData(
      icon: LucideIcons.link2,
      title: context.tr.landingHeroFeatureOnchainTitle,
      body: context.tr.landingHeroFeatureOnchainBody,
    ),
    _LandingCardData(
      icon: LucideIcons.repeat2,
      title: context.tr.landingHeroFeatureInternalTitle,
      body: context.tr.landingHeroFeatureInternalBody,
    ),
    _LandingCardData(
      icon: LucideIcons.shieldCheck,
      title: context.tr.landingHeroFeatureSecurityTitle,
      body: context.tr.landingHeroFeatureSecurityBody,
    ),
  ];
}

List<_LandingCardData> _productCards(BuildContext context) {
  return [
    _LandingCardData(
      icon: LucideIcons.eyeOff,
      title: 'Privacidade Onion',
      body:
          'Total anonimato. Todas as conexões são roteadas nativamente via rede Tor, ocultando seu IP e localização geográfica de qualquer observador externo.',
    ),
    _LandingCardData(
      icon: LucideIcons.zap,
      title: 'Liquidez Lightning',
      body:
          'Pagamentos instantâneos com taxas próximas de zero. Integrado nativamente para fluxos de caixa empresariais e transferências pessoais globais.',
      highlighted: true,
    ),
    _LandingCardData(
      icon: LucideIcons.shieldCheck,
      title: 'Custódia Institucional',
      body:
          'Segurança com tecnologia MPC (Multi-Party Computation) e arquitetura segmentada para proteção contra ataques físicos e digitais.',
    ),
  ];
}

List<_LandingCardData> _architectureCards(BuildContext context) {
  return [
    _LandingCardData(
      icon: LucideIcons.boxes,
      title: 'Bitcoin Core',
      body: 'Validação total de nós em infraestrutura própria.',
    ),
    _LandingCardData(
      icon: LucideIcons.globe2,
      title: 'Rede Tor',
      body: 'Ofuscação de tráfego e anonimato de rede mandatórios.',
    ),
    _LandingCardData(
      icon: LucideIcons.network,
      title: 'MPC Tech',
      body: 'Assinaturas distribuídas sem ponto único de falha.',
      highlighted: true,
    ),
    _LandingCardData(
      icon: LucideIcons.activity,
      title: 'Auditoria Live',
      body: 'Prova de reservas criptográfica em tempo real.',
    ),
  ];
}

List<_LandingCardData> _securityCards(BuildContext context) {
  return [
    _LandingCardData(
      icon: LucideIcons.keyRound,
      title: context.tr.landingSecurityPasskeysTitle,
      body: context.tr.landingSecurityPasskeysBody,
    ),
    _LandingCardData(
      icon: LucideIcons.shieldCheck,
      title: context.tr.landingSecurityVaultMpcTitle,
      body: context.tr.landingSecurityVaultMpcBody,
    ),
    _LandingCardData(
      icon: LucideIcons.eyeOff,
      title: context.tr.landingSecurityPrivacyTitle,
      body: context.tr.landingSecurityPrivacyBody,
    ),
    _LandingCardData(
      icon: LucideIcons.scrollText,
      title: context.tr.landingSecurityAuditTitle,
      body: context.tr.landingSecurityAuditBody,
    ),
  ];
}

TextStyle _displayStyle(BuildContext context, double size) {
  final compact = MediaQuery.sizeOf(context).width < 760;
  return TextStyle(
    fontFamily: AppTypography.titleFontFamily,
    fontSize: compact ? math.min(size, 52) : size,
    fontWeight: FontWeight.w300,
    height: 1.02,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle _sectionTitleStyle(BuildContext context, double size) {
  final compact = MediaQuery.sizeOf(context).width < 760;
  return TextStyle(
    fontFamily: AppTypography.titleFontFamily,
    fontSize: compact ? math.min(size, 34) : size,
    fontWeight: FontWeight.w300,
    height: 1.12,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle _eyebrowStyle() {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: _gold,
  );
}

TextStyle _monoStyle(Color color) {
  return TextStyle(
    fontFamily: AppTypography.monoFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.35,
    letterSpacing: 0.6,
    color: color,
  );
}

TextStyle _cardTitleStyle(double size) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.18,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle _bodyStyle(double size) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: _muted,
  );
}

TextStyle _smallStyle(Color color) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    height: 1.35,
    letterSpacing: 0,
    color: color,
  );
}

String _statusLabel(BuildContext context, Map<String, dynamic>? status) {
  final value = status?['status']?.toString().toUpperCase();
  if (value == 'UP') return context.tr.landingStatusOnline;
  if (value == 'DEGRADED') return context.tr.landingStatusDegraded;
  if (value == 'DOWN') return context.tr.landingStatusUnavailable;
  return context.tr.landingStatusChecking;
}

String _short(Object? value, String fallback) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return fallback;
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
