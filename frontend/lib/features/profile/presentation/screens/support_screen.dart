import 'package:flutter/material.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildHeader(context),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSupportOption(
                    context,
                    context.l10n.faq,
                    context.l10n.faqDesc,
                    Icons.quiz_rounded,
                    () {},
                  ),
                  _buildSupportOption(
                    context,
                    context.l10n.contactSupport,
                    context.l10n.contactSupportDesc,
                    Icons.support_agent_rounded,
                    () {},
                  ),
                  _buildSupportOption(
                    context,
                    context.l10n.termsOfService,
                    context.l10n.termsOfServiceDesc,
                    Icons.description_rounded,
                    () {},
                  ),
                  _buildSupportOption(
                    context,
                    context.l10n.privacyPolicy,
                    context.l10n.privacyPolicyDesc,
                    Icons.privacy_tip_rounded,
                    () {},
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "KEROSENE v1.0.0",
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.2),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${context.l10n.developedBy} DANIEL-ASTROFER",
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.1),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.7),
                    size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.l10n.helpSupport.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(letterSpacing: 2),
        ),
      ],
    );
  }
}
