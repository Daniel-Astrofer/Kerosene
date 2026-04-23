import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/presentation/models/signup_seed_material.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

final Set<String> _signupBip39WordSet = {
  ...Language.english.list,
  ...Language.portuguese.list,
  ...Language.spanish.list,
};
final List<String> _signupBip39Words = _signupBip39WordSet.toList()..sort();

List<String> _signupBip39Suggestions(String prefix) {
  if (prefix.length < 2) {
    return const [];
  }

  final normalized = prefix.toLowerCase();
  return _signupBip39Words
      .where((word) => word.startsWith(normalized))
      .take(5)
      .toList();
}

bool _isValidSignupBip39Word(String word) {
  if (word.isEmpty) {
    return false;
  }

  return _signupBip39WordSet.contains(word.toLowerCase());
}

class SignupVerificationStep extends StatefulWidget {
  final SignupSeedMaterial? seedMaterial;
  final VoidCallback onNext;

  const SignupVerificationStep({
    super.key,
    required this.seedMaterial,
    required this.onNext,
  });

  @override
  State<SignupVerificationStep> createState() => _SignupVerificationStepState();
}

class _SignupVerificationStepState extends State<SignupVerificationStep> {
  final Map<int, TextEditingController> _controllers = {};
  List<int> _verificationIndices = const [];
  String? _errorText;
  bool _slip39Confirmed = false;

  @override
  void initState() {
    super.initState();
    _syncWithSeedMaterial();
  }

  @override
  void didUpdateWidget(covariant SignupVerificationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedMaterial != widget.seedMaterial) {
      setState(_syncWithSeedMaterial);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncWithSeedMaterial() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _verificationIndices = const [];
    _errorText = null;
    _slip39Confirmed = false;

    final seedMaterial = widget.seedMaterial;
    if (seedMaterial == null || seedMaterial.usesSlip39) {
      return;
    }

    _verificationIndices = _buildVerificationIndices(
      seedMaterial.primaryWords.length,
    );

    for (final index in _verificationIndices) {
      _controllers[index] = TextEditingController();
    }
  }

  List<int> _buildVerificationIndices(int wordCount) {
    final indices = <int>{
      1,
      wordCount ~/ 2,
      wordCount - 2,
    }..removeWhere((index) => index < 0 || index >= wordCount);

    for (var index = 0; indices.length < 3 && index < wordCount; index += 2) {
      indices.add(index);
    }

    final result = indices.toList()..sort();
    return result.take(3).toList();
  }

  String _normalizeWord(String value) {
    return value.trim().toLowerCase();
  }

  String _progressText() {
    return _filledCount.toString() +
        '/' +
        _verificationIndices.length.toString();
  }

  String _slip39QuorumText(SignupSeedMaterial seedMaterial) {
    return seedMaterial.slip39Threshold.toString() +
        '/' +
        seedMaterial.slip39TotalShares.toString();
  }

  int get _filledCount {
    return _verificationIndices
        .where(
          (index) => (_controllers[index]?.text.trim().isNotEmpty ?? false),
        )
        .length;
  }

  bool get _isPhraseReady {
    return _verificationIndices.isNotEmpty &&
        _verificationIndices.every(
          (index) => _controllers[index]?.text.trim().isNotEmpty ?? false,
        );
  }

  bool _isPhraseValid(SignupSeedMaterial seedMaterial) {
    return _verificationIndices.every(
      (index) =>
          _normalizeWord(_controllers[index]?.text ?? '') ==
          _normalizeWord(seedMaterial.primaryWords[index]),
    );
  }

  void _clearErrorIfNeeded() {
    if (_errorText == null) {
      return;
    }

    setState(() {
      _errorText = null;
    });
  }

  void _submit() {
    final seedMaterial = widget.seedMaterial;
    if (seedMaterial == null) {
      return;
    }

    if (seedMaterial.usesSlip39) {
      if (_slip39Confirmed) {
        widget.onNext();
      }
      return;
    }

    if (!_isPhraseValid(seedMaterial)) {
      setState(() {
        _errorText = AppCopy.signupVerificationError.resolve(context);
      });
      return;
    }

    setState(() {
      _errorText = null;
    });
    widget.onNext();
  }

