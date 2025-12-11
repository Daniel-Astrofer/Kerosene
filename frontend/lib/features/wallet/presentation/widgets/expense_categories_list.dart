import 'package:flutter/material.dart';
import '../../domain/entities/expense_category.dart';

/// Lista de categorias de despesas
class ExpenseCategoriesList extends StatelessWidget {
  const ExpenseCategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Obter categorias reais do provider
    final categories = [
      ExpenseCategories.subscription,
      ExpenseCategories.grocery,
      ExpenseCategories.shopping,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((category) {
        return _buildCategoryCard(category);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(ExpenseCategory category) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              category.icon,
              color: category.color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${(category.amountSatoshis / 100000000 * 50000).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
