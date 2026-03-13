import 'package:flutter/material.dart';
import '../providers/market_provider.dart';

class OrderBookWidget extends StatelessWidget {
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;

  const OrderBookWidget({super.key, required this.bids, required this.asks});

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty && asks.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleAsks = asks.take(5).toList().reversed.toList();
    final visibleBids = bids.take(5).toList();

    // Compute max amount for depth bar scaling
    final allVisible = [...visibleAsks, ...visibleBids];
    final maxAmount = allVisible.fold<double>(
      0.0,
      (prev, e) => e.amount > prev ? e.amount : prev,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order Book",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0055),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Sellers",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF94),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Buyers",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Headers
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Price",
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
              const Expanded(
                child: Text(
                  "Amount",
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Asks (Sellers) - Red
          Column(
            children: visibleAsks
                .map(
                  (e) => _buildRow(
                    e,
                    const Color(0xFFFF0055),
                    maxAmount,
                    isAsk: true,
                  ),
                )
                .toList(),
          ),

          const Divider(color: Colors.white10, height: 16),

          // Bids (Buyers) - Green
          Column(
            children: visibleBids
                .map(
                  (e) => _buildRow(
                    e,
                    const Color(0xFF00FF94),
                    maxAmount,
                    isAsk: false,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    OrderBookEntry entry,
    Color color,
    double maxAmount, {
    required bool isAsk,
  }) {
    final ratio = maxAmount > 0
        ? (entry.amount / maxAmount).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth * ratio;

          return Stack(
            children: [
              // Depth bar background
              Align(
                alignment: isAsk ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 24,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Text content
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        entry.price.toStringAsFixed(2),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        entry.amount.toStringAsFixed(4),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
