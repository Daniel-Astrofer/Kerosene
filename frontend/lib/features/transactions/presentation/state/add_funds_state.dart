import 'package:equatable/equatable.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';
import '../../domain/entities/payment_link.dart';

abstract class AddFundsState extends Equatable {
  const AddFundsState();

  @override
  List<Object?> get props => [];
}

class AddFundsInitial extends AddFundsState {
  const AddFundsInitial();
}

enum AddFundsLoadingStep {
  general,
  depositAddress,
  createTransaction,
  signTransaction,
  broadcastTransaction,
  paymentRequest,
}

class AddFundsLoading extends AddFundsState {
  final AddFundsLoadingStep step;
  const AddFundsLoading({this.step = AddFundsLoadingStep.general});

  @override
  List<Object?> get props => [step];
}

class AddFundsLoadedDepositAddress extends AddFundsState {
  final String depositAddress;
  const AddFundsLoadedDepositAddress(this.depositAddress);

  @override
  List<Object?> get props => [depositAddress];
}

class AddFundsPaymentLinkCreated extends AddFundsState {
  final PaymentLink paymentLink;
  const AddFundsPaymentLinkCreated(this.paymentLink);

  @override
  List<Object?> get props => [paymentLink];
}

class AddFundsSigning extends AddFundsState {
  final UnsignedTransaction unsignedTransaction;
  const AddFundsSigning(this.unsignedTransaction);

  @override
  List<Object?> get props => [unsignedTransaction];
}

class AddFundsBroadcasting extends AddFundsState {
  const AddFundsBroadcasting();
}

class AddFundsWaitingConfirmation extends AddFundsState {
  final String txid;
  const AddFundsWaitingConfirmation(this.txid);

  @override
  List<Object?> get props => [txid];
}

enum AddFundsSuccessKind {
  depositConfirmed,
}

class AddFundsSuccess extends AddFundsState {
  final String txid;
  final AddFundsSuccessKind kind;
  const AddFundsSuccess({
    required this.txid,
    this.kind = AddFundsSuccessKind.depositConfirmed,
  });

  @override
  List<Object?> get props => [txid, kind];
}

class AddFundsError extends AddFundsState {
  final String message;
  const AddFundsError(this.message);

  @override
  List<Object?> get props => [message];
}
