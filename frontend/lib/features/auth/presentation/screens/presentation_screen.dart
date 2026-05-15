import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/kerosene_logo.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

const Color _presentationInk = Color(0xFF020405);
const Color _presentationMuted = Color(0xFFA6A8A4);
const Color _presentationAmber = Color(0xFFFFB21A);
const Color _presentationGreen = Color(0xFF63F47D);

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _copy({
    required BuildContext context,
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

  List<_PresentationSlide> _slides(BuildContext context) {
    return [
      _PresentationSlide(
        title: _copy(
          context: context,
          pt: 'Seu banco Bitcoin.',
          en: 'Your Bitcoin bank.',
          es: 'Tu banco Bitcoin.',
        ),
        summary: _copy(
          context: context,
          pt: 'Custódia profissional, segurança institucional e infraestrutura para suas operações diárias com Bitcoin.',
          en: 'Professional custody, institutional security, and infrastructure for your daily Bitcoin operations.',
          es: 'Custodia profesional, seguridad institucional e infraestructura para tus operaciones diarias con Bitcoin.',
        ),
        features: [
          _PresentationFeature(
            icon: LucideIcons.shieldCheck,
            title: _copy(
              context: context,
              pt: 'Custódia profissional',
              en: 'Professional custody',
              es: 'Custodia profesional',
            ),
            body: _copy(
              context: context,
              pt: 'Infraestrutura segura para guardar e operar seus bitcoins com praticidade.',
              en: 'Secure infrastructure to store and operate your bitcoins with practicality.',
              es: 'Infraestructura segura para guardar y operar tus bitcoins con practicidad.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.qrCode,
            title: _copy(
              context: context,
              pt: 'Pagamentos por QR Code',
              en: 'QR Code payments',
              es: 'Pagos por QR Code',
            ),
            body: _copy(
              context: context,
              pt: 'Envie e receba com agilidade via on-chain, Lightning e Kerosene.',
              en: 'Send and receive quickly through on-chain, Lightning, and Kerosene.',
              es: 'Envía y recibe con agilidad por on-chain, Lightning y Kerosene.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.briefcase,
            title: _copy(
              context: context,
              pt: 'Painel empresarial',
              en: 'Business dashboard',
              es: 'Panel empresarial',
            ),
            body: _copy(
              context: context,
              pt: 'Gestão administrativa para empresas com visão operacional e financeira.',
              en: 'Administrative management for companies with operational and financial visibility.',
              es: 'Gestión administrativa para empresas con visión operativa y financiera.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.percent,
            title: _copy(
              context: context,
              pt: 'Taxas inteligentes',
              en: 'Smart fees',
              es: 'Tarifas inteligentes',
            ),
            body: _copy(
              context: context,
              pt: 'Taxas de depósito e saque variáveis conforme perfil e score.',
              en: 'Variable deposit and withdrawal fees according to profile and score.',
              es: 'Tarifas variables de depósito y retiro según perfil y score.',
            ),
          ),
        ],
      ),
      _PresentationSlide(
        title: _copy(
          context: context,
          pt: 'Segurança para operar.',
          en: 'Security for operations.',
          es: 'Seguridad para operar.',
        ),
        summary: _copy(
          context: context,
          pt: 'Acesso forte, proteção de sessão e camadas de verificação pensadas para reduzir risco desde o primeiro login.',
          en: 'Strong access, session protection, and verification layers designed to reduce risk from the first login.',
          es: 'Acceso fuerte, protección de sesión y capas de verificación diseñadas para reducir riesgo desde el primer login.',
        ),
        features: [
          _PresentationFeature(
            icon: LucideIcons.fingerprint,
            title: _copy(
              context: context,
              pt: 'Passkey biométrica',
              en: 'Biometric passkey',
              es: 'Passkey biométrica',
            ),
            body: _copy(
              context: context,
              pt: 'A chave do dispositivo protege o acesso sem depender de senhas frágeis.',
              en: 'The device key protects access without relying on weak passwords.',
              es: 'La clave del dispositivo protege el acceso sin depender de contraseñas débiles.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.keyRound,
            title: _copy(
              context: context,
              pt: 'Verificação em duas etapas',
              en: 'Two-step verification',
              es: 'Verificación en dos pasos',
            ),
            body: _copy(
              context: context,
              pt: 'Camadas adicionais protegem operações sensíveis e recuperação de conta.',
              en: 'Additional layers protect sensitive operations and account recovery.',
              es: 'Capas adicionales protegen operaciones sensibles y recuperación de cuenta.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.network,
            title: _copy(
              context: context,
              pt: 'Rede protegida',
              en: 'Protected network',
              es: 'Red protegida',
            ),
            body: _copy(
              context: context,
              pt: 'Infraestrutura preparada para privacidade, resiliência e estabilidade.',
              en: 'Infrastructure prepared for privacy, resilience, and stability.',
              es: 'Infraestructura preparada para privacidad, resiliencia y estabilidad.',
            ),
          ),
        ],
      ),
      _PresentationSlide(
        title: _copy(
          context: context,
          pt: 'Pagamentos sem atrito.',
          en: 'Frictionless payments.',
          es: 'Pagos sin fricción.',
        ),
        summary: _copy(
          context: context,
          pt: 'Use Bitcoin do jeito certo para cada situação: QR Code, Lightning, on-chain e transferências internas.',
          en: 'Use Bitcoin the right way for each situation: QR Code, Lightning, on-chain, and internal transfers.',
          es: 'Usa Bitcoin de la forma correcta para cada situación: QR Code, Lightning, on-chain y transferencias internas.',
        ),
        features: [
          _PresentationFeature(
            icon: LucideIcons.scanLine,
            title: _copy(
              context: context,
              pt: 'Leitura instantânea',
              en: 'Instant scanning',
              es: 'Lectura instantánea',
            ),
            body: _copy(
              context: context,
              pt: 'Cole ou escaneie cobranças Bitcoin, Lightning e Kerosene em um fluxo único.',
              en: 'Paste or scan Bitcoin, Lightning, and Kerosene requests in a single flow.',
              es: 'Pega o escanea cobros Bitcoin, Lightning y Kerosene en un flujo único.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.zap,
            title: _copy(
              context: context,
              pt: 'Lightning nativo',
              en: 'Native Lightning',
              es: 'Lightning nativo',
            ),
            body: _copy(
              context: context,
              pt: 'Recebimentos rápidos e pagamentos compatíveis com faturas Lightning.',
              en: 'Fast receives and payments compatible with Lightning invoices.',
              es: 'Recibimientos rápidos y pagos compatibles con facturas Lightning.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.arrowLeftRight,
            title: _copy(
              context: context,
              pt: 'Transferências internas',
              en: 'Internal transfers',
              es: 'Transferencias internas',
            ),
            body: _copy(
              context: context,
              pt: 'Movimente saldo entre usuários Kerosene com experiência direta e rápida.',
              en: 'Move balances between Kerosene users with a direct and fast experience.',
              es: 'Mueve saldos entre usuarios Kerosene con experiencia directa y rápida.',
            ),
          ),
        ],
      ),
      _PresentationSlide(
        title: _copy(
          context: context,
          pt: 'Controle financeiro real.',
          en: 'Real financial control.',
          es: 'Control financiero real.',
        ),
        summary: _copy(
          context: context,
          pt: 'Acompanhe saldo, carteiras, histórico e notificações críticas em uma home feita para operação diária.',
          en: 'Track balance, wallets, history, and critical notifications in a home built for daily operations.',
          es: 'Acompaña saldo, carteras, historial y notificaciones críticas en una home hecha para operación diaria.',
        ),
        features: [
          _PresentationFeature(
            icon: LucideIcons.walletCards,
            title: _copy(
              context: context,
              pt: 'Carteiras separadas',
              en: 'Separated wallets',
              es: 'Carteras separadas',
            ),
            body: _copy(
              context: context,
              pt: 'Veja carteira Kerosene, on-chain e outras posições de forma organizada.',
              en: 'See Kerosene, on-chain, and other positions in an organized way.',
              es: 'Ve cartera Kerosene, on-chain y otras posiciones de forma organizada.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.activity,
            title: _copy(
              context: context,
              pt: 'Atividade recente',
              en: 'Recent activity',
              es: 'Actividad reciente',
            ),
            body: _copy(
              context: context,
              pt: 'Histórico claro para conferir entradas, saídas, horários e contraparte.',
              en: 'Clear history to check inflows, outflows, times, and counterparties.',
              es: 'Historial claro para revisar entradas, salidas, horarios y contraparte.',
            ),
          ),
          _PresentationFeature(
            icon: LucideIcons.bell,
            title: _copy(
              context: context,
              pt: 'Alertas de sessão',
              en: 'Session alerts',
              es: 'Alertas de sesión',
            ),
            body: _copy(
              context: context,
              pt: 'Notificações ajudam a acompanhar eventos importantes sem sair da tela inicial.',
              en: 'Notifications help track important events without leaving the home screen.',
              es: 'Notificaciones ayudan a seguir eventos importantes sin salir de la pantalla inicial.',
            ),
          ),
        ],
      ),
    ];
  }

  void _openSignup() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  void _openLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);

    return Scaffold(
      backgroundColor: _presentationInk,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PresentationBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return _PresentationPage(
                        slide: slides[index],
                        pageIndex: index,
                        totalPages: slides.length,
                      );
                    },
                  ),
                ),
                _PresentationFooter(
                  currentPage: _currentPage,
                  totalPages: slides.length,
                  onCreateAccount: _openSignup,
                  onLogin: _openLogin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationBackdrop extends StatelessWidget {
  const _PresentationBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF070A0C),
            Color(0xFF020405),
            Color(0xFF010202),
          ],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.54, -0.42),
                  radius: 0.88,
                  colors: [
                    const Color(0xFF8FA9B6).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.92, 0.04),
                  radius: 0.72,
                  colors: [
                    const Color(0xFF17383B).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _PresentationMist())),
        ],
      ),
    );
  }
}

