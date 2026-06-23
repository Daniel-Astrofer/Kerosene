// ignore_for_file: use_key_in_widget_constructors, unused_element

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';

import 'package:kerosene/features/landing/presentation/kerosene_landing_primitives.dart';
export 'package:kerosene/features/landing/presentation/kerosene_landing_primitives.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_tokens.dart';

class LandingTopNav extends StatelessWidget {
  final VoidCallback onProduct;
  final VoidCallback onSecurity;
  final VoidCallback onBusiness;
  final VoidCallback onInfrastructure;
  final VoidCallback onFaq;

  const LandingTopNav({
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
        color: landingSurface.withValues(alpha: 0.84),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: landingContentMaxWidth),
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
                    LandingBrandMark(label: context.tr.appTitle),
                    if (!compact)
                      Wrap(
                        spacing: 38,
                        children: navItems
                            .map(
                              (item) => LandingNavTextButton(
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
                                (item) => LandingNavTextButton(
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
                        LandingButton(
                          label: context.tr.landingLoginAction,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/admin'),
                        ),
                        LandingButton(
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

class LandingHeroSection extends StatelessWidget {
  final String statusLabel;
  final VoidCallback onCreateAccount;
  final VoidCallback onBusinessPanel;

  const LandingHeroSection({
    required this.statusLabel,
    required this.onCreateAccount,
    required this.onBusinessPanel,
  });

  @override
  Widget build(BuildContext context) {
    return LandingSectionShell(
      topPadding: 128,
      bottomPadding: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LandingEyebrowPill(
                icon: KeroseneIcons.security,
                label: 'BITCOIN INFRAESTRUTURA PRIVADA',
              ),
              const SizedBox(height: 26),
              RichText(
                text: TextSpan(
                  style: landingDisplayStyle(context, compact ? 48 : 72),
                  children: const [
                    TextSpan(text: landingHeroLeadText),
                    TextSpan(
                      text: 'Privado. Anônimo. Global.',
                      style: TextStyle(
                        color: landingGold,
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
                  landingHeroBodyText,
                  style: landingBodyStyle(compact ? 18 : 19),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  LandingButton(
                    label: context.tr.landingCreateAccountAction,
                    filled: true,
                    large: true,
                    onPressed: onCreateAccount,
                  ),
                  LandingButton(
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
                  const LandingAvatarStack(),
                  const SizedBox(width: 16),
                  Text.rich(
                    TextSpan(
                      text: 'Acesse via Tor: ',
                      children: const [
                        TextSpan(
                          text: 'kerosene66...onion',
                          style: TextStyle(color: landingGold),
                        ),
                      ],
                    ),
                    style: landingMonoStyle(landingMuted),
                  ),
                ],
              ),
            ],
          );

          final stage = LandingHeroVaultStage(statusLabel: statusLabel);

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

class LandingProductSection extends StatelessWidget {
  final VoidCallback onCreateAccount;

  const LandingProductSection({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LandingCenteredTitle(text: 'O que a Kerosene faz'),
        const SizedBox(height: 10),
        Container(width: 48, height: 4, color: landingGold),
        const SizedBox(height: 40),
        LandingCardGrid(items: landingProductCards(context), minCardWidth: 340),
      ],
    );
  }
}

class LandingAudienceSection extends StatelessWidget {
  const LandingAudienceSection();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.hexFF0E0E0E,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final people = LandingAudienceColumn(
              title: 'Para Indivíduos',
              subtitle:
                  'Soberania financeira simplificada. Sem perguntas, sem fronteiras.',
              items: const [
                LandingAudienceItem('Privacidade Diária',
                    'Transações indetectáveis para sua segurança pessoal.'),
                LandingAudienceItem('Carteira Segura',
                    'Custódia com padrão institucional no seu celular.'),
                LandingAudienceItem('No-KYC por Design',
                    'Nós não sabemos quem você é, e é assim que deve ser.'),
              ],
              visual: const LandingPhoneImagePanel(),
            );
            final business = LandingAudienceColumn(
              title: 'Para Empresas',
              subtitle:
                  'Infraestrutura robusta para operações corporativas globais.',
              items: const [
                LandingAudienceItem('Modo Administrativo via Tor',
                    'Painel web completo para equipes, acessível apenas por rotas seguras.'),
                LandingAudienceItem('Gestão Multisig',
                    'Controle hierárquico de gastos e aprovações de transações.'),
                LandingAudienceItem('Supervisão de Liquidez',
                    'Monitoramento em tempo real de fluxos e reservas.'),
              ],
              visual: const LandingApiAccessCard(),
              icon: KeroseneIcons.settlement,
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

class LandingArchitectureSection extends StatelessWidget {
  const LandingArchitectureSection();

  @override
  Widget build(BuildContext context) {
    const architectureTitle = 'Arquitetura de Segurança';
    const architectureBody = 'Tecnologia de ponta para cenários sensíveis.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(architectureTitle, style: landingSectionTitleStyle(context, 38)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(architectureBody, style: landingBodyStyle(17)),
        ),
        const SizedBox(height: 34),
        LandingArchitectureRail(items: landingArchitectureCards(context)),
      ],
    );
  }
}

class LandingSecuritySection extends StatelessWidget {
  const LandingSecuritySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.landingSecurityTitle,
          style: landingSectionTitleStyle(context, 38),
        ),
        const SizedBox(height: 22),
        LandingCardGrid(
            items: landingSecurityCards(context), minCardWidth: 310),
      ],
    );
  }
}

class LandingFinalCta extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onBusinessPanel;

  const LandingFinalCta({
    required this.onCreateAccount,
    required this.onBusinessPanel,
  });

  @override
  Widget build(BuildContext context) {
    return LandingGlassPanel(
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
                  style: landingDisplayStyle(context, compact ? 38 : 58),
                  children: const [
                    TextSpan(text: landingSecurityLeadText),
                    TextSpan(
                      text: 'Mais previsibilidade.',
                      style: TextStyle(color: landingGold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  landingStatusCtaBodyText,
                  textAlign: TextAlign.center,
                  style: landingBodyStyle(18),
                ),
              ),
              const SizedBox(height: 34),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  LandingButton(
                    label: 'Começar Agora',
                    filled: true,
                    onPressed: onCreateAccount,
                  ),
                  LandingButton(
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

class LandingFooter extends StatelessWidget {
  final String statusLabel;

  const LandingFooter({required this.statusLabel});

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
          constraints: const BoxConstraints(maxWidth: landingContentMaxWidth),
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
                  LandingBrandMark(label: context.tr.appTitle, compact: true),
                  Text(context.tr.landingFooterRights,
                      style: landingSmallStyle(landingFaint)),
                ],
              ),
              Wrap(
                spacing: 56,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.tr.privacyPolicy,
                      style: landingSmallStyle(landingMuted)),
                  Text(context.tr.landingNavSecurity,
                      style: landingSmallStyle(landingMuted)),
                  Text(context.tr.landingNavBusiness,
                      style: landingSmallStyle(landingMuted)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.tr.landingFooterStatus,
                          style: landingSmallStyle(landingMuted)),
                      const SizedBox(width: 14),
                      LandingStatusDot(
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

class LandingStatusDetails extends StatelessWidget {
  final Map<String, dynamic>? readiness;
  final Map<String, dynamic>? release;
  final bool loading;

  const LandingStatusDetails({
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
            style: landingSectionTitleStyle(context, 42)),
        const SizedBox(height: 14),
        Text(context.tr.landingStatusPageSubtitle, style: landingBodyStyle(17)),
        const SizedBox(height: 28),
        if (loading)
          const LandingSkeletonBlock(height: 220)
        else
          LandingCardGrid(
            minCardWidth: 300,
            items: [
              LandingCardData(
                icon: KeroseneIcons.activity,
                title: context.tr.landingFooterStatus,
                body: landingStatusLabel(context, readiness),
              ),
              LandingCardData(
                icon: KeroseneIcons.settlement,
                title: context.tr.landingStatusRelease,
                body:
                    '${release?['version'] ?? context.tr.landingStatusUnknown} - ${authorized ? context.tr.landingStatusAuthorized : release?['reason'] ?? context.tr.pending}',
              ),
              LandingCardData(
                icon: KeroseneIcons.server,
                title: context.tr.landingStatusService,
                body: '${readiness?['service'] ?? context.tr.appTitle}',
              ),
              LandingCardData(
                icon: KeroseneIcons.globe,
                title: context.tr.landingStatusRegion,
                body:
                    '${readiness?['region'] ?? context.tr.landingStatusUnknown}',
              ),
              LandingCardData(
                icon: KeroseneIcons.biometric,
                title: context.tr.landingStatusBuild,
                body: landingShort(
                    release?['gitCommit'], context.tr.landingStatusUnknown),
              ),
              LandingCardData(
                icon: KeroseneIcons.fileVerified,
                title: context.tr.landingStatusManifest,
                body: landingShort(release?['manifestDigest'],
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
              return LandingCheckPill(
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

class LandingBrandMark extends StatelessWidget {
  final String label;
  final bool compact;

  const LandingBrandMark({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeroseneLogo(size: compact ? 34 : 44, showText: false),
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

class LandingEyebrowPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const LandingEyebrowPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.hexFF2A2A2A,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: landingGold),
          const SizedBox(width: 8),
          Text(label, style: landingMonoStyle(landingMuted)),
        ],
      ),
    );
  }
}

class LandingAvatarStack extends StatelessWidget {
  const LandingAvatarStack();

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.hexFF353534,
      AppColors.hexFF2A2A2A,
      AppColors.hexFF1C1B1B
    ];
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

class LandingHeroVaultStage extends StatelessWidget {
  final String statusLabel;

  const LandingHeroVaultStage({required this.statusLabel});

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
                      color: landingGold.withValues(alpha: 0.18),
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
                      colors: [AppColors.hexFF242424, AppColors.hexFF050505],
                    ),
                  ),
                  child: CustomPaint(painter: const LandingVaultPainter()),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: LandingGlassPanel(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr.landingNetworkStatusLabel,
                            style: landingMonoStyle(landingGold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusLabel == context.tr.landingStatusOnline
                                ? context.tr.landingNetworkOnlineDetail
                                : context.tr.landingNetworkFallbackDetail,
                            style: landingCardTitleStyle(20),
                          ),
                        ],
                      ),
                    ),
                    const Icon(KeroseneIcons.network,
                        color: landingGold, size: 38),
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

class LandingPhoneStage extends StatelessWidget {
  final String statusLabel;

  const LandingPhoneStage({required this.statusLabel});

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
          LandingPhoneMockup(statusLabel: statusLabel),
        ],
      ),
    );
  }
}

class LandingPhoneMockup extends StatelessWidget {
  final String statusLabel;

  const LandingPhoneMockup({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.hexFF030405,
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
                child: LandingStatusDot(
                    online: statusLabel == context.tr.landingStatusOnline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingHeroFeatureStrip extends StatelessWidget {
  final List<LandingCardData> items;

  const LandingHeroFeatureStrip({required this.items});

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
              LandingRoundIcon(icon: item.icon, size: 52),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: landingCardTitleStyle(15)),
                    const SizedBox(height: 5),
                    Text(item.body,
                        style: landingSmallStyle(landingMuted)
                            .copyWith(height: 1.35)),
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

class LandingCardGrid extends StatelessWidget {
  final List<LandingCardData> items;
  final double minCardWidth;

  const LandingCardGrid({
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
                  child: LandingFeatureCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class LandingFeatureCard extends StatelessWidget {
  final LandingCardData data;

  const LandingFeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return LandingGlassPanel(
      padding: const EdgeInsets.all(32),
      borderColor:
          data.highlighted ? landingGold.withValues(alpha: 0.72) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandingSquareIcon(icon: data.icon, active: data.highlighted),
          const SizedBox(height: 24),
          Text(data.title, style: landingCardTitleStyle(22)),
          const SizedBox(height: 12),
          Text(data.body, style: landingBodyStyle(16)),
        ],
      ),
    );
  }
}
