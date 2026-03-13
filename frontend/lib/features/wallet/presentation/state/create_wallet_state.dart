abstract class CreateWalletState {
  const CreateWalletState();
}

class CreateWalletInitial extends CreateWalletState {
  const CreateWalletInitial();
}

class CreateWalletLoading extends CreateWalletState {
  const CreateWalletLoading();
}

class CreateWalletSuccess extends CreateWalletState {
  final String result;
  const CreateWalletSuccess(this.result);
}

class CreateWalletError extends CreateWalletState {
  final String message;
  const CreateWalletError(this.message);
}
