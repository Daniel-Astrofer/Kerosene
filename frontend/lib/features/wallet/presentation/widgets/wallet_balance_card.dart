import 'package:flutter/material.dart';
import '../../domain/entities/wallet.dart';
import 'dart:math' as math;

/// Widget do card de balanço com gráfico circular
class WalletBalanceCard extends StatelessWidget {
  final Wallet wallet;
  final double btcToUsdRate;

  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.btcToUsdRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A),
            const Color(0xFF0F1229),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gráfico circular de balanço
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gráfico circular
                CustomPaint(
                  size: const Size(160, 160),
                  painter: BalanceChartPainter(
                    percentage: 0.65, // 65% do total
                  ),
                ),
                // Ícone central
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1229),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Label "Balance"
          const Text(
            'Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),

          // Endereço da carteira (mascarado)
          Text(
            _maskAddress(wallet.address),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Saldo em USD
          Text(
            wallet.balanceInUSD(btcToUsdRate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Saldo em BTC
          Text(
            '${wallet.balanceBTC.toStringAsFixed(8)} BTC',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _maskAddress(String address) {
    if (address.length <= 8) return address;
    return '${address.substring(0, 4)} ${address.substring(4, 8)} ${address.substring(8, 12)} ${address.substring(12, 16)}';
  }
}

/// Painter para o gráfico circular de balanço
class BalanceChartPainter extends CustomPainter {
  final double percentage;

  BalanceChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle (cinza)
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1F3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, bgPaint);

    // Progress arc (gradiente)
    final rect = Rect.fromCircle(center: center, radius: radius - 6);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * percentage),
      colors: const [
        Color(0xFF7B61FF),
        Color(0xFF00D4FF),
      ],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(BalanceChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
