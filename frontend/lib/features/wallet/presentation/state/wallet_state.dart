import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';

/// Estados da feature Wallet usando sealed classes para type-safety
sealed class WalletState {
  const WalletState();
}

/// Estado inicial
final class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Estado de carregamento
final class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Estado com carteiras carregadas
final class WalletLoaded extends WalletState {
  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final double btcToUsdRate;

  const WalletLoaded({
    required this.wallets,
    this.selectedWallet,
    required this.btcToUsdRate,
  });

  /// Saldo total em satoshis
  int get totalBalanceSatoshis =>
      wallets.fold(0, (sum, wallet) => sum + wallet.balanceSatoshis);

  /// Saldo total em BTC
  double get totalBalanceBTC => totalBalanceSatoshis / 100000000.0;

  /// Saldo total em USD
  double get totalBalanceUSD => totalBalanceBTC * btcToUsdRate;

  WalletLoaded copyWith({
    List<Wallet>? wallets,
    Wallet? selectedWallet,
    double? btcToUsdRate,
  }) {
    return WalletLoaded(
      wallets: wallets ?? this.wallets,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      btcToUsdRate: btcToUsdRate ?? this.btcToUsdRate,
    );
  }
}

/// Estado de erro
final class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);
}

// ==================== Transaction States ====================

/// Estados de transações
sealed class TransactionState {
  const TransactionState();
}

/// Estado inicial
final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// Estado de carregamento
final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

/// Estado com transações carregadas
final class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final bool hasMore;

  const TransactionLoaded({
    required this.transactions,
    this.hasMore = false,
  });

  /// Transações pendentes
  List<Transaction> get pendingTransactions =>
      transactions.where((tx) => tx.isPending).toList();

  /// Transações confirmadas
  List<Transaction> get confirmedTransactions =>
      transactions.where((tx) => tx.isConfirmed).toList();

  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Estado de erro
final class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);
}

// ==================== Send Money States ====================

/// Estados de envio de dinheiro
sealed class SendMoneyState {
  const SendMoneyState();
}

/// Estado inicial
final class SendMoneyInitial extends SendMoneyState {
  const SendMoneyInitial();
}

/// Estado de validação de endereço
final class SendMoneyValidatingAddress extends SendMoneyState {
  const SendMoneyValidatingAddress();
}

/// Estado de estimativa de taxa
final class SendMoneyEstimatingFee extends SendMoneyState {
  const SendMoneyEstimatingFee();
}

/// Estado pronto para enviar
final class SendMoneyReady extends SendMoneyState {
  final String toAddress;
  final int amountSatoshis;
  final int feeSatoshis;

  const SendMoneyReady({
    required this.toAddress,
    required this.amountSatoshis,
    required this.feeSatoshis,
  });

  int get totalSatoshis => amountSatoshis + feeSatoshis;
  double get totalBTC => totalSatoshis / 100000000.0;
}

/// Estado de envio em progresso
final class SendMoneySending extends SendMoneyState {
  const SendMoneySending();
}

/// Estado de sucesso
final class SendMoneySuccess extends SendMoneyState {
  final Transaction transaction;

  const SendMoneySuccess(this.transaction);
}

/// Estado de erro
final class SendMoneyError extends SendMoneyState {
  final String message;

  const SendMoneyError(this.message);
}
