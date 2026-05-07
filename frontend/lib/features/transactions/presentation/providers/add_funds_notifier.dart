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

class AddFundsNotifier extends Notifier<AddFundsState> {
  late CreateUnsignedTransactionUseCase createUnsignedTransactionUseCase;
  late BroadcastTransactionUseCase broadcastTransactionUseCase;
  late GetDepositAddressUseCase getDepositAddressUseCase;
  late CreatePaymentLinkUseCase createPaymentLinkUseCase;

  @override
  AddFundsState build() {
    createUnsignedTransactionUseCase =
        ref.watch(createUnsignedTransactionUseCaseProvider);
    broadcastTransactionUseCase =
        ref.watch(broadcastTransactionUseCaseProvider);
    getDepositAddressUseCase = ref.watch(getDepositAddressUseCaseProvider);
    createPaymentLinkUseCase = ref.watch(createPaymentLinkUseCaseProvider);
    return const AddFundsInitial();
  }

  Future<void> loadDepositAddress() async {
    state = const AddFundsLoading(step: AddFundsLoadingStep.depositAddress);
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
    state = const AddFundsLoading(step: AddFundsLoadingStep.createTransaction);

    // 1. Create Unsigned Transaction
    final result = await createUnsignedTransactionUseCase(
      toAddress: toAddress,
      amountBTC: amountBTC,
      feeLevel:
          'standard', // Users can pass this or derive from feeSatoshis tier
    );

    result.fold((failure) => state = AddFundsError(failure.message), (
      unsignedTx,
    ) async {
      state = const AddFundsLoading(step: AddFundsLoadingStep.signTransaction);

      try {
        // 2. Sign Transaction (Client Side)
        final signedTxHex = await TransactionSigner.sign(
          unsignedTx: unsignedTx,
          mnemonic: mnemonic,
        );

        state = const AddFundsLoading(
            step: AddFundsLoadingStep.broadcastTransaction);

        // 3. Broadcast
        final broadcastResult = await broadcastTransactionUseCase(
          rawTxHex: signedTxHex,
          toAddress: toAddress,
          amount: amountBTC,
        );

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
        state = const AddFundsError('SIGNING_FAILED');
      }
    });
  }

  Future<void> createPaymentLink({
    required double amount,
    required String receiverWalletName,
  }) async {
    state = const AddFundsLoading(step: AddFundsLoadingStep.paymentRequest);

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

final addFundsProvider =
    NotifierProvider<AddFundsNotifier, AddFundsState>(AddFundsNotifier.new);
