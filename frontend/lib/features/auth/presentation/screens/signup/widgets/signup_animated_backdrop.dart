import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';

class SignupAnimatedBackdrop extends StatelessWidget {
  const SignupAnimatedBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.onboardingBackgroundGradient,
      ),
      child: SizedBox.expand(),
    );
  }
}
