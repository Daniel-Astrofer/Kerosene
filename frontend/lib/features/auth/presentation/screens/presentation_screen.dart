import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';


class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  int _currentPage = 0;

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

  List<_Slide> _getSlides(BuildContext context) {
    return [
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'INFRAESTRUTURA',
          en: 'INFRASTRUCTURE',
          es: 'INFRAESTRUCTURA',
        ),
        title: _copy(
          context: context,
          pt: 'Conexão via rede anônima.',
          en: 'Connection via onion network.',
          es: 'Conexión vía red onion.',
        ),
        body: _copy(
          context: context,
          pt: 'Todas as requisições passam por roteamento privado. Sem credenciais expostas.',
          en: 'All requests go through onion routing. No exposed clearnet, no intermediate CDN.',
          es: 'Todas las solicitudes pasan por enrutamiento onion. Sin clearnet expuesta, sin CDN intermediario.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Conexão anônima por  padrão',
            en: 'Onion routing by default',
            es: 'Enrutamiento onion por defecto',
          ),
          _copy(
            context: context,
            pt: 'Sem dependência de infraestrutura exposta',
            en: 'No dependence on exposed infrastructure',
            es: 'Sin dependencia de infraestructura expuesta',
          ),
          _copy(
            context: context,
            pt: 'Privacidade como princípio, não opção',
            en: 'Privacy as architecture, not an option',
            es: 'Privacidad como arquitectura, no opción',
          ),
        ],
        metricLabel: _copy(context: context, pt: 'Protocolo:', en: 'NETWORK', es: 'RED'),
        metricValue: 'ONION',
        icon: LucideIcons.shield,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'AUTENTICAÇÃO',
          en: 'AUTHENTICATION',
          es: 'AUTENTICACIÓN',
        ),
        title: _copy(
          context: context,
          pt: 'Passkey.',
          en: 'Passkey, TOTP, and seed.',
          es: 'Passkey, TOTP y seed.',
        ),
        body: _copy(
          context: context,
          pt: 'O login prioriza passkey local. Fallback para senha forte + TOTP. Recuperação via seed BIP39.',
          en: 'Login prioritizes local passkey. Fallback to strong password + TOTP. Recovery via BIP39 seed.',
          es: 'El login prioriza passkey local. Respaldo con contraseña fuerte + TOTP. Recuperación vía seed BIP39.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Passkey vincula este dispositivo',
            en: 'Passkey binds this device',
            es: 'Passkey vincula este dispositivo',
          ),
          _copy(
            context: context,
            pt: 'TOTP obrigatório como segunda camada',
            en: 'TOTP required as second layer',
            es: 'TOTP obligatorio como segunda capa',
          ),
          _copy(
            context: context,
            pt: 'Seed exibida uma vez para backup offline',
            en: 'Seed shown once for offline backup',
            es: 'Seed mostrada una vez para respaldo offline',
          ),
        ],
        metricLabel: _copy(context: context, pt: 'ACESSO', en: 'ACCESS', es: 'ACCESO'),
        metricValue: 'PASSKEY',
        icon: LucideIcons.fingerprint,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'OPERAÇÕES',
          en: 'OPERATIONS',
          es: 'OPERACIONES',
        ),
        title: _copy(
          context: context,
          pt: 'On-chain, Lightning e interno.',
          en: 'On-chain, Lightning, and internal.',
          es: 'On-chain, Lightning e interno.',
        ),
        body: _copy(
          context: context,
          pt: 'Depósito e saque via Bitcoin on-chain ou Lightning. Transferências internas entre contas sem taxa.',
          en: 'Deposit and withdraw via Bitcoin on-chain or Lightning. Internal transfers between accounts with no fee.',
          es: 'Depósito y retiro vía Bitcoin on-chain o Lightning. Transferencias internas entre cuentas sin comisión.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Depósito on-chain e Lightning',
            en: 'On-chain and Lightning deposits',
            es: 'Depósitos on-chain y Lightning',
          ),
          _copy(
            context: context,
            pt: 'Transferência interna sem custo',
            en: 'Internal transfer with no cost',
            es: 'Transferencia interna sin costo',
          ),
          _copy(
            context: context,
            pt: 'Primeiro depósito libera recebimentos',
            en: 'First deposit enables receiving',
            es: 'El primer depósito habilita recepciones',
          ),
        ],
        metricLabel: _copy(context: context, pt: 'MOEDA', en: 'CURRENCY', es: 'MONEDA'),
        metricValue: 'BTC',
        icon: LucideIcons.arrowLeftRight,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'CADASTRO',
          en: 'SIGNUP',
          es: 'REGISTRO',
        ),
        title: _copy(
          context: context,
          pt: 'Sem e-mail. Sem telefone.',
          en: 'No email. No phone.',
          es: 'Sin email. Sin teléfono.',
        ),
        body: _copy(
          context: context,
          pt: 'Você escolhe um username, gera a seed, configura TOTP e registra a passkey. Nenhum dado pessoal é solicitado.',
          en: 'You choose a username, generate the seed, set up TOTP, and register the passkey. No personal data is requested.',
          es: 'Eliges un username, generas la seed, configuras TOTP y registras la passkey. No se solicitan datos personales.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Username como única identidade',
            en: 'Username as the only identity',
            es: 'Username como única identidad',
          ),
          _copy(
            context: context,
            pt: 'Proof-of-Work no registro para controle de spam',
            en: 'Proof-of-Work at signup for spam control',
            es: 'Proof-of-Work en el registro para control de spam',
          ),
          _copy(
            context: context,
            pt: 'Sem depósito obrigatório no cadastro',
            en: 'No required deposit at signup',
            es: 'Sin depósito obligatorio en el registro',
          ),
        ],
        metricLabel: _copy(context: context, pt: 'DADOS', en: 'DATA', es: 'DATOS'),
        metricValue: _copy(context: context, pt: 'ZERO', en: 'ZERO', es: 'CERO'),
        icon: LucideIcons.userCheck,
      ),
    ];
  }

  void _finishPresentation() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);

    return Scaffold(
      backgroundColor: authEntryInk,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0B0B),
              Color(0xFF050505),
              authEntryInk,
            ],
            stops: [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                currentPage: _currentPage,
                totalPages: slides.length,
                onSkip: _finishPresentation,
              ),
              Expanded(
                child: PageView.builder(
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    return _SlideView(
                      slide: slides[index],
                      index: index,
                      totalSlides: slides.length,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),
              _Footer(
                currentPage: _currentPage,
                totalPages: slides.length,
                onNext: () {
                  if (_currentPage == slides.length - 1) {
                    _finishPresentation();
                  } else {
                    setState(() => _currentPage++);
                  }
                },
                onFinish: _finishPresentation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;

  const _Header({
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              'assets/logo/kerosene-logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${currentPage + 1} / $totalPages',
            style: AppTypography.caption.copyWith(
              fontFamily: 'JetBrainsMono',
              color: authEntryFaint,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                'SKIP',
                style: AppTypography.caption.copyWith(
                  fontFamily: 'HubotSansCondensed',
                  color: authEntryFaint,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _Footer({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onFinish,
  });

  String _copy(BuildContext context,
      {required String pt, required String en, required String es}) {
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
    final isLast = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Row(
            children: List.generate(totalPages, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == totalPages - 1 ? 0 : 6),
                  height: 3,
                  color: currentPage >= index
                      ? authEntryText
                      : Colors.white.withValues(alpha: 0.06),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: Material(
              color: isLast ? authEntryButton : Colors.transparent,
              child: InkWell(
                onTap: isLast ? onFinish : onNext,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast
                            ? _copy(context,
                                pt: 'CRIAR CONTA',
                                en: 'CREATE ACCOUNT',
                                es: 'CREAR CUENTA')
                            : _copy(context,
                                pt: 'CONTINUAR',
                                en: 'CONTINUE',
                                es: 'CONTINUAR'),
                        style: AppTypography.buttonText.copyWith(
                          fontFamily: 'HubotSansCondensed',
                          color: isLast ? authEntryInk : authEntryText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 16,
                          color: authEntryText,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final int index;
  final int totalSlides;
  final bool isActive;

  const _SlideView({
    required this.slide,
    required this.index,
    required this.totalSlides,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isActive ? 1.0 : 0.0,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: authEntrySurface,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    slide.icon,
                    size: 20,
                    color: authEntryText,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  slide.eyebrow,
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'HubotSansCondensed',
                    color: authEntryFaint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              slide.title,
              style: AppTypography.h1.copyWith(
                fontFamily: 'HubotSansCondensed',
                color: authEntryText,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 0.94,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              slide.body,
              style: AppTypography.bodyMedium.copyWith(
                color: authEntryMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: authEntrySurface,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.metricLabel,
                          style: AppTypography.caption.copyWith(
                            color: authEntryFaint,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.metricValue,
                          style: AppTypography.h2.copyWith(
                            fontFamily: 'JetBrainsMono',
                            color: authEntryText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    '${index + 1}/$totalSlides',
                    style: AppTypography.caption.copyWith(
                      fontFamily: 'JetBrainsMono',
                      color: authEntryFaint,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...slide.details.asMap().entries.map((entry) {
              final i = entry.key;
              final detail = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < slide.details.length - 1 ? 0 : 0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 2,
                      ),
                      bottom: i < slide.details.length - 1
                          ? BorderSide(
                              color: Colors.white.withValues(alpha: 0.04),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    detail,
                    style: AppTypography.bodyMedium.copyWith(
                      color: authEntryText,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final String eyebrow;
  final String title;
  final String body;
  final List<String> details;
  final String metricLabel;
  final String metricValue;
  final IconData icon;

  _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.details,
    required this.metricLabel,
    required this.metricValue,
    required this.icon,
  });
}
