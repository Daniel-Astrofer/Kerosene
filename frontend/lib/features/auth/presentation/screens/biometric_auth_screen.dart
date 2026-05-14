import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/security/biometric_service.dart';

/// Biometric authentication dialog — triggered for secure vault access.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: const BiometricAuthScreen(),
        );
      },
    );
    return result ?? false;
  }

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), _triggerBiometrics);
    });
  }

  Future<void> _triggerBiometrics() async {
    final success = await _biometricService.authenticate(
      localizedReason: context.l10n.secureAccess,
    );
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Close Button
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl + AppSpacing.xl),

              // Welcome Texts
              Text(
                context.l10n.welcomeBack,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Text(
                context.l10n.secureAccess,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // Fingerprint Scanner UI Graphic
              Center(
                child: GestureDetector(
                  onTap: _triggerBiometrics,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Glow Circles
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        // Fingerprint Icon
                        Icon(
                          LucideIcons.fingerprint,
                          color: Theme.of(context).colorScheme.primary,
                          size: 56,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Text
              Text(
                context.l10n.biometricAuthDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.verifyingDevice,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: AppSpacing.xxl + AppSpacing.xl),

              // Alternative Login Button (Use PIN)
              InkWell(
                onTap: () => Navigator.of(context).pop(false),
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.keyRound,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        context.l10n.changePassword,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              // Bottom Handle Bar
              Center(
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
