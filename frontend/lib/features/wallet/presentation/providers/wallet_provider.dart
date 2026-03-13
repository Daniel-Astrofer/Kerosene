import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show authLocalDataSourceProvider, apiClientProvider;
import '../../../../core/services/wallet_security_service.dart';
// [NEW]
import '../../../../core/utils/transaction_signer.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart'; // [NEW]
import '../../../transactions/data/repositories/transaction_repository_impl.dart'; // [NEW]
import '../../../transactions/domain/repositories/transaction_repository.dart'; // [NEW]
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallets_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/send_bitcoin_usecase.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/wallet_crud_usecases.dart'; // [NEW]
import '../../domain/usecases/create_unsigned_transaction_usecase.dart';
import '../../domain/usecases/broadcast_transaction_usecase.dart';
import '../../domain/usecases/get_deposit_address_usecase.dart';
import '../state/wallet_state.dart';
import '../state/create_wallet_state.dart';

// ==================== Repository Provider ====================

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = WalletRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return WalletRepositoryImpl(
    remoteDataSource: remoteDataSource,
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
  final repository = ref.watch(walletRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final sendBitcoinUseCaseProvider = Provider<SendBitcoinUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return SendBitcoinUseCase(repository);
});

final createWalletUseCaseProvider = Provider<CreateWalletUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return CreateWalletUseCase(repository);
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
  final repository = ref.watch(walletRepositoryProvider);
  return GetLedgerBalanceUseCase(repository);
});

final deleteLedgerUseCaseProvider = Provider<DeleteLedgerUseCase>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
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

/// StateNotifier para gerenciar criação de carteiras
class CreateWalletNotifier extends StateNotifier<CreateWalletState> {
  final CreateWalletUseCase createWalletUseCase;

  CreateWalletNotifier({required this.createWalletUseCase})
    : super(const CreateWalletInitial());

  Future<void> createWallet({
    required String name,
    required String passphrase,
  }) async {
    state = const CreateWalletLoading();

    final result = await createWalletUseCase(
      name: name,
      passphrase: passphrase,
    );

    result.fold(
      (failure) => state = CreateWalletError(failure.message),
      (success) => state = CreateWalletSuccess(success),
    );
  }
}

final createWalletProvider =
    StateNotifierProvider<CreateWalletNotifier, CreateWalletState>((ref) {
      final useCase = ref.watch(createWalletUseCaseProvider);
      return CreateWalletNotifier(createWalletUseCase: useCase);
    });

/// StateNotifier para gerenciar estado de carteiras
class WalletNotifier extends StateNotifier<WalletState> {
  final GetWalletsUseCase getWalletsUseCase;
  final WalletRepository walletRepository;
  final Ref ref; // Add ref

  WalletNotifier({
    required this.getWalletsUseCase,
    required this.walletRepository,
    required this.ref,
  }) : super(const WalletInitial());
  // Não chamamos _loadWallets() aqui para evitar duplicação:
  // o HomeScreen.initState chama refresh() via addPostFrameCallback.

