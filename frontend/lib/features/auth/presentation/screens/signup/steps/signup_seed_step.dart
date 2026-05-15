import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';

/// Signup Step 2: Seed Phrase Generation
class SignupSeedStep extends StatefulWidget {
  final ValueChanged<String> onNext;

  const SignupSeedStep({super.key, required this.onNext});

  @override
  State<SignupSeedStep> createState() => _SignupSeedStepState();
}

class _SignupSeedStepState extends State<SignupSeedStep> {
  late String _mnemonic;
  int _wordCount = 18;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  void _generateMnemonic() {
    int strength = 128;
    if (_wordCount == 18) strength = 192;
    if (_wordCount == 24) strength = 256;
    setState(() {
      _mnemonic = bip39.generateMnemonic(strength: strength);
    });
  }

  Widget _buildWordCountSelector(int count) {
    final isSelected = _wordCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              _wordCount = count;
              _generateMnemonic();
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(LucideIcons.chevronDown,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Seja Bem-Vindo',
                        style: Theme.of(context).textTheme.displayLarge!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Anote estas palavras em um papel\nfísico.\nNunca as salve digitalmente.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      height: 48,
                      width: 260,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          _buildWordCountSelector(12),
                          _buildWordCountSelector(18),
                          _buildWordCountSelector(24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Builder(
                          builder: (context) {
                            final words =
                                _mnemonic.trim().split(RegExp(r'\s+'));

                            return Column(
                              key: ValueKey(
                                  _wordCount), // Rebuild explicitly if count changes
                              children: List.generate((words.length / 2).ceil(),
                                  (rowIndex) {
                                final int firstIndex = rowIndex * 2;
                                final int secondIndex = rowIndex * 2 + 1;
                                final bool hasSecond =
                                    secondIndex < words.length;

                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: rowIndex ==
                                              (words.length / 2).ceil() - 1
                                          ? 0
                                          : 16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: _buildWordItem(
                                              firstIndex, words)),
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
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 32),
                  BouncingButton(
                    text: 'Continuar',
                    onPressed: () => widget.onNext(_mnemonic),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWordItem(int index, List<String> words) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
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
