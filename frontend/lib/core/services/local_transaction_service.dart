import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/wallet/domain/entities/transaction.dart';

class LocalTransactionService {
  static const String _transactionsKey = 'kerosene_transactions';

  Future<void> saveTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Transaction> transactions = await getTransactions();

    // Add new transaction at the beginning
    transactions.insert(0, transaction);

    final String jsonString = jsonEncode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_transactionsKey, jsonString);
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_transactionsKey);

    if (jsonString == null) {
      // Seed data on first run to show features are active
      final seeded = _seedData();
      await prefs.setString(
        _transactionsKey,
        jsonEncode(seeded.map((t) => t.toJson()).toList()),
      );
      return seeded;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  List<Transaction> _seedData() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'seed-1',
        fromAddress: 'External',
        toAddress: 'Me',
        amountSatoshis: 1000000, // 0.01 BTC
        feeSatoshis: 0,
        status: TransactionStatus.confirmed,
        type: TransactionType.receive,
        confirmations: 12,
        timestamp: now.subtract(const Duration(hours: 2)),
        description: "Welcome Bonus",
      ),
      Transaction(
        id: 'seed-2',
        fromAddress: 'Me',
        toAddress: 'External',
        amountSatoshis: 50000, // 0.0005 BTC
        feeSatoshis: 1000,
        status: TransactionStatus.confirmed,
        type: TransactionType.send,
        confirmations: 6,
        timestamp: now.subtract(const Duration(days: 1)),
        description: "Initial Setup",
      ),
    ];
  }

  Future<void> removeTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Transaction> transactions = await getTransactions();

    transactions.removeWhere((t) => t.id == id);

    final String jsonString = jsonEncode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_transactionsKey, jsonString);
  }

  Future<void> clearTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
  }
}
