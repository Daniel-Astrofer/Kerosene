import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/utils/safe_display_text.dart';

import '../../domain/entities/wallet.dart';
import '../providers/balance_settings_provider.dart';
import 'package:kerosene/design_system/icons.dart';

/// Widget do card de balanço com gráfico circular
class WalletBalanceCard extends ConsumerWidget {
  final Wallet wallet;

  const WalletBalanceCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final responsive = context.responsive;
    const balanceLabel = 'Balance';
    const portfolioLabel = 'Total Portfolio Value';
    final chartSize = responsive.isTinyPhone ? 132.0 : 160.0;
    final innerSize = chartSize * 0.625;

    return Container(
      padding: EdgeInsets.all(responsive.isTinyPhone ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.hexFF1A1F3A, AppColors.hexFF0F1229],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.hexFF7B61FF.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gráfico circular de balanço
          SizedBox(
            width: chartSize,
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gráfico circular
                CustomPaint(
                  size: Size(chartSize, chartSize),
                  painter: BalanceChartPainter(
                    percentage: 0.65, // 65% do total
                  ),
                ),
                // Ícone central
                Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: AppColors.hexFF0F1229,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    KeroseneIcons.chart,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Label "Balance"
          Text(
            balanceLabel,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),

          // Endereço da carteira (mascarado)
          Text(
            SafeDisplayText.displayAddress(context, wallet.address),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.38),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Saldo em BTC
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                balanceSettings.formatBalance(wallet.balance),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: responsive.isTinyPhone ? 30 : 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Label "Total Portfolio"
          Text(
            portfolioLabel,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.54),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
      ..color = AppColors.hexFF1A1F3A
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, bgPaint);

    // Progress arc (gradiente)
    final rect = Rect.fromCircle(center: center, radius: radius - 6);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * percentage),
      colors: const [AppColors.hexFF7B61FF, AppColors.hexFF00D4FF],
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
