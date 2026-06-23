// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:kerosene/features/auth/presentation/widgets/totp_input_container.dart';

class AuthColors {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color field;
  final Color border;
  final Color borderSoft;
  final Color text;
  final Color muted;
  final Color dim;
  final Color success;
  final Color errorText;

  const AuthColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.field,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.muted,
    required this.dim,
    required this.success,
    required this.errorText,
  });

  factory AuthColors.of(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return const AuthColors(
        isLight: true,
        background: AppColors.hexFFF7F7F5,
        surface: AppColors.hexFFFFFFFF,
        field: AppColors.hexFFF0F1EE,
        border: AppColors.hexFFDDE0D8,
        borderSoft: AppColors.hexFFE2E4DE,
        text: AppColors.hexFF181A17,
        muted: AppColors.hexFF62675F,
        dim: AppColors.hexFF8B9087,
        success: AppColors.hexFF16A34A,
        errorText: AppColors.hexFFDC2626,
      );
    }
    return const AuthColors(
      isLight: false,
      background: AppColors.hexFF000000,
      surface: AppColors.hexFF0A0A0A,
      field: AppColors.hexFF1A1A1A,
      border: AppColors.hexFF333333,
      borderSoft: AppColors.hexFF27272A,
      text: AppColors.hexFFFFFFFF,
      muted: AppColors.hexFFA1A1AA,
      dim: AppColors.hexFF71717A,
      success: AppColors.hexFF4ADE80,
      errorText: AppColors.hexFFF4C7C7,
    );
  }

  BorderRadius get radiusMedium =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(12);
  BorderRadius get radiusButton =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(999);
}

class LoginTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const LoginTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(KeroseneIcons.back, size: 24),
              color: colors.text.withValues(alpha: 0.86),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: colors.text.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginTitleBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LoginTypography.title(colors)),
        const SizedBox(height: 10),
        Text(subtitle, style: LoginTypography.subtitle(colors)),
      ],
    );
  }
}

class LoginInlineFeedback extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const LoginInlineFeedback({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return LoginPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.text.withValues(alpha: 0.82)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LoginTypography.label(colors).copyWith(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style:
                      LoginTypography.bodySmall(colors).copyWith(height: 1.34),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hintText;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const LoginTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.focusNode,
    this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LoginTypography.label(colors)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: colors.text,
          style: LoginTypography.field(colors).copyWith(
            color: enabled ? colors.text : colors.text.withValues(alpha: 0.48),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.field,
            hintText: hintText,
            hintStyle: LoginTypography.field(colors).copyWith(
              color: colors.dim,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            enabledBorder: border,
            disabledBorder: border.copyWith(
              borderSide:
                  BorderSide(color: colors.border.withValues(alpha: 0.72)),
            ),
            focusedBorder: border.copyWith(
              borderSide:
                  BorderSide(color: colors.text.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginTotpPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasError;
  final int errorPulseKey;
  final ValueChanged<String> onCompleted;
  final VoidCallback onSubmit;
  final String title;
  final String subtitle;
  final String buttonLabel;

  const LoginTotpPanel({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasError,
    required this.errorPulseKey,
    required this.onCompleted,
    required this.onSubmit,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return LoginPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.text.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.text.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(
                  KeroseneIcons.passkey,
                  color: colors.text,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LoginTypography.sectionTitle(colors)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: LoginTypography.bodySmall(colors),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TotpInputContainer(
            controller: controller,
            focusNode: focusNode,
            enabled: !isLoading,
            hasError: hasError,
            errorPulseKey: errorPulseKey,
            onCompleted: onCompleted,
          ),
          const SizedBox(height: 18),
          LoginPrimaryButton(
            text: buttonLabel,
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

class LoginPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;

  const LoginPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    final disabled = onPressed == null || isLoading;
    final background =
        disabled ? colors.text.withValues(alpha: 0.42) : colors.text;
    final foreground = colors.background;

    return AuthMotionPressScale(
      enabled: !disabled,
      child: SizedBox(
        height: 54,
        child: FilledButton(
          onPressed: disabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed?.call();
                },
          style: FilledButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: foreground,
            disabledForegroundColor: foreground.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide.none,
            ),
            textStyle: LoginTypography.button(colors, color: foreground),
          ),
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
                ),
        ),
      ),
    );
  }
}

class LoginSignupLink extends StatelessWidget {
  final VoidCallback? onTap;
  final String lead;
  final String action;

  const LoginSignupLink({
    required this.onTap,
    required this.lead,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text.rich(
              TextSpan(
                text: '$lead ',
                style: LoginTypography.bodySmall(colors),
                children: [
                  TextSpan(
                    text: action,
                    style: LoginTypography.bodySmall(
                      colors,
                      color: colors.text,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const LoginPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AuthColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.borderSoft),
      ),
      child: child,
    );
  }
}

class LoginTypography {
  const LoginTypography._();

  static TextStyle title(AuthColors colors) {
    return AppTypography.newsreader(
      color: colors.text,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle subtitle(AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.muted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle label(AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );
  }

  static TextStyle field(AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmall(AuthColors colors, {Color? color}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color ?? colors.muted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle(AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle button(AuthColors colors, {required Color color}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: 0,
    );
  }
}
