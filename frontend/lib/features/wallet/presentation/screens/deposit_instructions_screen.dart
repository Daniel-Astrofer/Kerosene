import 'package:flutter/material.dart';

/// Luxury Deposit Instructions Screen — matches Figma "Luxury Deposit Instructions Screen"
class DepositInstructionsScreen extends StatelessWidget {
  const DepositInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    _buildSecureBadge(),
                    const SizedBox(height: 28),
                    _buildInstructionsCard(),
                    const SizedBox(height: 32),
                    _buildContinueButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'DEPOSIT BTC',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSecureBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00C896).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00C896).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: Color(0xFF00C896),
              size: 12,
            ),
            const SizedBox(width: 6),
            const Text(
              'SECURE',
              style: TextStyle(
                color: Color(0xFF00C896),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D1FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF00D1FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Instruções de Depósito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Instructions list
          _buildInstructionItem(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF00D1FF),
            label: 'Rede',
            title: 'Only deposit BTC from the',
            highlight: 'Lightning network',
            highlightColor: const Color(0xFF00D1FF),
            suffix: '.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: Icons.south_rounded,
            iconColor: const Color(0xFF00C896),
            label: 'Mínimo',
            title: 'Minimum deposit is',
            highlight: '0.000001 BTC',
            highlightColor: const Color(0xFF00C896),
            suffix: '.',
            note: 'Depósitos abaixo deste valor serão perdidos.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: Icons.north_rounded,
            iconColor: const Color(0xFFFFB938),
            label: 'Máximo',
            title: 'Maximum deposit is',
            highlight: '1.00 BTC',
            highlightColor: const Color(0xFFFFB938),
            suffix: ' per transaction.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF9B59FF),
            label: 'Processamento',
            title: 'Processing Time is',
            highlight: '< 1 Minute',
            highlightColor: const Color(0xFF9B59FF),
            suffix: ' via Lightning.',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String title,
    required String highlight,
    required Color highlightColor,
    String suffix = '',
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: '$title '),
                      TextSpan(
                        text: highlight,
                        style: TextStyle(
                          color: highlightColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: suffix),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D1FF), Color(0xFF00FFE0)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Navigator.pop(context),
            child: const Center(
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
