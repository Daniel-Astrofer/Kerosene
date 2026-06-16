import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/price_provider.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import '../../../../core/services/wallet_security_service.dart';
// [NEW]
import '../../../../core/utils/transaction_signer.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallets_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/send_bitcoin_usecase.dart';
import '../../domain/usecases/wallet_crud_usecases.dart'; // [NEW]
import '../../domain/usecases/create_unsigned_transaction_usecase.dart';
import '../../domain/usecases/broadcast_transaction_usecase.dart';
import '../../domain/usecases/get_deposit_address_usecase.dart';
import '../state/wallet_state.dart';

// ==================== Repository Providers ====================

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = LedgerRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);
  return LedgerRepositoryImpl(
    remoteDataSource: remoteDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = WalletRemoteDataSourceImpl(apiClient);
  final ledgerRemoteDataSource = LedgerRemoteDataSourceImpl(apiClient);
  final transactionRemoteDataSource =
      TransactionRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return WalletRepositoryImpl(
    remoteDataSource: remoteDataSource,
    ledgerRemoteDataSource: ledgerRemoteDataSource,
    transactionRemoteDataSource: transactionRemoteDataSource,
    authLocalDataSource: authLocalDataSource,
    walletSecurityService: WalletSecurityService(),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = TransactionRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return TransactionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});

// ==================== UseCase Providers ====================

final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return GetWalletsUseCase(repository);
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final sendBitcoinUseCaseProvider = Provider<SendBitcoinUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return SendBitcoinUseCase(repository);
});

// [NEW] Wallet CRUD Providers
final findWalletUseCaseProvider = Provider<FindWalletUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return FindWalletUseCase(repository);
});

final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return UpdateWalletUseCase(repository);
});

final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return DeleteWalletUseCase(repository);
});

final getLedgerBalanceUseCaseProvider = Provider<GetLedgerBalanceUseCase>((
  ref,
) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return GetLedgerBalanceUseCase(repository);
});

final deleteLedgerUseCaseProvider = Provider<DeleteLedgerUseCase>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return DeleteLedgerUseCase(repository);
});

final createUnsignedTransactionUseCaseProvider =
    Provider<CreateUnsignedTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CreateUnsignedTransactionUseCase(repository);
});

final broadcastTransactionUseCaseProvider =
    Provider<BroadcastTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return BroadcastTransactionUseCase(repository);
});

final getDepositAddressUseCaseProvider = Provider<GetDepositAddressUseCase>((
  ref,
) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetDepositAddressUseCase(repository);
});

// ==================== State Notifiers ====================

/// StateNotifier para gerenciar estado de carteiras
class WalletNotifier extends Notifier<WalletState> {
  late GetWalletsUseCase getWalletsUseCase;
  late WalletRepository walletRepository;

  @override
  WalletState build() {
    getWalletsUseCase = ref.watch(getWalletsUseCaseProvider);
    walletRepository = ref.watch(walletRepositoryProvider);
    return const WalletInitial();
  }
  // Não chamamos _loadWallets() aqui para evitar duplicação:
  // o HomeScreen.initState chama refresh() via addPostFrameCallback.

  /// Carrega carteiras e taxa de câmbio
  Future<void> _loadWallets({bool isRefresh = false}) async {
    if (!isRefresh || state is! WalletLoaded) {
      state = const WalletLoading();
    }

    final walletsResult = await getWalletsUseCase();

    const btcToUsdRate = 0.0;

    walletsResult.fold(
      (failure) {
        // If we fail to fetch wallets (e.g. 403, 401, timeout), we should emit an Error state, NOT an empty loaded state!
        state = WalletError(
          failure.message,
          statusCode: failure.statusCode,
          errorCode: failure.errorCode,
        );
      },
      (wallets) {
        state = WalletLoaded(
          wallets: wallets,
          selectedWallet: wallets.isNotEmpty ? wallets.first : null,
          btcToUsdRate: btcToUsdRate,
        );
      },
    );
  }

  /// Recarrega carteiras
  Future<void> refresh() async {
    await _loadWallets(isRefresh: true);
  }

  /// Seleciona uma carteira
  void selectWallet(Wallet wallet) {
    if (state is WalletLoaded) {
      final currentState = state as WalletLoaded;
      state = currentState.copyWith(selectedWallet: wallet);
    }
  }

