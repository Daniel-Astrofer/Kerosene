import 'dart:typed_data';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:slip39/slip39.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/presentation/models/signup_seed_material.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupSeedStep extends StatefulWidget {
  final SeedSecurityOption seedSecurityOption;
  final int slip39TotalShares;
  final int slip39Threshold;
  final ValueChanged<SignupSeedMaterial> onNext;

  const SignupSeedStep({
    super.key,
    required this.seedSecurityOption,
    required this.slip39TotalShares,
    required this.slip39Threshold,
    required this.onNext,
  });

  @override
  State<SignupSeedStep> createState() => _SignupSeedStepState();
}

class _SignupSeedStepState extends State<SignupSeedStep>
    with SingleTickerProviderStateMixin {
  late Mnemonic _primaryMnemonic;
  Mnemonic? _recoveryMnemonic;
  List<String> _slip39Shares = const [];
  int _wordCount = 18;
  bool _confirmedWritten = false;
  late final AnimationController _wordCountSelectorController;

  bool get _isSlip39 => widget.seedSecurityOption == SeedSecurityOption.slip39;
  bool get _isMultisig =>
      widget.seedSecurityOption == SeedSecurityOption.multisig2fa;

  @override
  void initState() {
    super.initState();
    _wordCountSelectorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0,
      upperBound: 2,
      value: _wordCountIndex(_wordCount).toDouble(),
    );
    _generateRecoveryMaterial();
  }

  @override
  void dispose() {
    _wordCountSelectorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SignupSeedStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedSecurityOption != widget.seedSecurityOption ||
        oldWidget.slip39Threshold != widget.slip39Threshold ||
        oldWidget.slip39TotalShares != widget.slip39TotalShares) {
      _generateRecoveryMaterial();
    }
  }

  MnemonicLength _mnemonicLengthFromWordCount(int wordCount) {
    switch (wordCount) {
      case 12:
        return MnemonicLength.words12;
      case 24:
        return MnemonicLength.words24;
      case 18:
      default:
        return MnemonicLength.words18;
    }
  }

  void _generateRecoveryMaterial() {
    final primaryWordCount = _isMultisig ? 18 : _wordCount;
    final primaryMnemonic = Mnemonic.generate(
      Language.portuguese,
      length: _mnemonicLengthFromWordCount(primaryWordCount),
    );

    List<String> shares = const [];
    Mnemonic? recoveryMnemonic;

    if (_isSlip39) {
      final groups = List.generate(widget.slip39TotalShares, (_) => [1, 1]);
      final slip = Slip39.from(
        groups,
        masterSecret: Uint8List.fromList(primaryMnemonic.entropy),
        threshold: widget.slip39Threshold,
      );

      shares =
          slip.fromPath('r').mnemonics.take(widget.slip39TotalShares).toList();
    }

    if (_isMultisig) {
      recoveryMnemonic = Mnemonic.generate(
        Language.portuguese,
        length: MnemonicLength.words12,
      );
    }

    setState(() {
      _primaryMnemonic = primaryMnemonic;
      _recoveryMnemonic = recoveryMnemonic;
      _slip39Shares = shares;
      _wordCount = primaryWordCount;
      _confirmedWritten = false;
    });
  }

  void _submit() {
    widget.onNext(
      SignupSeedMaterial(
        primaryMnemonic: _primaryMnemonic.sentence,
        recoveryMnemonic: _recoveryMnemonic?.sentence ?? '',
        securityOption: widget.seedSecurityOption,
        wordCount: _wordCount,
        recoveryWordCount:
            _recoveryMnemonic?.sentence.trim().split(RegExp(r'\s+')).length ??
                0,
        slip39Shares: _slip39Shares,
        slip39TotalShares: widget.slip39TotalShares,
        slip39Threshold: widget.slip39Threshold,
      ),
    );
  }

  int _wordCountIndex(int count) {
    switch (count) {
      case 12:
        return 0;
      case 24:
        return 2;
      case 18:
      default:
        return 1;
    }
  }

  Color _wordCountColor(int count) {
    switch (count) {
      case 12:
        return AppColors.success;
      case 24:
        return AppColors.error;
      case 18:
      default:
        return AppColors.warning;
    }
  }

  Color _selectorTrackColor(double progress) {
    if (progress <= 1) {
      return Color.lerp(
            _wordCountColor(12),
            _wordCountColor(18),
            progress,
          ) ??
          _wordCountColor(18);
    }

    return Color.lerp(
          _wordCountColor(18),
          _wordCountColor(24),
          progress - 1,
        ) ??
        _wordCountColor(24);
  }

  String _securityLevelLabel(int count) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final level = switch (count) {
      12 => 1,
      24 => 3,
      _ => 2,
    };

    switch (languageCode) {
      case 'en':
        return 'Security $level';
      case 'es':
        return 'Seguridad $level';
      default:
        return 'Nivel $level';
    }
  }

  void _selectWordCount(int count) {
    if (_wordCount == count) {
      return;
    }

    _wordCountSelectorController.animateTo(
      _wordCountIndex(count).toDouble(),
      curve: Curves.easeOutCubic,
    );
    _wordCount = count;
    _generateRecoveryMaterial();
  }

  Widget _buildWordCountSelector() {
    return SizedBox(
      height: 72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth - 8;
          final segmentWidth = trackWidth / 3;

          return AnimatedBuilder(
            animation: _wordCountSelectorController,
            builder: (context, child) {
              final progress = _wordCountSelectorController.value;
              final highlightColor = _selectorTrackColor(progress);

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: segmentWidth * progress,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: highlightColor.withValues(alpha: 0.14),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [12, 18, 24].map((count) {
                        final isSelected = _wordCount == count;
                        final inactiveColor = _wordCountColor(count);

                        return Expanded(
                          child: InkWell(
                            onTap: () => _selectWordCount(count),
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox.expand(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$count',
                                    style: AppTypography.number.copyWith(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : inactiveColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _securityLevelLabel(count),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withValues(alpha: 0.92)
                                              : inactiveColor.withValues(
                                                  alpha: 0.88,
                                                ),
                                          letterSpacing: 0.3,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWordGrid(List<String> words, {required Color accentColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          children: List.generate((words.length / 2).ceil(), (rowIndex) {
            final firstIndex = rowIndex * 2;
            final secondIndex = rowIndex * 2 + 1;
            final hasSecond = secondIndex < words.length;

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == (words.length / 2).ceil() - 1 ? 0 : 16,
              ),
              child: Row(
                children: [
                  Expanded(child: _buildWordItem(firstIndex, words)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: hasSecond
                        ? _buildWordItem(secondIndex, words)
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMultisigMnemonicCard({
    required String title,
    required String badge,
    required String subtitle,
    required List<String> words,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: accentColor,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildWordGrid(words, accentColor: accentColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standardAccent = _wordCountColor(_wordCount);
    final heroAccent = _isSlip39
        ? Theme.of(context).colorScheme.primary
        : _isMultisig
            ? Theme.of(context).colorScheme.secondary
            : standardAccent;
    final title = _isMultisig
        ? AppCopy.signupSecurityMultisigTitle.resolve(context)
        : _isSlip39
            ? AppCopy.signupSeedTitleSlip39.resolve(context)
            : AppCopy.signupSeedTitleStandard.resolve(context);
    final subtitle = _isMultisig
        ? AppCopy.signupSecurityMultisigConfigBody.resolve(context)
        : _isSlip39
            ? AppCopy.signupSeedSubtitleSlip39.resolve(context)
            : AppCopy.signupSeedSubtitleStandard.resolve(context);
    final warning = _isMultisig
        ? context.tr.twoFaCoSignerNote
        : _isSlip39
            ? AppCopy.signupSeedWarningSlip39.resolve(context)
            : AppCopy.signupSeedWarningStandard.resolve(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: heroAccent.withValues(alpha: 0.12),
                  ),
                  child: AnimatedGlyphIcon(
                    icon: _isSlip39
                        ? LucideIcons.layoutGrid
                        : _isMultisig
                            ? LucideIcons.shieldCheck
                            : LucideIcons.keyRound,
                    size: 30,
                    color: heroAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayLarge!,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnimatedGlyphIcon(
                        icon: LucideIcons.alertTriangle,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          warning,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isMultisig) ...[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 332),
                      child: _buildWordCountSelector(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _generateRecoveryMaterial,
                    icon: const AnimatedGlyphIcon(
                      icon: LucideIcons.refreshCw,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isSlip39
                          ? AppCopy.signupSeedGenerateNewShares.resolve(context)
                          : AppCopy.signupSeedGenerateNewPhrase
                              .resolve(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isSlip39) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.slip39SharesTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr.slip39SharesSubtitle(
                            widget.slip39Threshold,
                            widget.slip39TotalShares,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.45,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(_slip39Shares.length, (index) {
                          final share = _slip39Shares[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == _slip39Shares.length - 1 ? 0 : 14,
                            ),
                            child: _Slip39ShareCard(
                              label: context.tr.slip39ShareLabel(
                                index + 1,
                                _slip39Shares.length,
                              ),
                              share: share,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ] else if (_isMultisig) ...[
                  _buildMultisigMnemonicCard(
                    title: context.tr.twoFaPrimaryTitle,
                    badge: context.tr.twoFaPrimaryBadge,
                    subtitle: context.tr.twoFaPrimarySubtitle,
                    words:
                        _primaryMnemonic.sentence.trim().split(RegExp(r'\s+')),
                    accentColor: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildMultisigMnemonicCard(
                    title: context.tr.twoFaBackupTitle,
                    badge: context.tr.twoFaBackupBadge,
                    subtitle: context.tr.twoFaBackupSubtitle,
                    words: (_recoveryMnemonic?.sentence ?? '')
                        .trim()
                        .split(RegExp(r'\s+'))
                        .where((word) => word.isNotEmpty)
                        .toList(),
                    accentColor: AppColors.warning,
                  ),
                ] else ...[
                  _buildWordGrid(
                    _primaryMnemonic.sentence.trim().split(RegExp(r'\s+')),
                    accentColor: standardAccent,
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _confirmedWritten,
                        onChanged: (value) {
                          setState(() => _confirmedWritten = value ?? false);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _isSlip39
                                ? AppCopy.signupSeedConfirmationSlip39(
                                    context,
                                    threshold: widget.slip39Threshold,
                                    totalShares: widget.slip39TotalShares,
                                  )
                                : _isMultisig
                                    ? context.tr.twoFaBothStored
                                    : AppCopy.signupSeedConfirmationStandard
                                        .resolve(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                BouncingButton(
                  text: _isSlip39
                      ? AppCopy.signupSeedContinueSlip39.resolve(context)
                      : _isMultisig
                          ? AppCopy.signupSeedContinueMultisig.resolve(context)
                          : AppCopy.signupSeedContinueStandard.resolve(context),
                  onPressed: _confirmedWritten ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordItem(int index, List<String> words) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: AppTypography.number.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              words[index],
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slip39ShareCard extends StatelessWidget {
  final String label;
  final String share;

  const _Slip39ShareCard({
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
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
            ],
          ),
          Text(
            share,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
