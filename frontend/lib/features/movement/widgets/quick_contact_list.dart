import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';

/// Lista de contatos rápidos - Refatorada
class QuickContactList extends StatelessWidget {
  const QuickContactList({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      ('Add', KeroseneIcons.plus, null),
      ('GA', null, 'Gilbert'),
      ('SC', null, 'Steph'),
      ('HW', null, 'Harris'),
      ('GN', null, 'Giannis'),
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactItem(
            label: contact.$1,
            icon: contact.$2,
            name: contact.$3,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildContactItem({
    required String label,
    IconData? icon,
    String? name,
    required int index,
  }) {
    final bool isAdd = icon != null;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isAdd
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isAdd ? null : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isAdd
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  if (isAdd)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: isAdd
                    ? Icon(icon, color: Colors.white, size: 24)
                    : Text(
                        label,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            (name ?? label).toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      )
          .animate(delay: (index * 50).ms)
          .fade()
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }
}
