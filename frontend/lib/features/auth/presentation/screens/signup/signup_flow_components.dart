// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:qr_flutter/qr_flutter.dart';

const Color _signupInk = AppColors.hexFF000000;
const Color _signupSurface = AppColors.hexFF0A0A0A;
const Color _signupField = AppColors.hexFF1A1A1A;
const Color _signupBorder = AppColors.hexFF333333;
const Color _signupBorderSoft = AppColors.hexFF27272A;
const Color _signupMuted = AppColors.hexFFA1A1AA;
const Color _signupDim = AppColors.hexFF71717A;
const Color _signupText = AppColors.hexFFFFFFFF;

class SignupTypography {
  const SignupTypography._();

  static TextStyle title() {
    return AppTypography.newsreader(
      color: _signupText,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle subtitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupMuted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle label() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );
  }

  static TextStyle field() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmall({Color color = _signupMuted}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle bodyMedium({Color color = _signupText}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle button({required Color color}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: 0,
    );
  }

  static TextStyle successTitle() {
    return AppTypography.newsreader(
      color: _signupText,
      fontSize: 31,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle successSubtitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupMuted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }
}

class SignupTopBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback onBack;

  const SignupTopBar({
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
              color: _signupText.withValues(alpha: 0.86),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < totalSteps; index++) ...[
                if (index > 0) const SizedBox(width: 7),
                SizedBox(
                  width: 30,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AuthMotion.step,
                      curve: KeroseneMotion.standard,
                      width: index == step ? 30 : (index < step ? 18 : 8),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: index <= step
                            ? _signupText.withValues(
                                alpha: index == step ? 1 : 0.58,
                              )
                            : Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SignupStepColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const SignupStepColumn({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionStagger(
      children: [
        Text(
          title,
          style: SignupTypography.title(),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: SignupTypography.subtitle(),
        ),
        const SizedBox(height: 34),
        ...children,
      ],
    );
  }
}

class SignupInlineFeedback extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const SignupInlineFeedback({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SignupPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.82),
          ),
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
                  style: SignupTypography.label().copyWith(
                    color: _signupText,
                    fontSize: 14,
                    height: 1.16,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: SignupTypography.bodySmall().copyWith(
                    color: _signupMuted,
                    height: 1.34,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const SignupTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _signupBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SignupTypography.label(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: _signupText,
          style: SignupTypography.field(),
          decoration: InputDecoration(
            filled: true,
            fillColor: _signupField,
            hintText: hintText,
            hintStyle: SignupTypography.field().copyWith(
              color: _signupDim,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ],
    );
  }
}

class SignupRuleRow extends StatelessWidget {
  final bool passed;
  final String text;

  const SignupRuleRow({required this.passed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? KeroseneIcons.success : KeroseneIcons.circle,
            size: 18,
            color: passed
                ? _signupText.withValues(alpha: 0.82)
                : _signupDim.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SignupTypography.bodySmall(
                color:
                    passed ? _signupText.withValues(alpha: 0.82) : _signupMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupRiskAcknowledgement extends StatelessWidget {
  final bool checked;
  final String text;
  final VoidCallback onTap;

  const SignupRiskAcknowledgement({
    required this.checked,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: checked ? _signupText : Colors.transparent,
              border: Border.all(color: checked ? _signupText : _signupDim),
            ),
            child: checked
                ? const Icon(KeroseneIcons.check, size: 13, color: _signupInk)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: SignupTypography.bodySmall(color: _signupMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final double borderRadius;

  const SignupPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background = outlined
        ? Colors.white.withValues(alpha: disabled ? 0.02 : 0.03)
        : disabled
            ? Colors.white.withValues(alpha: 0.42)
            : _signupText;
    final foreground = outlined ? _signupText : _signupInk;

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
              side: outlined
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.16))
                  : BorderSide.none,
            ),
            textStyle: SignupTypography.button(color: foreground),
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
              : Text(text),
        ),
      ),
    );
  }
}

class SignupPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const SignupPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _signupSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _signupBorderSoft),
      ),
      child: child,
    );
  }
}

class SignupSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const SignupSpinner({
    required this.size,
    required this.strokeWidth,
  });

  @override
  State<SignupSpinner> createState() => SignupSpinnerState();
}

class SignupSpinnerState extends State<SignupSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.calm,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthMotion.reduce(context)) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          color: _signupText,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
      );
    }

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: SignupSpinnerPainter(strokeWidth: widget.strokeWidth),
        ),
      ),
    );
  }
}

class SignupSpinnerPainter extends CustomPainter {
  final double strokeWidth;

  const SignupSpinnerPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _signupText;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.57,
      4.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SignupSpinnerPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}

class TotpQrBox extends StatelessWidget {
  final String data;
  final double size;

  const TotpQrBox({
    required this.data,
    this.size = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size >= 150 ? 12 : 8),
      decoration: BoxDecoration(
        color: _signupText,
        borderRadius: BorderRadius.circular(12),
      ),
      child: data.isEmpty
          ? const Center(
              child: Icon(KeroseneIcons.qr, color: _signupInk, size: 42),
            )
          : QrImageView(data: data, version: QrVersions.auto),
    );
  }
}

class TotpDigitBoxes extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const TotpDigitBoxes({
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<TotpDigitBoxes> createState() => TotpDigitBoxesState();
}

class TotpDigitBoxesState extends State<TotpDigitBoxes> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TotpDigitBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _focus() {
    if (widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.replaceAll(RegExp(r'\D'), '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.01,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final digit = index < code.length ? code[index] : '';
              final active = _focusNode.hasFocus && index == code.length;
              return AnimatedContainer(
                duration: AuthMotion.step,
                curve: KeroseneMotion.standard,
                width: 48,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _signupField,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? _signupText.withValues(alpha: 0.72)
                        : _signupBorder,
                  ),
                ),
                child: Text(
                  digit,
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: AppTypography.numericFontFamily,
                    color: _signupText,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class NumberedInstruction extends StatelessWidget {
  final int number;
  final String text;

  const NumberedInstruction({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _signupMuted),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: SignupTypography.bodySmall(color: _signupText).copyWith(
              color: _signupText,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: SignupTypography.bodySmall(color: _signupMuted),
          ),
        ),
      ],
    );
  }
}

class RecoveryCodesCopyButton extends StatelessWidget {
  final List<String> codes;
  final VoidCallback onCopied;

  const RecoveryCodesCopyButton({
    required this.codes,
    required this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      enabled: true,
      child: OutlinedButton.icon(
        onPressed: onCopied,
        icon: const Icon(KeroseneIcons.copy, size: 20),
        label: Text(_signupCopyRecoveryCodesAction(context)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: _signupText,
          backgroundColor: _signupField,
          side: const BorderSide(color: _signupBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: SignupTypography.button(color: _signupText).copyWith(
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _signupCopyRecoveryCodesAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Copy recovery codes',
    'es' => 'Copiar códigos de recuperación',
    _ => 'Copiar códigos de recuperação',
  };
}

class SignupBullet extends StatelessWidget {
  final String text;
  final IconData icon;

  const SignupBullet({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: _signupDim, size: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: SignupTypography.bodyMedium(color: _signupMuted),
            ),
          ),
        ],
      ),
    );
  }
}
