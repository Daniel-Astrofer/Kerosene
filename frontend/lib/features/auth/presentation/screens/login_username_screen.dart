import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'passkey_verification_screen.dart';
/// Username entry screen — first step of the login flow.
/// Navigates to PasskeyVerificationScreen.
class LoginUsernameScreen extends ConsumerStatefulWidget {
  const LoginUsernameScreen({super.key});

  @override
  ConsumerState<LoginUsernameScreen> createState() => _LoginUsernameScreenState();
}

class _LoginUsernameScreenState extends ConsumerState<LoginUsernameScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasskeyVerificationScreen(
            username: _usernameController.text,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CyberBackground(
      useScroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 72),
                  Text(
                    context.l10n.welcomeBack,
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      fontSize: 32,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  CyberTextField(
                    controller: _usernameController,
                    label: context.l10n.username.toUpperCase(),
                    hint: 'astroferas',
                    prefixIcon: Icon(
                      LucideIcons.user,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.required;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 96),

                  BouncingButton(
                    text: context.l10n.continueButton,
                    onPressed: _handleContinue,
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
