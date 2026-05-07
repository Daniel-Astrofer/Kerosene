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

  List<_Slide> _getSlides(BuildContext context) {
    return [
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'SEGURANÇA INSTITUCIONAL',
          en: 'INSTITUTIONAL SECURITY',
          es: 'SEGURIDAD INSTITUCIONAL',
        ),
        title: _copy(
          context: context,
          pt: 'Privacidade absoluta.',
          en: 'Absolute privacy.',
          es: 'Privacidad absoluta.',
        ),
        body: _copy(
          context: context,
          pt: 'Sua conexão é protegida por roteamento anônimo avançado. Uma infraestrutura robusta desenvolvida para garantir sigilo e estabilidade em todas as operações.',
          en: 'Your connection is protected by advanced anonymous routing. A robust infrastructure developed to guarantee confidentiality and stability in all operations.',
          es: 'Su conexión está protegida por enrutamiento anónimo avanzado. Una infraestructura robusta desarrollada para garantizar confidencialidad y estabilidad en todas las operaciones.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Conexão anônima por padrão',
            en: 'Anonymous connection by default',
            es: 'Conexión anónima por defecto',
          ),
          _copy(
            context: context,
            pt: 'Sem exposição a intermediários',
            en: 'No exposure to intermediaries',
            es: 'Sin exposición a intermediarios',
          ),
          _copy(
            context: context,
            pt: 'Privacidade como pilar estrutural',
            en: 'Privacy as a structural pillar',
            es: 'Privacidad como pilar estructural',
          ),
        ],
        metricLabel: _copy(
            context: context,
            pt: 'INFRAESTRUTURA',
            en: 'INFRASTRUCTURE',
            es: 'INFRAESTRUCTURA'),
        metricValue: 'ONION',
        icon: LucideIcons.shield,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'ACESSO RESTRITO',
          en: 'RESTRICTED ACCESS',
          es: 'ACCESO RESTRINGIDO',
        ),
        title: _copy(
          context: context,
          pt: 'Autenticação de ponta.',
          en: 'State-of-the-art authentication.',
          es: 'Autenticación de vanguardia.',
        ),
        body: _copy(
          context: context,
          pt: 'Proteja seu patrimônio com o que há de mais seguro. Login via Passkey biométrica e verificação em duas etapas, com recuperação via frase semente criptográfica.',
          en: 'Protect your assets with the highest security standards. Login via biometric Passkey and two-step verification, with recovery via cryptographic seed phrase.',
          es: 'Proteja sus activos con los más altos estándares de seguridad. Inicio de sesión mediante Passkey biométrica y verificación en dos pasos, con recuperación vía frase semilla criptográfica.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Biometria vinculada ao dispositivo',
            en: 'Biometrics bound to device',
            es: 'Biometría vinculada al dispositivo',
          ),
          _copy(
            context: context,
            pt: 'Camada adicional com TOTP',
            en: 'Additional layer with TOTP',
            es: 'Capa adicional con TOTP',
          ),
          _copy(
            context: context,
            pt: 'Recuperação offline segura',
            en: 'Secure offline recovery',
            es: 'Recuperación offline segura',
          ),
        ],
        metricLabel:
            _copy(context: context, pt: 'ACESSO', en: 'ACCESS', es: 'ACCESO'),
        metricValue: 'PASSKEY',
        icon: LucideIcons.fingerprint,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'TRANSAÇÕES',
          en: 'TRANSACTIONS',
          es: 'TRANSACCIONES',
        ),
        title: _copy(
          context: context,
          pt: 'Mobilidade financeira.',
          en: 'Financial mobility.',
          es: 'Movilidad financiera.',
        ),
        body: _copy(
          context: context,
          pt: 'Movimente seus recursos com liberdade e velocidade. Suporte nativo à rede Bitcoin, Lightning Network e transferências instantâneas e gratuitas entre clientes Kerosene.',
          en: 'Move your resources with freedom and speed. Native support for the Bitcoin network, Lightning Network, and instant, free transfers between Kerosene clients.',
          es: 'Mueva sus recursos con libertad y velocidad. Soporte nativo para la red Bitcoin, Lightning Network y transferencias instantáneas y gratuitas entre clientes de Kerosene.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Depósitos e saques globais',
            en: 'Global deposits and withdrawals',
            es: 'Depósitos y retiros globales',
          ),
          _copy(
            context: context,
            pt: 'Transferências internas sem custo',
            en: 'Internal transfers at no cost',
            es: 'Transferencias internas sin costo',
          ),
          _copy(
            context: context,
            pt: 'Liquidez imediata',
            en: 'Immediate liquidity',
            es: 'Liquidez inmediata',
          ),
        ],
        metricLabel:
            _copy(context: context, pt: 'REDE', en: 'NETWORK', es: 'RED'),
        metricValue: 'BITCOIN',
        icon: LucideIcons.arrowLeftRight,
      ),
      _Slide(
        eyebrow: _copy(
          context: context,
          pt: 'PRIVACIDADE',
          en: 'PRIVACY',
          es: 'PRIVACIDAD',
        ),
        title: _copy(
          context: context,
          pt: 'Cadastro privado.',
          en: 'Private registration.',
          es: 'Registro privado.',
        ),
        body: _copy(
          context: context,
          pt: 'Nenhuma informação pessoal é exigida. Seu acesso é baseado em um nome de usuário único e credenciais locais, garantindo anonimato desde o primeiro momento.',
          en: 'No personal information is required. Your access is based on a unique username and local credentials, ensuring anonymity from the very beginning.',
          es: 'No se requiere información personal. Su acceso se basa en un nombre de usuario único y credenciales locales, garantizando el anonimato desde el primer momento.',
        ),
        details: [
          _copy(
            context: context,
            pt: 'Identidade digital independente',
            en: 'Independent digital identity',
            es: 'Identidad digital independiente',
          ),
          _copy(
            context: context,
            pt: 'Proteção automática contra abuso',
            en: 'Automatic abuse protection',
            es: 'Protección automática contra abuso',
          ),
          _copy(
            context: context,
            pt: 'Total controle sobre seus dados',
            en: 'Total control over your data',
            es: 'Control total sobre sus datos',
          ),
        ],
        metricLabel:
            _copy(context: context, pt: 'DADOS', en: 'DATA', es: 'DATOS'),
        metricValue:
            _copy(context: context, pt: 'ZERO', en: 'ZERO', es: 'CERO'),
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
                  controller: _pageController,
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
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin:
                      EdgeInsets.only(right: index == totalPages - 1 ? 0 : 8),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: currentPage >= index
                        ? authEntryText
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLast ? onFinish : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? authEntryButton : authEntrySurface,
                foregroundColor: isLast ? authEntryInk : authEntryText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isLast
                      ? BorderSide.none
                      : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
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
                            pt: 'CONTINUAR', en: 'CONTINUE', es: 'CONTINUAR'),
                    style: AppTypography.buttonText.copyWith(
                      fontFamily: 'HubotSansCondensed',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      LucideIcons.arrowRight,
                      size: 18,
                    ),
                  ],
                ],
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
      duration: const Duration(milliseconds: 300),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: authEntrySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
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
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              slide.body,
              style: AppTypography.bodyMedium.copyWith(
                color: authEntryMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: authEntrySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
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
                        const SizedBox(height: 6),
                        Text(
                          slide.metricValue,
                          style: AppTypography.h2.copyWith(
                            fontFamily: 'JetBrainsMono',
                            color: authEntryText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.12),
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: slide.details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 18,
                          color: authEntryButton,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detail,
                            style: AppTypography.bodyMedium.copyWith(
                              color: authEntryText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
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
