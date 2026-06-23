// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';

import 'signup_flow_components.dart';

const Color _signupPanel = AppColors.hexFF111111;
const Color _signupBorderSoft = AppColors.hexFF27272A;

class SignupSuccessScene extends StatefulWidget {
  final String appTitle;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onContinue;

  const SignupSuccessScene({
    required this.appTitle,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onContinue,
  });

  @override
  State<SignupSuccessScene> createState() => SignupSuccessSceneState();
}

class SignupSuccessSceneState extends State<SignupSuccessScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AuthMotion.ceremonial,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthMotion.reduce(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final badgeProgress = AuthMotion.reduce(context)
            ? 1.0
            : _easeInOut(_interval(_controller.value, 0, 0.32));
        final headingProgress =
            _easeInOut(_interval(_controller.value, 0.18, 0.62));
        final bodyProgress =
            _easeInOut(_interval(_controller.value, 0.32, 0.82));
        final buttonProgress =
            _easeInOut(_interval(_controller.value, 0.56, 1));

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  context.responsive.isTinyPhone ? 24.0 : 32.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Semantics(
                      label: widget.appTitle,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          Opacity(
                            opacity: badgeProgress,
                            child: Transform.scale(
                              scale: 0.92 + (0.08 * badgeProgress),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _signupPanel,
                                  border: Border.all(color: _signupBorderSoft),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.hexFF63FEA7
                                          .withValues(alpha: 0.15),
                                      blurRadius: 60,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.hexFF63FEA7
                                            .withValues(alpha: 0.10),
                                      ),
                                    ),
                                    const Icon(
                                      KeroseneIcons.success,
                                      color: AppColors.hexFF63FEA7,
                                      size: 52,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Opacity(
                            opacity: headingProgress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - headingProgress)),
                              child: Text(
                                _withSuccessBang(widget.title),
                                textAlign: TextAlign.center,
                                style: SignupTypography.successTitle(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: bodyProgress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - bodyProgress)),
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                style: SignupTypography.successSubtitle(),
                              ),
                            ),
                          ),
                          const Spacer(flex: 3),
                          Opacity(
                            opacity: buttonProgress,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - buttonProgress)),
                              child: SignupPrimaryButton(
                                text: widget.actionLabel,
                                onPressed: widget.onContinue,
                                borderRadius: 999,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static double _interval(double value, double start, double end) {
    if (value <= start) {
      return 0;
    }
    if (value >= end) {
      return 1;
    }
    return (value - start) / (end - start);
  }

  static double _easeInOut(double value) {
    return KeroseneMotion.standard.transform(value.clamp(0.0, 1.0));
  }

  static String _withSuccessBang(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('!')) {
      return trimmed;
    }
    return '$trimmed!';
  }
}
