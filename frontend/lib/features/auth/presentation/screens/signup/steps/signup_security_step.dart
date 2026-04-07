import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/l10n/l10n_extension.dart';

/// Signup Step: Security Preferences (Redesigned to match Figma images)
class SignupSecurityStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const SignupSecurityStep({super.key, required this.onNext});

  @override
  ConsumerState<SignupSecurityStep> createState() => _SignupSecurityStepState();
}

class _SignupSecurityStepState extends ConsumerState<SignupSecurityStep> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleContinue() {
    final option = SeedSecurityOption.values[_selectedIndex];
    ref.read(signupFlowProvider.notifier).setSeedSecurityOption(option);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      context.l10n.seedStandardTitle,
      'Shamir SLIP-39',
      'Cofre Multisig',
    ];

    return Column(
      children: [
        // Tab Selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tabs.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Pageable Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            children: [
              _SecurityDetail(
                title: context.l10n.seedStandardTitle,
                titleColor: Theme.of(context).colorScheme.secondary,
                description: context.l10n.seedStandardDesc,
                icon: LucideIcons.shield,
                features: const [
                  _FeatureCard(
                    icon: LucideIcons.shieldCheck,
                    title: 'Simplicidade Extrema',
                    subtitle: 'Ideal para uso diário e iniciantes.',
                  ),
                  _FeatureCard(
                    icon: LucideIcons.wallet,
                    title: 'Backup Padrão',
                    subtitle:
                        'Compatível com BIP-39 e a maioria das hardware wallets.',
                  ),
                ],
              ),
              _SecurityDetail(
                title: 'Shamir SLIP-39',
                titleColor: AppColors.warning,
                description:
                    'Divida a semente em varias partes e exija apenas uma fracao delas para restaurar o acesso.',
                icon: LucideIcons.layoutGrid,
                features: const [
                  _FeatureCard(
                    icon: LucideIcons.shieldAlert,
                    title: 'Resiliência a Perdas',
                    subtitle: 'Perder um fragmento não compromete seus fundos.',
                  ),
                  _FeatureCard(
                    icon: LucideIcons.network,
                    title: 'Segurança Distribuída',
                    subtitle:
                        'Distribua partes com pessoas de confiança ou locais seguros.',
                  ),
                ],
              ),
              _SecurityDetail(
                title: 'Cofre Multisig',
                titleColor: Theme.of(context).colorScheme.primary,
                description: context.l10n.seedMultisigDesc,
                icon: LucideIcons.key,
                icon2: LucideIcons.key, // Representing double keys
                features: const [
                  _FeatureCard(
                    icon: LucideIcons.users,
                    title: 'Controle Compartilhado',
                    subtitle:
                        'Distribua a autoridade entre chaves físicas e digitais.',
                  ),
                  _FeatureCard(
                    icon: LucideIcons.landmark,
                    title: 'Proteção Institucional',
                    subtitle:
                        'O mesmo padrão de custódia usado por grandes fundos.',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Button
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
          child: BouncingButton(
            text: context.l10n.continueButton,
            onPressed: _handleContinue,
          ),
        ),
      ],
    );
  }
}

class _SecurityDetail extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String description;
  final IconData icon;
  final IconData? icon2;
  final List<Widget> features;

  const _SecurityDetail({
    required this.title,
    required this.titleColor,
    required this.description,
    required this.icon,
    this.icon2,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0x08FFFFFF),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                              color: const Color(0x14FFFFFF), width: 1),
                        ),
                        child: Stack(
                          children: [
                            // Glow Blur Top Right (overlay-blur)
                            Positioned(
                              top: -95,
                              right: -95,
                              child: Container(
                                width: 256,
                                height: 256,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: titleColor.withOpacity(0.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: titleColor.withOpacity(0.1),
                                      blurRadius: 40,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.xxl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 24),
                                  // Glow Icon Container
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              titleColor.withOpacity(0.15),
                                              titleColor.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color:
                                                  titleColor.withOpacity(0.2)),
                                        ),
                                        child: Center(
                                          child: icon2 != null
                                              ? SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        child: Icon(icon,
                                                            color: titleColor,
                                                            size: 28),
                                                      ),
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Icon(icon2,
                                                            color: titleColor,
                                                            size: 28),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Icon(icon,
                                                  color: titleColor, size: 40),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 48),

                                  Text(
                                    title,
                                    style: AppTypography.h1.copyWith(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  Text(
                                    description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 48),

                                  // Features container container-2
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: features,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w200,
                    fontSize: 11,
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