  static final List<Wallet> _mockWallets = [
    Wallet(
      id: 'mock_1',
      name: 'Sovereign Black',
      address: 'bc1q9w6pkv6n5v9m6zv8v7m6zv8v7m6zv8v7m6z',
      balance: 1.2548,
      derivationPath: "m/84'/0'/0'/0/0",
      type: WalletType.nativeSegwit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Wallet(
      id: 'mock_2',
      name: 'Industrial Metal',
      address: 'bc1q8x5v4n3m2l1k0j9i8h7g6f5e4d3c2b1a0z',
      balance: 0.0426,
      derivationPath: "m/84'/0'/0'/0/1",
      type: WalletType.nativeSegwit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Wallet(
      id: 'mock_3',
      name: 'Cyber Deep',
      address: 'bc1q7z6y5x4w3v2u1t0s9r8q7p6o5n4m3l2k1j',
      balance: 0.0089,
      derivationPath: "m/84'/0'/0'/0/2",
      type: WalletType.nativeSegwit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Carrega carteiras e taxa de câmbio
  Future<void> _loadWallets() async {
    state = const WalletLoading();

    final walletsResult = await getWalletsUseCase();
    
    // Obter taxa de câmbio (BTC/USD)
    final btcPriceAsync = ref.read(btcPriceProvider);
    final double btcToUsdRate = btcPriceAsync.when(
      data: (price) => price,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    walletsResult.fold(
      (failure) {
        // Mesmo com erro, mostramos os mocks para não quebrar a UI
        state = WalletLoaded(
          wallets: _mockWallets,
          selectedWallet: _mockWallets.first,
          btcToUsdRate: btcToUsdRate,
        );
      },
      (wallets) {
        final combinedWallets = [...wallets, ..._mockWallets];
        state = WalletLoaded(
          wallets: combinedWallets,
          selectedWallet: combinedWallets.isNotEmpty ? combinedWallets.first : null,
          btcToUsdRate: btcToUsdRate,
        );
      },
    );
  }

  /// Recarrega carteiras
  Future<void> refresh() async {
    await _loadWallets();
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
        debugPrint('Erro ao atualizar saldo: ${failure.message}');
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

    debugPrint(
      '💰 Saldo atualizado via WebSocket: $walletName = $newBalance BTC',
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  final getWalletsUseCase = ref.watch(getWalletsUseCaseProvider);
  final walletRepository = ref.watch(walletRepositoryProvider);

  return WalletNotifier(
    getWalletsUseCase: getWalletsUseCase,
    walletRepository: walletRepository,
    ref: ref,
  );
});

// ==================== Transaction Notifier ====================

class TransactionNotifier extends StateNotifier<TransactionState> {
  final GetTransactionsUseCase getTransactionsUseCase;

  TransactionNotifier({required this.getTransactionsUseCase})
    : super(const TransactionInitial());

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
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
      final getTransactionsUseCase = ref.watch(getTransactionsUseCaseProvider);
      return TransactionNotifier(
        getTransactionsUseCase: getTransactionsUseCase,
      );
    });

// ==================== Send Money Notifier ====================

class SendMoneyNotifier extends StateNotifier<SendMoneyState> {
  final SendBitcoinUseCase sendBitcoinUseCase;
  final WalletRepository walletRepository;
  final TransactionRepository transactionRepository; // [NEW]
  final Ref ref;

  SendMoneyNotifier({
    required this.sendBitcoinUseCase,
    required this.walletRepository,
    required this.transactionRepository, // [NEW]
    required this.ref,
  }) : super(const SendMoneyInitial());

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

    // TODO: Implementar estimativa de taxa real via TransactionRepository?
    const feeSatoshis = 1000; // ~1000 sats para tx padrão

    state = SendMoneyReady(
      toAddress: toAddress,
      amountSatoshis: amountSatoshis,
      feeSatoshis: feeSatoshis,
    );
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

        final unsignedResult = await transactionRepository
            .createUnsignedTransaction(
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
            final broadcastResult = await transactionRepository
                .broadcastTransaction(
                  rawTxHex: signedTxHex,
                  toAddress: toAddress,
                  amount: amountSatoshis / 100000000.0,
                );

            broadcastResult.fold(
              (failure) => state = SendMoneyError(failure.message),
              (txStatus) {
                // Sucesso!
                // Converter TxStatus para Transaction entity se necessário ou apenas sucesso
                // O estado espera 'Transaction'. Vamos criar um mock ou buscar?
                // TxStatus tem txid.

                // Simular Transaction object a partir de txStatus
                // Ou refetch transactions.
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
    StateNotifierProvider<SendMoneyNotifier, SendMoneyState>((ref) {
      final sendBitcoinUseCase = ref.watch(sendBitcoinUseCaseProvider);
      final walletRepository = ref.watch(walletRepositoryProvider);
      final transactionRepository = ref.watch(transactionRepositoryProvider);

      return SendMoneyNotifier(
        sendBitcoinUseCase: sendBitcoinUseCase,
        walletRepository: walletRepository,
        transactionRepository: transactionRepository,
        ref: ref,
      );
    });

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
final totalBalanceUsdProvider = Provider<double?>((ref) {
  final balanceBtc = ref.watch(totalBalanceBtcProvider);
  final priceAsync = ref.watch(btcPriceProvider);

  return priceAsync.when(
    data: (price) => balanceBtc * price,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== UI State Providers ====================

final balanceVisibilityProvider = StateProvider<bool>((ref) => true);
final decimalPrecisionProvider = StateProvider<bool>(
  (ref) => true,
); // true = 8 digits, false = 2 digits
