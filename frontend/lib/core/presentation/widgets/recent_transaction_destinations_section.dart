import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';

const Color _recentDestinationPanelColor = Color(0xFF0D0D0D);
const Color _recentDestinationBorderColor = Color(0xFF262626);
const Color _recentDestinationTextColor = Color(0xFFF1F1ED);
const Color _recentDestinationMutedTextColor = Color(0xFFA0A09B);
const Color _recentDestinationFaintTextColor = Color(0xFF6B6B66);

class RecentTransactionDestinationsSection extends StatelessWidget {
  final List<RecentTransactionDestination> destinations;
  final ValueChanged<RecentTransactionDestination> onSelect;
  final String title;
  final int maxItems;
  final double radius;

  const RecentTransactionDestinationsSection({
    super.key,
    required this.destinations,
    required this.onSelect,
    required this.title,
    this.maxItems = 4,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleDestinations =
        destinations.take(maxItems).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _recentDestinationFaintTextColor,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: _recentDestinationPanelColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _recentDestinationBorderColor),
          ),
          child: Column(
            children: [
              for (var index = 0;
                  index < visibleDestinations.length;
                  index++) ...[
                _RecentDestinationRow(
                  destination: visibleDestinations[index],
                  onTap: () => onSelect(visibleDestinations[index]),
                  radius: radius,
                ),
                if (index != visibleDestinations.length - 1)
                  Divider(
                    height: 1,
                    color: _recentDestinationBorderColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentDestinationRow extends StatelessWidget {
  final RecentTransactionDestination destination;
  final VoidCallback onTap;
  final double radius;

  const _RecentDestinationRow({
    required this.destination,
    required this.onTap,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                _iconFor(destination.kind),
                size: 17,
                color: _recentDestinationMutedTextColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _recentDestinationTextColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'JetBrainsMono',
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.label ?? _kindLabel(destination.kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _recentDestinationMutedTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.cornerDownLeft,
                size: 16,
                color: _recentDestinationFaintTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(RecentTransactionDestinationKind kind) {
    return switch (kind) {
      RecentTransactionDestinationKind.internal => LucideIcons.user,
      RecentTransactionDestinationKind.onChain => LucideIcons.link,
      RecentTransactionDestinationKind.lightning => LucideIcons.zap,
    };
  }

  String _kindLabel(RecentTransactionDestinationKind kind) {
    return switch (kind) {
      RecentTransactionDestinationKind.internal => 'Transferencia interna',
      RecentTransactionDestinationKind.onChain => 'Endereco on-chain',
      RecentTransactionDestinationKind.lightning => 'Invoice Lightning',
    };
  }
}
