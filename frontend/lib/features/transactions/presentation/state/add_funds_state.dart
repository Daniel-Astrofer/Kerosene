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

class AddFundsLoading extends AddFundsState {
  final String message;
  const AddFundsLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
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

class AddFundsSuccess extends AddFundsState {
  final String txid;
  final String message;
  const AddFundsSuccess({
    required this.txid,
    this.message = 'Deposit Confirmed!',
  });

  @override
  List<Object?> get props => [txid, message];
}

class AddFundsError extends AddFundsState {
  final String message;
  const AddFundsError(this.message);

  @override
  List<Object?> get props => [message];
}
