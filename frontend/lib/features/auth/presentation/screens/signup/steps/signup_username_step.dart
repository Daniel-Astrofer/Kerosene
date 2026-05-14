import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';

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
  static const _adjectives = [
    'atlas',
    'brisa',
    'claro',
    'delta',
    'nexus',
    'orbita',
    'prisma',
    'solis',
    'vetor',
    'zenit',
  ];

  static const _nouns = [
    'vault',
    'node',
    'river',
    'prime',
    'wave',
    'grid',
    'lumen',
    'stone',
    'field',
    'signal',
  ];

  final _random = Random.secure();
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _errorText = _validate(widget.initialUsername.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _normalizeInput(String value) {
    final sanitized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final normalized = sanitized.substring(0, sanitized.length.clamp(0, 15));

    if (normalized != value) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    setState(() {
      _errorText = _validate(normalized);
    });
  }

  String _generateUsername() {
    for (var attempt = 0; attempt < 20; attempt++) {
      final adjective = _adjectives[_random.nextInt(_adjectives.length)];
      final noun = _nouns[_random.nextInt(_nouns.length)];
      final number = (100 + _random.nextInt(900)).toString();
      final candidate = '${adjective}_$noun$number';
      if (candidate.length <= 15) {
        return candidate;
      }
    }

    return 'node${100 + _random.nextInt(900)}';
  }

  String? _validate(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return AppCopy.signupUsernameValidationRequired.resolve(context);
    }
    if (text.length < 3) {
      return AppCopy.signupUsernameValidationMin.resolve(context);
    }
    if (text.length > 15) {
      return AppCopy.signupUsernameValidationMax.resolve(context);
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(text)) {
      return AppCopy.signupUsernameValidationCharset.resolve(context);
    }
    return null;
  }

  void _generateAutomatically() {
    final username = _generateUsername();
    _controller.value = TextEditingValue(
      text: username,
      selection: TextSelection.collapsed(offset: username.length),
    );
    setState(() {
      _errorText = null;
    });
  }

  void _validateAndSubmit() {
    final text = _controller.text.trim();
    final validation = _validate(text);
    if (validation != null) {
      setState(() => _errorText = validation);
      return;
    }

    setState(() => _errorText = null);
    widget.onNext(text);
  }

  @override
  Widget build(BuildContext context) {
    final current = _controller.text.trim();
    final preview = current.isEmpty
        ? AppCopy.signupUsernamePreviewPlaceholder.resolve(context)
        : current;
    final canContinue = _validate(current) == null;

    return SignupStepLayout(
      eyebrow: AppCopy.signupUsernameEyebrow.resolve(context),
      title: AppCopy.signupUsernameTitle.resolve(context),
      subtitle: AppCopy.signupUsernameSubtitle.resolve(context),
      icon: LucideIcons.user,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupUsernameHighlightLabel.resolve(context),
      highlightValue: '@$preview',
      highlightHint: canContinue
          ? AppCopy.signupUsernameHighlightReady.resolve(context)
          : AppCopy.signupUsernameHighlightPending.resolve(context),
      chips: [
        AppCopy.signupUsernameChipLength.resolve(context),
        AppCopy.signupUsernameChipCharset.resolve(context),
        AppCopy.signupUsernameChipUnderscore.resolve(context),
      ],
      footer: SignupPrimaryFooter(
        text: AppCopy.signupUsernameContinue.resolve(context),
        onPressed: _validateAndSubmit,
        icon: LucideIcons.arrowRight,
      ),
      children: [
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.signupUsernameLabel.resolve(context),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              CyberTextField(
                controller: _controller,
                label: AppCopy.signupUsernameLabel.resolve(context),
                hint: AppCopy.signupUsernameHint.resolve(context),
                errorText: _errorText,
                onChanged: _normalizeInput,
                prefixIcon: Icon(
                  LucideIcons.atSign,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  tooltip:
                      AppCopy.signupUsernameGenerateTooltip.resolve(context),
                  onPressed: _generateAutomatically,
                  icon: Icon(
                    LucideIcons.dices,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SignupTag(
                    label: canContinue
                        ? AppCopy.signupUsernameValidTag.resolve(context)
                        : AppCopy.signupUsernameAdjustTag.resolve(context),
                    tone: canContinue
                        ? SignupSurfaceTone.success
                        : SignupSurfaceTone.warning,
                    icon: canContinue
                        ? LucideIcons.badgeCheck
                        : LucideIcons.alertTriangle,
                  ),
                  SignupTag(
                    label: AppCopy.signupUsernameNoSpaces.resolve(context),
                  ),
                  SignupTag(
                    label: AppCopy.signupUsernameNoUppercase.resolve(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.signupUsernameSpeedTitle.resolve(context),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppCopy.signupUsernameSpeedBody.resolve(context),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: _generateAutomatically,
                icon: Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                label: Text(
                  AppCopy.signupUsernameSuggestNow.resolve(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: LucideIcons.shieldCheck,
          title: AppCopy.signupUsernameNoticeTitle.resolve(context),
          message: AppCopy.signupUsernameNoticeBody.resolve(context),
          tone: SignupSurfaceTone.primary,
        ),
      ],
    );
  }
}
