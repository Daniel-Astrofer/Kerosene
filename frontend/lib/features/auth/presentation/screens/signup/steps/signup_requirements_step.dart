import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';

class SignupRequirementsStep extends StatelessWidget {
  final VoidCallback onNext;

  const SignupRequirementsStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    
                    // Icon with glow
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              Theme.of(context).colorScheme.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.md),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.shieldCheck,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    Text(
                      'Antes de Começar',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(AppSpacing.lg),
                        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Para fazer parte de nosso serviço é necessário pagar uma ',
                            ),
                            TextSpan(
                              text: 'taxa de inscrição ',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: 'cobrada na criação da conta, '),
                            TextSpan(
                              text: 'que vai diretamente para sua conta ',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(
                              text: 'descontado as taxas de transação e de serviço.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildStepItem(
                      icon: LucideIcons.smartphone,
                      content: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'É aconselhável baixar um aplicativo autenticador de ',
                            ),
                            TextSpan(
                              text: 'Two-Factor-Authentication ',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(
                              text: 'para não perder acesso a sua conta.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildStepItem(
                      icon: LucideIcons.penTool,
                      content: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Salve suas senhas fisicamente',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(
                              text: ', se caso perder suas senhas ou segredos, ',
                            ),
                            TextSpan(
                              text: 'a conta será perdida para sempre sem chance de recuperação',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 32),

                    BouncingButton(
                      text: 'Estou Ciente e Continuar',
                      onPressed: onNext,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStepItem({required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: content),
        ],
      ),
    );
  }
}
