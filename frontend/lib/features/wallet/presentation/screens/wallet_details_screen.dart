import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_card.dart';
import 'send_money_screen.dart';
import 'withdraw_screen.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class WalletDetailsScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  ConsumerState<WalletDetailsScreen> createState() =>
      _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends ConsumerState<WalletDetailsScreen> {
  bool _isBlocked = false;
  String _selectedFilter = 'Transações';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Hero Wallet Card
              Hero(
                tag: 'wallet-card-${widget.wallet.id}',
                child: Opacity(
                  opacity: _isBlocked ? 0.5 : 1.0,
                  child: WalletCard(wallet: widget.wallet, isSelected: true),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "HISTÓRICO",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: _buildFilterChips(),
              ),
              const SizedBox(height: 16),
              _buildTransactionHistory(),
              const SizedBox(height: 32),

              // Management Menu
              _buildMenuItem(
                icon: Icons.edit_outlined,
                label: "Alterar nome do cartão",
                onTap: () => _showEditDialog(context),
              ),
              _buildMenuItem(
                icon: _isBlocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                label: _isBlocked ? "Desbloquear cartão" : "Bloquear cartão",
                onTap: () {
                  setState(() {
                    _isBlocked = !_isBlocked;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isBlocked ? "Cartão bloqueado" : "Cartão desbloqueado",
                      ),
                      backgroundColor: _isBlocked
                          ? Colors.redAccent
                          : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDestructive: !_isBlocked,
              ),
              _buildMenuItem(
                icon: Icons.account_balance_wallet_rounded,
                label: "Saque On-chain",
                onTap: () {
                  if (_isBlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Desbloqueie o cartão para realizar saques",
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WithdrawScreen(walletId: widget.wallet.name),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.send_rounded,
                label: "Passar",
                onTap: () {
                  if (_isBlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Desbloqueie o cartão para realizar transferências",
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SendMoneyScreen(walletId: widget.wallet.name),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.delete_outline_rounded,
                label: "Apagar cartão",
                onTap: () => _showDeleteDialog(context),
                isDestructive: true,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.redAccent : Colors.white70,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDestructive
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.wallet.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectanglePlatform.isIOS
            ? null
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Alterar nome",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Novo nome",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final useCase = ref.read(updateWalletUseCaseProvider);
                final result = await useCase(
                  name: widget.wallet.name,
                  newName: newName,
                );
                result.fold(
                  (l) => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.message))),
                  (r) {
                    ref.read(walletProvider.notifier).refresh();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F288),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Apagar cartão",
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Esta ação não pode ser desfeita. Digite sua senha para confirmar:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Senha",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final passphrase = controller.text.trim();
              if (passphrase.isNotEmpty) {
                final useCase = ref.read(deleteWalletUseCaseProvider);
                final result = await useCase(
                  name: widget.wallet.name,
                  passphrase: passphrase,
                );
                result.fold(
                  (l) => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l.message))),
                  (r) {
                    ref.read(walletProvider.notifier).refresh();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                );
              }
            },
            child: const Text("Apagar"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip('Transações'),
          const SizedBox(width: 8),
          _buildChip('Depósitos'),
          const SizedBox(width: 8),
          _buildChip('Saques'),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF7931A)
                : Colors.white.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final historyAsync = ref.watch(transactionHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Color(0xFFF7931A),
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erro ao carregar histórico',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ),
      data: (allTransactions) {
        final filteredList = allTransactions.where((tx) {
          if (_selectedFilter == 'Depósitos') {
            return tx.type == TransactionType.receive;
          } else if (_selectedFilter == 'Saques') {
            return tx.type == TransactionType.send;
          }
          return true; // Transações (All)
        }).toList();

        return RecentTransactionsList(transactions: filteredList);
      },
    );
  }
}

// Dummy class to fix RoundedRectanglePlatform undefined error if it occurs or just use normal border
class RoundedRectanglePlatform {
  static bool get isIOS => false; // Simplified
}
