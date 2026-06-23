// ignore_for_file: use_key_in_widget_constructors

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';

const Color _authBlack = AppColors.hexFF000000;
const Color _authWhite = AppColors.hexFFFFFFFF;
const Color _authMuted = AppColors.hexFFA3A3A3;
const Color _authSurface = AppColors.hexFF141313;
const Color _authSurfaceRaised = AppColors.hexFF1C1C1E;
const Color _authBorder = AppColors.hexFF2A2A2A;
const Color _authErrorText = AppColors.hexFFF4C7C7;
const Color _authSuccess = AppColors.hexFF4ADE80;

class PasskeyIssueInfo {
  final IconData icon;
  final String title;
  final String message;
  final bool allowRetry;
  final bool allowTotpFallback;

  const PasskeyIssueInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.allowRetry = true,
    this.allowTotpFallback = true,
  });
}

class TopBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onPressed,
          icon: const Icon(KeroseneIcons.back, size: 24),
          color: _authWhite.withValues(alpha: 0.84),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class PasskeyAuthView extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String subtitle;
  final bool isShort;
  final bool isSuccess;

  const PasskeyAuthView({
    required this.animation,
    required this.title,
    required this.subtitle,
    required this.isShort,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final sensorSize = responsive.isTinyPhone
        ? 196.0
        : isShort
            ? 156.0
            : 256.0;
    final iconSize = sensorSize * 0.42;
    final titleSize = responsive.isTinyPhone
        ? 34.0
        : isShort
            ? 32.0
            : 42.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SensorVisualizer(
            animation: animation,
            size: sensorSize,
            iconSize: iconSize,
            isSuccess: isSuccess,
          ),
          SizedBox(height: isShort ? AppSpacing.lg : 46),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _authWhite,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authMuted,
              fontSize: responsive.isTinyPhone ? 14 : 16,
              fontWeight: FontWeight.w300,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class SensorVisualizer extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final double iconSize;
  final bool isSuccess;

  const SensorVisualizer({
    required this.animation,
    required this.size,
    required this.iconSize,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final waveA = math.sin(animation.value * math.pi * 2);
          final waveB = math.sin((animation.value * math.pi * 2) + math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              PulseRing(
                size: size,
                scale: 0.92 + waveB * 0.08,
                opacity: 0.30 + waveB.abs() * 0.18,
                inset: 0,
              ),
              PulseRing(
                size: size,
                scale: 0.88 + waveA * 0.10,
                opacity: 0.42 + waveA.abs() * 0.22,
                inset: size * 0.07,
              ),
              Container(
                width: size * 0.64,
                height: size * 0.64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _authSurface.withValues(alpha: 0.74),
                  border: Border.all(
                    color: _authWhite.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  isSuccess ? KeroseneIcons.security : KeroseneIcons.biometric,
                  size: iconSize,
                  color: isSuccess ? _authSuccess : _authWhite,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PulseRing extends StatelessWidget {
  final double size;
  final double scale;
  final double opacity;
  final double inset;

  const PulseRing({
    required this.size,
    required this.scale,
    required this.opacity,
    required this.inset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size - inset * 2,
        height: size - inset * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _authWhite.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}

class PasskeyIssueView extends StatelessWidget {
  final PasskeyIssueInfo? issue;
  final bool isShort;
  final bool canRetry;
  final bool canUseTotp;
  final VoidCallback? onRetry;
  final VoidCallback? onUseTotp;
  final VoidCallback? onBackToPassword;
  final String Function({
    required String pt,
    required String en,
    required String es,
  }) copy;

  const PasskeyIssueView({
    required this.issue,
    required this.isShort,
    required this.canRetry,
    required this.canUseTotp,
    required this.onRetry,
    required this.onUseTotp,
    required this.onBackToPassword,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final titleSize = responsive.isTinyPhone
        ? 32.0
        : isShort
            ? 30.0
            : 38.0;
    final message = issue?.message ??
        copy(
          pt: 'Biometria não reconhecida. Tente novamente ou use outro método.',
          en: 'Biometrics were not recognized. Try again or use another method.',
          es: 'Biometría no reconocida. Intenta de nuevo o usa otro método.',
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorGlyph(size: isShort ? 92 : 120, icon: issue?.icon),
          SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xl),
          Text(
            copy(
              pt: 'Falha na Autenticação',
              en: 'Authentication Failed',
              es: 'Falló la Autenticación',
            ),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _authWhite.withValues(alpha: 0.96),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authErrorText,
              fontSize: responsive.isTinyPhone ? 14 : 15,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: isShort ? AppSpacing.xl : 58),
          if (canRetry)
            ActionButton(
              text: copy(
                pt: 'Tentar novamente',
                en: 'Try again',
                es: 'Intentar de nuevo',
              ).toUpperCase(),
              onPressed: onRetry,
            ),
          if (canRetry) const SizedBox(height: AppSpacing.md),
          if (canUseTotp)
            ActionButton(
              text: copy(
                pt: 'Usar TOTP',
                en: 'Use TOTP',
                es: 'Usar TOTP',
              ).toUpperCase(),
              onPressed: onUseTotp,
              secondary: true,
            )
          else
            ActionButton(
              text: copy(
                pt: 'Voltar para senha',
                en: 'Back to password',
                es: 'Volver a contraseña',
              ).toUpperCase(),
              onPressed: onBackToPassword,
              secondary: true,
            ),
        ],
      ),
    );
  }
}

class ErrorGlyph extends StatelessWidget {
  final double size;
  final IconData? icon;

  const ErrorGlyph({
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _authSurface,
              border: Border.all(color: _authErrorText.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: _authErrorText.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon ?? KeroseneIcons.biometric,
              color: _authErrorText,
              size: size * 0.46,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: _authErrorText,
                shape: BoxShape.circle,
                border: Border.all(color: _authBlack, width: 2),
              ),
              child: Icon(
                KeroseneIcons.warning,
                size: size * 0.16,
                color: _authBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TotpFallbackView extends StatelessWidget {
  final String code;
  final bool hasError;
  final String? errorMessage;
  final int errorPulseKey;
  final bool isLoading;
  final bool isShort;
  final KeroseneResponsiveMetrics responsive;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final String Function({
    required String pt,
    required String en,
    required String es,
  }) copy;

  const TotpFallbackView({
    required this.code,
    required this.hasError,
    required this.errorMessage,
    required this.errorPulseKey,
    required this.isLoading,
    required this.isShort,
    required this.responsive,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = responsive.isTinyPhone
        ? 34.0
        : isShort
            ? 31.0
            : 40.0;
    final keypadGap = isShort ? AppSpacing.xs : AppSpacing.md;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copy(
              pt: 'Código de Segurança',
              en: 'Security Code',
              es: 'Código de Seguridad',
            ),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _authWhite,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            copy(
              pt: 'Insira o código de 6 dígitos do seu app autenticador',
              en: 'Enter the 6-digit code from your authenticator app',
              es: 'Ingresa el código de 6 dígitos de tu app autenticadora',
            ),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authMuted,
              fontSize: responsive.isTinyPhone ? 14 : 16,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: isShort ? AppSpacing.lg : 48),
          AuthMotionShake(
            triggerKey: errorPulseKey,
            enabled: hasError,
            child: PinDots(codeLength: code.length, hasError: hasError),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: _authErrorText,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ],
          SizedBox(height: isShort ? AppSpacing.lg : 46),
          TotpKeypad(
            isShort: isShort,
            gap: keypadGap,
            onDigit: isLoading ? null : onDigit,
            onDelete: isLoading ? null : onDelete,
          ),
          SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xl),
          ActionButton(
            text: copy(
              pt: 'Confirmar',
              en: 'Confirm',
              es: 'Confirmar',
            ),
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class PinDots extends StatelessWidget {
  final int codeLength;
  final bool hasError;

  const PinDots({
    required this.codeLength,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < codeLength;
        return AnimatedContainer(
          duration: KeroseneMotion.short,
          curve: KeroseneMotion.standard,
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? _authWhite
                : hasError
                    ? _authErrorText.withValues(alpha: 0.12)
                    : _authSurface,
            border: Border.all(
              color: filled
                  ? _authWhite
                  : hasError
                      ? _authErrorText
                      : _authBorder,
            ),
          ),
        );
      }),
    );
  }
}

class TotpKeypad extends StatelessWidget {
  final bool isShort;
  final double gap;
  final ValueChanged<String>? onDigit;
  final VoidCallback? onDelete;

  const TotpKeypad({
    required this.isShort,
    required this.gap,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KeypadRow(values: const ['1', '2', '3'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        KeypadRow(values: const ['4', '5', '6'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        KeypadRow(values: const ['7', '8', '9'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        Row(
          children: [
            const Expanded(child: SizedBox(height: 58)),
            SizedBox(width: gap),
            Expanded(
              child: KeypadButton(
                value: '0',
                isShort: isShort,
                onPressed: onDigit == null ? null : () => onDigit?.call('0'),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: KeypadButton(
                icon: KeroseneIcons.backspace,
                isShort: isShort,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class KeypadRow extends StatelessWidget {
  final List<String> values;
  final double gap;
  final ValueChanged<String>? onDigit;

  const KeypadRow({
    required this.values,
    required this.gap,
    required this.onDigit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          Expanded(
            child: KeypadButton(
              value: values[index],
              onPressed:
                  onDigit == null ? null : () => onDigit?.call(values[index]),
            ),
          ),
          if (index != values.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String? value;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isShort;

  const KeypadButton({
    this.value,
    this.icon,
    this.onPressed,
    this.isShort = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      enabled: onPressed != null,
      child: SizedBox(
        height: isShort ? 46 : 64,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: _authMuted, size: 22)
                  : Text(
                      value ?? '',
                      style: AppTypography.newsreader(
                        color: _authWhite,
                        fontSize: isShort ? 25 : 29,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool isLoading;

  const ActionButton({
    required this.text,
    required this.onPressed,
    this.secondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background = secondary ? _authSurfaceRaised : _authWhite;
    final foreground = secondary ? _authWhite : _authBlack;

    return AuthMotionPressScale(
      enabled: !disabled,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed?.call();
                  },
            child: Ink(
              decoration: BoxDecoration(
                color:
                    disabled ? background.withValues(alpha: 0.42) : background,
                border: Border.all(
                  color: secondary ? _authSurfaceRaised : Colors.transparent,
                ),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.buttonText.copyWith(
                          color: disabled
                              ? foreground.withValues(alpha: 0.7)
                              : foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