class _PresentationMist extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.035),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.018),
        ],
      ).createShader(Offset.zero & size);

    for (var i = 0; i < 12; i++) {
      final dx = size.width * ((i * 29) % 100) / 100;
      final dy = size.height * ((i * 47) % 100) / 100;
      canvas.drawCircle(Offset(dx, dy), 0.9 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PresentationPage extends StatelessWidget {
  final _PresentationSlide slide;
  final int pageIndex;
  final int totalPages;

  const _PresentationPage({
    required this.slide,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontalPadding = isWide ? 48.0 : 24.0;
        final verticalPadding = isWide ? 36.0 : 22.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 10,
                          child: _PresentationCopyColumn(
                            slide: slide,
                            pageIndex: pageIndex,
                            totalPages: totalPages,
                            compact: false,
                          ),
                        ),
                        const SizedBox(width: 42),
                        const Expanded(
                          flex: 11,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _HomePreviewPhone(maxWidth: 374),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PresentationCopyColumn(
                          slide: slide,
                          pageIndex: pageIndex,
                          totalPages: totalPages,
                          compact: true,
                        ),
                        const SizedBox(height: 28),
                        const Center(child: _HomePreviewPhone(maxWidth: 316)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _PresentationCopyColumn extends StatelessWidget {
  final _PresentationSlide slide;
  final int pageIndex;
  final int totalPages;
  final bool compact;

  const _PresentationCopyColumn({
    required this.slide,
    required this.pageIndex,
    required this.totalPages,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 56.0 : 74.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandMark(),
        SizedBox(height: compact ? 42 : 64),
        Text(
          slide.title,
          style: AppTypography.h1.copyWith(
            fontFamily: AppTypography.titleFontFamily,
            color: authEntryText,
            fontSize: titleSize,
            fontWeight: FontWeight.w300,
            height: 0.98,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 520 : 470),
          child: Text(
            slide.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: _presentationMuted,
              fontSize: compact ? 18 : 21,
              height: 1.42,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: compact ? 34 : 50),
        _FeatureList(features: slide.features),
        SizedBox(height: compact ? 14 : 22),
        Text(
          '${pageIndex + 1} / $totalPages',
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.42),
            fontFamily: 'IBM Plex Mono',
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KeroseneLogo(size: 48, showText: false),
        const SizedBox(width: 18),
        Text(
          'KEROSENE',
          style: AppTypography.h3.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontFamily: AppTypography.fontFamily,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 4.2,
          ),
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  final List<_PresentationFeature> features;

  const _FeatureList({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < features.length; index++) ...[
          if (index > 0)
            Divider(
              height: 26,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          _PresentationFeatureRow(feature: features[index]),
        ],
      ],
    );
  }
}

class _PresentationFeatureRow extends StatelessWidget {
  final _PresentationFeature feature;

  const _PresentationFeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.045),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(feature.icon, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feature.body,
                style: AppTypography.bodyLarge.copyWith(
                  color: _presentationMuted,
                  height: 1.34,
                  fontSize: 18,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomePreviewPhone extends StatelessWidget {
  final double maxWidth;

  const _HomePreviewPhone({required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : maxWidth;
        final width = math.min(maxWidth, math.max(248.0, available));

        return SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF030506),
              borderRadius: BorderRadius.circular(width * 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.64),
                  blurRadius: 42,
                  offset: const Offset(0, 28),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: -6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.027),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width * 0.073),
                child: AspectRatio(
                  aspectRatio: 9 / 19.3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _HomePreviewBackground(),
                      _HomePreviewContent(scale: width / 374),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomePreviewBackground extends StatelessWidget {
  const _HomePreviewBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF05090B),
            Color(0xFF010303),
            Color(0xFF030505),
          ],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.26, -0.82),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF6D8799).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.08, 0.42),
                  radius: 0.72,
                  colors: [
                    const Color(0xFF17383B).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewContent extends StatelessWidget {
  final double scale;

  const _HomePreviewContent({required this.scale});

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

  @override
  Widget build(BuildContext context) {
    final bottomNavigationHeight = 66.0 * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(18 * scale, 18 * scale, 18 * scale, 0),
      child: Stack(
        children: [
          Positioned.fill(
            bottom: bottomNavigationHeight + 10 * scale,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomePreviewStatusBar(scale: scale),
                  SizedBox(height: 20 * scale),
                  _HomePreviewHeader(scale: scale),
                  SizedBox(height: 24 * scale),
                  Text(
                    _copy(
                      context,
                      pt: 'Bom dia, Lucas',
                      en: 'Good morning, Lucas',
                      es: 'Buenos días, Lucas',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * scale,
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  _HomePreviewBalanceCard(scale: scale),
                  SizedBox(height: 12 * scale),
                  _HomePreviewDots(scale: scale, count: 2, activeIndex: 0),
                  SizedBox(height: 16 * scale),
                  _HomePreviewActions(scale: scale),
                  SizedBox(height: 14 * scale),
                  _HomePreviewSecurityCard(scale: scale),
                  SizedBox(height: 20 * scale),
                  _HomePreviewSectionHeader(scale: scale),
                  SizedBox(height: 10 * scale),
                  _HomePreviewTransactions(scale: scale),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14 * scale,
            child: _HomePreviewNavigation(scale: scale),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewStatusBar extends StatelessWidget {
  final double scale;

  const _HomePreviewStatusBar({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        Icon(LucideIcons.signal, size: 13 * scale, color: Colors.white),
        SizedBox(width: 5 * scale),
        Icon(LucideIcons.wifi, size: 13 * scale, color: Colors.white),
        SizedBox(width: 5 * scale),
        Icon(LucideIcons.batteryFull, size: 17 * scale, color: Colors.white),
      ],
    );
  }
}

class _HomePreviewHeader extends StatelessWidget {
  final double scale;

  const _HomePreviewHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KeroseneLogo(size: 32 * scale, showText: false),
        SizedBox(width: 10 * scale),
        Text(
          'KEROSENE',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 12 * scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2 * scale,
          ),
        ),
        const Spacer(),
        Icon(
          LucideIcons.eye,
          size: 20 * scale,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        SizedBox(width: 14 * scale),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              LucideIcons.bell,
              size: 20 * scale,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            Positioned(
              right: -1 * scale,
              top: -4 * scale,
              child: Container(
                width: 7 * scale,
                height: 7 * scale,
                decoration: const BoxDecoration(
                  color: _presentationAmber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomePreviewBalanceCard extends StatelessWidget {
  final double scale;

  const _HomePreviewBalanceCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _PreviewGlassPanel(
      scale: scale,
      borderRadius: 18 * scale,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              16 * scale,
              18 * scale,
              14 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SALDO TOTAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 8.5 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(width: 7 * scale),
                    Icon(
                      LucideIcons.eye,
                      size: 11 * scale,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18 * scale,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ],
                ),
                SizedBox(height: 12 * scale),
                RichText(
                  maxLines: 1,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '0,245690',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.97),
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0,
                        ),
                      ),
                      TextSpan(
                        text: ' BTC',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7 * scale),
                Text(
                  'R\$ 63.758,46',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Icon(
                      LucideIcons.triangle,
                      size: 10 * scale,
                      color: _presentationGreen,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      '2,35% (24h)',
                      style: TextStyle(
                        color: _presentationGreen,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _HomePreviewBreakdownItem(
                    scale: scale,
                    label: context.l10n.homeKeroseneWalletLabel,
                    btc: '0,070000 BTC',
                    fiat: 'R\$ 18.100,23',
                  ),
                ),
                _HomePreviewDivider(scale: scale),
                Expanded(
                  child: _HomePreviewBreakdownItem(
                    scale: scale,
                    label: context.l10n.homeOnchainWalletLabel,
                    btc: '0,175690 BTC',
                    fiat: 'R\$ 45.658,23',
                  ),
                ),
                _HomePreviewDivider(scale: scale),
                Expanded(
                  child: _HomePreviewBreakdownItem(
                    scale: scale,
                    label: context.l10n.homeOtherWalletsLabel,
                    btc: '0,000000 BTC',
                    fiat: 'R\$ 0,00',
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

class _HomePreviewBreakdownItem extends StatelessWidget {
  final double scale;
  final String label;
  final String btc;
  final String fiat;

  const _HomePreviewBreakdownItem({
    required this.scale,
    required this.label,
    required this.btc,
    required this.fiat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(12 * scale, 14 * scale, 8 * scale, 14 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 7.4 * scale,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            btc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.8 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            fiat,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 9.4 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewDivider extends StatelessWidget {
  final double scale;

  const _HomePreviewDivider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: 16 * scale,
      endIndent: 16 * scale,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _HomePreviewActions extends StatelessWidget {
  final double scale;

  const _HomePreviewActions({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomePreviewActionButton(
            scale: scale,
            icon: LucideIcons.arrowUp,
            label: context.l10n.homeSendTitle,
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: _HomePreviewActionButton(
            scale: scale,
            icon: LucideIcons.arrowDown,
            label: context.l10n.homeReceiveActionShort,
          ),
        ),
      ],
    );
  }
}

class _HomePreviewActionButton extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;

  const _HomePreviewActionButton({
    required this.scale,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _PreviewGlassPanel(
      scale: scale,
      borderRadius: 14 * scale,
      padding:
          EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.045),
            ),
            child: Icon(icon, size: 20 * scale, color: Colors.white),
          ),
          SizedBox(width: 10 * scale),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewSecurityCard extends StatelessWidget {
  final double scale;

  const _HomePreviewSecurityCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _PreviewGlassPanel(
      scale: scale,
      borderRadius: 18 * scale,
      padding:
          EdgeInsets.fromLTRB(16 * scale, 15 * scale, 12 * scale, 14 * scale),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bitcoins sob seu controle.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w900,
                    height: 1.14,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 9 * scale),
                Text(
                  'Segurança de ponta para proteger o que é seu.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10 * scale,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 13 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 9 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7 * scale),
                  ),
                  child: Text(
                    'Saiba mais',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10 * scale),
          Container(
            width: 84 * scale,
            height: 86 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * scale),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF30363A), Color(0xFF07090B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16 * scale,
                  offset: Offset(0, 8 * scale),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: 9 * scale,
                  top: 10 * scale,
                  bottom: 10 * scale,
                  child: Container(
                    width: 7 * scale,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                  ),
                ),
                Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.48),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.bitcoin,
                    size: 26 * scale,
                    color: Colors.white.withValues(alpha: 0.88),
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

class _HomePreviewSectionHeader extends StatelessWidget {
  final double scale;

  const _HomePreviewSectionHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Atividades recentes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          'Ver todas',
          style: TextStyle(
            color: _presentationAmber,
            fontSize: 11 * scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _HomePreviewTransactions extends StatelessWidget {
  final double scale;

  const _HomePreviewTransactions({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _PreviewGlassPanel(
      scale: scale,
      borderRadius: 16 * scale,
      padding: EdgeInsets.symmetric(vertical: 5 * scale),
      child: Column(
        children: [
          _HomePreviewTxRow(
            scale: scale,
            incoming: true,
            title: context.l10n.homeTxReceived,
            subtitle: '${context.l10n.homeCounterpartyFrom} bc1q...4nkz',
            amount: '+0,012500 BTC',
            time: context.l10n.homeTodayAt('09:21'),
          ),
          _HomePreviewTxRow(
            scale: scale,
            incoming: false,
            title: context.l10n.homeTxSent,
            subtitle: '${context.l10n.homeCounterpartyTo} bc1q...dp9x',
            amount: '-0,005000 BTC',
            time: context.l10n.homeYesterdayAt('18:43'),
          ),
          _HomePreviewTxRow(
            scale: scale,
            incoming: true,
            title: context.l10n.homeTxReceived,
            subtitle: '${context.l10n.homeCounterpartyFrom} bc1q...az8v',
            amount: '+0,030000 BTC',
            time: context.l10n.homeYesterdayAt('14:02'),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewTxRow extends StatelessWidget {
  final double scale;
  final bool incoming;
  final String title;
  final String subtitle;
  final String amount;
  final String time;

  const _HomePreviewTxRow({
    required this.scale,
    required this.incoming,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final accent = incoming ? _presentationGreen : Colors.white;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 9 * scale),
      child: Row(
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.055),
            ),
            child: Icon(
              incoming ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              size: 18 * scale,
              color: accent,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 9 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: incoming ? _presentationGreen : Colors.white,
                  fontSize: 10.5 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 9 * scale,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomePreviewNavigation extends StatelessWidget {
  final double scale;

  const _HomePreviewNavigation({required this.scale});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(24 * scale),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: SizedBox(
            height: 60 * scale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HomePreviewNavItem(
                  scale: scale,
                  icon: LucideIcons.home,
                  label: context.l10n.primaryNavHome,
                  active: true,
                ),
                _HomePreviewNavItem(
                  scale: scale,
                  icon: LucideIcons.walletCards,
                  label: context.l10n.wallets,
                ),
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.zap,
                    size: 25 * scale,
                    color: Colors.white,
                  ),
                ),
                _HomePreviewNavItem(
                  scale: scale,
                  icon: LucideIcons.list,
                  label: context.l10n.primaryNavHistory,
                ),
                _HomePreviewNavItem(
                  scale: scale,
                  icon: LucideIcons.settings,
                  label: context.l10n.primaryNavSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePreviewNavItem extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;
  final bool active;

  const _HomePreviewNavItem({
    required this.scale,
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _presentationAmber : Colors.white;

    return SizedBox(
      width: 46 * scale,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18 * scale,
            color: color.withValues(alpha: active ? 1 : 0.86),
          ),
          SizedBox(height: 5 * scale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: active ? 1 : 0.86),
              fontSize: 8.2 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewDots extends StatelessWidget {
  final double scale;
  final int count;
  final int activeIndex;

  const _HomePreviewDots({
    required this.scale,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) SizedBox(width: 8 * scale),
          Container(
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == activeIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewGlassPanel extends StatelessWidget {
  final double scale;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _PreviewGlassPanel({
    required this.scale,
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14 * scale, sigmaY: 14 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE512171C), Color(0xD7080B0E)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 22 * scale,
                offset: Offset(0, 12 * scale),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PresentationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const _PresentationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.onCreateAccount,
    required this.onLogin,
  });

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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _presentationInk.withValues(alpha: 0.92),
            _presentationInk,
          ],
          stops: const [0, 0.36, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackButtons = constraints.maxWidth < 360;

                    final createButton = _PresentationCtaButton(
                      label: _copy(
                        context,
                        pt: 'Criar conta',
                        en: 'Create account',
                        es: 'Crear cuenta',
                      ),
                      onPressed: onCreateAccount,
                      primary: true,
                    );
                    final loginButton = _PresentationCtaButton(
                      label: _copy(
                        context,
                        pt: 'Já tenho conta',
                        en: 'I have an account',
                        es: 'Ya tengo cuenta',
                      ),
                      onPressed: onLogin,
                      primary: false,
                    );

                    if (stackButtons) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          createButton,
                          const SizedBox(height: 12),
                          loginButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: createButton),
                        const SizedBox(width: 16),
                        Expanded(child: loginButton),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < totalPages; index++) ...[
                      if (index > 0) const SizedBox(width: 18),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: currentPage == index ? 18 : 14,
                        height: currentPage == index ? 18 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentationCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _PresentationCtaButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: primary ? Colors.white : Colors.transparent,
          foregroundColor: primary ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: primary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.46)),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.buttonText.copyWith(
              color:
                  primary ? Colors.black : Colors.white.withValues(alpha: 0.76),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentationSlide {
  final String title;
  final String summary;
  final List<_PresentationFeature> features;

  const _PresentationSlide({
    required this.title,
    required this.summary,
    required this.features,
  });
}

class _PresentationFeature {
  final IconData icon;
  final String title;
  final String body;

  const _PresentationFeature({
    required this.icon,
    required this.title,
    required this.body,
  });
}
