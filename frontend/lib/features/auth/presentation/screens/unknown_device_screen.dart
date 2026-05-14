import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../controller/auth_controller.dart';
import '../../controller/auth_local_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Screen shown when the API returns an "unknown device" error during login.
/// The user must enter their TOTP code from their authenticator app to link
/// the new device to their account.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class UnknownDeviceScreen extends ConsumerStatefulWidget {
  final String username;
  final String passphrase;
  final bool rememberMe;
  final String? preAuthToken;

  const UnknownDeviceScreen({
    super.key,
    required this.username,
    required this.passphrase,
    this.rememberMe = false,
    this.preAuthToken,
  });

  @override
  ConsumerState<UnknownDeviceScreen> createState() =>
      _UnknownDeviceScreenState();
}

class _UnknownDeviceScreenState extends ConsumerState<UnknownDeviceScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        if (widget.rememberMe) {
          final localDataSource = ref.read(authLocalDataSourceProvider);
          await localDataSource.saveCredentials(
            widget.username,
            widget.passphrase,
          );
        }
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.toString()),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            if (_codeController.text.length == 6) {
              _handleVerify();
            } else {
              _codeController.clear();
            }
          },
          onGoBack: () {
            ref.read(authControllerProvider.notifier).clearError();
            Navigator.pop(context);
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.md,
                    left: AppSpacing.sm,
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.xl),

                      // ── Warning Banner ──
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.sm + AppSpacing.xs),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Text(
                                context.l10n.unknownDeviceBanner,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.xxl + AppSpacing.md),

                      // ── Pulsing Device Icon ──
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.smartphone,
                            size: 48,
                            color: AppColors.warning,
                          ),
                        ),
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // ── Title ──
                      Text(
                        context.l10n.unknownDeviceTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge!,
                      ),

                      SizedBox(height: AppSpacing.sm + AppSpacing.xs),

                      Text(
                        context.l10n.unknownDeviceDesc,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.6,
                            ),
                      ),

                      SizedBox(height: AppSpacing.sm + AppSpacing.xs),

                      // ── Username chip ──
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md - 2,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.xl),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 14,
                              color: AppColors.white50,
                            ),
                            SizedBox(width: AppSpacing.xs + 2),
                            Text(
                              widget.username,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: AppColors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.xxl + AppSpacing.md),

                      // ── TOTP Input ──
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    letterSpacing: 10,
                                  ),
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                if (value.length == 6 && !isLoading) {
                                  _handleVerify();
                                }
                              },
                              decoration: InputDecoration(
                                counterText: "",
                                hintText: context.l10n.unknownDeviceInputHint,
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.08),
                                      letterSpacing: 10,
                                    ),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.md),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.md),
                                  borderSide: BorderSide(
                                    color: AppColors.warning,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.md),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context
                                      .l10n.unknownDeviceInputErrorEmpty;
                                }
                                if (value.length != 6) {
                                  return context
                                      .l10n.unknownDeviceInputErrorLength;
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: AppSpacing.sm + AppSpacing.xs),

                            Text(
                              context.l10n.unknownDeviceHelper,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.35),
                                  ),
                            ),

                            SizedBox(height: AppSpacing.xxl + AppSpacing.sm),

                            // ── Verify Button ──
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                  disabledBackgroundColor:
                                      AppColors.warning.withValues(alpha: 0.4),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.link,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          SizedBox(width: AppSpacing.sm),
                                          Text(
                                            context.l10n.unknownDeviceAction,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // ── Security Note ──
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.sm + AppSpacing.xs),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.3),
                            ),
                            SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Text(
                                context.l10n.unknownDeviceSecurityNote,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.3),
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.xxl),
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

  void _handleVerify() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ref.read(authControllerProvider.notifier).verifyLoginTotp(
            username: widget.username,
            passphrase: widget.passphrase,
            totpCode: _codeController.text,
            preAuthToken: widget.preAuthToken,
          );
    }
  }
}
