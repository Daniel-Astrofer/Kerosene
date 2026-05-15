import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import '../../../../l10n/l10n_extension.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  final PageController _pageController = PageController();
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

  List<_PresentationSlide> _getSlides(BuildContext context) {
    return [
      _PresentationSlide(
        eyebrow: _copy(
          context: context,
          pt: 'INFRAESTRUTURA PRIVADA',
          en: 'PRIVATE INFRASTRUCTURE',
          es: 'INFRAESTRUCTURA PRIVADA',
        ),
        title: _copy(
          context: context,
          pt: 'Privacidade e defesa desde o primeiro acesso',
          en: 'Privacy and defense from the first access',
          es: 'Privacidad y defensa desde el primer acceso',
        ),
        summary: _copy(
          context: context,
          pt: 'A plataforma opera sobre rede onion e ambiente protegido para reduzir exposição, interferência externa e correlação indevida de tráfego.',
          en: 'The platform operates over the onion network and a protected environment to reduce exposure, external interference, and improper traffic correlation.',
          es: 'La plataforma opera sobre la red onion y un entorno protegido para reducir exposición, interferencia externa y correlación indebida de tráfico.',
        ),
        highlights: [
          _copy(
            context: context,
            pt: 'Roteamento onion por padrão',
            en: 'Onion routing by default',
            es: 'Enrutamiento onion por defecto',
          ),
          _copy(
            context: context,
            pt: 'Superfície de ataque reduzida',
            en: 'Reduced attack surface',
            es: 'Superficie de ataque reducida',
          ),
          _copy(
            context: context,
            pt: 'Segurança tratada como arquitetura, não como recurso opcional',
            en: 'Security treated as architecture, not as an optional feature',
            es: 'La seguridad tratada como arquitectura, no como una función opcional',
          ),
        ],
        note: _copy(
          context: context,
          pt: 'Segurança não é um modo de uso. É a base operacional do sistema.',
          en: 'Security is not a usage mode. It is the operational foundation of the system.',
          es: 'La seguridad no es un modo de uso. Es la base operativa del sistema.',
        ),
        icon: LucideIcons.shield,
      ),
      _PresentationSlide(
        eyebrow: _copy(
          context: context,
          pt: 'ONBOARDING CONTROLADO',
          en: 'CONTROLLED ONBOARDING',
          es: 'ONBOARDING CONTROLADO',
        ),
        title: _copy(
          context: context,
          pt: 'Criação de conta com custo econômico verificável',
          en: 'Account creation with a verifiable economic cost',
          es: 'Creación de cuenta con costo económico verificable',
        ),
        summary: _copy(
          context: context,
          pt: 'O depósito inicial de 0.003 BTC permanece na sua conta. Apenas a taxa de rede necessária para confirmação é consumida no processo.',
          en: 'The initial 0.003 BTC deposit remains in your account. Only the network fee required for confirmation is consumed during the process.',
          es: 'El depósito inicial de 0.003 BTC permanece en tu cuenta. Solo se consume la tarifa de red necesaria para la confirmación.',
        ),
        highlights: [
          _copy(
            context: context,
            pt: 'Aumenta o custo de automação abusiva',
            en: 'Raises the cost of abusive automation',
            es: 'Aumenta el costo de la automatización abusiva',
          ),
          _copy(
            context: context,
            pt: 'Reduz criação massiva de contas',
            en: 'Reduces mass account creation',
            es: 'Reduce la creación masiva de cuentas',
          ),
          _copy(
            context: context,
            pt: 'Protege estabilidade operacional para toda a base',
            en: 'Protects operational stability for the whole user base',
            es: 'Protege la estabilidad operativa de toda la base',
          ),
        ],
        note: _copy(
          context: context,
          pt: 'Não é mensalidade nem assinatura. É uma barreira técnica contra abuso.',
          en: 'It is not a subscription or monthly fee. It is a technical barrier against abuse.',
          es: 'No es una suscripción ni una mensualidad. Es una barrera técnica contra el abuso.',
        ),
        icon: LucideIcons.wallet,
      ),
      _PresentationSlide(
        eyebrow: _copy(
          context: context,
          pt: 'POLÍTICA OPERACIONAL',
          en: 'OPERATING POLICY',
          es: 'POLÍTICA OPERATIVA',
        ),
        title: _copy(
          context: context,
          pt: 'Tarifas previsíveis e leitura financeira clara',
          en: 'Predictable fees and clear financial reading',
          es: 'Tarifas predecibles y lectura financiera clara',
        ),
        summary: _copy(
          context: context,
          pt: 'Depósitos e saques seguem uma política fixa. Transferências internas permanecem instantâneas e sem custo entre usuários da plataforma.',
          en: 'Deposits and withdrawals follow a fixed policy. Internal transfers remain instant and free between platform users.',
          es: 'Los depósitos y retiros siguen una política fija. Las transferencias internas siguen siendo instantáneas y gratuitas entre usuarios de la plataforma.',
        ),
        highlights: [
          _copy(
            context: context,
            pt: '0.9% em depósitos',
            en: '0.9% on deposits',
            es: '0.9% en depósitos',
          ),
          _copy(
            context: context,
            pt: '0.9% em saques',
            en: '0.9% on withdrawals',
            es: '0.9% en retiros',
          ),
          _copy(
            context: context,
            pt: '0% em transferências internas',
            en: '0% on internal transfers',
            es: '0% en transferencias internas',
          ),
        ],
        note: _copy(
          context: context,
          pt: 'Sem tarifas ocultas e sem variações inesperadas no fluxo principal.',
          en: 'No hidden fees and no unexpected variations in the main flow.',
          es: 'Sin tarifas ocultas ni variaciones inesperadas en el flujo principal.',
        ),
        icon: LucideIcons.percent,
      ),
      _PresentationSlide(
        eyebrow: _copy(
          context: context,
          pt: 'COMPROMISSO DA PLATAFORMA',
          en: 'PLATFORM COMMITMENT',
          es: 'COMPROMISO DE LA PLATAFORMA',
        ),
        title: _copy(
          context: context,
          pt: 'Operação estável, auditável e construída para durar',
          en: 'Stable, auditable operation built to last',
          es: 'Operación estable, auditable y construida para durar',
        ),
        summary: _copy(
          context: context,
          pt: 'A Kerosene prioriza estabilidade técnica, transparência operacional e previsibilidade de custo antes de crescimento superficial ou efeitos visuais.',
          en: 'Kerosene prioritizes technical stability, operational transparency, and cost predictability before superficial growth or visual effects.',
          es: 'Kerosene prioriza estabilidad técnica, transparencia operativa y previsibilidad de costos antes que crecimiento superficial o efectos visuales.',
        ),
        highlights: [
          _copy(
            context: context,
            pt: 'Processos desenhados para longo prazo',
            en: 'Processes designed for the long term',
            es: 'Procesos diseñados para el largo plazo',
          ),
          _copy(
            context: context,
            pt: 'Leitura de risco e custo sempre explícita',
            en: 'Risk and cost reading kept explicit',
            es: 'Lectura de riesgo y costo siempre explícita',
          ),
          _copy(
            context: context,
            pt: 'Infraestrutura sólida acima de retórica promocional',
            en: 'Solid infrastructure above promotional rhetoric',
            es: 'Infraestructura sólida por encima de la retórica promocional',
          ),
        ],
        note: _copy(
          context: context,
          pt: 'A proposta é soberania operacional com previsibilidade, não espetáculo.',
          en: 'The proposition is operational sovereignty with predictability, not spectacle.',
          es: 'La propuesta es soberanía operativa con previsibilidad, no espectáculo.',
        ),
        icon: LucideIcons.trendingUp,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalSlides) {
    if (_currentPage < totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishPresentation() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF07090E),
              Color(0xFF0B1017),
              Color(0xFF050608),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'KEROSENE',
                            style: AppTypography.buttonText.copyWith(
                              fontSize: 12,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finishPresentation,
                      child: Text(
                        context.l10n.presentationSkip,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _copy(
                      context: context,
                      pt: 'Onboarding institucional',
                      en: 'Institutional onboarding',
                      es: 'Onboarding institucional',
                    ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white50,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(
                      context: context,
                      slide: slides[index],
                      index: index,
                      totalSlides: slides.length,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
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
                              _copy(
                                context: context,
                                pt: 'Etapa ${_currentPage + 1} de ${slides.length}',
                                en: 'Step ${_currentPage + 1} of ${slides.length}',
                                es: 'Paso ${_currentPage + 1} de ${slides.length}',
                              ),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white50,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(
                                slides.length,
                                (index) => Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: index == slides.length - 1 ? 0 : 8,
                                    ),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _currentPage >= index
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Colors.white
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      BouncingButton(
                        width: _currentPage == slides.length - 1 ? 190 : 128,
                        text: _currentPage == slides.length - 1
                            ? context.l10n.presentationStart
                            : context.l10n.presentationNext,
                        onPressed: () {
                          if (_currentPage == slides.length - 1) {
                            _finishPresentation();
                          } else {
                            _nextPage(slides.length);
                          }
                        },
                        icon: _currentPage < slides.length - 1
                            ? LucideIcons.arrowRight
                            : null,
                        color: _currentPage == slides.length - 1
                            ? null
                            : Colors.transparent,
                        variant: _currentPage == slides.length - 1
                            ? BouncingButtonVariant.solid
                            : BouncingButtonVariant.outlined,
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

  Widget _buildSlide({
    required BuildContext context,
    required _PresentationSlide slide,
    required int index,
    required int totalSlides,
    required bool isActive,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: isActive ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: isActive ? Offset.zero : const Offset(0, 0.05),
        curve: Curves.easeOutCubic,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 680),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 22,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _copy(
                                  context: context,
                                  pt: 'BLOCO ${index + 1}/$totalSlides',
                                  en: 'BLOCK ${index + 1}/$totalSlides',
                                  es: 'BLOQUE ${index + 1}/$totalSlides',
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white50,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            slide.eyebrow,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white50,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.title,
                            style: AppTypography.h1.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.summary,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: slide.highlights
                                  .map(
                                    (point) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin:
                                                const EdgeInsets.only(top: 7),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.9),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              point,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10161F),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              slide.note,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _PresentationSlide {
  final String eyebrow;
  final String title;
  final String summary;
  final List<String> highlights;
  final String note;
  final IconData icon;

  _PresentationSlide({
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.highlights,
    required this.note,
    required this.icon,
  });
}
