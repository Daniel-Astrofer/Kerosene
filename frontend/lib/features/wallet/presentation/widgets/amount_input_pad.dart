import 'package:flutter/material.dart';

/// Widget do teclado numérico para input de valores
class AmountInputPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onDecimal;

  const AmountInputPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onDecimal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 16),

          // Linha 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 16),

          // Linha 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 16),

          // Linha 4: 00, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('00'),
              _buildKey('0'),
              _buildActionKey(
                Icons.backspace_outlined,
                onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => onNumberPressed(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1229),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1229),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
