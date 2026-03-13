import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entidade ExpenseCategory - Categoria de despesas
final class ExpenseCategory extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int amountSatoshis;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.amountSatoshis,
  });

  /// Valor em BTC
  double get amountBTC => amountSatoshis / 100000000.0;

  /// Valor formatado em USD
  String amountInUSD(double btcToUsdRate) {
    final usdValue = amountBTC * btcToUsdRate;
    return '\$${usdValue.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [id, name, icon, color, amountSatoshis];
}

/// Categorias pré-definidas
class ExpenseCategories {
  static const subscription = ExpenseCategory(
    id: 'subscription',
    name: 'Subscription',
    icon: Icons.subscriptions_outlined,
    color: Color(0xFF7B61FF),
    amountSatoshis: 12100000, // ~$121.00 em exemplo
  );

  static const grocery = ExpenseCategory(
    id: 'grocery',
    name: 'Grocery',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFF7B61FF),
    amountSatoshis: 12100000,
  );

  static const shopping = ExpenseCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_cart_outlined,
    color: Color(0xFF7B61FF),
    amountSatoshis: 12100000,
  );
}