  IconData _iconForSeed(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial?.usesSlip39 ?? false) {
      return LucideIcons.layoutGrid;
    }
    if (seedMaterial?.usesMultisig ?? false) {
      return LucideIcons.shieldCheck;
    }
    return LucideIcons.badgeCheck;
  }

  String _titleForSeed(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial?.usesSlip39 ?? false) {
      return AppCopy.signupVerificationSlip39Title.resolve(context);
    }
    return AppCopy.signupVerificationTitle.resolve(context);
  }

  String _subtitleForSeed(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial == null) {
      return AppCopy.signupVerificationSubtitle(
        context,
        missingCount: 3,
      );
    }

    if (seedMaterial.usesSlip39) {
      return AppCopy.signupFlowStepDescription(
        context,
        step: 4,
        securityOption: seedMaterial.securityOption.name,
      );
    }

    return AppCopy.signupVerificationSubtitle(
      context,
      missingCount: _verificationIndices.length,
    );
  }

  List<String> _chipsForSeed(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial == null) {
      return const [];
    }

    final chips = <String>[
      AppCopy.signupFlowSecurityLabel(
        context,
        option: seedMaterial.securityOption.name,
      ),
    ];

    if (seedMaterial.usesSlip39) {
      chips.add(
        context.l10n.slip39SharesSubtitle(
          seedMaterial.slip39Threshold,
          seedMaterial.slip39TotalShares,
        ),
      );
    } else if (seedMaterial.usesMultisig) {
      chips.add(context.l10n.twoFaPrimaryBadge);
      chips.add(context.l10n.twoFaBackupBadge);
    }

    return chips;
  }

  bool _canContinue(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial == null) {
      return false;
    }
    if (seedMaterial.usesSlip39) {
      return _slip39Confirmed;
    }
    return _isPhraseReady;
  }

  List<Widget> _buildChildren(SignupSeedMaterial? seedMaterial) {
    if (seedMaterial == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (seedMaterial.usesSlip39) {
      return _buildSlip39Children(seedMaterial);
    }

    return _buildPhraseChildren(seedMaterial);
  }

  List<Widget> _buildPhraseChildren(SignupSeedMaterial seedMaterial) {
    return [
      if (seedMaterial.usesMultisig)
        SignupInlineNotice(
          icon: LucideIcons.shieldAlert,
          title: context.l10n.twoFaBackupTitle,
          message: context.l10n.twoFaBackupSubtitle,
          tone: SignupSurfaceTone.warning,
        ),
      if (seedMaterial.usesMultisig) const SizedBox(height: AppSpacing.md),
      SignupPanel(
        tone: SignupSurfaceTone.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.signupVerificationFillHighlighted.resolve(context),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 520 ? 1 : 2;
                final spacing = AppSpacing.md;
                final itemWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - spacing) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(
                    seedMaterial.primaryWords.length,
                    (index) => SizedBox(
                      width: itemWidth,
                      child: _WordCard(
                        positionLabel: (index + 1).toString(),
                        word: seedMaterial.primaryWords[index],
                        controller: _controllers[index],
                        highlighted: _verificationIndices.contains(index),
                        onChanged: (_) {
                          _clearErrorIfNeeded();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      if (_errorText != null) ...[
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: LucideIcons.alertTriangle,
          title: AppCopy.signupVerificationTitle.resolve(context),
          message: _errorText!,
          tone: SignupSurfaceTone.warning,
        ),
      ],
    ];
  }

  List<Widget> _buildSlip39Children(SignupSeedMaterial seedMaterial) {
    return [
      SignupPanel(
        tone: SignupSurfaceTone.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.slip39SharesTitle,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.slip39SharesSubtitle(
                seedMaterial.slip39Threshold,
                seedMaterial.slip39TotalShares,
              ),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(seedMaterial.slip39Shares.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == seedMaterial.slip39Shares.length - 1
                      ? 0
                      : AppSpacing.md,
                ),
                child: _ShareReviewCard(
                  label: context.l10n.slip39ShareLabel(
                    index + 1,
                    seedMaterial.slip39Shares.length,
                  ),
                  share: seedMaterial.slip39Shares[index],
                ),
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SignupPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _slip39Confirmed,
              onChanged: (value) {
                setState(() {
                  _slip39Confirmed = value ?? false;
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  AppCopy.signupSeedConfirmationSlip39(
                    context,
                    threshold: seedMaterial.slip39Threshold,
                    totalShares: seedMaterial.slip39TotalShares,
                  ),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        height: 1.45,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final seedMaterial = widget.seedMaterial;
    final usesSlip39 = seedMaterial?.usesSlip39 ?? false;

    return SignupStepLayout(
      eyebrow: AppCopy.signupFlowPhaseProtection.resolve(context),
      title: _titleForSeed(seedMaterial),
      subtitle: _subtitleForSeed(seedMaterial),
      icon: _iconForSeed(seedMaterial),
      tone: SignupSurfaceTone.primary,
      highlightLabel: usesSlip39
          ? context.l10n.slip39SharesTitle
          : AppCopy.signupVerificationFillHighlighted.resolve(context),
      highlightValue: usesSlip39 && seedMaterial != null
          ? _slip39QuorumText(seedMaterial)
          : _progressText(),
      highlightHint: usesSlip39 && seedMaterial != null
          ? context.l10n.slip39SharesSubtitle(
              seedMaterial.slip39Threshold,
              seedMaterial.slip39TotalShares,
            )
          : AppCopy.signupVerificationFillHighlighted.resolve(context),
      chips: _chipsForSeed(seedMaterial),
      children: _buildChildren(seedMaterial),
      footer: SignupPrimaryFooter(
        text: AppCopy.signupVerificationContinue.resolve(context),
        onPressed: _canContinue(seedMaterial) ? _submit : null,
        icon: LucideIcons.arrowRight,
      ),
    );
  }
}

class _WordCard extends StatefulWidget {
  final String positionLabel;
  final String word;
  final TextEditingController? controller;
  final bool highlighted;
  final ValueChanged<String>? onChanged;

  const _WordCard({
    required this.positionLabel,
    required this.word,
    required this.controller,
    required this.highlighted,
    required this.onChanged,
  });

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  late final FocusNode _focusNode;
  List<String> _suggestions = const [];
  bool _hasTyped = false;

  String get _normalizedInput =>
      widget.controller?.text.trim().toLowerCase() ?? '';

  bool get _matchesExpectedWord =>
      _normalizedInput.isNotEmpty &&
      _normalizedInput == widget.word.trim().toLowerCase();

  bool get _hasValidationError =>
      _normalizedInput.isNotEmpty &&
      (!_isValidSignupBip39Word(_normalizedInput) || !_matchesExpectedWord);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller?.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    _handleTextChanged();
  }

  @override
  void didUpdateWidget(covariant _WordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChanged);
      widget.controller?.addListener(_handleTextChanged);
      _handleTextChanged();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChanged);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && mounted) {
      setState(() {
        _suggestions = const [];
      });
    }
  }

  void _handleTextChanged() {
    final text = _normalizedInput;
    final suggestions =
        text.isNotEmpty ? _signupBip39Suggestions(text) : const <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _hasTyped = text.isNotEmpty;
      _suggestions = suggestions;
    });
  }

  void _applySuggestion(String word) {
    final controller = widget.controller;
    if (controller == null) {
      return;
    }

    controller.text = word;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: word.length),
    );
    widget.onChanged?.call(word);

    setState(() {
      _suggestions = const [];
      _hasTyped = true;
    });
  }

  Color _inputBorderColor(Color accent, BuildContext context) {
    if (_matchesExpectedWord) {
      return Colors.greenAccent.withValues(alpha: 0.60);
    }
    if (_hasValidationError) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.70);
    }
    if (_focusNode.hasFocus) {
      return accent;
    }
    if (_hasTyped) {
      return Colors.white.withValues(alpha: 0.16);
    }
    return Colors.white.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.highlighted
        ? Theme.of(context).colorScheme.secondary
        : Colors.white.withValues(alpha: 0.22);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: widget.highlighted
            ? accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(
          color: widget.highlighted
              ? _inputBorderColor(accent, context)
              : Colors.white.withValues(alpha: 0.08),
          width: widget.highlighted && _focusNode.hasFocus ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.positionLabel,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: widget.highlighted
                      ? accent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (!widget.highlighted)
            Text(
              widget.word,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '',
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_hasTyped)
                  Icon(
                    _matchesExpectedWord
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: _matchesExpectedWord
                        ? Colors.greenAccent.withValues(alpha: 0.80)
                        : Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.80),
                  ),
              ],
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _suggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _applySuggestion(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ShareReviewCard extends StatelessWidget {
  final String label;
  final String share;

  const _ShareReviewCard({
    required this.label,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            share,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}
