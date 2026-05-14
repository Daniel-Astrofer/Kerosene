import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import '../../../../core/providers/biometric_provider.dart';
import '../../../security/presentation/screens/sovereignty_status_screen.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // ─── Sovereignty Status ───
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SovereigntyStatusScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.sovereigntyStatus,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.l10n.sovereigntyStatusDesc,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Biometrics
                  Consumer(
                    builder: (context, ref, child) {
                      final bioState = ref.watch(biometricProvider);
                      if (!bioState.isSupported) {
                        return const SizedBox.shrink();
                      }

                      return _buildSwitchItem(
                        context,
                        context.l10n.biometricAuth,
                        context.l10n.biometricAuthDesc,
                        bioState.isEnabled,
                        (value) {
                          ref
                              .read(biometricProvider.notifier)
                              .toggleBiometric(value);
                        },
                        Icons.fingerprint_rounded,
                      );
                    },
                  ),

                  // Change PIN
                  _buildActionItem(
                    context,
                    context.l10n.changePin,
                    context.l10n.changePinDesc,
                    Icons.lock_outline_rounded,
                    () {},
                  ),

                  // Change Password
                  _buildActionItem(
                    context,
                    context.l10n.changePassword,
                    context.l10n.changePasswordDesc,
                    Icons.password_rounded,
                    () {},
                  ),

                  // 2FA
                  _buildSwitchItem(
                    context,
                    context.l10n.twoFactorAuth,
                    context.l10n.twoFactorAuthDesc,
                    false, // Mock state
                    (value) {}, // Mock action
                    Icons.security_rounded,
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            context.l10n.enableTwoFactorInfo,
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.7),
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
    );
  }

  Widget _buildSwitchItem(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            inactiveThumbColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            inactiveTrackColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
          ),
        ],
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
          context.l10n.security.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildActionItem(
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
}
