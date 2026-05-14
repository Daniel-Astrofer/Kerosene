import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';

/// Signup Step 3: Mnemonic Verification
class SignupVerificationStep extends StatefulWidget {
  final String mnemonic;
  final VoidCallback onNext;

  const SignupVerificationStep({
    super.key,
    required this.mnemonic,
    required this.onNext,
  });

  @override
  State<SignupVerificationStep> createState() => _SignupVerificationStepState();
}

class _SignupVerificationStepState extends State<SignupVerificationStep> {
  List<String>? _words;
  List<TextEditingController>? _controllers;
  List<FocusNode>? _focusNodes;
  Set<int>? _missingIndices;

  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.mnemonic.isNotEmpty) {
      _initData();
    }
  }

  @override
  void didUpdateWidget(SignupVerificationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mnemonic != oldWidget.mnemonic && widget.mnemonic.isNotEmpty) {
      _initData();
    }
  }

  void _initData() {
    // Guarantee that _words contains all individual words, handling multiple spaces robustly.
    final words = widget.mnemonic.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || (words.length == 1 && words[0] == '')) return;

    setState(() {
      _words = words;
      _controllers =
          List.generate(words.length, (index) => TextEditingController());
      _focusNodes = List.generate(words.length, (index) => FocusNode());

      _missingIndices = {};
      final random = math.Random();

      // Ensure we don't loop forever if words are less than 3
      final int targetCount = math.min(3, words.length);

      while (_missingIndices!.length < targetCount) {
        _missingIndices!.add(random.nextInt(words.length));
      }
    });
  }

  @override
  void dispose() {
    if (_controllers != null) {
      for (var c in _controllers!) {
        c.dispose();
      }
    }
    if (_focusNodes != null) {
      for (var f in _focusNodes!) {
        f.dispose();
      }
    }
    super.dispose();
  }

  void _verify() {
    if (_words == null || _controllers == null || _missingIndices == null) {
      return;
    }

    bool allMatch = true;
    for (int i = 0; i < _words!.length; i++) {
      if (_missingIndices!.contains(i)) {
        if (_controllers![i].text.trim().toLowerCase() !=
            _words![i].toLowerCase()) {
          allMatch = false;
          break;
        }
      }
    }

    if (allMatch) {
      setState(() => _error = null);
      widget.onNext();
    } else {
      setState(() => _error =
          'Algumas palavras estão incorretas. Verifique e tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_words == null) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Verificação de Segurança',
                      style: Theme.of(context).textTheme.displayLarge!,
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Para garantir que você guardou a frase corretamente, digite todas as palavras abaixo.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Grid of Words (Grid Card)
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
                              return Column(
                                children: List.generate(
                                    (_words!.length / 2).ceil(), (rowIndex) {
                                  final int firstIndex = rowIndex * 2;
                                  final int secondIndex = rowIndex * 2 + 1;
                                  final bool hasSecond =
                                      secondIndex < _words!.length;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom: rowIndex ==
                                                (_words!.length / 2).ceil() - 1
                                            ? 0
                                            : 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: _buildWordItem(firstIndex)),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: hasSecond
                                              ? _buildWordItem(secondIndex)
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
                      text: 'Verificar e Continuar',
                      onPressed: _verify,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWordItem(int index) {
    if (_words == null ||
        _missingIndices == null ||
        _controllers == null ||
        _focusNodes == null) {
      return const SizedBox();
    }

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
            child: _missingIndices!.contains(index)
                ? TextField(
                    controller: _controllers![index],
                    focusNode: _focusNodes![index],
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      int nextMissing = -1;
                      for (int i = index + 1; i < _words!.length; i++) {
                        if (_missingIndices!.contains(i)) {
                          nextMissing = i;
                          break;
                        }
                      }
                      if (nextMissing != -1) {
                        _focusNodes![nextMissing].requestFocus();
                      } else {
                        _verify();
                      }
                    },
                  )
                : Text(
                    _words![index],
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