  /// Atualiza saldo de uma carteira específica
  /// IMPORTANTE: walletId deve ser o NOME da wallet, não o ID numérico!
  Future<void> updateWalletBalance(String walletId) async {
    if (state is! WalletLoaded) return;

    final result = await walletRepository.updateWalletBalance(walletId);

    result.fold(
      (failure) {
        // Log error mas não muda estado para não interromper UX
        debugPrint('Wallet balance refresh failed.');
      },
      (updatedWallet) {
        final currentState = state as WalletLoaded;
        final updatedWallets = currentState.wallets.map((wallet) {
          // Comparar por NAME, não por ID!
          return wallet.name == walletId ? updatedWallet : wallet;
        }).toList();

        state = currentState.copyWith(wallets: updatedWallets);
      },
    );
  }

  /// Atualiza saldo de uma wallet via WebSocket (tempo real)
  /// Este método é chamado quando uma atualização de saldo é recebida via WebSocket
  void updateBalanceFromWebSocket(String walletName, double newBalance) {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;
    final updatedWallets = currentState.wallets.map((wallet) {
      if (wallet.name == walletName) {
        return wallet.copyWith(balance: newBalance);
      }
      return wallet;
    }).toList();

    state = currentState.copyWith(wallets: updatedWallets);

    debugPrint('Wallet balance refreshed from realtime feed.');
  }
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

// ==================== Transaction Notifier ====================

class TransactionNotifier extends Notifier<TransactionState> {
  late GetTransactionsUseCase getTransactionsUseCase;

  @override
  TransactionState build() {
    getTransactionsUseCase = ref.watch(getTransactionsUseCaseProvider);
    return const TransactionInitial();
  }

  Future<void> loadTransactions(String walletId, {int limit = 50}) async {
    state = const TransactionLoading();

    final result = await getTransactionsUseCase(
      walletId: walletId,
      limit: limit,
    );

    result.fold(
      (failure) => state = TransactionError(failure.message),
      (transactions) => state = TransactionLoaded(
        transactions: transactions,
        hasMore: transactions.length >= limit,
      ),
    );
  }

  // Falta implementar loadMore e refresh se necessário, mas para esse contexto
  // de correção de compilação, o básico basta. Vou manter simples.
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
        TransactionNotifier.new);

// ==================== Send Money Notifier ====================

class SendMoneyNotifier extends Notifier<SendMoneyState> {
  late SendBitcoinUseCase sendBitcoinUseCase;
  late WalletRepository walletRepository;
  late TransactionRepository transactionRepository;

  @override
  SendMoneyState build() {
    sendBitcoinUseCase = ref.watch(sendBitcoinUseCaseProvider);
    walletRepository = ref.watch(walletRepositoryProvider);
    transactionRepository = ref.watch(transactionRepositoryProvider);
    return const SendMoneyInitial();
  }

  /// Valida endereço e estima taxa
  Future<void> prepareTransaction({
    required String toAddress,
    required int amountSatoshis,
  }) async {
    state = const SendMoneyValidatingAddress();

    // Validar endereço
    final addressResult = await walletRepository.validateAddress(toAddress);

    final isValid = addressResult.fold((failure) => false, (valid) => valid);

    if (!isValid) {
      state = const SendMoneyError('Endereço Bitcoin inválido');
      return;
    }

    // Estimar taxa
    state = const SendMoneyEstimatingFee();

    final feeSatoshis = await _estimateNetworkFeeSats(amountSatoshis);
    if (feeSatoshis == null || feeSatoshis <= 0) {
      state = const SendMoneyError(
        'Não conseguimos calcular a taxa de rede agora. Tente novamente.',
      );
      return;
    }

    state = SendMoneyReady(
      toAddress: toAddress,
      amountSatoshis: amountSatoshis,
      feeSatoshis: feeSatoshis,
    );
  }

  Future<int?> _estimateNetworkFeeSats(int amountSatoshis) async {
    try {
      final estimate =
          await transactionRepository.estimateFee(amountSatoshis / 100000000.0);
      final estimatedStandardSats =
          (estimate.estimatedStandardBtc * 100000000).ceil();
      if (estimatedStandardSats > 0) {
        return estimatedStandardSats;
      }
      return (estimate.standardSatPerByte * 250).ceil();
    } catch (_) {
      return null;
    }
  }

