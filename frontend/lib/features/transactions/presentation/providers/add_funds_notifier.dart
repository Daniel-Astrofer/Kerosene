import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/domain/usecases/create_unsigned_transaction_usecase.dart';
import '../../../wallet/domain/usecases/broadcast_transaction_usecase.dart';
import '../../../wallet/domain/usecases/get_deposit_address_usecase.dart';
import '../../domain/usecases/create_payment_link_usecase.dart';
import '../../domain/providers/payment_link_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import '../../../../core/utils/transaction_signer.dart';
import '../state/add_funds_state.dart';

class AddFundsNotifier extends StateNotifier<AddFundsState> {
  final CreateUnsignedTransactionUseCase createUnsignedTransactionUseCase;
  final BroadcastTransactionUseCase broadcastTransactionUseCase;
  final GetDepositAddressUseCase getDepositAddressUseCase;
  final CreatePaymentLinkUseCase createPaymentLinkUseCase;

  final Ref ref;

  AddFundsNotifier({
    required this.createUnsignedTransactionUseCase,
    required this.broadcastTransactionUseCase,
    required this.getDepositAddressUseCase,
    required this.createPaymentLinkUseCase,
    required this.ref,
  }) : super(const AddFundsInitial());

  Future<void> loadDepositAddress() async {
    state = const AddFundsLoading(message: 'Loading deposit address...');
    final result = await getDepositAddressUseCase();
    result.fold(
      (failure) => state = AddFundsError(failure.message),
      (address) => state = AddFundsLoadedDepositAddress(address),
    );
  }

  Future<void> initiateDeposit({
    required String fromAddress,
    required String toAddress,
    required double amountBTC,
    required int feeSatoshis,
    required String mnemonic, // Or passphrase to derive keys
  }) async {
    state = const AddFundsLoading(message: 'Creating transaction...');

    // 1. Create Unsigned Transaction
    final result = await createUnsignedTransactionUseCase(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amountBTC: amountBTC,
      feeSatoshis: feeSatoshis,
    );

    result.fold((failure) => state = AddFundsError(failure.message), (
      unsignedTx,
    ) async {
      state = const AddFundsLoading(message: 'Signing transaction...');

      try {
        // 2. Sign Transaction (Client Side)
        final signedTxHex = await TransactionSigner.sign(
          unsignedTx: unsignedTx,
          mnemonic: mnemonic,
        );

        state = const AddFundsLoading(message: 'Broadcasting...');

        // 3. Broadcast
        final broadcastResult = await broadcastTransactionUseCase(signedTxHex);

        broadcastResult.fold(
          (failure) => state = AddFundsError(failure.message),
          (txStatus) {
            state = AddFundsWaitingConfirmation(txStatus.txid);
            // Start polling or listening logic here if needed,
            // or just let the UI show "Waiting" and user checks history.
            // For better UX, we could poll status a few times.
          },
        );
      } catch (e) {
        state = AddFundsError('Signing failed: $e');
      }
    });
  }

  Future<void> createPaymentLink({
    required double amount,
    required String receiverWalletName,
  }) async {
    state = const AddFundsLoading(message: 'Creating payment request...');

    final result = await createPaymentLinkUseCase(
      amount: amount,
      receiverWalletName: receiverWalletName,
    );

    result.fold((failure) => state = AddFundsError(failure.message), (
      paymentLink,
    ) {
      state = AddFundsPaymentLinkCreated(paymentLink);
    });
  }

  void reset() {
    state = const AddFundsInitial();
  }
}

final addFundsProvider = StateNotifierProvider<AddFundsNotifier, AddFundsState>(
  (ref) {
    final createUnsigned = ref.watch(createUnsignedTransactionUseCaseProvider);
    final broadcast = ref.watch(broadcastTransactionUseCaseProvider);
    final getAddress = ref.watch(getDepositAddressUseCaseProvider);
    final createPaymentLink = ref.watch(createPaymentLinkUseCaseProvider);

    return AddFundsNotifier(
      createUnsignedTransactionUseCase: createUnsigned,
      broadcastTransactionUseCase: broadcast,
      getDepositAddressUseCase: getAddress,
      createPaymentLinkUseCase: createPaymentLink,
      ref: ref,
    );
  },
);
