import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';

/// Signup Step 1: Username
class SignupUsernameStep extends StatefulWidget {
  final String initialUsername;
  final ValueChanged<String> onNext;

  const SignupUsernameStep({
    super.key,
    required this.initialUsername,
    required this.onNext,
  });

  @override
  State<SignupUsernameStep> createState() => _SignupUsernameStepState();
}

class _SignupUsernameStepState extends State<SignupUsernameStep> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'O nome de usuário é obrigatório');
    } else if (text.length < 3) {
      setState(() => _errorText = 'No mínimo 3 caracteres');
    } else if (!RegExp(r'^[a-z0-9_]+$').hasMatch(text)) {
      setState(() => _errorText = 'Apenas letras minúsculas, números e "_"');
    } else {
      setState(() => _errorText = null);
      widget.onNext(text);
    }
  }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'ESCOLHA SEU USERNAME',
                      style: Theme.of(context).textTheme.displayLarge!,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Este será o seu identificador universal no ecossistema Kerosene.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 48),
                    
                    CyberTextField(
                      controller: _controller,
                      label: 'USERNAME',
                      hint: 'ex: username',
                      errorText: _errorText,
                      prefixIcon: Icon(LucideIcons.user, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    
                    const Spacer(),
                    const SizedBox(height: 32),
                    
                    BouncingButton(
                      text: 'Continuar',
                      onPressed: _validateAndSubmit,
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
}
