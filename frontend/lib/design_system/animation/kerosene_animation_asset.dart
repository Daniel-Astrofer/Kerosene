/// Planned animation assets for Kerosene.
///
/// The design system owns names and use-cases before runtime packages are added.
/// Rive/Lottie wrappers should consume this enum instead of raw asset paths.
enum KeroseneAnimationAsset {
  successCheck,
  pendingConfirmation,
  emptyWallet,
  secureConnection,
  paymentReceived,
  networkReview,
  passkeyAuth,
  nfcReceive,
  transactionStatus,
  securityShield,
  bitcoinConfirmation,
  torConnection,
}

extension KeroseneAnimationAssetPath on KeroseneAnimationAsset {
  String get path {
    return switch (this) {
      KeroseneAnimationAsset.successCheck =>
        'assets/animations/lottie/success_check.json',
      KeroseneAnimationAsset.pendingConfirmation =>
        'assets/animations/lottie/pending_confirmation.json',
      KeroseneAnimationAsset.emptyWallet =>
        'assets/animations/lottie/empty_wallet.json',
      KeroseneAnimationAsset.secureConnection =>
        'assets/animations/lottie/secure_connection.json',
      KeroseneAnimationAsset.paymentReceived =>
        'assets/animations/lottie/payment_received.json',
      KeroseneAnimationAsset.networkReview =>
        'assets/animations/lottie/network_review.json',
      KeroseneAnimationAsset.passkeyAuth =>
        'assets/animations/rive/passkey_auth.riv',
      KeroseneAnimationAsset.nfcReceive =>
        'assets/animations/rive/nfc_receive.riv',
      KeroseneAnimationAsset.transactionStatus =>
        'assets/animations/rive/transaction_status.riv',
      KeroseneAnimationAsset.securityShield =>
        'assets/animations/rive/security_shield.riv',
      KeroseneAnimationAsset.bitcoinConfirmation =>
        'assets/animations/rive/bitcoin_confirmation.riv',
      KeroseneAnimationAsset.torConnection =>
        'assets/animations/rive/tor_connection.riv',
    };
  }

  bool get isLottie => path.endsWith('.json');
  bool get isRive => path.endsWith('.riv');
}

enum KeroseneRiveStateMachine {
  passkey,
  nfc,
  transaction,
  security,
  bitcoin,
  tor,
}

extension KeroseneRiveStateMachineName on KeroseneRiveStateMachine {
  String get name {
    return switch (this) {
      KeroseneRiveStateMachine.passkey => 'PasskeyStateMachine',
      KeroseneRiveStateMachine.nfc => 'NfcStateMachine',
      KeroseneRiveStateMachine.transaction => 'TransactionStateMachine',
      KeroseneRiveStateMachine.security => 'SecurityStateMachine',
      KeroseneRiveStateMachine.bitcoin => 'BitcoinConfirmationStateMachine',
      KeroseneRiveStateMachine.tor => 'TorConnectionStateMachine',
    };
  }
}
