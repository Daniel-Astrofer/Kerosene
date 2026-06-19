import 'package:flutter/material.dart';
import 'package:kerosene/core/copy/kerosene_ui_copy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/security/app_pin_service.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';

enum _PinMode { setup, enter }

/// A full-screen PIN dialog for protected operations.
class PinDialog extends StatefulWidget {
  final bool isSetup;

  const PinDialog({super.key, required this.isSetup});

  static Future<bool> show(
    BuildContext context, {
    required bool isSetup,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor:
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      pageBuilder: (context, anim1, anim2) => PinDialog(isSetup: isSetup),
      transitionDuration: KeroseneMotion.medium,
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  late _PinMode _mode;
  final _pinService = AppPinService();

  String _entered = '';
  String? _error;

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _mode = widget.isSetup ? _PinMode.setup : _PinMode.enter;
  }

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });

    if (_entered.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _error = null;
    });
  }

  Future<void> _handleComplete() async {
    switch (_mode) {
      case _PinMode.setup:
        await _pinService.setPin(_entered);
        if (mounted) Navigator.of(context).pop(true);
        break;

      case _PinMode.enter:
        final ok = await _pinService.verifyPin(_entered);
        if (ok) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = 'Não conseguimos confirmar esse PIN. Tente novamente.';
            _entered = '';
          });
        }
        break;
    }
  }

  String get _title {
    switch (_mode) {
      case _PinMode.setup:
        return 'Criar PIN';
      case _PinMode.enter:
        return 'Confirme seu acesso';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _PinMode.setup:
        return 'Escolha um PIN de 6 dígitos para proteger sua carteira.';
      case _PinMode.enter:
        return 'Digite seu PIN de segurança para continuar com esta operação.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeroseneBrandTokens.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KeroseneBrandTokens.backgroundSoft,
              KeroseneBrandTokens.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              _buildVisualIndicator().animate().scale().fade(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      letterSpacing: -0.6,
                      color: KeroseneBrandTokens.textPrimary,
                    ),
              ).animate().fade().slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: KeroseneBrandTokens.textSecondary,
                      ),
                ),
              ).animate(delay: KeroseneMotion.fast).fade(),
              const Spacer(),
              _buildDots().animate().fade(),
              const SizedBox(height: AppSpacing.md),
              _buildErrorMessage(),
              const Spacer(),
              _buildModernKeypad()
                  .animate(delay: KeroseneMotion.short)
                  .fade()
                  .slideY(begin: 0.2, end: 0),
              if (!widget.isSetup)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      KeroseneUiCopy.cancelOperation,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: KeroseneBrandTokens.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                ).animate(delay: KeroseneMotion.long).fade(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualIndicator() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KeroseneBrandTokens.brand.withValues(alpha: 0.05),
        border: Border.all(
          color: KeroseneBrandTokens.brand.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: KeroseneBrandTokens.brand.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          KeroseneIcons.security,
          color: KeroseneBrandTokens.brand,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _entered.length;
        return AnimatedContainer(
          duration: KeroseneMotion.short,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? KeroseneBrandTokens.brand
                : KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
            border: Border.all(
              color: filled
                  ? KeroseneBrandTokens.textPrimary.withValues(alpha: 0.3)
                  : KeroseneBrandTokens.textPrimary.withValues(alpha: 0.1),
              width: 2,
            ),
            boxShadow: [
              if (filled)
                BoxShadow(
                  color: KeroseneBrandTokens.brand.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return SizedBox(
      height: 24,
      child: AnimatedSwitcher(
        duration: KeroseneMotion.medium,
        child: _error != null
            ? Text(
                _error!,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: KeroseneBrandTokens.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                key: ValueKey(_error),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildModernKeypad() {
    final List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) => _buildKey(key)).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == '←' || key == 'C';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          if (key == '←') {
            _onDelete();
          } else if (key == 'C') {
            setState(() {
              _entered = '';
              _error = null;
            });
          } else {
            _onDigit(key);
          }
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.02),
            border: Border.all(
              color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isSpecial && key == '←'
              ? const Icon(
                  KeroseneIcons.backspace,
                  color: KeroseneBrandTokens.textPrimary,
                  size: 24,
                )
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: isSpecial && key == 'C'
                            ? KeroseneBrandTokens.error.withValues(alpha: 0.7)
                            : KeroseneBrandTokens.textPrimary,
                        fontFamily: AppTypography.financialFontFamily,
                        fontWeight: FontWeight.w300,
                      ),
                ),
        ),
      ),
    );
  }
}