  /// Executa envio de Bitcoin
  Future<void> sendBitcoin({
    required String fromWalletId,
    required String toAddress,
    required int amountSatoshis,
    required int feeSatoshis,
    String? description,
  }) async {
    state = const SendMoneySending();

    // 1. Tentar obter mnemônico (Autenticação Biométrica)
    final mnemonicResult = await walletRepository.getMnemonic();

    // Se obteve mnemônico com sucesso, prosseguir com fluxo Client-Side
    if (mnemonicResult.isRight() &&
        mnemonicResult.getOrElse(() => null) != null) {
      final mnemonic = mnemonicResult.getOrElse(() => null)!;

      try {
        // 2. Criar Transação Não Assinada (PSBT/Hex)
        // Precisamos do fromAddress. Se fromWalletId for o ID, precisamos buscar a wallet para ter o endereço?
        // Ou assumimos que o backend resolve pelo ID/Nome no createUnsigned?
        // createUnsignedTransaction pede fromAddress.
        // Vamos buscar a wallet para garantir.
        final walletResult = await walletRepository.getWalletById(fromWalletId);
        String fromAddress = fromWalletId; // Fallback

        walletResult.fold((_) {}, (w) {
          if (w.address.isNotEmpty) fromAddress = w.address;
        });

        final unsignedResult =
            await transactionRepository.createUnsignedTransaction(
          toAddress: toAddress,
          amount: amountSatoshis / 100000000.0,
          feeLevel: 'standard',
        );

        await unsignedResult.fold(
          (failure) async {
            // Se falhar criar unsigned, tentar fallback custodial?
            // Provavelmente erro de saldo ou backend.
            state = SendMoneyError(failure.message);
          },
          (unsignedTx) async {
            // 3. Assinar Localmente
            final signedTxHex = await TransactionSigner.sign(
              unsignedTx: unsignedTx,
              mnemonic: mnemonic,
            );

            // 4. Broadcast
            final broadcastResult =
                await transactionRepository.broadcastTransaction(
              rawTxHex: signedTxHex,
              toAddress: toAddress,
              amount: amountSatoshis / 100000000.0,
            );

            broadcastResult.fold(
              (failure) => state = SendMoneyError(failure.message),
              (txStatus) {
                // Keep local state in sync until history refresh returns.
                state = SendMoneySuccess(
                  Transaction(
                    id: txStatus.txid,
                    amountSatoshis: amountSatoshis,
                    feeSatoshis: feeSatoshis,
                    timestamp: DateTime.now(),
                    fromAddress: txStatus.sender.isNotEmpty
                        ? txStatus.sender
                        : fromAddress,
                    toAddress: txStatus.receiver.isNotEmpty
                        ? txStatus.receiver
                        : toAddress,
                    status: TransactionStatus.pending,
                    type: TransactionType.send,
                    confirmations: 0,
                    description: txStatus.context ?? description,
                  ),
                );

                // Refresh wallet balances and transaction history
                ref.read(walletProvider.notifier).refresh();
                ref
                    .read(transactionProvider.notifier)
                    .loadTransactions(fromWalletId);
              },
            );
          },
        );
      } catch (e) {
        state = SendMoneyError('Erro no fluxo seguro: $e');
      }
      return;
    }

    // Fallback: Fluxo Custodial / Legacy
    final result = await sendBitcoinUseCase(
      fromWalletId: fromWalletId,
      toAddress: toAddress,
      amountSatoshis: amountSatoshis,
      feeSatoshis: feeSatoshis,
      description: description,
    );

    result.fold((failure) => state = SendMoneyError(failure.message), (
      transaction,
    ) {
      state = SendMoneySuccess(transaction);

      // Refresh wallet balances andTransaction history
      ref.read(walletProvider.notifier).refresh();
      ref.read(transactionProvider.notifier).loadTransactions(fromWalletId);
    });
  }

  /// Reseta estado
  void reset() {
    state = const SendMoneyInitial();
  }
}

final sendMoneyProvider =
    NotifierProvider<SendMoneyNotifier, SendMoneyState>(SendMoneyNotifier.new);

// ==================== Total Balance Providers ====================

/// Provider for total BTC balance across all wallets
final totalBalanceBtcProvider = Provider<double>((ref) {
  final walletState = ref.watch(walletProvider);

  if (walletState is! WalletLoaded) return 0.0;

  return walletState.wallets.fold(0.0, (sum, wallet) {
    return sum + wallet.balance;
  });
});

/// Provider for total balance in USD using real-time price
final totalBalanceUsdProvider = Provider.autoDispose<double?>((ref) {
  final balanceBtc = ref.watch(totalBalanceBtcProvider);
  final priceAsync = ref.watch(backendBtcRatesProvider);

  return priceAsync.when(
    data: (rates) {
      final price = rates?.btcUsd;
      if (price == null || price <= 0) {
        return null;
      }
      return balanceBtc * price;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== UI State Providers ====================

class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final balanceVisibilityProvider =
    NotifierProvider<BalanceVisibilityNotifier, bool>(
        BalanceVisibilityNotifier.new);

class DecimalPrecisionNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final decimalPrecisionProvider =
    NotifierProvider<DecimalPrecisionNotifier, bool>(
        DecimalPrecisionNotifier.new);
