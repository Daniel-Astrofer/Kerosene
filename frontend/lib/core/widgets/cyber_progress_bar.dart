import 'package:flutter/material.dart';

class CyberProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const CyberProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 10, // Default total steps for signup
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: currentStep,
          child: Container(
            height: 2,
            color: const Color(0xFF2962FF),
          ),
        ),
        Expanded(
          flex: totalSteps - currentStep,
          child: Container(
            height: 2,
            color: const Color(0xFF1E1E24),
          ),
        ),
      ],
    );
  }
}
