import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/security/app_pin_service.dart';

enum _PinMode { setup, enter }

/// A premium full-screen PIN dialog - Refactored
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
      barrierColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: 0.95),
      pageBuilder: (context, anim1, anim2) => PinDialog(isSetup: isSetup),
      transitionDuration: const Duration(milliseconds: 160),
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
            _error = 'PIN INCORRETO. TENTE NOVAMENTE.';
            _entered = '';
          });
        }
        break;
    }
  }

  String get _title {
    switch (_mode) {
      case _PinMode.setup:
        return 'CRIAR PIN';
      case _PinMode.enter:
        return 'AUTENTICAÇÃO';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _PinMode.setup:
        return 'Escolha um PIN de 6 dígitos para proteger sua carteira.';
      case _PinMode.enter:
        return 'Digite seu PIN de segurança para processar esta operação.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final height = responsive.size.height;
    final tightHeight = height < 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: false,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: tightHeight ? AppSpacing.lg : 64.0),
              _buildVisualIndicator().animate().scale().fade(),
              SizedBox(height: tightHeight ? AppSpacing.md : AppSpacing.xl),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                child: Text(
                  _subtitle,
                  maxLines: tightHeight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Colors.white70),
                ),
              ).animate(delay: 100.ms).fade(),
              SizedBox(height: tightHeight ? AppSpacing.lg : AppSpacing.xxl),
              _buildDots().animate().fade(),
              SizedBox(height: tightHeight ? AppSpacing.sm : AppSpacing.lg),
              _buildErrorMessage(),
              const Spacer(),
              _buildModernKeypad()
                  .animate(delay: 200.ms)
                  .fade()
                  .slideY(begin: 0.2, end: 0),
              if (!widget.isSetup)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: tightHeight ? AppSpacing.md : AppSpacing.xl,
                    top: tightHeight ? AppSpacing.md : AppSpacing.xxl,
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'CANCELAR',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate(delay: 400.ms).fade()
              else
                SizedBox(
                  height: tightHeight ? AppSpacing.xl : AppSpacing.xxl + 48,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualIndicator() {
    return const Icon(LucideIcons.lock, color: Colors.white38, size: 24);
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _entered.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white54 : Colors.transparent,
            border: Border.all(
              color: filled ? Colors.transparent : Colors.white24,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return SizedBox(
      height: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _error != null
            ? Text(
                _error!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
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

    final responsive = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map((key) => Expanded(child: _buildKey(key)))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == '←' || key == 'C';
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.all(
        responsive.isTinyPhone ? AppSpacing.xs : AppSpacing.sm,
      ),
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
          height: responsive.size.height < 700 ? 48 : 58,
          decoration: const BoxDecoration(color: Colors.transparent),
          alignment: Alignment.center,
          child: isSpecial && key == '←'
              ? const Icon(LucideIcons.delete, color: Colors.white70, size: 18)
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: isSpecial && key == 'C'
                        ? Colors.white70
                        : Colors.white,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w400,
                    fontSize: 24,
                  ),
                ),
        ),
      ),
    );
  }
}
