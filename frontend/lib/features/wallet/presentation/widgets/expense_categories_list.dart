import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import '../../domain/entities/expense_category.dart';

/// Lista de categorias de despesas - Refatorada
class ExpenseCategoriesList extends StatelessWidget {
  const ExpenseCategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ExpenseCategories.subscription,
      ExpenseCategories.grocery,
      ExpenseCategories.shopping,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.asMap().entries.map((entry) {
        return _buildCategoryCard(entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(ExpenseCategory category, int index) {
    return Expanded(
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              category.name.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${category.amountBTC.toStringAsFixed(8)} BTC',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 100).ms).fade().slideX(begin: 0.1, end: 0),
    );
  }
}
