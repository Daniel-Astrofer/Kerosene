import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../controller/auth_controller.dart';
import 'totp_screen.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'package:teste/core/widgets/bouncing_button.dart';

/// Passphrase (seed phrase) login screen — grid-based word input.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class LoginPassphraseScreen extends ConsumerStatefulWidget {
  final String username;

  const LoginPassphraseScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<LoginPassphraseScreen> createState() =>
      _LoginPassphraseScreenState();
}

class _LoginPassphraseScreenState extends ConsumerState<LoginPassphraseScreen> {
  int _wordCount = 18;
  String? _validationError;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(24, (index) => TextEditingController());
    _focusNodes = List.generate(24, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleContinue() {
    final words =
        _controllers.take(_wordCount).map((c) => c.text.trim()).toList();

    final emptyIndex = words.indexWhere((w) => w.isEmpty);
    if (emptyIndex != -1) {
      setState(() {
        _validationError = 'Preencha todas as palavras para continuar.';
      });
      _focusNodes[emptyIndex].requestFocus();
      return;
    }

    setState(() {
      _validationError = null;
    });

    final passphrase = words.join(' ');
    ref.read(authControllerProvider.notifier).login(
          username: widget.username,
          password: passphrase,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        HomeScreen.skipNextAuth = true;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
      } else if (next is AuthRequiresLoginTotp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotpScreen(
              username: next.username,
              passphrase: next.passphrase,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onGoBack: () {
            ref.read(authControllerProvider.notifier).clearError();
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: 48),
                          // Heading
                          Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.shieldCheck,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                context.l10n.secureAccess,
                                style: AppTypography.h1.copyWith(
                                  fontSize: 28,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Digite sua frase secreta exatamente como foi armazenada.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.55),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Esta etapa autentica o acesso e nao altera sua seed.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.45),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Word Count Toggle
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.03),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.08)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [12, 18, 24].map((count) {
                                final isSelected = _wordCount == count;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _wordCount = count;
                                      _validationError = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: AppTypography.number.copyWith(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.w500
                                            : FontWeight.w300,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Grid of Words (Grid Card)
                          Container(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.02),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.xl),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.3)),
                              boxShadow: [],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.xl),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Builder(
                                  builder: (context) {
                                    return Column(
                                      key: ValueKey(_wordCount),
                                      children: List.generate(
                                          (_wordCount / 2).ceil(), (rowIndex) {
                                        final int firstIndex = rowIndex * 2;
                                        final int secondIndex =
                                            rowIndex * 2 + 1;
                                        final bool hasSecond =
                                            secondIndex < _wordCount;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: rowIndex ==
                                                      (_wordCount / 2).ceil() -
                                                          1
                                                  ? 0
                                                  : 16.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  child: _buildWordItem(
                                                      firstIndex)),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: hasSecond
                                                    ? _buildWordItem(
                                                        secondIndex)
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

                          if (_validationError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _validationError!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const Spacer(),
                          const SizedBox(height: 32),

                          // Continue Button
                          BouncingButton(
                            text: context.l10n.continueButton,
                            isLoading: isLoading,
                            onPressed: _handleContinue,
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordItem(int index) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: AppTypography.number.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
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
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              textInputAction: TextInputAction.next,
              onSubmitted: (val) {
                if (index < _wordCount - 1) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _handleContinue();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
