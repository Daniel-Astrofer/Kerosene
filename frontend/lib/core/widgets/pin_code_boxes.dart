import 'package:flutter/material.dart';

class PinCodeBoxes extends StatelessWidget {
  final int length;
  final TextEditingController controller;
  final Function(String) onChanged;

  const PinCodeBoxes({
    super.key,
    this.length = 6,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visible Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(length, (index) {
            final text = controller.text;
            final char = index < text.length ? text[index] : '';
            return Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF151515), // Dark block
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                char,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
        // Hidden TextField to capture input
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: length,
              onChanged: onChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
