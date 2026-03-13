import 'package:flutter/material.dart';

class FearAndGreedWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const FearAndGreedWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final value = int.tryParse(data['value'] ?? '0') ?? 0;
    final classification = data['value_classification'] ?? 'Unknown';

    Color getColor(int val) {
      if (val < 25) return const Color(0xFFFF0055); // Extreme Fear
      if (val < 45) return Colors.orangeAccent; // Fear
      if (val < 55) return Colors.yellowAccent; // Neutral
      if (val < 75) return Colors.lightGreenAccent; // Greed
      return const Color(0xFF00FF94); // Extreme Greed
    }

    final color = getColor(value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fear & Greed Index",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.speed_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speedometer / Gauge Implementation (Simplified as Progress Arc or Text)
              // For now, let's use a nice circular indicator or just big text
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: value / 100,
                      color: color,
                      backgroundColor: Colors.white10,
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    "$value",
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classification,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Market Sentiment",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
