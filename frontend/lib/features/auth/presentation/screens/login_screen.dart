import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../controller/auth_controller.dart';
import '../../controller/auth_providers.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'totp_screen.dart';

/// Login screen — username + password authentication.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class LoginScreen extends ConsumerStatefulWidget {
  final String? username;
  const LoginScreen({super.key, this.username});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    if (widget.username != null) {
      _usernameController.text = widget.username!;
    } else {
      _loadSavedCredentials();
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final localDataSource = ref.read(authLocalDataSourceProvider);
      final creds = await localDataSource.getCredentials();
      if (creds != null && mounted) {
        setState(() {
          _usernameController.text = creds['username'] ?? '';
          _passwordController.text = creds['passphrase'] ?? '';
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        return;
      }
      ref.read(authControllerProvider.notifier).login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        final localDataSource = ref.read(authLocalDataSourceProvider);
        if (_rememberMe) {
          await localDataSource.saveCredentials(
            _usernameController.text,
            _passwordController.text,
          );
        } else {
          await localDataSource.removeCredentials();
        }

        if (context.mounted) {
          HomeScreen.skipNextAuth = true;
          Navigator.pushReplacementNamed(context, '/home_loading');
        }
      } else if (next is AuthRequiresLoginTotp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotpScreen(
              username: _usernameController.text,
              passphrase: _passwordController.text,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthError) {
        if (context.mounted) {
          showCustomErrorDialog(
            context,
            ErrorTranslator.translate(context.l10n, next.message),
            onRetry: () {
              ref.read(authControllerProvider.notifier).clearError();
              if (_usernameController.text.isNotEmpty &&
                  _passwordController.text.isNotEmpty) {
                _handleLogin();
              }
            },
            onGoBack: () {
              ref.read(authControllerProvider.notifier).clearError();
              Navigator.pop(context);
            },
          );
        }
      }
    });

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 342),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.l10n.secureAccess,
                      style: Theme.of(context).textTheme.displayLarge!,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.sm),

                    // Logo placeholder
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white10,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.wallet, color: Theme.of(context).colorScheme.onPrimary, size: AppSpacing.md),
                    ),
                    SizedBox(height: AppSpacing.xl),

                    CyberTextField(
                      controller: _usernameController,
                      label: context.l10n.username.toUpperCase(),
                      hint: 'astroferas',
                      prefixIcon: Icon(
                        LucideIcons.user,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                           return context.l10n.required;
                         }
                         return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CyberTextField(
                      controller: _passwordController,
                      label: context.l10n.passphrase.toUpperCase(),
                      hint: '••••••••',
                      prefixIcon: Icon(
                        LucideIcons.lock,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      isPassword: _obscurePassword,
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                           return context.l10n.required;
                         }
                         return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          color: AppColors.white30,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl + AppSpacing.xs),

                    // Remember Me Toggle
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _rememberMe
                                        ? Theme.of(context).colorScheme.primary
                                        : AppColors.white30,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                                  color: _rememberMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                                child: _rememberMe
                                    ? Icon(
                                        LucideIcons.check,
                                        size: 14,
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                      )
                                    : null,
                              ),
                              Text(
                                context.l10n.rememberMe,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: AppColors.white50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.xxl + AppSpacing.sm),

                    // Continue Button
                    BouncingButton(
                      text: context.l10n.continueButton,
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    ),

                    SizedBox(height: AppSpacing.xxl),

                    // Forgot Password & SignUp Link
                    TextButton(
                      onPressed: () {
                        // Action for forgot password
                      },
                      child: Text(
                        context.l10n.forgotPassword,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: Text.rich(
                          TextSpan(
                            text: '${context.l10n.newHere} ',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.textMuted,
                            ),
                            children: [
                              TextSpan(
                                text: context.l10n.signUpNow,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
