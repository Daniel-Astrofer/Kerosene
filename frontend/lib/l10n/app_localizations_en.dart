// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kerosene';

  @override
  String get home => 'Home';

  @override
  String get market => 'Market';

  @override
  String get profile => 'Profile';

  @override
  String get totalBalance => 'Total Balance (BTC)';

  @override
  String get totalBalanceGeneric => 'Total Balance';

  @override
  String get myWallets => 'My Wallets';

  @override
  String get actions => 'Actions';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get addFunds => 'Add Funds';

  @override
  String get addCard => 'ADD CARD';

  @override
  String get manual => 'MANUAL';

  @override
  String get qrCode => 'QR Code';

  @override
  String get nfc => 'NFC';

  @override
  String get howMuchToReceive => 'How much do you want to receive?';

  @override
  String get fixedAmountByRequest => 'FIXED AMOUNT BY REQUEST';

  @override
  String get recipientData => 'RECIPIENT DATA';

  @override
  String get recipientHint => 'Username or BTC address';

  @override
  String get descriptionHint => 'Description (optional)';

  @override
  String get next => 'NEXT';

  @override
  String get reviewSend => 'REVIEW SEND';

  @override
  String get recipient => 'Recipient';

  @override
  String get description => 'DESCRIPTION';

  @override
  String get networkFee => 'Network Fee';

  @override
  String get free => 'FREE';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get securityTotp => 'SECURITY (TOTP)';

  @override
  String get destinationAddressHint => 'Destination BTC Address';

  @override
  String get totpHint => '6 digits from your authenticator';

  @override
  String get confirmWithdraw => 'CONFIRM WITHDRAW';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get noTransactions => 'No transactions found';

  @override
  String get bitcoinTrading => 'Bitcoin Trading';

  @override
  String get marketStats => 'Market Stats';

  @override
  String get high24h => '24h High';

  @override
  String get low24h => '24h Low';

  @override
  String get totalVolume24h => 'Total Volume (24h)';

  @override
  String get fiatVolume => 'Fiat Volume';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalData => 'Personal Data';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get wallets => 'Wallets';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get depositAddress => 'Deposit Address';

  @override
  String get platformDepositAddress => 'Platform Deposit Address';

  @override
  String get amount => 'Amount';

  @override
  String get sourceWallet => 'Source Wallet';

  @override
  String get generatePaymentLink => 'Generate Payment Link';

  @override
  String get paymentInstructions => 'Payment Instructions';

  @override
  String get sendExactAmount =>
      'Send exactly this amount to the address below:';

  @override
  String get fundsWillBeCredited =>
      'Funds will be credited after network confirmation';

  @override
  String get close => 'Close';

  @override
  String get addressCopied => 'Address copied!';

  @override
  String get destinationAddress => 'DESTINATION ADDRESS';

  @override
  String get estimatedFee => 'Estimated Fee';

  @override
  String get total => 'Total';

  @override
  String get confirmSend => 'Confirm & Send';

  @override
  String get scanQR => 'Scan QR';

  @override
  String get pasteAddress => 'Paste Address';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get status => 'Status';

  @override
  String get value => 'Value';

  @override
  String get fee => 'Fee';

  @override
  String get hash => 'Hash';

  @override
  String get date => 'Date';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get pending => 'Pending';

  @override
  String get failed => 'Failed';

  @override
  String helloUser(String name) {
    return 'Hello, $name!';
  }

  @override
  String get welcome => 'Welcome';

  @override
  String get getStarted => 'Get Started';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Name';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get goBack => 'Go Back';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get insufficientFunds => 'Insufficient funds';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseCompleteFields => 'Please complete all fields';

  @override
  String get depositInitiated => 'Deposit Initiated!';

  @override
  String get depositSuccess =>
      'Your deposit transaction was sent. It will be credited once confirmed.';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noChartData => 'No chart data';

  @override
  String get walletSettings => 'Wallet Settings';

  @override
  String get spendingLimit => 'Spending Limit';

  @override
  String get exportPrivateKey => 'Export Private Key';

  @override
  String get removeWallet => 'Remove Wallet';

  @override
  String currencyQuotation(Object value) {
    return '1 BRL = $value USD';
  }

  @override
  String approximateValue(Object currency, Object value) {
    return '≈ $value $currency';
  }

  @override
  String get paymentLinks => 'Payment Links';

  @override
  String get youWillReceive => 'You will receive';

  @override
  String get confirmationTime => 'Confirmation time';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get setSpendingLimit => 'Set Spending Limit';

  @override
  String get amountInBtc => 'Amount in BTC';

  @override
  String get getStartedDescription =>
      'Create your first Bitcoin wallet to get started.';

  @override
  String get welcomeSlogan =>
      'The world\'s first privacy-focused international Bitcoin bank.';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToAccess => 'Sign in to access your wallet';

  @override
  String get username => 'Username';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get required => 'Required';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get currency => 'Currency';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get selectWalletToSend => 'Select a wallet to send.';

  @override
  String get errorLoadingWallets => 'Error loading wallets';

  @override
  String get add => 'Add';

  @override
  String get deposit => 'Deposit';

  @override
  String get sentTo => 'Sent to';

  @override
  String get receivedFrom => 'Received from';

  @override
  String get showLess => 'Show Less';

  @override
  String get copy => 'COPY';

  @override
  String get share => 'SHARE';

  @override
  String get waitingConnection => 'Waiting for connection...';

  @override
  String get offlineRetryHint => 'Pull down or tap try again.';

  @override
  String get nfcUnavailable => 'NFC UNAVAILABLE';

  @override
  String get processing => 'PROCESSING...';

  @override
  String get nfcInDevelopment => 'NFC UNAVAILABLE ON THIS DEVICE';

  @override
  String get amountToReceive => 'AMOUNT TO RECEIVE';

  @override
  String get approachToSend => 'APPROACH TO SEND';

  @override
  String get approachToRead => 'APPROACH TO READ';

  @override
  String get nfcInstructions =>
      'Keep your device close to the reader or another smartphone to process.';

  @override
  String get cancelOperation => 'CANCEL OPERATION';

  @override
  String get confirming => 'Confirming';

  @override
  String get sendBitcoin => 'SEND BITCOIN';

  @override
  String get receiveBitcoin => 'RECEIVE BITCOIN';

  @override
  String get onChain => 'ON-CHAIN';

  @override
  String get lightning => 'LIGHTNING';

  @override
  String get transactionAmount => 'TRANSACTION AMOUNT';

  @override
  String get approximateNfc => 'APPROXIMATE NFC';

  @override
  String get createLink => 'CREATE LINK';

  @override
  String get history => 'HISTORY';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get secureAccess => 'Secure Access';

  @override
  String get newHere => 'New here?';

  @override
  String get signUpNow => 'Sign Up';

  @override
  String get amountToSend => 'AMOUNT TO SEND';

  @override
  String get processingDuration => 'PROCESSING: ~15 MINS';

  @override
  String get withdrawConfirmButton => 'CONFIRM AND SEND';

  @override
  String get secureWithdrawal => 'SECURE WITHDRAWAL';

  @override
  String get totalToReceive => 'TOTAL TO RECEIVE';

  @override
  String get sovereignKeyVerification => 'PASSKEY VERIFICATION';

  @override
  String get readyToScan => 'READY TO SCAN';

  @override
  String get sovereigntyStatusTitle => 'SECURITY STATUS';

  @override
  String get liveAttestationReport => 'SECURITY REPORT';

  @override
  String get systemSovereign => 'SECURITY SYSTEM';

  @override
  String get integrityAlert => 'INTEGRITY ALERT';

  @override
  String get hardwareAttestation => 'DEVICE CHECK';

  @override
  String get networkConsensus => 'NETWORK CONFIRMATIONS';

  @override
  String get ledgerIntegrity => 'FINANCIAL INTEGRITY';

  @override
  String get memoryProtection => 'LOCAL PROTECTION';

  @override
  String get serverUptime => 'Service availability';

  @override
  String get realtimeReportInfo => 'Real-time report generated';

  @override
  String get analyzingSovereignty => 'CHECKING SECURITY…';

  @override
  String get chooseUniqueHandle => 'Choose your Unique Handle';

  @override
  String get chooseUniqueHandleDesc =>
      'This will be your unique handle on the Kerosene network. Use it to receive transfers from other users.';

  @override
  String get handleLabel => 'HANDLE (VISIBLE IN APP)';

  @override
  String get handleHint => 'ex: satoshi_99';

  @override
  String get errUsernameRequired => 'Please enter a username';

  @override
  String get errUsernameTooShort => 'Minimum of 3 characters';

  @override
  String get errUsernameInvalid =>
      'Only lowercase letters, numbers and underscores (_)';

  @override
  String get generatePaymentRequest => 'GENERATE PAYMENT REQUEST';

  @override
  String get phone => 'PHONE';

  @override
  String get personalAddress => 'ADDRESS';

  @override
  String get notificationChannels => 'CHANNELS';

  @override
  String get notificationAlerts => 'ALERTS';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsDesc => 'Receive alerts on your device';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get emailNotificationsDesc => 'Receive updates via email';

  @override
  String get transactionUpdates => 'Transaction Updates';

  @override
  String get transactionUpdatesDesc => 'Incoming and outgoing transactions';

  @override
  String get securityAlertsTitle => 'Security Alerts';

  @override
  String get securityAlertsDesc => 'Login attempts and password changes';

  @override
  String get marketingNews => 'Marketing & News';

  @override
  String get marketingNewsDesc => 'Stay updated with latest features';

  @override
  String get sovereigntyStatus => 'Security Status';

  @override
  String get sovereigntyStatusDesc => 'Account protection and service health';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get biometricAuthDesc => 'Use FaceID or Fingerprint to unlock';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinDesc => 'Update your 6-digit access code';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'Update your account password';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get twoFactorAuthDesc => 'Add an extra layer of security';

  @override
  String get enableTwoFactorInfo =>
      'Enable 2FA to protect your assets from unauthorized access.';

  @override
  String get faq => 'FAQ';

  @override
  String get faqDesc => 'Frequently Asked Questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get contactSupportDesc => 'Get help from our team';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceDesc => 'Read our terms and conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'How we handle your data';

  @override
  String get developedBy => 'DEVELOPED BY';

  @override
  String get typeSend => 'Send';

  @override
  String get typeReceive => 'Receive';

  @override
  String get typeSwap => 'Swap';

  @override
  String get typeFee => 'Fee';

  @override
  String get hashCopied => 'Hash copied!';

  @override
  String get transactionSentSuccess => 'Transaction sent successfully!';

  @override
  String get selectRecipient => 'Select Recipient';

  @override
  String get searchAddress => 'Search or paste address';

  @override
  String get noRecentContacts => 'No recent contacts';

  @override
  String get unknown => 'Unknown';

  @override
  String fromWallet(Object name) {
    return 'From: $name';
  }

  @override
  String get yourBitcoinAddress => 'Your Bitcoin Address';

  @override
  String get addressNotAvailable => 'Address not available';

  @override
  String get copyAddress => 'Copy Address';

  @override
  String get receiveMethod => 'Receive Method';

  @override
  String get generateQrCodeDescription => 'Generate a code to be scanned';

  @override
  String get nfcBeam => 'NFC Beam';

  @override
  String get nfcTagDescription => 'Write the request to an NFC tag';

  @override
  String get scanToPay => 'Scan to Pay';

  @override
  String get approachPhoneToNfc => 'Bring phone close to NFC tag';

  @override
  String get nfcTagNotSupported => 'Tag does not support NDEF';

  @override
  String get nfcTagNotWritable => 'Tag not writable';

  @override
  String get nfcTagCapacityError => 'Request larger than tag capacity';

  @override
  String get nfcTagWrittenSuccess => 'Tag written successfully!';

  @override
  String get nfcTagInvalid =>
      'This tag does not contain a readable payment request.';

  @override
  String get nfcPaymentNotFound =>
      'No compatible payment request was found on this tag.';

  @override
  String get nfcCouldNotProcess =>
      'We could not process this NFC tag. Try again.';

  @override
  String get writeNfcTag => 'Write NFC Tag';

  @override
  String errorWriting(Object error) {
    return 'Error writing: $error';
  }

  @override
  String get typeWithdrawal => 'Withdrawal';

  @override
  String get typeDeposit => 'Deposit';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get torOnionActive => 'Onion Protocol Active (Kerosene Core)';

  @override
  String get signupFeeTitle => 'Activation Fee';

  @override
  String get signupFeeSubtitle =>
      'A one-time fee of 0.003 BTC is required to activate your account and prevent spam.';

  @override
  String get signupFeeWhyTitle => 'Why a fee?';

  @override
  String get signupFeeWhyBody =>
      'Kerosene has no registration form or email. The fee is a Proof-of-Work that protects the network from bots and fake accounts.';

  @override
  String get signupFeeNotRefundable => 'Non-refundable';

  @override
  String get signupFeeNotRefundableBody =>
      'Once sent, the fee cannot be recovered. Ensure you are ready before proceeding.';

  @override
  String get signupFeeContinue => 'Understood, Continue';

  @override
  String get seedSecurityTitle => 'Seed Security';

  @override
  String get seedSecuritySubtitle =>
      'Choose how you want to protect your wallet recovery phrase. Kerosene offers advanced security options for high-net-worth setups.';

  @override
  String get seedStandardTitle => 'Standard';

  @override
  String get seedStandardDesc =>
      'A single 12, 18, or 24-word recovery phrase. Best for general use and simplicity.';

  @override
  String get seedSlip39Title => 'Shamir SLIP-39 (Multi-part)';

  @override
  String get seedSlip39Desc =>
      'Split your seed into multiple pieces. Requires a minimum threshold of pieces to recover (e.g., 3-of-5). Best for distributed physical storage.';

  @override
  String get seedMultisigTitle => '2FA Multisig Vault';

  @override
  String get seedMultisigDesc =>
      'A 2-of-3 Multisig wallet. Kerosene acts as a co-signer and requires TOTP authorization for withdrawals. Protects against local device theft.';

  @override
  String get seedSlip39ConfigTitle => 'SLIP-39 Configuration';

  @override
  String get seedSlip39TotalShares => 'Total Shares (Pieces)';

  @override
  String get seedSlip39Threshold => 'Required Threshold';

  @override
  String seedSlip39Summary(Object threshold, Object total) {
    return 'Requires $threshold out of $total shares to restore the wallet.';
  }

  @override
  String get passphraseTitle => 'Your Secret Phrase';

  @override
  String get passphraseSubtitle =>
      'Write down these 18 words on a physical piece of paper. Never save this digitally.';

  @override
  String get passphraseWrittenDown => 'I Have Written It Down';

  @override
  String get passphraseWarning =>
      'If you lose these words, you will permanently lose access to your account and funds.';

  @override
  String get passphraseVerifyTitle => 'Verify Phrase';

  @override
  String get passphraseVerifySubtitle =>
      'Type your secret phrase to confirm you have backed it up correctly.';

  @override
  String get passphraseVerifyHint => 'word1 word2 word3...';

  @override
  String get passphraseVerifyError => 'Incorrect passphrase. Please try again.';

  @override
  String get passphraseVerifyContinue => 'Verify & Continue';

  @override
  String get passphraseGoBack => 'Go back to view phrase again';

  @override
  String get passphraseEnterWords => 'Enter your 18 words';

  @override
  String get slip39SharesTitle => 'Your SLIP-39 Shares';

  @override
  String slip39SharesSubtitle(Object threshold, Object total) {
    return 'Your seed is split into $total pieces. You need $threshold of them to recover your wallet. Write each share on a separate piece of paper and store them in different locations.';
  }

  @override
  String slip39ShareLabel(Object index, Object total) {
    return 'Share $index of $total';
  }

  @override
  String slip39ShareCopied(Object index) {
    return 'Share $index copied';
  }

  @override
  String slip39VerifyShareTitle(Object index) {
    return 'Verify Share $index';
  }

  @override
  String slip39VerifyShareSubtitle(Object index) {
    return 'Type the words for Share $index exactly as you wrote them down.';
  }

  @override
  String slip39ConfirmShare(Object index) {
    return 'Confirm Share $index';
  }

  @override
  String get slip39AllConfirmedContinue => 'All Shares Confirmed — Continue';

  @override
  String slip39ConfirmAllPending(Object total) {
    return 'Confirm all $total shares to continue';
  }

  @override
  String slip39Warning(Object threshold) {
    return 'Do NOT store all shares in the same place. If an attacker finds $threshold pieces they can recover your wallet.';
  }

  @override
  String get twoFaPrimaryTitle => 'Your Primary Seed';

  @override
  String get twoFaPrimaryBadge => 'Key 1 of 3 — Stays on your device only';

  @override
  String get twoFaPrimarySubtitle =>
      'This 18-word phrase is your primary private key. It alone is NOT enough to sign transactions — a secondary TOTP authorization is always required from Kerosene. Write these words on paper and store them securely.';

  @override
  String get twoFaPrimaryWritten => 'I Have Written It Down';

  @override
  String get twoFaBackupTitle => 'Your Recovery Seed';

  @override
  String get twoFaBackupBadge => 'Key 3 of 3 — Emergency / Recovery';

  @override
  String get twoFaBackupSubtitle =>
      'Keep this 12-word backup separate from your primary phrase. Together, they help you recover access in an emergency.';

  @override
  String get twoFaCoSignerNote =>
      'Key 2 of 3 is held encrypted by Kerosene and is only used to co-sign trasactions when you provide a valid TOTP code.';

  @override
  String get twoFaBothStored => 'I Have Stored Both Seeds';

  @override
  String get twoFaBackToPrimary => 'Back to Primary Seed';

  @override
  String get twoFaVerifyTitle => 'Verify Primary Seed';

  @override
  String get twoFaVerifySubtitle =>
      'Confirm your Primary Key (18 words) to prove you have it safely stored.';

  @override
  String get twoFaVerifyHint => 'word1 word2 word3...';

  @override
  String get twoFaVerifyError =>
      'Incorrect. Please re-check your Primary Seed.';

  @override
  String get twoFaVerifyActivate => 'Verify & Activate 2FA Vault';

  @override
  String get twoFaBackToBackup => 'Back to Recovery Seed';

  @override
  String get totpSetupTitle => 'Setup Authenticator';

  @override
  String get totpSetupSubtitle =>
      'Scan the QR code with your authenticator app, then enter the 6-digit code to verify.';

  @override
  String get totpCodeLabel => 'Enter 6-digit code';

  @override
  String get totpVerifyButton => 'Verify & Continue';

  @override
  String get totpErrorInvalid => 'Invalid code. Please try again.';

  @override
  String get passkeyTitle => 'Device key';

  @override
  String get passkeySubtitle =>
      'Secure your account with a biometric hardware key. No password required.';

  @override
  String get passkeyRegisterButton => 'Activate device key';

  @override
  String get passkeySuccessMessage => 'Device key activated!';

  @override
  String get passkeySkip => 'Skip for now';

  @override
  String get usernameTitle => 'Choose Your Handle';

  @override
  String get usernameSubtitle =>
      'Pick a unique username. This is your public identity on Kerosene.';

  @override
  String get usernameFieldLabel => 'Username';

  @override
  String get usernameFieldHint => '@your_handle';

  @override
  String get usernameCheckButton => 'Check Availability';

  @override
  String get usernameAvailable => 'Username available!';

  @override
  String get usernameTaken => 'Username already in use.';

  @override
  String get usernameContinue => 'Reserve Handle & Continue';

  @override
  String get paymentTitle => 'Activation Payment';

  @override
  String get paymentSubtitle =>
      'Send exactly the amount shown below to activate your account.';

  @override
  String get paymentTimeLeft => 'Time left';

  @override
  String get paymentExpired => 'Payment window expired';

  @override
  String get paymentExpiredMessage =>
      'You did not complete the payment within the 15-minute window. Your temporary data will be cleared and you must start over.';

  @override
  String get paymentWaiting => 'Waiting for payment...';

  @override
  String get paymentAmountLabel => 'Amount';

  @override
  String get paymentAddressLabel => 'Deposit Address';

  @override
  String get paymentCopyAddress => 'Copy Address';

  @override
  String get paymentAddressCopied => 'Address copied!';

  @override
  String get confirmationsTitle => 'Waiting for Confirmations';

  @override
  String get confirmationsSubtitle =>
      'Your payment was detected. Waiting for 3 bitcoin network confirmations to finalize your account.';

  @override
  String confirmationsProgress(Object current, Object total) {
    return '$current / $total confirmations';
  }

  @override
  String get confirmationsDone => 'Account Activated!';

  @override
  String get presentationSlide1Title =>
      'Secure Infrastructure from the First Access';

  @override
  String get presentationSlide1Body =>
      'Kerosene operates with advanced technological architecture in a protected environment via the onion network. This structure reinforces privacy, resilience, and protection against external interference.\n\nSecurity is not an add-on.\nIt is the foundation of the system.';

  @override
  String get presentationSlide2Title =>
      'Account Creation with Structural Protection Mechanism';

  @override
  String get presentationSlide2Body =>
      'To preserve infrastructure integrity, account creation requires sending 0.003 BTC.\nThis amount remains entirely in your account.\nDuring registration, only the network transaction fee necessary for operation confirmation is deducted.\nThis technical requirement exists to:\n\n• Prevent automated account creation\n• Reduce distributed attack vectors\n• Maintain operational stability\n• Protect all platform users\n\nIt is not a monthly fee.\nIt is not a recurring charge.\nIt is a structural protection mechanism.';

  @override
  String get presentationSlide3Title => 'Clear and Objective Fee Structure';

  @override
  String get presentationSlide3Body =>
      'Our policy is simple:\n\n• External deposits and withdrawals use the wallet card fee\n• Bronze: 0.9%\n• White: 0.8%\n• Black: 0.7%\n• 0% for internal transfers\n\nTransfers between Kerosene users are instant and free.\n\nNo hidden fees.';

  @override
  String get presentationSlide4Title => 'Commitment to Predictability';

  @override
  String get presentationSlide4Body =>
      'Kerosene was designed to operate with:\n\n• Technical stability\n• Operational transparency\n• Structural security\n• Cost predictability\n\nOur priority is to maintain a solid, protected, and long-term sustainable infrastructure.';

  @override
  String get presentationSkip => 'Skip';

  @override
  String get presentationNext => 'Next';

  @override
  String get presentationStart => 'Access Kerosene';

  @override
  String get signupScreenTitle => 'Create Wallet';

  @override
  String get signupScreenSubtitle => 'Setup your username and secure key.';

  @override
  String get signupUsernameHelper => 'Only a-z, 0-9 and _';

  @override
  String get signupUsernameHint => 'lower case letters, numbers and _';

  @override
  String get signupUsernameMinChars => 'Min 3 chars';

  @override
  String get signupUsernameInvalid => 'Invalid characters';

  @override
  String get signupMnemonicLabel => 'YOUR SECRET PHRASE (BIP39)';

  @override
  String get signupMnemonicWarning =>
      'Save this phrase securely. It is the ONLY way to recover your account.';

  @override
  String get signupMnemonicCopySuccess => 'Phrase copied securely!';

  @override
  String get signupMnemonicCopy => 'Copy';

  @override
  String get signupMnemonicGenerateNew => 'Generate New';

  @override
  String get signupMnemonicError => 'Error generating phrase, try again';

  @override
  String get feeExplanationTitle => 'Secure Network Fee';

  @override
  String get feeExplanationSubtitle =>
      'To prevent spam and ensure the robustness of the Kerosene network, account creation requires a small anti-spam fee of 0.003 BTC.';

  @override
  String get feeExplanationWhereGoesTitle => 'Where does it go?';

  @override
  String get feeExplanationWhereGoesSubtitle =>
      'The full 0.003 BTC goes directly into your wallet balance once the account is created.';

  @override
  String get feeExplanationContinue => 'I Understand, Continue';

  @override
  String get seedSecurityContinue => 'Continue';

  @override
  String get totpTitle => 'Two-Factor Authentication';

  @override
  String get totpSubtitle =>
      'Scan this QR code with your authenticator app (e.g. Google Authenticator, Authy).';

  @override
  String get totpSecretCopied => 'Secret copied to clipboard';

  @override
  String get totpEnterCodeHint => '000000';

  @override
  String get totpEnter6Digits => 'Enter 6 digits';

  @override
  String get totpInvalidCode => 'Invalid code. Try again.';

  @override
  String get totpVerifyContinue => 'Verify & Continue';

  @override
  String get totpVerifying => 'Verifying code...';

  @override
  String get totpAuthenticating => 'Authenticating...';

  @override
  String get totpEstablishingSession => 'Establishing Session...';

  @override
  String get passkeySessionNotFound =>
      'Session not found. Please restart the process.';

  @override
  String get passkeyNoBiometrics =>
      'Set up biometrics or a screen lock on this device to use the device key.';

  @override
  String passkeyErrorStarting(String message) {
    return 'Error starting registration: $message';
  }

  @override
  String get passkeyBiometricReason =>
      'Unlock the device key to secure your Kerosene wallet';

  @override
  String passkeyErrorFinishing(String message) {
    return 'Error finishing registration: $message';
  }

  @override
  String get passkeyAuthFailed => 'Authentication cancelled or failed.';

  @override
  String passkeyUnexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get passkeyLoadingInitBiom => 'Initializing Biometrics...';

  @override
  String get passkeyLoadingSecuring => 'Securing Device...';

  @override
  String get passkeyLoadingRegistering => 'Activating device key...';

  @override
  String get usernameHintChars => 'a-z, 0-9 and _';

  @override
  String get usernameHelperLength => 'Must be between 3 and 15 characters';

  @override
  String get usernameErrorMin => 'Min 3 chars';

  @override
  String get usernameErrorMax => 'Max 15 chars';

  @override
  String get usernameErrorInvalidChars => 'Invalid characters';

  @override
  String get usernameLoadingPow => 'Calculating Proof of Work...';

  @override
  String get usernameLoadingKeys => 'Securing Keys...';

  @override
  String get usernameLoadingInvoice => 'Generating Invoice...';

  @override
  String get usernameLoadingNetwork => 'Connecting to Network...';

  @override
  String get paymentExpiredLabel => 'EXPIRED';

  @override
  String get confNetworkError => 'Network Error';

  @override
  String get confNetworkVerified => 'Network Verified!';

  @override
  String get confConfirming => 'Confirming on Blockchain';

  @override
  String get confErrorMsg =>
      'We could not finish creating your account. Please restart the setup safely.';

  @override
  String get confVerifiedMsg =>
      'Your account has been officially created and your fee added to your balance. Entering gateway...';

  @override
  String get confWaitingMsg =>
      'Waiting for 3 Bitcoin network confirmations. This can take roughly 30 minutes, but you can safely leave the app; we will notify you when it is ready.';

  @override
  String get confRestartSignup => 'Restart Signup';

  @override
  String get confNotificationNotice =>
      'You will receive a push notification once the 3rd confirmation lands.';

  @override
  String get homePlatformLiquidity => 'PLATFORM LIQUIDITY';

  @override
  String get homeDeposits => 'DEPOSITS';

  @override
  String get homeWithdrawals => 'WITHDRAWALS';

  @override
  String get authRequired => 'Authentication required';

  @override
  String get unlock => 'Unlock';

  @override
  String get pendingDeposits => 'Pending Deposits';

  @override
  String get saqueAction => 'Withdraw';

  @override
  String get detailsTransaction => 'Transaction Details';

  @override
  String get detailsClose => 'Close';

  @override
  String get noWalletsFound => 'No wallets found';

  @override
  String get createWalletPrompt =>
      'Create a wallet to start monitoring transactions';

  @override
  String get createWalletAction => 'Create Wallet';

  @override
  String get withdrawExternalBtc => 'External BTC Withdrawal';

  @override
  String get withdrawExternalBtcDesc =>
      'Move funds from your Kerosene wallet to an external Bitcoin address.';

  @override
  String get withdrawAddressLabel => 'Bitcoin Address (toAddress)';

  @override
  String get withdrawAmountLabel => 'Amount in BTC';

  @override
  String get withdrawDescLabel => 'Description (Optional)';

  @override
  String get withdrawDescHint => 'Ex: Transfer to Hardware Wallet';

  @override
  String get withdrawCancel => 'CANCEL';

  @override
  String get withdrawAction => 'WITHDRAW NOW';

  @override
  String get errorAddressRequired => 'Address is required';

  @override
  String get errorAmountRequired => 'Amount is required';

  @override
  String get errorAmountInvalid => 'Invalid amount';

  @override
  String get txSent => 'Transfer Sent';

  @override
  String get txReceived => 'Transfer Received';

  @override
  String get loginTotpTitle => 'Device Verification';

  @override
  String get loginTotpDesc =>
      'This device is new. Please enter the 6-digit code from your authenticator app to authorize it.';

  @override
  String get loginTotpAction => 'VERIFY & LOGIN';

  @override
  String get createWalletNameRequired => 'Name is required';

  @override
  String get createWalletNameChars => 'Only letters and numbers are allowed';

  @override
  String get sendDescriptionLabel =>
      'Description (optional, e.g. Pizza payment)';

  @override
  String sendInsufficientBalance(String amount) {
    return 'Insufficient balance. Missing $amount BTC to complete this send.';
  }

  @override
  String get sendSelectWallet => 'Select Wallet';

  @override
  String get sendReviewTitle => 'Review Transaction';

  @override
  String get sendTrackedReviewTitle => 'Confirm Tracked Payment';

  @override
  String get sendRecipientLabel => 'Recipient';

  @override
  String get sendNetworkFeeLabel => 'Network Fee';

  @override
  String get sendTotalLabel => 'Total';

  @override
  String get sendConfirmAction => 'Confirm';

  @override
  String get sendPayNowAction => 'Pay Now';

  @override
  String get sendEnterAddressError =>
      'Please enter a valid recipient username or address';

  @override
  String get sendEnterAmountError => 'Please enter a valid amount';

  @override
  String get sendPaymentSuccess => 'Payment successful!';

  @override
  String get receiveReceivingWallet => 'Receiving Wallet';

  @override
  String get receiveExpirationLabel => 'Payment Link Expiration';

  @override
  String get receiveNoExpiration => 'No Expiration';

  @override
  String get receive15Min => '15 Minutes';

  @override
  String get receive1Hour => '1 Hour';

  @override
  String get receive24Hours => '24 Hours';

  @override
  String get receiveGenAction => 'Generate Payment Link';

  @override
  String get receiveQrMethod => 'QR Code';

  @override
  String get receiveNfcMethod => 'NFC Beam';

  @override
  String get receiveScanToPay => 'Scan to Pay';

  @override
  String get receiveReadyToBeam => 'Ready to Beam';

  @override
  String get receiveWriteNfc => 'Write to NFC Tag';

  @override
  String get unknownDeviceTitle => 'Authorize New Device';

  @override
  String get unknownDeviceDesc =>
      'This device has not been linked to your account.\nEnter the 6-digit code from your authenticator app to authorize it.';

  @override
  String get unknownDeviceBanner => 'New device detected';

  @override
  String get unknownDeviceInputHint => '000000';

  @override
  String get unknownDeviceInputErrorEmpty => 'Enter the 6-digit code';

  @override
  String get unknownDeviceInputErrorLength => 'Code must be 6 digits';

  @override
  String get unknownDeviceHelper =>
      'Open your authenticator app and enter the current code.';

  @override
  String get unknownDeviceAction => 'AUTHORIZE & SIGN IN';

  @override
  String get unknownDeviceSecurityNote =>
      'If you did not attempt to log in, your credentials may be compromised. Change your passphrase immediately.';

  @override
  String get createWalletTitle => 'New Wallet';

  @override
  String get createWalletSuccess => 'Wallet created successfully!';

  @override
  String get createWalletErrorGenFirst => 'Please generate a passphrase first.';

  @override
  String get createWalletIdentity => 'WALLET IDENTITY';

  @override
  String get createWalletNameHint => 'Savings, Daily, etc.';

  @override
  String get createWalletSecurity => 'PASSPHRASE SECURITY';

  @override
  String createWalletWords(int count) {
    return '$count Words';
  }

  @override
  String get createWalletActionGen => 'Generate Security Key';

  @override
  String get createWalletActionCreate => 'CREATE WALLET';

  @override
  String get createWalletCopyAction => 'Copy';

  @override
  String get createWalletCopySuccess => 'Copied!';

  @override
  String get createWalletNewAction => 'New';

  @override
  String get createWalletWarning =>
      'Keep these words safe. Without them, your funds will be lost.';

  @override
  String get bitcoinAccountsTitle => 'Bitcoin Accounts';

  @override
  String get bitcoinAccountsSubtitle =>
      'Keep your Kerosene card and cold wallets in one simple view. Private keys stay off the app unless you are creating a new cold wallet.';

  @override
  String get bitcoinAccountsErrorTitle => 'Bitcoin accounts unavailable';

  @override
  String get bitcoinAccountsErrorMessage =>
      'We could not load your accounts right now. Try again in a moment.';

  @override
  String get bitcoinAccountsCreateColdWallet => 'Create cold wallet';

  @override
  String get bitcoinAccountsNewKeroseneCard => 'New Kerosene card';

  @override
  String get bitcoinAccountsEmptyTitle => 'No Bitcoin account yet';

  @override
  String get bitcoinAccountsEmptyMessage =>
      'Create a cold wallet for long-term storage or add a Kerosene card for daily receiving.';

  @override
  String get bitcoinAccountsKeroseneCardSection => 'Kerosene card';

  @override
  String get bitcoinAccountsColdWalletSection => 'Cold wallets';

  @override
  String get bitcoinAccountsNoKeroseneCard => 'No Kerosene card is active yet.';

  @override
  String get bitcoinAccountsNoColdWallet =>
      'No cold wallet is being watched yet.';

  @override
  String get bitcoinAccountsKeroseneCardBadge => 'Kerosene card';

  @override
  String get bitcoinAccountsColdWalletBadge => 'Watch-only';

  @override
  String get bitcoinAccountsUnnamedAccount => 'Bitcoin account';

  @override
  String get bitcoinAccountsAvailableBalance => 'Available balance';

  @override
  String get bitcoinAccountsObservedBalance => 'Observed balance';

  @override
  String get bitcoinAccountsKeroseneCardNote =>
      'Use this card to receive Bitcoin inside Kerosene and move funds quickly.';

  @override
  String get bitcoinAccountsColdWalletNote =>
      'Kerosene only watches this wallet. Spending still requires your recovery words or your offline device.';

  @override
  String get bitcoinAccountsPendingBalance => 'Waiting';

  @override
  String get bitcoinAccountsReservedBalance => 'Reserved';

  @override
  String get bitcoinAccountsReviewBalance => 'Review';

  @override
  String get bitcoinAccountsReceiveBtc => 'Receive BTC';

  @override
  String get bitcoinAccountsStatusActive => 'Ready';

  @override
  String get bitcoinAccountsStatusPending => 'Setting up';

  @override
  String get bitcoinAccountsStatusDisabled => 'Paused';

  @override
  String get bitcoinAccountsStatusReady => 'Available';

  @override
  String get bitcoinAccountsCreateCardTitle => 'New Kerosene card';

  @override
  String get bitcoinAccountsCardNameLabel => 'Card name';

  @override
  String get bitcoinAccountsCardNameHint => 'Daily, Savings, Travel';

  @override
  String get bitcoinAccountsCreateCardNotice =>
      'This card is for funds you want available inside Kerosene.';

  @override
  String get bitcoinAccountsCreateCardAction => 'Create card';

  @override
  String get bitcoinAccountsCreateCardErrorTitle => 'Card not created';

  @override
  String get bitcoinAccountsCreateCardErrorMessage =>
      'We could not create this card right now. Check the name and try again.';

  @override
  String get coldWalletCreateTitle => 'Create cold wallet';

  @override
  String get coldWalletCreateSubtitle =>
      'Generate the recovery words on this device, write them down, and Kerosene will keep only the information needed to show balances.';

  @override
  String get coldWalletNameLabel => 'Wallet name';

  @override
  String get coldWalletNameHint => 'Vault, Family reserve, Long-term';

  @override
  String get coldWalletSecurityLevelTitle => 'Security level';

  @override
  String get coldWalletLevelEssentialTitle => 'Essential';

  @override
  String get coldWalletLevelEssentialBody =>
      '12 recovery words. Easier to write, suitable for smaller balances.';

  @override
  String get coldWalletLevelRecommendedTitle => 'Recommended';

  @override
  String get coldWalletLevelRecommendedBody =>
      '24 recovery words. Best default for long-term Bitcoin storage.';

  @override
  String get coldWalletLevelMaximumTitle => 'Maximum';

  @override
  String get coldWalletLevelMaximumBody =>
      '24 words plus one extra word. Losing either one means losing access.';

  @override
  String get coldWalletExtraWordLabel => 'Extra word';

  @override
  String get coldWalletExtraWordHint => 'Do not reuse a password';

  @override
  String get coldWalletExtraWordWarning =>
      'The extra word is not recoverable by Kerosene. Store it separately from the recovery words.';

  @override
  String get coldWalletChecklistTitle => 'Before generating';

  @override
  String get coldWalletChecklistPaper => 'I have paper or metal backup ready.';

  @override
  String get coldWalletChecklistPrivate =>
      'I am in a private place with no cameras around.';

  @override
  String get coldWalletChecklistOffline =>
      'I turned off Wi-Fi and mobile data manually.';

  @override
  String get coldWalletChecklistNoPhotos =>
      'I will not take screenshots or photos.';

  @override
  String get coldWalletGenerateAction => 'Generate words';

  @override
  String get coldWalletBackupTitle => 'Write these words down';

  @override
  String get coldWalletBackupSubtitle =>
      'These words control the wallet. Kerosene cannot restore them later and will not save them.';

  @override
  String get coldWalletWordsHidden =>
      'Words are hidden until you choose to reveal them.';

  @override
  String get coldWalletShowWords => 'Show words';

  @override
  String get coldWalletHideWords => 'Hide words';

  @override
  String get coldWalletBackupDoneAction => 'I wrote them down';

  @override
  String get coldWalletVerifySubtitle =>
      'Enter the requested words to confirm your backup before importing the public watch-only key.';

  @override
  String coldWalletVerifyWordLabel(int index) {
    return 'Word $index';
  }

  @override
  String get coldWalletVerifyFailedTitle => 'Backup not confirmed';

  @override
  String get coldWalletVerifyFailedMessage => 'Check the words and try again.';

  @override
  String get coldWalletImportAction => 'Finish and watch wallet';

  @override
  String get coldWalletImportingAction => 'Importing...';

  @override
  String get coldWalletImportedTitle => 'Cold wallet added';

  @override
  String get coldWalletImportedMessage =>
      'Only the public watch-only key was imported.';

  @override
  String get coldWalletImportErrorTitle => 'Cold wallet not added';

  @override
  String get coldWalletImportErrorMessage =>
      'Reconnect to the internet and try again. Your recovery words were not sent.';

  @override
  String get bitcoinReceiveTitle => 'Receive BTC';

  @override
  String get bitcoinReceiveAmountOptional => 'Optional amount in sats';

  @override
  String get bitcoinReceiveOneTime => 'One-time address';

  @override
  String get bitcoinReceiveOneTimeSubtitle =>
      'Recommended for privacy and clean tracking.';

  @override
  String get bitcoinReceiveGenerateAddress => 'Generate address';

  @override
  String get bitcoinReceiveGenerating => 'Generating...';

  @override
  String get bitcoinReceiveRefresh => 'Refresh';

  @override
  String get bitcoinReceiveCreateErrorTitle => 'Could not generate';

  @override
  String get bitcoinReceiveCreateErrorMessage =>
      'Review the data and try a new address.';

  @override
  String get bitcoinReceiveStatusErrorTitle => 'Status unavailable';

  @override
  String get bitcoinReceiveStatusErrorMessage =>
      'We could not update this receiving request right now.';

  @override
  String get bitcoinReceiveCopiedTitle => 'Copied';

  @override
  String get bitcoinReceiveCopiedMessage => 'Bitcoin address copied.';

  @override
  String get bitcoinReceiveStatusActive => 'Waiting';

  @override
  String get bitcoinReceiveStatusDetected => 'Detected';

  @override
  String get bitcoinReceiveStatusConfirming => 'Confirming';

  @override
  String get bitcoinReceiveStatusPaid => 'Paid';

  @override
  String get bitcoinReceiveStatusExpired => 'Expired';

  @override
  String get bitcoinReceiveStatusLate => 'Late payment';

  @override
  String get bitcoinReceiveStatusReview => 'In review';

  @override
  String get bitcoinReceiveStatusAction => 'Needs review';

  @override
  String get bitcoinReceiveStatusProtected => 'Protected';

  @override
  String get bitcoinReceiveStatusWaiting => 'Waiting';

  @override
  String get bitcoinReceiveMessageActive =>
      'Send BTC to this address. We will update this screen when the network sees the payment.';

  @override
  String get bitcoinReceiveMessageDetected =>
      'Payment was seen on the Bitcoin network and is waiting for confirmations.';

  @override
  String get bitcoinReceiveMessageConfirming =>
      'The transaction is in a block and is still confirming.';

  @override
  String get bitcoinReceiveMessagePaid =>
      'Payment confirmed and added to your Kerosene card balance.';

  @override
  String get bitcoinReceiveMessageExpired =>
      'This request expired. Generate a new address to continue.';

  @override
  String get bitcoinReceiveMessageLate =>
      'A payment arrived after expiration and is being reviewed safely.';

  @override
  String get bitcoinReceiveMessageReview =>
      'Your confirmation was received. We are waiting for the safe release condition.';

  @override
  String get bitcoinReceiveMessageAction =>
      'Confirm this payment to finish receiving it safely.';

  @override
  String get bitcoinReceiveMessageProtected =>
      'This receiving request was protected after a sync problem. Refresh later.';

  @override
  String get bitcoinReceiveMessageWaiting => 'Waiting for the Bitcoin network.';

  @override
  String get onchainDepositTitle => 'On-chain deposit';

  @override
  String get onchainDepositSubtitle =>
      'Scan the QR code or copy the Bitcoin address exactly as shown.';

  @override
  String get onchainDepositPreparingSubtitle =>
      'Preparing your receiving address.';

  @override
  String get onchainDepositLoadingTitle => 'Loading';

  @override
  String get onchainDepositLoadingMessage =>
      'Getting the latest quote before creating the address.';

  @override
  String get onchainDepositAddressUnavailable =>
      'We could not create a valid Bitcoin address. Try again.';

  @override
  String get onchainDepositTrackingUnavailable =>
      'We could not start tracking this deposit. Try again.';

  @override
  String get onchainDepositAddressCopied => 'Bitcoin address copied.';

  @override
  String get onchainDepositSelectedWallet => 'Selected wallet';

  @override
  String get onchainDepositLocalNetwork => 'Local test network';

  @override
  String get onchainDepositStatusCompleted => 'Completed';

  @override
  String get onchainDepositStatusConfirmed => 'Confirmed';

  @override
  String get onchainDepositStatusDetected => 'Detected';

  @override
  String get onchainDepositStatusWaiting => 'Waiting for payment';

  @override
  String get onchainDepositStatusFailed => 'Failed';

  @override
  String get onchainDepositStatusCancelled => 'Cancelled';

  @override
  String get onchainDepositStatusExpired => 'Expired';

  @override
  String get onchainDepositDescriptionCancelled =>
      'This deposit was cancelled. Create a new address if you still want to deposit.';

  @override
  String onchainDepositDescriptionWaiting(String network) {
    return 'This address is reserved for this deposit on $network.';
  }

  @override
  String get onchainDepositDescriptionConfirmed =>
      'The Bitcoin network confirmed this deposit.';

  @override
  String onchainDepositDescriptionConfirming(int current, int total) {
    return 'Payment detected. Waiting for $current/$total confirmations.';
  }

  @override
  String onchainDepositDetectedNotice(int current, int total) {
    return 'Payment detected. Tracking $current/$total confirmations.';
  }

  @override
  String get onchainDepositConfirmedNotice => 'Deposit confirmed.';

  @override
  String get onchainDepositCancelTitle => 'Cancel deposit';

  @override
  String get onchainDepositCancelMessage =>
      'This address will stop being used for this deposit if no payment was detected yet.';

  @override
  String get onchainDepositCancelAction => 'Cancel deposit';

  @override
  String get onchainDepositCancelling => 'Cancelling...';

  @override
  String get onchainDepositCancelledNotice => 'Deposit cancelled.';

  @override
  String get onchainDepositGettingAddressTitle => 'Creating address';

  @override
  String get onchainDepositGettingAddressMessage =>
      'After payment, your balance updates when Bitcoin confirmations arrive.';

  @override
  String get onchainDepositErrorTitle => 'Could not prepare deposit';

  @override
  String get onchainDepositTotalLabel => 'Total to deposit';

  @override
  String onchainDepositNetworkTag(String network) {
    return '$network address';
  }

  @override
  String get onchainDepositTrackingTitle => 'Payment tracking';

  @override
  String get onchainDepositConfirmationsLabel => 'Confirmations';

  @override
  String get onchainDepositTxidLabel => 'Transaction code';

  @override
  String get onchainDepositObservedAmountLabel => 'Amount seen';

  @override
  String get onchainDepositAmountCheckLabel => 'Amount check';

  @override
  String get onchainDepositAmountCheckOk => 'Amount matches';

  @override
  String get onchainDepositAmountCheckDifferent => 'Different amount';

  @override
  String get onchainDepositQrTitle => 'Bitcoin address';

  @override
  String get onchainDepositQuoteLabel => 'BTC quote';

  @override
  String get onchainDepositDestinationWalletLabel => 'Goes to';

  @override
  String get onchainDepositNetworkLabel => 'Network';

  @override
  String get onchainDepositExpectedAmountLabel => 'Expected amount';

  @override
  String get onchainDepositReceivedAmountLabel => 'Received amount';

  @override
  String get onchainDepositMinimumConfirmationsLabel => 'Minimum confirmations';

  @override
  String onchainDepositMinimumConfirmationsValue(int count) {
    return '$count blocks';
  }

  @override
  String get onchainDepositCustodyLabel => 'Wallet type';

  @override
  String get onchainDepositCustodySelf => 'Cold wallet, view only';

  @override
  String get onchainDepositCustodyKerosene => 'Kerosene card';

  @override
  String get onchainDepositSecuritySelf =>
      'Kerosene only watches this address. Spending stays under your recovery words or your offline device.';

  @override
  String get onchainDepositSecurityKerosene =>
      'This address is created for your Kerosene card and watched until the deposit is confirmed.';

  @override
  String get errUnexpected => 'An unexpected error occurred.';

  @override
  String get errAuthUserAlreadyExists => 'This username is already in use.';

  @override
  String get errAuthUsernameMissing => 'Username is required.';

  @override
  String get errAuthPassphraseMissing => 'Passphrase is required.';

  @override
  String get errAuthInvalidUsernameFormat => 'Invalid username format.';

  @override
  String get errAuthCharLimitExceeded => 'Character limit exceeded.';

  @override
  String get errAuthUserNotFound =>
      'User not found. Please check your spelling.';

  @override
  String get errAuthInvalidPassphraseFormat =>
      'Passphrase does not meet requirements.';

  @override
  String get errAuthIncorrectTotp =>
      'The TOTP code is incorrect or has expired.';

  @override
  String get errAuthInvalidCredentials => 'Incorrect username or passphrase.';

  @override
  String get errAuthUnrecognizedDevice =>
      'Unrecognized device. Please authorize it.';

  @override
  String get errAuthTotpTimeout => 'The time to enter the code has expired.';

  @override
  String get errLedgerNotFound =>
      'Financial account not found. Please ensure your registration is complete.';

  @override
  String get errLedgerAlreadyExists => 'Account already has financial records.';

  @override
  String get errLedgerInsufficientBalance =>
      'You do not have enough balance to perform this transaction.';

  @override
  String get errLedgerInvalidOperation => 'Invalid operation attempt.';

  @override
  String get errLedgerReceiverNotFound => 'Transaction recipient not found.';

  @override
  String get errLedgerGeneric =>
      'We could not complete this movement right now.';

  @override
  String get errLedgerPaymentRequestNotFound => 'Payment link not found.';

  @override
  String get errLedgerPaymentRequestExpired => 'This payment link has expired.';

  @override
  String get errLedgerPaymentRequestAlreadyPaid =>
      'This payment link has already been paid.';

  @override
  String get errLedgerPaymentRequestSelfPay =>
      'You cannot pay a link created by yourself.';

  @override
  String get errWalletAlreadyExists =>
      'A wallet with this name already exists.';

  @override
  String get errWalletNotFound => 'The specified wallet was not found.';

  @override
  String get errWalletGeneric => 'We could not validate this wallet right now.';

  @override
  String get errNotifMissingToken => 'Notification token missing.';

  @override
  String get errNotifMissingFields => 'Required notification fields missing.';

  @override
  String get errInternalServer => 'Kerosene is temporarily unavailable.';

  @override
  String get errSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errForbidden => 'Access denied or unrecognized device.';

  @override
  String get errTooManySignupAttempts =>
      'Too many signup attempts. Please try again later.';

  @override
  String get errNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errTimeout =>
      'The connection timed out. Check your internet and try again.';

  @override
  String get errCommFailure => 'We could not reach Kerosene right now.';

  @override
  String get errInvalidBtcAddress => 'The provided Bitcoin address is invalid.';

  @override
  String get withdrawInvalidFields =>
      'Please enter a valid address and amount.';

  @override
  String get withdrawAuthReason => 'Authenticate to confirm withdrawal.';

  @override
  String get withdrawAuthCancelled => 'Authentication cancelled.';

  @override
  String get withdrawSuccess =>
      'Withdrawal successfully sent to the Bitcoin network!';

  @override
  String get withdrawFeeSection => 'NETWORK DIFFICULTY (FEE)';

  @override
  String get withdrawFeeFast => 'Fast';

  @override
  String get withdrawFeeMedium => 'Medium';

  @override
  String get withdrawFeeSlow => 'Slow';

  @override
  String get withdrawErrorFee => 'Error estimating network fees.';

  @override
  String get verifyingDevice => 'VERIFYING DEVICE';

  @override
  String get connectingToServer => 'CONNECTING TO SERVER';

  @override
  String get sendingData => 'SENDING DATA';

  @override
  String get apiDisplayActive => 'Active';

  @override
  String get apiDisplayWaiting => 'Waiting';

  @override
  String get apiDisplayBeingChecked => 'Being checked';

  @override
  String get apiDisplayDetected => 'Detected';

  @override
  String get apiDisplayConfirming => 'Confirming';

  @override
  String get apiDisplayCompleted => 'Completed';

  @override
  String get apiDisplayExpired => 'Expired';

  @override
  String get apiDisplayCancelled => 'Cancelled';

  @override
  String get apiDisplayNotCompleted => 'Not completed';

  @override
  String get apiDisplayProtected => 'Protected';

  @override
  String get apiDisplayAvailable => 'Available';

  @override
  String get apiDisplayUnavailable => 'Unavailable';

  @override
  String get apiDisplayHealthy => 'Healthy';

  @override
  String get apiDisplayNeedsAttention => 'Needs attention';

  @override
  String get apiDisplayActionNeeded => 'Action needed';

  @override
  String get apiDisplayInReview => 'In review';

  @override
  String get apiDisplayBeingTracked => 'Being tracked';

  @override
  String get apiDisplayAutomatic => 'Automatic';

  @override
  String get apiDisplayManualConfirmation => 'Manual confirmation';

  @override
  String get apiDisplayPrivate => 'Private';

  @override
  String get apiDisplayShareable => 'Shareable';

  @override
  String get apiDisplayWatchedColdWallet => 'Watched cold wallet';

  @override
  String get apiDisplayKeroseneCard => 'Kerosene card';

  @override
  String get apiDisplayBitcoinWallet => 'Bitcoin wallet';

  @override
  String get apiDisplayDeviceKey => 'Device key';

  @override
  String get apiDisplayAuthenticatorCode => 'Authenticator code';

  @override
  String get apiDisplayAccessPassword => 'Access password';

  @override
  String get apiDisplayRecoveryCodes => 'Recovery codes';

  @override
  String get apiDisplaySecureConfirmation => 'Secure confirmation';

  @override
  String get apiDisplayGenericActionError =>
      'We could not complete this action right now. Please try again.';

  @override
  String get apiDisplayLightningUnavailable =>
      'Lightning is not available for this wallet right now.';

  @override
  String get apiDisplayDepositAddressCreateFailed =>
      'We could not create an address for this deposit.';

  @override
  String get apiDisplaySecureConfirmationStartFailed =>
      'We could not start secure confirmation. Please try again.';

  @override
  String get apiDisplayInformationUnavailable => 'Information unavailable';

  @override
  String get apiDisplayAddressUnavailable => 'Address unavailable';

  @override
  String get apiDisplayCopied => 'Copied';

  @override
  String get apiDisplayDataCopied => 'Data copied';

  @override
  String get apiDisplayTransactionSummaryCopied =>
      'Transaction summary copied to the clipboard.';

  @override
  String get apiDisplayReceiveCancelled => 'Receiving request cancelled.';

  @override
  String get detailReference => 'Reference';

  @override
  String get detailRequestCode => 'Request code';

  @override
  String get detailConfirmationCode => 'Confirmation code';

  @override
  String get detailLightningCode => 'Lightning code';

  @override
  String get detailType => 'Type';

  @override
  String get detailBtcAmount => 'BTC';

  @override
  String get detailPaymentLink => 'Payment link';

  @override
  String get detailOnboardingVoucher => 'Onboarding voucher';

  @override
  String get detailExternalWithdrawal => 'External withdrawal';

  @override
  String get detailInternalMovement => 'Internal movement';

  @override
  String get detailBitcoinNetwork => 'Bitcoin network';

  @override
  String get qrScannerInstruction => 'Align the QR code inside the frame.';

  @override
  String get errorPopupSuccessTitle => 'Done';

  @override
  String get errorPopupTransactionTitle =>
      'We could not complete the transaction';

  @override
  String get errorPopupBalanceTitle => 'Balance required';

  @override
  String get errorPopupNetworkTitle => 'Connection issue';

  @override
  String get errorPopupAccessTitle => 'Access check failed';

  @override
  String get errInvalidNetworkAddress =>
      'This Bitcoin address does not match this wallet network. Check it and try again.';

  @override
  String get errCustodyProviderUnavailable =>
      'This transfer option is not available right now. Try another option or come back later.';

  @override
  String get errPayloadTooLarge => 'This content is too large to send safely.';

  @override
  String get errRecoveryBadRequest =>
      'Review the recovery codes, the new recovery phrase, and the authenticator code.';

  @override
  String get errRecoveryRejected =>
      'We could not confirm recovery. Review the information and try again.';

  @override
  String get errRecoverySessionExpired =>
      'The recovery time expired. Please restart the process.';

  @override
  String get errRecoveryRateLimited =>
      'Please wait a few minutes before trying recovery again.';

  @override
  String get errPasskeyDeviceNotLinked =>
      'This device is not linked to your account for passkey confirmation. Link this device and try again.';

  @override
  String get errPasskeyRequired =>
      'A passkey compatible with this login is required to finish this operation.';

  @override
  String get errPasskeyWrongDevice =>
      'This passkey cannot be used for this login. Sign in with passphrase and authenticator code, then link a new passkey on this device.';

  @override
  String get errPasskeyRejected =>
      'This passkey was rejected for the operation. If the problem persists, link another compatible passkey.';

  @override
  String get errPasskeyLinkGuidance =>
      'Sign in with passphrase and authenticator code, then link a passkey compatible with this device.';

  @override
  String get errReceiverNotReady =>
      'This user is not ready to receive funds yet.';

  @override
  String get errOnchainReceiverMethodNotFound =>
      'This user does not have an on-chain wallet registered to receive.';

  @override
  String get errOnchainInvalidAddress =>
      'The Bitcoin address is not valid for this network.';

  @override
  String get errOnchainAmountBelowDust =>
      'The amount is too low for on-chain sending after fees.';

  @override
  String get errOnchainInsufficientFundsForFee =>
      'Insufficient balance to cover the amount and the network fee.';

  @override
  String get errLightningInsufficientLiquidity =>
      'There is not enough Lightning liquidity to complete this payment now. Try another method or a lower amount.';

  @override
  String get errLightningRouteNotFound =>
      'We could not find a reliable Lightning route for this payment.';

  @override
  String get errLightningReceiverMethodNotFound =>
      'This user has not configured Lightning receiving yet.';

  @override
  String get errQuoteExpired =>
      'The quote expired. Generate a new one before confirming.';

  @override
  String get errQuoteChanged =>
      'The quote changed. Review the updated values before confirming.';

  @override
  String get errNetAmountNegative =>
      'The net amount would be less than zero after fees.';

  @override
  String get errInsufficientBalanceForFees =>
      'Insufficient balance to cover the amount and fees.';

  @override
  String get homeTxReceived => 'Received';

  @override
  String get homeTxSent => 'Sent';

  @override
  String get homeTxPaid => 'Paid';

  @override
  String get homeNow => 'now';

  @override
  String homeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String homeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String homeYesterdayAt(String time) {
    return 'Yesterday at $time';
  }

  @override
  String get homeWalletRequiredTitle => 'Wallet required';

  @override
  String get homeWalletRequiredMessage =>
      'Select or create a wallet before using this action.';

  @override
  String get homeNfcUnavailable =>
      'NFC is not available on this device right now.';

  @override
  String get homeSendInternalLabel => 'Send within Kerosene';

  @override
  String get homeSendInternalSubtitle => 'Immediate transfer between accounts';

  @override
  String get homeSendOnchainLabel => 'Send on-chain';

  @override
  String get homeSendOnchainSubtitle => 'To a Bitcoin address';

  @override
  String get homeSendLightningLabel => 'Send via Lightning';

  @override
  String get homeSendLightningSubtitle =>
      'Invoice, LNURL, or Lightning Address';

  @override
  String get homeScanQrLabel => 'Scan QR';

  @override
  String get homeScanQrSubtitle => 'Read a request or address';

  @override
  String get homePaymentLinkLabel => 'Payment link';

  @override
  String get homePaymentLinkSubtitle =>
      'Paste an internal link, on-chain URI, Lightning request, or request ID.';

  @override
  String get homeNfcPayLabel => 'Pay by NFC';

  @override
  String get homeNfcPaySubtitle => 'Hold nearby to start';

  @override
  String get homeSendTitle => 'Send';

  @override
  String get homePrimaryNoWalletTitle => 'Set up your main wallet';

  @override
  String get homePrimaryNoWalletSubtitle =>
      'Create a wallet to receive, send, and track your balance securely.';

  @override
  String get homePrimaryReadyNoBalanceTitle => 'Wallet ready to use';

  @override
  String get homePrimaryReadyNoBalanceSubtitle =>
      'Deposit whenever you want. We track network confirmation in real time.';

  @override
  String get homePrimaryReadyTitle => 'Ready to move funds';

  @override
  String get homePrimaryReadySubtitle =>
      'Access the main wallet actions with clear confirmation before each payment.';

  @override
  String get homeCreateWalletAction => 'Create wallet';

  @override
  String get homeDepositFundsAction => 'Deposit funds';

  @override
  String get homeSendBtcAction => 'Send BTC';

  @override
  String get homeReceiveBtcAction => 'Receive BTC';

  @override
  String get homeViewDepositsAction => 'View deposits';

  @override
  String get homePendingLinkTitle => 'Waiting for details';

  @override
  String get homePendingLinkMessage =>
      'Paste a link, Lightning request, Bitcoin address, or Kerosene code.';

  @override
  String get homeLightningPaymentTitle => 'Lightning payment';

  @override
  String get homeOnchainPaymentTitle => 'On-chain payment';

  @override
  String get homeInternalTransferTitle => 'Internal transfer';

  @override
  String get homeInvalidLinkTitle => 'Invalid code';

  @override
  String get homeInvalidLinkMessage =>
      'Remove spaces or line breaks and try again.';

  @override
  String get homeInternalLinkTitle => 'Internal link';

  @override
  String get homeInvoiceOrLnurl => 'Invoice or LNURL';

  @override
  String get homeBitcoinAddress => 'Bitcoin address';

  @override
  String get homeKeroseneUser => 'Kerosene user';

  @override
  String get homePaymentId => 'Payment ID';

  @override
  String get homePaymentLinkTitle => 'Payment link';

  @override
  String get homePayloadLabel => 'Payment details';

  @override
  String get homePayloadHint =>
      'Kerosene link, bitcoin:..., lightning:..., or ID';

  @override
  String get homePasteAction => 'Paste';

  @override
  String get homePayloadActionContinueOnchain => 'Continue on-chain';

  @override
  String get homePayloadActionContinueLightning => 'Continue Lightning';

  @override
  String get homePayloadActionContinueInternal => 'Continue internal';

  @override
  String get homePayloadActionLoadLink => 'Load link';

  @override
  String get homePayloadActionContinue => 'Continue';

  @override
  String get homeAmountFromLink => 'Defined by the link';

  @override
  String get homeAmountNotProvided => 'Not provided';

  @override
  String get homeDestinationLocked => 'Protected destination';

  @override
  String get homeLoadingLinkData => 'Loading link details';

  @override
  String get homeLinkValidationLater =>
      'Details will be validated when you continue';

  @override
  String get homeNetworkLabel => 'Network';

  @override
  String get homeDestinationLabel => 'Destination';

  @override
  String get homeAmountLabel => 'Amount';

  @override
  String get homeNetworkInternal => 'Internal';

  @override
  String get homeNetworkOnchain => 'On-chain';

  @override
  String get homeNetworkLightning => 'Lightning';

  @override
  String get homeNetworkInvalid => 'Invalid';

  @override
  String get homeNetworkWaiting => 'Waiting';

  @override
  String get homeEmptyNoWalletTitle => 'Create your first wallet';

  @override
  String get homeEmptyNoWalletDescription =>
      'You need a wallet to start moving funds.';

  @override
  String get homeEmptyNoBalanceTitle => 'Add funds to begin';

  @override
  String get homeEmptyNoBalanceDescription =>
      'Once the first deposit arrives, your activity appears here.';

  @override
  String get homeEmptyNoTransactionsTitle => 'No recent transactions';

  @override
  String get homeEmptyNoTransactionsDescription =>
      'New activity will appear automatically in this area.';

  @override
  String get homeDepositAction => 'Deposit';

  @override
  String get homeRefreshAction => 'Refresh';

  @override
  String get homeFullHistory => 'View full history';

  @override
  String get homeLoadingTransactionsTitle => 'Loading';

  @override
  String get homeLoadingTransactionsSubtitle => 'Syncing your activity.';

  @override
  String get homeOpenReceiveScreen => 'Open receive screen';

  @override
  String get authAccountAccessTitle => 'Account access';

  @override
  String get authAccountPasswordLabel => 'Account password';

  @override
  String get authUsernameRequiredMessage => 'Enter the account username.';

  @override
  String get authAccessEyebrow => 'Access account';

  @override
  String get authUsernameStepSubtitle => 'First enter your username.';

  @override
  String get authUsernameHint => 'Username';

  @override
  String get authPasskeyFirstNoteTitle => 'Protected access';

  @override
  String get authPasskeyFirstNoteBody =>
      'Kerosene checks this device key first.';

  @override
  String get authPrivateAccessEyebrow => 'Private access';

  @override
  String get authAccountPasswordTitle => 'Account password';

  @override
  String get authAccountPasswordHint => 'Enter your password';

  @override
  String get authCredentialSendingTitle => 'Signing in';

  @override
  String get authCredentialTitle => 'Credential';

  @override
  String get authCredentialSendingBody =>
      'We are protecting your sign-in. Please wait a moment.';

  @override
  String get authCredentialBody =>
      'Use the account password to continue. Your wallet keys are never requested in this sign-in.';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authEmergencyRecoveryAction => 'Emergency recovery';

  @override
  String get authFlowInterruptedTitle => 'We could not continue';

  @override
  String get authInvalidUsernameTitle => 'Invalid username';

  @override
  String get authWeakPasswordTitle => 'Weak password';

  @override
  String get authInvalidConfirmationTitle => 'Invalid confirmation';

  @override
  String get authPasswordMismatchMessage =>
      'The password confirmation does not match.';

  @override
  String get authConfirmationRequiredTitle => 'Confirmation required';

  @override
  String get authPasswordRiskRequiredMessage =>
      'Confirm that you understand the importance of keeping the account password safe.';

  @override
  String get authAccountEyebrow => 'Account';

  @override
  String get authCreateAccountTitle => 'Create account';

  @override
  String get authCreateAccountSubtitle =>
      'Choose your Kerosene access credentials.';

  @override
  String get authUsernameMinError => 'Use at least 3 characters.';

  @override
  String get authUsernameCharsError =>
      'Use only lowercase letters, numbers, and underscores.';

  @override
  String get authPasswordStrengthMessage =>
      'Use at least 12 characters with uppercase, lowercase, number, and symbol.';

  @override
  String get authAccountCredentialsTitle => 'Account and credentials';

  @override
  String get authAccountCredentialsBody =>
      'Choose your public identifier. The password comes in the next step.';

  @override
  String get authCustodyNoteTitle => 'Keep it carefully';

  @override
  String get authCustodyNoteBody =>
      'If you lose the password without recovery codes, account access may be lost. Keep the codes in a safe place.';

  @override
  String get authStrongPasswordTitle => 'Strong password';

  @override
  String get authStrongPasswordBody =>
      'Use a long, unique password that is hard to guess.';

  @override
  String get authPasswordReadyTitle => 'Ready';

  @override
  String get authPasswordMinimumTitle => 'Minimum rule';

  @override
  String get authPasswordRuleBody =>
      '12 characters or more, with uppercase, lowercase, number, and symbol.';

  @override
  String get authBackAction => 'Back';

  @override
  String get authReadyAction => 'Ready';

  @override
  String get authConfirmPasswordTitle => 'Confirm password';

  @override
  String get authConfirmPasswordBody =>
      'Repeat the password and confirm that you know where to keep it.';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPasswordRiskAcknowledgement =>
      'I understand that losing the password may prevent my account access.';

  @override
  String get authCreateAction => 'Create';

  @override
  String get authPasskeyRegisterTitle => 'Register device key';

  @override
  String get authPasskeyRegisterBody =>
      'Finish by creating this device\'s secure key to protect access.';

  @override
  String get authDeviceTitle => 'Device';

  @override
  String get authDeviceBody =>
      'This device key helps confirm it is you when signing in.';

  @override
  String get authRegisterPasskeyAction => 'Register key';

  @override
  String get authPasskeyStepLabel => 'Key';

  @override
  String get authSignupStepFallbackLabel => 'Signup';

  @override
  String get authSignupStepUsernameTitle => 'Username';

  @override
  String get authSignupStepPasswordTitle => 'Password';

  @override
  String get authSignupStepConfirmationTitle => 'Confirmation';

  @override
  String get authSignupStepCreationTitle => 'Creation';

  @override
  String get authPasswordLongHint => '12 characters or more';

  @override
  String get authSessionInterruptedTitle => 'Session interrupted';

  @override
  String get authSignupSessionExpiredMessage =>
      'Your signup session expired. Restart account creation to continue safely.';

  @override
  String get authSecurityPreparingTitle => 'Preparing security';

  @override
  String get authSecurityPreparingMessage =>
      'Account protection is still being prepared. Try again in a few seconds.';

  @override
  String get profileFallbackUser => 'User';

  @override
  String get profileNoWallet => 'No wallet';

  @override
  String get profileNoWallets => 'No wallets';

  @override
  String get profileOneActiveWallet => '1 active wallet';

  @override
  String profileActiveWallets(int count) {
    return '$count active wallets';
  }

  @override
  String get profileBiometricsChecking => 'Checking';

  @override
  String get profileBiometricsEnabled => 'Biometrics enabled';

  @override
  String get profileBiometricsDisabled => 'Biometrics disabled';

  @override
  String get profileBiometricsUnavailable => 'Biometrics unavailable';

  @override
  String get profileAlertsMonitoringActive => 'Alerts and monitoring active';

  @override
  String get profileMonitoringNoBanners => 'Monitoring active without banners';

  @override
  String get profileRealtimeAlertsDisabled => 'Real-time alerts disabled';

  @override
  String get profileAccessHeader => 'Profile and access';

  @override
  String get profileAccessSubtitle =>
      'Identity, account security, and session control.';

  @override
  String get profileAuthenticated => 'Account authenticated';

  @override
  String get profileAwaitingAuthentication => 'Awaiting authentication';

  @override
  String get profileIntro =>
      'This area brings together your access, account protection, and support channels.';

  @override
  String get profilePostureTitle => 'Current posture';

  @override
  String get profilePostureSubtitle =>
      'Important account signals in simple language.';

  @override
  String get profilePrioritiesTitle => 'Priorities';

  @override
  String get profilePrioritiesSubtitle =>
      'Access, security, and trust preferences.';

  @override
  String get profileSecuritySubtitle =>
      'Review biometrics, recovery, device key, and access practices.';

  @override
  String get profileSovereigntyReportTitle => 'Sovereignty report';

  @override
  String get profileSovereigntyReportSubtitle =>
      'Track hardware, consensus, and operational integrity.';

  @override
  String get profileSettingsSubtitle =>
      'Adjust privacy, language, appearance, and session.';

  @override
  String get profileAccountSupportTitle => 'Account and support';

  @override
  String get profileAccountSupportSubtitle =>
      'Personal data, notifications, and help.';

  @override
  String get profilePersonalDataSubtitle =>
      'Review name, data, and account information.';

  @override
  String get profileNotificationsSubtitle =>
      'Control transaction and security alerts.';

  @override
  String get profileSupportSubtitle =>
      'Open support channels for questions or incidents.';

  @override
  String get profileLogoutSubtitle =>
      'Ends this session and requires new authentication.';

  @override
  String get profileSecurityShamir => 'Advanced backup';

  @override
  String get profileSecurityMultisig => 'Vault with multiple approvals';

  @override
  String get profileSecurityStandard => 'Standard protection';

  @override
  String get walletEditNameAction => 'Edit name';

  @override
  String get securityCopiedTitle => 'Copied';

  @override
  String securityCopiedMessage(String label) {
    return '$label copied to the clipboard.';
  }

  @override
  String get securityTotpFailureTitle =>
      'We could not update the authenticator';

  @override
  String get securityInvalidCodeTitle => 'Invalid code';

  @override
  String get securityTotpCodeRequiredMessage =>
      'Enter the 6 digits from the authenticator.';

  @override
  String get securityTotpEnabledTitle => 'Authenticator enabled';

  @override
  String get securityTotpEnabledMessage =>
      'Your account now has an additional protection layer.';

  @override
  String get securityTotpDisableFailedTitle =>
      'We could not disable the authenticator';

  @override
  String get securityTotpDisabledTitle => 'Authenticator disabled';

  @override
  String get securityTotpDisabledMessage =>
      'Authenticator protection was removed from this account.';

  @override
  String get securityBackupRegenerateFailedTitle =>
      'We could not generate new codes';

  @override
  String get securityBackupCodesTitle => 'Recovery codes';

  @override
  String get securityBackupCodesBody =>
      'Keep these codes outside this device. They can help recover access.';

  @override
  String get securityBackupCodesCopyLabel => 'Recovery codes';

  @override
  String get securityBackupCodesCopyAction => 'Copy codes';

  @override
  String get securityRegisterDeviceFailedTitle =>
      'We could not register the device';

  @override
  String get securityDeviceRegisteredTitle => 'Device registered';

  @override
  String get securityDeviceRegisteredMessage =>
      'This device is now linked to your account.';

  @override
  String get securityDeviceInventoryLoadingSubtitle =>
      'The account has an authenticated device, but details are still loading.';

  @override
  String get securityRegisterDeviceSubtitle =>
      'Register this device as an authenticated device.';

  @override
  String get securityCompatibleDeviceOne =>
      'There is 1 device compatible with this sign-in.';

  @override
  String securityCompatibleDeviceMany(int count) {
    return 'There are $count devices compatible with this sign-in.';
  }

  @override
  String get securityLegacyDeviceSubtitle =>
      'Some older devices have limited compatibility. Link this device again if access fails.';

  @override
  String get securityNoCompatibleDeviceSubtitle =>
      'Registered devices are not compatible with this sign-in. Sign in with password and authenticator to link another.';

  @override
  String get securityScreenTitle => 'Security';

  @override
  String get securityScreenSubtitle =>
      'Authenticated devices, authenticator, recovery codes, and this device PIN.';

  @override
  String get securityUnprotectedTitle => 'Account not protected';

  @override
  String get securityUnprotectedFallback =>
      'Enable the authenticator to add an optional protection layer.';

  @override
  String get securityPinEntryTitle => 'Entry PIN';

  @override
  String get securityPinLoadError =>
      'We could not check the PIN for this device.';

  @override
  String get securityAuthenticatedDevicesTitle => 'Authenticated devices';

  @override
  String get securityRegisteredDeviceSubtitle =>
      'This device is registered for this account.';

  @override
  String get securityRegisterThisDeviceSubtitle => 'Register this device.';

  @override
  String get securityLinkNewDeviceAction => 'Link new device';

  @override
  String get securityRegisterDeviceAction => 'Register device';

  @override
  String get securityDeviceCompatibilityError =>
      'We could not check device compatibility for this sign-in.';

  @override
  String get securityTotpOptionalTitle => 'Optional authenticator';

  @override
  String get securityTotpEnabledSubtitle =>
      'Authenticator active. The unprotected account notice is hidden.';

  @override
  String get securityTotpDisabledSubtitle =>
      'No authenticator. The account is marked as not protected.';

  @override
  String get securityDisableTotpAction => 'Disable authenticator';

  @override
  String get securityEnableTotpAction => 'Enable authenticator';

  @override
  String securityBackupCodesRemaining(int count) {
    return '$count codes remaining. Keep them in a safe place.';
  }

  @override
  String get securityBackupCodesLockedSubtitle =>
      'Enable the authenticator to unlock recovery codes.';

  @override
  String get securityRegenerateCodesAction => 'Generate new codes';

  @override
  String get securityWaitingTotpAction => 'Waiting for authenticator';

  @override
  String get securityViewLatestAction => 'View latest';

  @override
  String get securityBackupCodesLoadError =>
      'We could not check recovery codes.';

  @override
  String get securityStatusLoadError =>
      'We could not check account security status.';

  @override
  String get securityCurrentStatusTitle => 'Current status';

  @override
  String get securityStrongPasswordPill => 'Strong password';

  @override
  String get securityDevicePill => 'Device';

  @override
  String get securityInboundPill => 'Receiving';

  @override
  String get securityAppPinPill => 'Entry PIN';

  @override
  String get securityLocalBiometricsPill => 'Local biometrics';

  @override
  String get securityCurrentHostLabel => 'Current device';

  @override
  String get securityCurrentRpLabel => 'Access domain';

  @override
  String get securityLegacyCredentialsTitle => 'Older credentials detected';

  @override
  String get securityLegacyCredentialsBody =>
      'Some older devices have incomplete details. Replace them with a new key when possible.';

  @override
  String get securityNoAuthenticatedDevice =>
      'No authenticated device has been linked for this account in this context.';

  @override
  String get securityDeviceDetailsUnavailable =>
      'The device is active, but details are not available yet.';

  @override
  String get securityInventoryNotLoaded =>
      'Device details have not loaded yet.';

  @override
  String get securityInventoryNone =>
      'No authenticated device registered for this account.';

  @override
  String get securityInventoryCompatible =>
      'At least one authenticated device can be used for this sign-in.';

  @override
  String get securityInventoryLegacy =>
      'Some devices have incomplete details. Review the list before relying on them.';

  @override
  String get securityInventoryIncompatible =>
      'The currently linked devices cannot be used for this sign-in.';

  @override
  String get securityInventoryUnknownBanner =>
      'We could not determine whether this sign-in has a usable device.';

  @override
  String get securityInventoryRegisterBanner =>
      'Link this device to enable compatible confirmations and sign-in.';

  @override
  String securityInventoryCompatibleCount(int count) {
    return '$count devices can confirm this sign-in now.';
  }

  @override
  String get securityInventoryCompatibleFallback =>
      'There is at least one device compatible with this sign-in.';

  @override
  String get securityInventoryLegacyBanner =>
      'There are older credentials. If this sign-in fails, use password and authenticator to link this device again.';

  @override
  String get securityInventoryIncompatibleBanner =>
      'No compatible device was found for this access. Sign in with password and authenticator to link another.';

  @override
  String get securityPinActiveLockedSubtitle =>
      'Entry PIN is active. It is temporarily locked on this device.';

  @override
  String securityPinActiveAttemptsSubtitle(int count) {
    return 'Entry PIN is active. $count attempts remain before lockout.';
  }

  @override
  String get securityPinDisabledSubtitle =>
      'Protect app entry on this device with a PIN independent from your main password.';

  @override
  String get securityChangePinAction => 'Change PIN';

  @override
  String get securityEnablePinAction => 'Enable PIN';

  @override
  String get securityDisableAction => 'Disable';

  @override
  String get securityPinMismatchError =>
      'The new PIN and confirmation must match.';

  @override
  String get securityPinEnableTitle => 'Enable entry PIN';

  @override
  String get securityPinChangeTitle => 'Change this device PIN';

  @override
  String get securityPinDisableTitle => 'Disable entry PIN';

  @override
  String get securityPinEnableBody =>
      'The PIN will be required whenever the app opens with this session on this device.';

  @override
  String get securityPinChangeBody =>
      'Use the current PIN or an authenticator code to set a new PIN.';

  @override
  String get securityPinDisableBody =>
      'Use the current PIN or an authenticator code to remove this device entry barrier.';

  @override
  String get securityCurrentPinLabel => 'Current PIN or authenticator code';

  @override
  String get securityTotpCodeLabel => 'Authenticator code';

  @override
  String securityNewPinLabel(int min, int max) {
    return 'New PIN ($min-$max digits)';
  }

  @override
  String get securityConfirmNewPinLabel => 'Confirm new PIN';

  @override
  String get securityDisablePinAction => 'Disable PIN';

  @override
  String get securitySavePinAction => 'Save PIN';

  @override
  String get securityDeviceBrandLabel => 'Brand';

  @override
  String get securityDeviceModelLabel => 'Model';

  @override
  String get securityDeviceSerialLabel => 'Serial number';

  @override
  String get securityDeviceInstallIdLabel => 'Installation ID';

  @override
  String get securityDeviceBrowserLabel => 'Browser';

  @override
  String get securityDeviceSystemLabel => 'System';

  @override
  String get securityDeviceStatusLabel => 'Status';

  @override
  String get securityDeviceFirstAccessLabel => 'First access';

  @override
  String get securityDeviceLastAccessLabel => 'Last access';

  @override
  String get securityDeviceOriginLabel => 'Origin';

  @override
  String get securityDeviceRelyingPartyLabel => 'Access domain';

  @override
  String get securityDeviceCanUse => 'Can be used for this sign-in.';

  @override
  String get securityDeviceCannotUse =>
      'Cannot be used for the current sign-in.';

  @override
  String get securityDeviceUnknownUse =>
      'Compatibility has not been determined for this credential yet.';

  @override
  String get securityStatusPending => 'Pending';

  @override
  String get securityStatusBlocked => 'Blocked';

  @override
  String get securityStatusRevoked => 'Revoked';

  @override
  String get securityStatusActive => 'Active';

  @override
  String get securityCompatibleBadge => 'Compatible';

  @override
  String get securityIncompatibleBadge => 'Incompatible';

  @override
  String get securityUnknownBadge => 'Unknown';

  @override
  String get securityTotpSetupTitle => 'Enable authenticator';

  @override
  String get securityCopySecretAction => 'Copy secret';

  @override
  String get securityValidateTotpAction => 'Validate code';

  @override
  String get settingsUiSecurityAccessSection => 'Security and access';

  @override
  String get settingsUiEnterpriseAccessSection => 'Enterprise access';

  @override
  String get settingsUiPrivacySection => 'Privacy';

  @override
  String get settingsUiAccountAccessSection => 'Account and access';

  @override
  String get settingsUiNotificationsSection => 'Notifications';

  @override
  String get settingsUiAppearanceSection => 'Appearance';

  @override
  String get settingsUiLocaleCurrencySection => 'Language and currency';

  @override
  String get settingsUiSessionSection => 'Session';

  @override
  String get settingsUiOperationalSummaryTitle => 'Operational summary';

  @override
  String get settingsUiAlertsLabel => 'Alerts';

  @override
  String get settingsUiAlertsBackgroundActive => 'Background active';

  @override
  String get settingsUiDisabled => 'Disabled';

  @override
  String get settingsUiThemeLabel => 'Theme';

  @override
  String get settingsUiChecking => 'Checking';

  @override
  String get settingsUiActive => 'Active';

  @override
  String get settingsUiInactive => 'Inactive';

  @override
  String get settingsUiUnavailable => 'Unavailable';

  @override
  String get settingsUiDecimalPrecisionTitle => 'Decimal precision';

  @override
  String settingsUiDecimalPrecisionSubtitle(int count) {
    return 'Showing $count decimal places';
  }

  @override
  String get settingsUiHideBalanceTitle => 'Hide balance';

  @override
  String get settingsUiBalanceHiddenSubtitle =>
      'Values are masked on the main interface';

  @override
  String get settingsUiBalanceVisibleSubtitle =>
      'Values are visible on operational screens';

  @override
  String get settingsUiSovereigntyReportTitle => 'Sovereignty report';

  @override
  String get settingsUiSovereigntyReportSubtitle =>
      'Open the attestation, consensus, and operational integrity panel';

  @override
  String get settingsUiSecurityUnprotectedSubtitle =>
      'Account not protected. Review authenticator and recovery codes.';

  @override
  String get settingsUiSecurityProtectedSubtitle =>
      'Account protected with strong password, authenticated devices, and optional factors.';

  @override
  String get settingsUiSecurityLoadingSubtitle => 'Checking account status';

  @override
  String get settingsUiSecurityErrorSubtitle =>
      'We could not check account security';

  @override
  String get settingsUiPasskeyRegisteredSubtitle =>
      'Authenticated device already registered for this account';

  @override
  String get settingsUiPasskeyRegisterSubtitle =>
      'Register this device with biometrics';

  @override
  String get settingsUiPasskeyLoadingSubtitle => 'Checking devices';

  @override
  String get settingsUiPasskeyErrorSubtitle => 'We could not check devices';

  @override
  String get settingsUiUnprotectedBannerTitle => 'Account not protected';

  @override
  String get settingsUiUnprotectedBannerBody =>
      'The authenticator is off. Open Security Center to enable protection and review recovery codes.';

  @override
  String get settingsUiBiometricUnlockTitle => 'Biometric unlock';

  @override
  String get settingsUiBiometricUnlockSubtitle =>
      'Use fingerprint or face to unlock';

  @override
  String get settingsUiSecurityCenterTitle => 'Security center';

  @override
  String get settingsUiSessionsActiveTitle => 'Active sessions';

  @override
  String get settingsUiSessionsActiveSubtitle =>
      'View and revoke device sessions';

  @override
  String get settingsUiSessionsActiveMessage =>
      'Your sessions are protected automatically. End access on this device if it is no longer with you.';

  @override
  String get settingsUiEnterpriseIntro =>
      'For enterprise use, generate an access key on this device and keep it safe.';

  @override
  String get settingsUiEnterpriseKeyLoading => 'Checking enterprise key...';

  @override
  String get settingsUiEnterpriseKeyLoadError =>
      'We could not check the enterprise key.';

  @override
  String get settingsUiEnterpriseCreateKeyTitle => 'Create enterprise key';

  @override
  String get settingsUiEnterpriseCreateKeySubtitle =>
      'Generates a strong key on this device and registers only the secure confirmation';

  @override
  String get settingsUiEnterpriseRotateKeyTitle => 'Change key';

  @override
  String get settingsUiEnterpriseRotateKeySubtitle =>
      'Revokes the current key and creates a new one';

  @override
  String get settingsUiEnterpriseRevokeKeyTitle => 'Revoke key';

  @override
  String get settingsUiEnterpriseRevokeKeySubtitle =>
      'Blocks new enterprise access until a new key is created';

  @override
  String get settingsUiEnterpriseCreateDialogMessage =>
      'This key authorizes enterprise access together with username and password. Keep it safe. Kerosene will never ask for your seed or recovery phrase.';

  @override
  String get settingsUiEnterpriseCreateKeyAction => 'Create key';

  @override
  String get settingsUiEnterpriseCreateKeyFailed =>
      'We could not create the key';

  @override
  String get settingsUiEnterpriseRevokeDialogMessage =>
      'The current key will no longer authorize enterprise access. Create a new one on this device when you need to reactivate it.';

  @override
  String get settingsUiEnterpriseRevokeAction => 'Revoke';

  @override
  String get settingsUiEnterpriseRevokeFailed => 'We could not revoke';

  @override
  String get settingsUiEnterpriseKeyRevokedTitle => 'Key revoked';

  @override
  String get settingsUiEnterpriseKeyRevokedMessage =>
      'Enterprise access will require a new key.';

  @override
  String get settingsUiEnterpriseDecisionFailed =>
      'We could not register the decision';

  @override
  String get settingsUiEnterpriseAccessAllowedTitle => 'Access allowed';

  @override
  String get settingsUiEnterpriseDeviceBlockedTitle => 'Device blocked';

  @override
  String get settingsUiEnterpriseAccessAllowedMessage =>
      'Enterprise access can continue in the browser.';

  @override
  String get settingsUiEnterpriseDeviceBlockedMessage =>
      'New attempts from this device were blocked.';

  @override
  String get settingsUiEnterpriseKeyCreatedTitle => 'Key created';

  @override
  String get settingsUiEnterpriseKeyCreatedMessage =>
      'This key will only be shown now. Keep it safe.';

  @override
  String get settingsUiEnterpriseKeyCopiedMessage => 'Enterprise key copied.';

  @override
  String get settingsUiCopyAction => 'Copy';

  @override
  String get settingsUiCloseAction => 'Close';

  @override
  String get settingsUiEnterpriseKeyActive =>
      'Key active for enterprise access.';

  @override
  String get settingsUiEnterpriseKeyMissing => 'No active enterprise key.';

  @override
  String get settingsUiEnterpriseAttemptTitle =>
      'There was an enterprise access attempt.';

  @override
  String get settingsUiBrowserLabel => 'Browser';

  @override
  String get settingsUiDeviceLabel => 'Device';

  @override
  String get settingsUiTimeLabel => 'Time';

  @override
  String get settingsUiAllowAction => 'Allow';

  @override
  String get settingsUiBlockAction => 'Block';

  @override
  String get settingsUiAuthenticatedLabel => 'Authenticated';

  @override
  String get settingsUiDeleteAccountTitle => 'Delete account';

  @override
  String get settingsUiDeleteAccountSubtitle => 'Permanently removes all data';

  @override
  String get settingsUiDeleteAccountDialogTitle => 'Delete account?';

  @override
  String get settingsUiDeleteAccountDialogMessage =>
      'This will permanently delete your account, wallets, and funds. This action cannot be undone.\n\nTo protect your funds, withdraw all balances before deleting the account.';

  @override
  String get settingsUiDeleteForeverAction => 'Delete forever';

  @override
  String get settingsUiTransactionSecurityAlertsTitle =>
      'Transaction and security alerts';

  @override
  String get settingsUiBackgroundAlertsOnSubtitle =>
      'Active. The app stays in the background to show transactions and security alerts.';

  @override
  String get settingsUiBackgroundAlertsOffSubtitle =>
      'Enable to keep the app in the background and receive transaction and security alerts.';

  @override
  String get settingsUiInAppBannersTitle => 'In-app banners';

  @override
  String get settingsUiInAppBannersOnSubtitle =>
      'Shows contextual alerts in the current session.';

  @override
  String get settingsUiInAppBannersOffSubtitle =>
      'Keeps the feed, but does not interrupt navigation with banners.';

  @override
  String get settingsUiFinancialEventsTitle => 'Financial events';

  @override
  String get settingsUiFinancialEventsOnSubtitle =>
      'Receives, sends, deposits, links, and mining appear in the feed.';

  @override
  String get settingsUiFinancialEventsOffSubtitle =>
      'Hides financial operation alerts from the session feed.';

  @override
  String get settingsUiSecurityEventsTitle => 'Security events';

  @override
  String get settingsUiSecurityEventsOnSubtitle =>
      'Sign-ins, recovery, and sensitive events remain highlighted.';

  @override
  String get settingsUiSecurityEventsOffSubtitle =>
      'Hides only security alerts from the session inbox.';

  @override
  String get settingsUiUpdatingBackgroundAlerts =>
      'Updating background monitoring.';

  @override
  String settingsUiBackgroundAlertsInfo(int count) {
    return 'When active, Kerosene keeps a background service to monitor sends, receives, and critical security events. On Android, a persistent system notification remains visible while monitoring is on. $count alerts have not been read in this session.';
  }

  @override
  String get settingsUiPermissionRequiredTitle => 'Permission required';

  @override
  String get settingsUiPermissionRequiredMessage =>
      'The system did not allow notifications. Authorize the app to enable background monitoring.';

  @override
  String get settingsUiMonitoringActiveTitle => 'Monitoring active';

  @override
  String get settingsUiMonitoringInactiveTitle => 'Monitoring disabled';

  @override
  String get settingsUiMonitoringActiveMessage =>
      'The app will continue in the background to show transactions and security alerts.';

  @override
  String get settingsUiMonitoringInactiveMessage =>
      'Kerosene will no longer keep the background alert service running.';

  @override
  String get settingsUiAlertsUpdateFailedTitle => 'We could not update alerts';

  @override
  String get settingsUiAlertsUpdateFailedMessage =>
      'We could not change background monitoring right now.';

  @override
  String get settingsUiLogoutTitle => 'Sign out';

  @override
  String get settingsUiLogoutSubtitle => 'Ends the current session';

  @override
  String get settingsUiLogoutDialogTitle => 'Sign out?';

  @override
  String get settingsUiLogoutDialogMessage =>
      'You will need to authenticate again to access the account.';

  @override
  String get settingsUiAuthenticatedDevicesBody =>
      'This registration uses the device biometric sensor as a physical security key. The details shown use auditable device data without exposing sensitive information.';

  @override
  String get settingsUiRegisterNewDeviceAction => 'Register new device';

  @override
  String get settingsUiLearnMoreAction => 'Learn more';

  @override
  String get settingsUiBackgroundAlertsTitle => 'Background alerts';

  @override
  String get settingsUiBackgroundAlertsConsentBody =>
      'When enabled, Kerosene will continue running in the background to show received and sent transactions and critical security alerts. On Android, the system will keep a persistent notification while monitoring is active.';

  @override
  String get settingsUiEnableMonitoringAction => 'Enable monitoring';

  @override
  String get settingsUiUnderstoodAction => 'Understood';

  @override
  String get transactionVisualCancelled => 'Canceled';

  @override
  String get transactionVisualRefund => 'Refund';

  @override
  String get transactionVisualFailed => 'Not completed';

  @override
  String get transactionVisualMining => 'Mining';

  @override
  String get transactionVisualSwap => 'Conversion';

  @override
  String get transactionVisualFee => 'Fee';

  @override
  String get transactionVisualLightningDeposit => 'Lightning deposit';

  @override
  String get transactionVisualLightningPayment => 'Lightning payment';

  @override
  String get transactionVisualLightningReceive => 'Lightning receive';

  @override
  String get transactionVisualDeposit => 'Deposit';

  @override
  String get transactionVisualWithdrawal => 'Withdrawal';

  @override
  String get transactionVisualNfcReceive => 'NFC receive';

  @override
  String get transactionVisualNfcPayment => 'NFC payment';

  @override
  String get transactionVisualQrReceive => 'QR receive';

  @override
  String get transactionVisualQrPayment => 'QR payment';

  @override
  String get transactionVisualPaymentLinkReceive => 'Payment link receive';

  @override
  String get transactionVisualPaymentLinkPayment => 'Payment link payment';

  @override
  String get transactionVisualInternalReceive => 'Kerosene receive';

  @override
  String get transactionVisualInternalSend => 'Kerosene send';

  @override
  String get transactionVisualEvent => 'Activity';

  @override
  String get transactionVisualOnChainReceive => 'On-chain receive';

  @override
  String get transactionVisualOnChainSend => 'On-chain send';

  @override
  String get withdrawUiColdWalletSendBlocked =>
      'This cold wallet is only monitored in the app. To send, sign the transaction on the device where your keys are kept.';

  @override
  String get withdrawUiLightningDestinationRequired =>
      'Enter a Lightning request or LNURL to continue.';

  @override
  String get withdrawUiLightningDestinationRequiredForFlow =>
      'Enter a Lightning request or LNURL for this send.';

  @override
  String get withdrawUiLightningDestinationWrongFlow =>
      'The destination is Lightning. Open Lightning send to continue.';

  @override
  String get withdrawUiOnchainDestinationWrongFlow =>
      'This field received an on-chain address. Use a Lightning request or LNURL.';

  @override
  String get withdrawUiLightningFieldWrongFlow =>
      'This field received a Lightning request. Use Lightning send to continue.';

  @override
  String withdrawUiConfiguredNetworkMismatch(String network) {
    return 'The address does not belong to the $network network configured for this wallet.';
  }

  @override
  String withdrawUiNetworkMismatch(String detected, String expected) {
    return 'This address belongs to $detected, but the wallet is operating on $expected.';
  }

  @override
  String get withdrawUiWaitFeeEstimate =>
      'Wait for the network fee estimate before reviewing the total send amount.';

  @override
  String get withdrawUiFeeEstimateUnavailable =>
      'We could not estimate the network fee right now. Try again shortly.';

  @override
  String get withdrawUiSecurityTotpRequired =>
      'This transaction requires your authenticator code and the security factors configured on your account.';

  @override
  String get withdrawUiSecurityPasskeyRequired =>
      'This transaction requires passkey confirmation before sending.';

  @override
  String get withdrawUiDetailNetwork => 'Network';

  @override
  String get withdrawUiDetailSourceWallet => 'Source wallet';

  @override
  String get withdrawUiDetailCard => 'Card';

  @override
  String get withdrawUiDetailType => 'Type';

  @override
  String get withdrawUiDetailExecution => 'Execution';

  @override
  String get withdrawUiLightningPayment => 'Lightning payment';

  @override
  String get withdrawUiOnchainWithdrawal => 'On-chain withdrawal';

  @override
  String get withdrawUiLightningLiquidityChecking =>
      'Checking Lightning liquidity';

  @override
  String get withdrawUiSecureWalletSignature => 'Secure wallet signature';

  @override
  String get withdrawUiAmountBtc => 'Amount in BTC';

  @override
  String withdrawUiPlatformFeeWithRate(String rate) {
    return 'Kerosene fee ($rate)';
  }

  @override
  String get withdrawUiRoutingFeeCap => 'Routing limit';

  @override
  String get withdrawUiEstimatedNetworkFee => 'Estimated network fee';

  @override
  String get withdrawUiNetworkFeeRate => 'Network fee';

  @override
  String get withdrawUiTotalDebited => 'Total debited';

  @override
  String get withdrawUiBalanceBefore => 'Balance before';

  @override
  String get withdrawUiBalanceAfter => 'Estimated balance after';

  @override
  String get withdrawUiFinalReview => 'Final review';

  @override
  String get withdrawUiSourceFrom => 'From';

  @override
  String get withdrawUiLightningReviewNotice =>
      'Review the Lightning request and routing limit. The payment will be sent through the best available route.';

  @override
  String get withdrawUiOnchainReviewNotice =>
      'Check the on-chain address carefully. After broadcast, a Bitcoin transaction cannot be reversed.';

  @override
  String get withdrawUiAuthIncomplete =>
      'Authentication was canceled or incomplete.';

  @override
  String get withdrawUiWalletLoadingSubtitle =>
      'Loading wallet to start the send.';

  @override
  String get withdrawUiLightningSubtitle =>
      'Enter the Lightning request, review the amount, and confirm the payment.';

  @override
  String get withdrawUiOnchainSubtitle =>
      'Enter the Bitcoin address, review fees, and confirm the withdrawal.';

  @override
  String get withdrawUiRecentLightning => 'Recent Lightning requests';

  @override
  String get withdrawUiRecentOnchain => 'Recent addresses';

  @override
  String get withdrawUiContinue => 'Continue';

  @override
  String get withdrawUiTreasuryLiquidity => 'Lightning liquidity';

  @override
  String get withdrawUiTreasuryUnavailable =>
      'We could not validate liquidity in real time on this attempt. Try again shortly.';

  @override
  String get withdrawUiTreasuryState => 'Status';

  @override
  String get withdrawUiTreasuryAvailableLightning => 'Available LN';

  @override
  String get withdrawUiTreasuryOutbound => 'Available outbound';

  @override
  String get withdrawUiTreasuryOnchainReserve => 'On-chain reserve';

  @override
  String get withdrawUiFeeEstimating => 'Estimating...';

  @override
  String get withdrawUiUnavailable => 'Unavailable';

  @override
  String get withdrawUiFeeWaiting => 'Waiting for fee';

  @override
  String get withdrawUiSelectedNetwork => 'Selected network';

  @override
  String get withdrawUiRoutingFeeMax => 'Maximum routing fee';

  @override
  String get withdrawUiFeeEstimateUnavailableLong =>
      'We could not estimate the network fee right now. Review again shortly before confirming the send.';

  @override
  String get withdrawUiEnterAmountForFees =>
      'Enter an amount to calculate the total cost before confirming.';

  @override
  String withdrawUiEquivalentTo(String amount) {
    return 'Equivalent to $amount';
  }

  @override
  String get withdrawUiColdWalletTitle => 'Cold wallet';

  @override
  String get withdrawUiColdWalletBody =>
      'This cold wallet is monitored for receiving, but withdrawal keys remain outside Kerosene.';

  @override
  String get withdrawUiOperationalExecution => 'Operational execution';

  @override
  String get withdrawUiOnchainOperationalBody =>
      'On-chain sends are prepared for secure signing before being sent to the Bitcoin network.';

  @override
  String get withdrawUiTreasuryLoadingBody =>
      'Loading liquidity and reserve before enabling the Lightning payment.';

  @override
  String get withdrawUiDestinationEmptyOnchain =>
      'Enter an on-chain Bitcoin address or bitcoin: URI to continue.';

  @override
  String get withdrawUiDestinationValidLightning =>
      'Lightning request or LNURL is valid for this send.';

  @override
  String get withdrawUiDestinationValidOnchain =>
      'On-chain address is valid for this send.';

  @override
  String withdrawUiDestinationValidOnchainNetwork(String network) {
    return 'On-chain address is valid for $network.';
  }

  @override
  String get withdrawUiScreenTitleOnchain => 'Send on-chain';

  @override
  String get withdrawUiScreenTitleLightning => 'Send Lightning';

  @override
  String get withdrawUiLiquidityHealthy => 'Lightning sends available';

  @override
  String get withdrawUiLiquidityRebalanceRequired =>
      'Liquidity adjustment recommended';

  @override
  String get withdrawUiLiquidityBlocked => 'Lightning sends paused';

  @override
  String get withdrawUiLiquidityUnknown => 'Operational status unavailable';

  @override
  String get withdrawUiLiquidityHealthyMessage =>
      'The Bitcoin reserve covers the Lightning liquidity available for sending.';

  @override
  String get withdrawUiLiquidityRebalanceMessage =>
      'The reserve is adequate, but Lightning liquidity needs adjustment before larger sends.';

  @override
  String get withdrawUiLiquidityBlockedMessage =>
      'Lightning payments are paused until the reserve returns to the required level.';

  @override
  String get withdrawUiLiquidityUnknownMessage =>
      'We cannot classify liquidity right now. Review the amounts before continuing.';

  @override
  String get withdrawUiDestinationHintOnchain => 'Paste the Bitcoin address';

  @override
  String get withdrawUiDestinationHintLightning =>
      'Paste the Lightning request or LNURL';

  @override
  String get depositLedgerAddressCopied => 'Address copied.';

  @override
  String get depositLedgerMovementsTitle => 'Activity';

  @override
  String depositLedgerPage(int page) {
    return 'Page $page';
  }

  @override
  String get depositLedgerBackTooltip => 'Back';

  @override
  String get depositLedgerRefreshTooltip => 'Refresh';

  @override
  String get depositLedgerStatementTitle => 'Statement';

  @override
  String get depositLedgerAccountSubtitle => 'Account activity';

  @override
  String get depositLedgerBalance => 'Balance';

  @override
  String get depositLedgerHideBalance => 'Hide balance';

  @override
  String get depositLedgerShowBalance => 'Show balance';

  @override
  String get depositLedgerItems => 'Items';

  @override
  String get depositLedgerPending => 'Pending';

  @override
  String get depositLedgerOpenCharges => 'Requests';

  @override
  String get depositLedgerNetwork => 'Network';

  @override
  String get depositLedgerActive => 'Active';

  @override
  String get depositLedgerManual => 'Manual';

  @override
  String get depositLedgerCopyAddress => 'Copy address';

  @override
  String get depositLedgerLoadingCharges => 'Loading requests';

  @override
  String get depositLedgerOpenChargesTitle => 'Open requests';

  @override
  String get depositLedgerVoucherTitle => 'Welcome voucher';

  @override
  String get depositLedgerPaymentLinkTitle => 'Payment link';

  @override
  String depositLedgerExpiresIn(String time) {
    return 'Expires $time';
  }

  @override
  String get depositLedgerNow => 'Now';

  @override
  String get depositLedgerCopyAction => 'copy';

  @override
  String get depositLedgerManageAction => 'manage';

  @override
  String get depositLedgerUpdating => 'Updating statement';

  @override
  String get depositLedgerEmptyTitle => 'No activity';

  @override
  String get depositLedgerEmptyMessage => 'Nothing on this page.';

  @override
  String get depositLedgerCancelReceive => 'Cancel receive';

  @override
  String get depositLedgerCancelReceiveMessage =>
      'This receive will be canceled in Kerosene. If someone has already sent BTC to the address, the Bitcoin network may still confirm the transaction.';

  @override
  String get depositLedgerBackAction => 'Back';

  @override
  String get depositLedgerReceiveCanceled => 'Receive canceled.';

  @override
  String get depositLedgerPreviousTooltip => 'Previous';

  @override
  String get depositLedgerNextTooltip => 'Next';

  @override
  String get depositLedgerAlerts => 'Alerts';

  @override
  String get depositLedgerUpdateAction => 'Refresh';

  @override
  String get depositLedgerErrorTitle => 'We could not update';

  @override
  String depositLedgerPageShort(int page) {
    return 'Page $page';
  }

  @override
  String depositLedgerRowsPerPage(int count) {
    return '$count per page';
  }

  @override
  String get depositLedgerNoCounterparty => 'No counterparty';

  @override
  String get depositLedgerStatusCompleted => 'Completed';

  @override
  String get depositLedgerStatusConfirming => 'Confirming';

  @override
  String get depositLedgerStatusPending => 'Pending';

  @override
  String get depositLedgerStatusFailed => 'Failed';

  @override
  String get depositLedgerStatusVerifying => 'Verifying';

  @override
  String get depositLedgerStatusPaid => 'Paid';

  @override
  String get depositLedgerStatusExpired => 'Expired';

  @override
  String get depositLedgerRelativeSoon => 'shortly';

  @override
  String depositLedgerRelativeInMinutes(int count) {
    return 'in $count min';
  }

  @override
  String depositLedgerRelativeInHours(int count) {
    return 'in $count h';
  }

  @override
  String depositLedgerRelativeInDays(int count) {
    return 'in $count d';
  }

  @override
  String get depositLedgerRelativeNow => 'now';

  @override
  String depositLedgerRelativeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String depositLedgerRelativeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get paymentConfirmationErrorTitle => 'We could not confirm';

  @override
  String get paymentConfirmationReviewSubtitle =>
      'Review the details and confirm with your security factors.';

  @override
  String get paymentConfirmationDateTime => 'Date and time';

  @override
  String get paymentConfirmationNetwork => 'Network';

  @override
  String get paymentConfirmationCopyAction => 'Copy';

  @override
  String paymentConfirmationCopied(String label) {
    return '$label copied.';
  }

  @override
  String get depositFlowDepositTitle => 'Deposit';

  @override
  String get depositFlowAmountSubtitle =>
      'Enter the amount and choose how you want to receive it.';

  @override
  String get depositFlowSelectedCurrency => 'Selected currency';

  @override
  String get depositFlowAmountLabel => 'Deposit amount';

  @override
  String get depositFlowContinue => 'Continue';

  @override
  String depositFlowEquivalentTo(String amount) {
    return 'Equivalent to $amount';
  }

  @override
  String depositFlowYouReceive(String amount) {
    return 'You receive $amount';
  }

  @override
  String get depositFlowMethodTitle => 'Deposit method';

  @override
  String get depositFlowMethodSubtitle =>
      'Choose how you want to receive this Bitcoin amount.';

  @override
  String get depositFlowSelectedAmount => 'Selected amount';

  @override
  String get depositFlowChooseOption => 'Choose an option';

  @override
  String get depositFlowLightningFastSubtitle =>
      'Fast receive with short validity and one-tap copy.';

  @override
  String get depositFlowLightningUnavailable =>
      'Lightning is not available for this wallet right now.';

  @override
  String get depositFlowLightningChecking =>
      'Checking availability for this wallet.';

  @override
  String get depositFlowLightningCheckError =>
      'We could not check Lightning right now. You can still use on-chain.';

  @override
  String get depositFlowLightningInstant => 'Instant';

  @override
  String get depositFlowUnavailable => 'Unavailable';

  @override
  String get depositFlowValidating => 'Checking';

  @override
  String get depositFlowOnchainColdTitle => 'Cold wallet Bitcoin on-chain';

  @override
  String get depositFlowOnchainTitle => 'Bitcoin on-chain';

  @override
  String get depositFlowOnchainColdSubtitle =>
      'Your cold wallet address for tracking the deposit securely.';

  @override
  String get depositFlowOnchainSubtitle =>
      'Unique Bitcoin address tracked until confirmation.';

  @override
  String get depositFlowColdWalletTag => 'Cold wallet';

  @override
  String get depositFlowConfirmationsTag => '3 confirmations';

  @override
  String get depositFlowProviderTitle => 'Purchase provider';

  @override
  String get depositFlowProviderSubtitle =>
      'Select the checkout to buy Bitcoin securely.';

  @override
  String get depositFlowRequestedPurchase => 'Requested purchase';

  @override
  String get depositFlowProviderSecurityHint =>
      'You will continue in a secure environment and the Bitcoin address will already be filled in for this payment.';

  @override
  String get depositFlowProvidersLoadingTitle => 'Loading providers';

  @override
  String get depositFlowProvidersLoadingMessage =>
      'Preparing purchase options with this wallet address.';

  @override
  String get depositFlowProvidersErrorTitle => 'We could not load providers';

  @override
  String get depositFlowUnknownError => 'We could not complete this right now.';

  @override
  String get depositFlowRetry => 'Try again';

  @override
  String get depositFlowNoProvidersTitle => 'No provider available';

  @override
  String get depositFlowNoProvidersMessage =>
      'We could not find purchase options right now.';

  @override
  String get depositFlowSecureAddress => 'Secure address';

  @override
  String get depositFlowCheckoutSubtitle => 'Secure checkout in the app.';

  @override
  String get depositFlowDepositAddressCopied => 'Deposit address copied.';

  @override
  String depositFlowEstimatedPurchase(String amount) {
    return 'Estimated purchase in $amount';
  }

  @override
  String get depositFlowProviderLoadError => 'We could not load the provider';

  @override
  String get depositFlowCheckoutAddressTitle =>
      'BTC address linked to checkout';

  @override
  String get depositFlowAddressUnavailable => 'Address unavailable';

  @override
  String get depositFlowCopy => 'Copy';

  @override
  String get depositLightningLoading => 'Loading';

  @override
  String get depositLightningGoesTo => 'Goes to';

  @override
  String get depositLightningSummary => 'Summary';

  @override
  String get depositInstructionsTitle => 'Deposit instructions';

  @override
  String get depositInstructionsSubtitle =>
      'A short, direct read in the same flow pattern.';

  @override
  String get depositInstructionsUnderstood => 'Understood';

  @override
  String get depositInstructionsNetworkLabel => 'Network';

  @override
  String get depositInstructionsNetworkTitle => 'Deposit BTC only through';

  @override
  String get depositInstructionsMinimumLabel => 'Minimum';

  @override
  String get depositInstructionsMinimumTitle => 'The minimum deposit is';

  @override
  String get depositInstructionsMinimumNote =>
      'Deposits below this amount will be lost.';

  @override
  String get depositInstructionsMaximumLabel => 'Maximum';

  @override
  String get depositInstructionsMaximumTitle => 'The maximum deposit is';

  @override
  String get depositInstructionsMaximumSuffix => ' per transaction.';

  @override
  String get depositInstructionsProcessingLabel => 'Processing';

  @override
  String get depositInstructionsProcessingTitle => 'Estimated time:';

  @override
  String get depositInstructionsProcessingHighlight => '< 1 minute';

  @override
  String get depositInstructionsProcessingSuffix => ' via Lightning.';

  @override
  String get depositQrReceiveTitle => 'Receive BTC';

  @override
  String get depositQrReceiveSubtitle => 'Simple, secure deposit QR.';

  @override
  String get depositQrSetAmount => 'Set amount';

  @override
  String get depositQrScanTitle => 'Scan to receive Bitcoin';

  @override
  String get depositQrBitcoinOnlyWarning =>
      'Send only Bitcoin (BTC) to this address.\nSending other assets will result in permanent loss.';

  @override
  String get depositQrAddressLabel => 'Your BTC address';

  @override
  String get depositQrCopy => 'Copy';

  @override
  String get depositQrCopied => 'Address copied.';

  @override
  String get depositQrShare => 'Share';

  @override
  String get depositQrSave => 'Save QR';

  @override
  String get receiveQrTitle => 'Receive by QR';

  @override
  String get receiveQrSubtitle => 'Compact monochrome QR for display.';

  @override
  String get receiveQrCopied => 'Copied to clipboard';

  @override
  String get withdrawReceiptSubtitle =>
      'Receipt with amount, destination and payment identifier.';

  @override
  String get receiveHubNfcUnavailable =>
      'NFC is not available on this device right now.';

  @override
  String get receiveHubTitle => 'Receive';

  @override
  String get receiveHubSubtitle =>
      'Deposit, request and QR in one simple flow.';

  @override
  String get receiveHubActions => 'Available actions';

  @override
  String get receiveHubIntro =>
      'Choose how you want to receive. Each option keeps the focus on amount, destination and confirmation.';

  @override
  String get receiveHubDeposit => 'Deposit';

  @override
  String get receiveHubDepositSubtitle =>
      'Add balance by purchase, Lightning or on-chain';

  @override
  String get receiveHubOnchain => 'Receive on-chain';

  @override
  String get receiveHubOnchainSubtitle =>
      'Generate a Bitcoin QR with optional amount';

  @override
  String get receiveHubLightning => 'Receive Lightning';

  @override
  String get receiveHubLightningSubtitle =>
      'Create an instant request for the wallet';

  @override
  String get receiveHubPaymentLink => 'Payment link';

  @override
  String get receiveHubPaymentLinkSubtitle =>
      'Tracked request with protected destination';

  @override
  String get receiveHubNfc => 'Receive by NFC';

  @override
  String get receiveHubNfcSubtitle => 'Prepare a tap-to-pay request';

  @override
  String get receiveHubNoWalletTitle => 'No wallet available';

  @override
  String get receiveHubNoWalletMessage =>
      'Create or select a wallet before starting a receive flow.';

  @override
  String get receiveScreenQrEyebrow => 'QR Code';

  @override
  String get receiveScreenPaymentLinkEyebrow => 'Payment link';

  @override
  String get receiveScreenOnchainEyebrow => 'On-chain';

  @override
  String get receiveScreenLightningEyebrow => 'Lightning';

  @override
  String get receiveScreenQrDescription =>
      'Generate an internal QR with protected amount and destination for confirmation.';

  @override
  String get receiveScreenNfcDescription =>
      'Prepare a tap-to-pay request with a protected destination.';

  @override
  String get receiveScreenPaymentLinkDescription =>
      'Create a tracked link that opens directly on confirmation.';

  @override
  String get receiveScreenOnchainDescription =>
      'Generate an on-chain Bitcoin QR with amount and destination set.';

  @override
  String get receiveScreenLightningDescription =>
      'Generate a Lightning request for fast receive.';

  @override
  String get receiveScreenGenerateQr => 'Generate QR';

  @override
  String get receiveScreenPrepareNfc => 'Prepare NFC';

  @override
  String get receiveScreenCreateLink => 'Create link';

  @override
  String get receiveScreenGenerateOnchainQr => 'Generate on-chain QR';

  @override
  String get receiveScreenGenerateLightningInvoice =>
      'Generate Lightning invoice';

  @override
  String get receiveScreenSelectDepositWallet => 'Select a wallet to deposit.';

  @override
  String get receiveScreenQrSubtitle =>
      'Set the amount and generate an internal QR with protected destination.';

  @override
  String get receiveScreenNfcSubtitle =>
      'Set the amount and prepare a tap-to-pay request.';

  @override
  String get receiveScreenPaymentLinkSubtitle =>
      'Set the amount and generate a tracked request.';

  @override
  String get receiveScreenOnchainSubtitle =>
      'Set the amount and generate a compatible Bitcoin QR.';

  @override
  String get receiveScreenLightningSubtitle =>
      'Set the amount and continue to a Lightning request.';

  @override
  String get receiveScreenInboundBlockedTitle => 'Receive unavailable';

  @override
  String get receiveScreenInboundBlockedMessage =>
      'Activate a wallet or add balance to receive through the platform.';

  @override
  String get receiveScreenRefreshStatus => 'Refresh status';

  @override
  String receiveScreenEquivalentTo(String amount) {
    return 'Equivalent to $amount';
  }

  @override
  String receiveScreenDestination(String walletName) {
    return 'Destination $walletName';
  }

  @override
  String get receiveScreenPrivacyHint =>
      'The payer will see only the details needed to confirm the receive.';

  @override
  String get receiveScreenSelectReceiveWallet => 'Select a wallet to receive.';

  @override
  String get receiveScreenInvalidPaymentLink =>
      'We could not create a valid payment link right now.';

  @override
  String receiveScreenPaymentLinkError(String error) {
    return 'We could not generate the payment link: $error';
  }

  @override
  String receiveScreenDefaultDescription(String walletName) {
    return 'Receive $walletName';
  }

  @override
  String get receiveScreenConfigureLinkEyebrow => 'Configure link';

  @override
  String get receiveScreenConfigureLinkTitle => 'Payment link';

  @override
  String get receiveScreenConfigureLinkSubtitle =>
      'Set validity, visibility and identification before generating the link.';

  @override
  String get receiveScreenDescriptionLabel => 'Description';

  @override
  String get receiveScreenReferenceLabel => 'Reference';

  @override
  String get receiveScreen15Minutes => '15 minutes';

  @override
  String get receiveScreen1Hour => '1 hour';

  @override
  String get receiveScreen3Hours => '3 hours';

  @override
  String get receiveScreen24Hours => '24 hours';

  @override
  String get receiveScreenValidityLabel => 'Validity';

  @override
  String get receiveScreenPrivate => 'Private';

  @override
  String get receiveScreenPublic => 'Public';

  @override
  String get receiveScreenVisibilityLabel => 'Visibility';

  @override
  String get receiveScreenUserActionRequired => 'Finish with your confirmation';

  @override
  String get receiveScreenAutoComplete => 'Complete automatically';

  @override
  String get receiveScreenCompletionLabel => 'Completion';

  @override
  String get receiveScreenCustomerLabel => 'Customer';

  @override
  String get receiveScreenNoteLabel => 'Note';

  @override
  String get receiveScreenGenerateLink => 'Generate link';

  @override
  String get receivePaymentLinkCancelled => 'Payment link cancelled.';

  @override
  String get receivePaymentLinkCancelTitle => 'Cancel link';

  @override
  String get receivePaymentLinkCancelMessage =>
      'You can add a reason to show in your history.';

  @override
  String get receivePaymentLinkCancelReason => 'Cancellation reason';

  @override
  String get receivePaymentLinkConfirmCancel => 'Confirm cancellation';

  @override
  String get receivePaymentLinkNotInformed => 'Not informed';

  @override
  String get receivePaymentLinkStatusChecking => 'Payment under review';

  @override
  String get receivePaymentLinkStatusReceived => 'Payment received';

  @override
  String get receivePaymentLinkStatusCancelled => 'Link cancelled';

  @override
  String get receivePaymentLinkStatusExpired => 'Link expired';

  @override
  String get receivePaymentLinkStatusWaiting => 'Waiting for payment';

  @override
  String get receivePaymentLinkCheckingMessage =>
      'The network has detected the payment. We are completing the final review.';

  @override
  String get receivePaymentLinkReceivedMessage =>
      'This link amount has been received and your history was updated.';

  @override
  String receivePaymentLinkCancelledReason(String reason) {
    return 'This link was cancelled: $reason.';
  }

  @override
  String get receivePaymentLinkCancelledMessage =>
      'This link was cancelled and no longer accepts payments.';

  @override
  String get receivePaymentLinkExpiredMessage =>
      'This link no longer accepts payments. Generate a new QR to continue receiving.';

  @override
  String get receivePaymentLinkLockedMessage =>
      'Anyone who opens this QR will see a simple confirmation with protected amount and destination.';

  @override
  String get receivePaymentLinkWaitingMessage =>
      'Use the QR Code or copy the payment link below. Status updates automatically.';

  @override
  String get receivePaymentLinkTitle => 'Receive';

  @override
  String get receivePaymentLinkSubtitle =>
      'QR, link and tracking in one simple screen.';

  @override
  String get receivePaymentLinkExpired => 'Expired';

  @override
  String receivePaymentLinkExpiresIn(String duration) {
    return 'Expires in $duration';
  }

  @override
  String receivePaymentLinkDepositFee(String amount) {
    return 'deposit $amount';
  }

  @override
  String receivePaymentLinkNetAmount(String amount) {
    return 'net $amount';
  }

  @override
  String get receivePaymentLinkExpires => 'Expires';

  @override
  String get receivePaymentLinkTransactionCode => 'Transaction code';

  @override
  String get receivePaymentLinkState => 'State';

  @override
  String get receivePaymentLinkPaymentLinkTitle => 'Payment link';

  @override
  String get receivePaymentLinkLockedHelper =>
      'This link opens payment confirmation with protected amount and destination.';

  @override
  String get receivePaymentLinkShareHelper =>
      'Share this link to receive the defined amount.';

  @override
  String get receivePaymentLinkCopied => 'Payment link copied to clipboard.';

  @override
  String get receivePaymentLinkDepositAddressHelper =>
      'Unique Bitcoin address for this payment.';

  @override
  String get receivePaymentLinkDepositAddressCopied =>
      'Deposit address copied to clipboard.';

  @override
  String get receivePaymentLinkRefresh => 'Refresh';

  @override
  String get receivePaymentLinkConfigurationTitle => 'Receive configuration';

  @override
  String get receivePaymentLinkVisibility => 'Visibility';

  @override
  String get receivePaymentLinkCompletion => 'Completion';

  @override
  String get receivePaymentLinkAmount => 'Amount';

  @override
  String get receivePaymentLinkAmountSet => 'Set';

  @override
  String get receivePaymentLinkAmountFlexible => 'Flexible';

  @override
  String get receivePaymentLinkReference => 'Reference';

  @override
  String get receivePaymentLinkCreatedAt => 'Created at';

  @override
  String get receivePaymentLinkPaidAt => 'Paid at';

  @override
  String get receivePaymentLinkConfirmedAt => 'Confirmed at';

  @override
  String get receivePaymentLinkCancelledAt => 'Cancelled at';

  @override
  String get receivePaymentLinkCopy => 'Copy';

  @override
  String get sendMoneyDestinationLabel => 'Destination';

  @override
  String get sendMoneyDestinationHint => 'Address or username';

  @override
  String get sendMoneyRecentTitle => 'Sent before';

  @override
  String get sendMoneyGoToAmount => 'Go to amount';

  @override
  String get sendMoneyMissingDestination => 'Enter the address or username.';

  @override
  String get sendMoneyExternalUseWithdraw =>
      'On-chain payments must use the withdraw flow.';

  @override
  String get sendMoneyReview => 'Review';

  @override
  String get sendMoneyDetailType => 'Type';

  @override
  String get sendMoneyTypePaymentLink => 'Internal payment link';

  @override
  String get sendMoneyTypeInternalTransfer => 'Internal Kerosene transfer';

  @override
  String get sendMoneyDetailValue => 'Amount';

  @override
  String get sendMoneyDetailValueBtc => 'Amount in BTC';

  @override
  String get sendMoneyDetailTotalBtc => 'Total in BTC';

  @override
  String get sendMoneyDetailBalanceBefore => 'Balance before sending';

  @override
  String get sendMoneyDetailLinkId => 'Link ID';

  @override
  String get sendMoneyDetailDestinationHash => 'Destination hash';

  @override
  String get sendMoneyDestinationHashCopied => 'Destination hash copied.';

  @override
  String get sendMoneyConfirmPayment => 'Confirm payment';

  @override
  String get sendMoneyLockedRequestEyebrow => 'Protected request';

  @override
  String get sendMoneyFinalReviewEyebrow => 'Final review';

  @override
  String get sendMoneySourceLabel => 'From';

  @override
  String get sendMoneyDestinationToLabel => 'To';

  @override
  String get sendMoneyInternalNetwork => 'Internal';

  @override
  String get sendMoneyLockedNotice =>
      'Amount and destination were set by the link. Confirm only if you recognize this request.';

  @override
  String get sendMoneyReviewNotice =>
      'Review the details before confirming. After authorization, the payment will be processed.';

  @override
  String get sendMoneySecurityMessage =>
      'Confirmation uses your current session and the security factors configured on your account before sending the payment.';

  @override
  String get sendMoneyAuthFailed =>
      'Authentication was cancelled or could not be completed.';

  @override
  String get sendMoneyInvalidPaymentRequest => 'Invalid payment request.';

  @override
  String get sendMoneyExternalQrUseWithdraw =>
      'External QR detected. Use the withdraw flow for on-chain payments.';

  @override
  String get sendMoneyRequestDataLoaded => 'Request details loaded.';

  @override
  String get sendMoneyInvalidQrRequest =>
      'This QR or NFC does not look like a valid request.';

  @override
  String get sendMoneyRequestAlreadyPaid =>
      'This request has already been paid.';

  @override
  String get sendMoneyRequestExpired => 'This payment request has expired.';

  @override
  String get sendMoneyLockedDestination => 'Protected destination';

  @override
  String get sendMoneyPaymentRequestLoaded => 'Payment request loaded.';

  @override
  String get walletConfigAddressCopiedMessage =>
      'Wallet address copied successfully.';

  @override
  String get walletConfigAddressCopiedTitle => 'Address copied';

  @override
  String get walletConfigExportNoticeMessage =>
      'Private key export depends on device security verification.';

  @override
  String get walletConfigExportNoticeTitle => 'Verification required';

  @override
  String get walletConfigAddressTitle => 'Wallet address';

  @override
  String get walletConfigAddressSubtitle =>
      'Use this address for on-chain deposits to this wallet.';

  @override
  String get walletConfigCopy => 'Copy';

  @override
  String get walletConfigFeesTitle => 'Wallet fees';

  @override
  String get walletConfigFeesSubtitle =>
      'Updated values for external movements from this wallet.';

  @override
  String get walletConfigControlsTitle => 'Controls';

  @override
  String get walletConfigControlsSubtitle =>
      'Usage and visual privacy settings for this wallet in the app.';

  @override
  String get walletConfigFreezeCardTitle => 'Freeze card';

  @override
  String get walletConfigFreezeCardSubtitle =>
      'Temporarily disables this wallet in the visual flow.';

  @override
  String get walletConfigHideBalanceTitle => 'Hide balance on home';

  @override
  String get walletConfigHideBalanceSubtitle =>
      'Keeps the wallet visible while reducing balance exposure.';

  @override
  String get walletConfigExportKeyTitle => 'Export private key';

  @override
  String get walletConfigExportKeySubtitle =>
      'Requires additional verification before revealing sensitive material.';

  @override
  String get walletConfigCardRuleTitle => 'Card rule';

  @override
  String get walletConfigCardRuleSubtitle =>
      'The profile considers account relationship and eligible volume from the last 30 days.';

  @override
  String get walletConfigTitle => 'Wallet card';

  @override
  String get walletConfigSubtitle => 'Visual setup, address and wallet fees.';

  @override
  String walletConfigHeroSummary(
      int level, String cardType, String withdrawRate, String depositRate) {
    return 'Level $level • $cardType. External withdrawals use $withdrawRate and external deposits use $depositRate.';
  }

  @override
  String get walletConfigNetworkLabel => 'Network';

  @override
  String get walletConfigPathLabel => 'Path';

  @override
  String get walletConfigStatusLabel => 'Status';

  @override
  String get walletConfigStatusFrozen => 'Frozen';

  @override
  String get walletConfigStatusActive => 'Active';

  @override
  String get walletConfigLevelLabel => 'Level';

  @override
  String get walletConfigWithdrawLabel => 'Withdraw';

  @override
  String get walletConfigWithdrawHelper => 'External outgoing';

  @override
  String get walletConfigDepositLabel => 'Deposit';

  @override
  String get walletConfigDepositHelper => 'External incoming';

  @override
  String get walletConfigInternalLabel => 'Internal';

  @override
  String get walletConfigInternalHelper => 'Between Kerosene wallets';

  @override
  String get walletCardUnavailableTitle => 'Card unavailable';

  @override
  String get walletCardNoActiveTitle => 'No active card';

  @override
  String get walletCardNoActiveMessage =>
      'Create a wallet to enable the account card.';

  @override
  String get walletCardAccountCardsTitle => 'Account cards';

  @override
  String walletCardAccountCardsSubtitle(String walletName) {
    return 'Swipe to view cards, fees and requirements for account $walletName.';
  }

  @override
  String get walletCardCurrentLabel => 'Current';

  @override
  String get walletCardUpgradeLabel => 'Upgrade';

  @override
  String get walletCardAutomatic => 'Automatic';

  @override
  String get walletCardValidityLabel => 'Validity';

  @override
  String get walletCardRotationLabel => 'Rotation';

  @override
  String get walletCardPreviousLabel => 'Previous';

  @override
  String get walletCardRotating => 'Rotating';

  @override
  String get walletCardExpiring => 'Expiring';

  @override
  String get walletCardActive => 'Active';

  @override
  String get walletCardNotInformed => 'Not informed';

  @override
  String get walletCardRotationTitle => 'Card rotation';

  @override
  String get walletCardRotationSubtitle =>
      'Card validity is real and the next issue happens automatically when the window expires.';

  @override
  String walletCardCurrentExpires(String cardNumber, String date) {
    return '$cardNumber • expires $date';
  }

  @override
  String get walletCardLastRotationLabel => 'Last rotation';

  @override
  String walletCardPreviousExpired(String cardNumber, String date) {
    return '$cardNumber • expired $date';
  }

  @override
  String get walletCardYourCard => 'Your card';

  @override
  String get walletCardDepositLabel => 'Deposit';

  @override
  String get walletCardWithdrawLabel => 'Withdraw';

  @override
  String get walletCardMiningLabel => 'Mining';

  @override
  String get walletCardHowToGet => 'How to get it';

  @override
  String get walletCardRulesTitle => 'How cards change';

  @override
  String get walletCardRulesSubtitle =>
      'When your account meets the requirements, the card changes automatically.';

  @override
  String get walletCardGraphiteTitle => 'Graphite';

  @override
  String get walletCardSilverTitle => 'Silver';

  @override
  String get walletCardBlackTitle => 'Black';

  @override
  String get walletCardHiddenTitle => 'Hidden';

  @override
  String get walletCardGraphiteTier => 'Entry';

  @override
  String get walletCardSilverTier => 'Intermediate';

  @override
  String get walletCardBlackTier => 'Top tier';

  @override
  String get walletCardGraphiteDescription =>
      'Initial card for new users. It is the default account level.';

  @override
  String get walletCardSilverDescription =>
      'Intermediate upgrade with lower fees for deposits, withdrawals and mining.';

  @override
  String get walletCardBlackDescription =>
      'Lowest platform cost for accounts with more time and higher volume.';

  @override
  String get walletCardGraphiteQualification =>
      'Available automatically for new accounts.';

  @override
  String get walletCardSilverQualification =>
      'Movement above 1500 per month and at least 6 months of account history.';

  @override
  String get walletCardBlackQualification =>
      'Movement above 4000 per month and at least 1 year of account history.';

  @override
  String get walletCardGraphiteEligibility => 'New users.';

  @override
  String get walletCardSilverEligibility =>
      'Movements above 1500 per month and 6 months of account history.';

  @override
  String get walletCardBlackEligibility =>
      'Movements above 4000 per month and 1 year of account history.';

  @override
  String get walletCardHashCopiedTitle => 'Hash copied';

  @override
  String get walletCardHashCopiedMessage => 'Wallet hash copied.';

  @override
  String get appEntryPinUnavailableTitle => 'PIN unavailable';

  @override
  String get appEntryPinUnavailableMessage =>
      'We could not validate entry protection. Refresh the status and try again.';

  @override
  String get appEntryRefresh => 'Refresh';

  @override
  String get appEntryConfirm => 'Confirm';

  @override
  String get appEntryReset => 'Reset';

  @override
  String get appEntryExit => 'Exit';

  @override
  String get appEntryTotpLabel => 'TOTP code';

  @override
  String get appEntryNewPinLabel => 'New numeric PIN';

  @override
  String appEntryPinLengthError(int min, int max) {
    return 'Use $min to $max digits.';
  }

  @override
  String appEntryRetryIn(String duration) {
    return 'Try again in $duration.';
  }

  @override
  String get appEntryUnlockPrompt =>
      'Enter this device PIN to open your wallet.';

  @override
  String get appEntryLockedHelper => 'Entry is temporarily blocked.';

  @override
  String appEntryAttemptsHelper(int count) {
    return 'Attempts remaining before lock: $count.';
  }

  @override
  String get appEntryLocalPinHelper => 'This PIN protects only this device.';

  @override
  String get appEntryEyebrow => 'Entry PIN';

  @override
  String get appEntryResetTitle => 'Reset PIN';

  @override
  String get appEntryResetMessage =>
      'Use the account authenticator code to set a new PIN on this device.';

  @override
  String get appEntrySavePin => 'Save PIN';

  @override
  String get sessionEndedTitle => 'Session ended';

  @override
  String get primaryNavHome => 'Home';

  @override
  String get primaryNavCard => 'Card';

  @override
  String get primaryNavHistory => 'History';

  @override
  String get primaryNavMining => 'Mining';

  @override
  String get primaryNavSettings => 'Settings';

  @override
  String get securityTreasuryBuffer => 'Buffer';

  @override
  String get securityTreasuryConfirmations => 'Confirmations';

  @override
  String get securityTreasuryLightning => 'Lightning';

  @override
  String get securityTreasuryProfit => 'Profit';

  @override
  String get miningContractSelectRigTitle => 'Select equipment';

  @override
  String get miningContractSelectRigMessage =>
      'We could not find equipment available for rent right now.';

  @override
  String get miningContractInvalidDurationTitle => 'Invalid term';

  @override
  String miningContractInvalidDurationMessage(int minHours, int maxHours) {
    return 'Choose a term between ${minHours}h and ${maxHours}h for this equipment.';
  }

  @override
  String get miningContractInvalidBudgetTitle => 'Invalid amount';

  @override
  String get miningContractInvalidBudgetMessage =>
      'Enter a BTC amount greater than zero.';

  @override
  String get miningContractInvalidHashrateTitle => 'Invalid power';

  @override
  String miningContractInvalidHashrateMessage(String unit) {
    return 'Enter the desired power in $unit.';
  }

  @override
  String get miningContractNoAllocationTitle => 'No estimated allocation';

  @override
  String get miningContractNoAllocationMessage =>
      'The selected combination does not generate contractable power.';

  @override
  String get miningContractTotpRequiredTitle => 'Code required';

  @override
  String get miningContractTotpRequiredMessage =>
      'Enter the wallet authenticator code to continue.';

  @override
  String get miningContractRequiredFieldsTitle => 'Required fields';

  @override
  String get miningContractRequiredFieldsMessage =>
      'Fill the receiving address, pool and miner identifier.';

  @override
  String get miningContractAuthIncompleteTitle => 'Authorization incomplete';

  @override
  String get miningContractAuthIncompleteMessage =>
      'The operation was cancelled before final authorization.';

  @override
  String get miningContractCreateFailedTitle =>
      'We could not create the allocation';

  @override
  String get miningContractUnknownError =>
      'We could not complete this right now.';

  @override
  String get miningContractCreatedTitle => 'Allocation created';

  @override
  String miningContractCreatedMessage(
      String rigName, String hashrate, int durationHours) {
    return '$rigName rented with $hashrate for ${durationHours}h.';
  }

  @override
  String get miningContractCancelFailedTitle => 'We could not cancel';

  @override
  String get miningContractCancelledTitle => 'Allocation ended';

  @override
  String get miningContractCancelledMessage =>
      'Proportional amounts were updated in your history.';

  @override
  String get miningContractRigsTitle => 'Available equipment';

  @override
  String get miningContractRigsSubtitle =>
      'Choose equipment and review the estimated price before authorizing.';

  @override
  String get miningContractCreateAction => 'Create allocation';

  @override
  String get miningContractAllocationsTitle => 'Active and recent allocations';

  @override
  String get miningContractAllocationsSubtitle =>
      'Track your contracts and cancel when the policy allows it.';

  @override
  String get miningContractNetworkContextTitle => 'Network and settlement';

  @override
  String get miningContractNetworkHashrate => 'Network power';

  @override
  String get miningContractDailyReward => 'Daily reward';

  @override
  String get miningContractSelectWalletHint =>
      'Select a wallet to debit the rental and fill the receiving address.';

  @override
  String miningContractActiveWallet(String walletName, String balance) {
    return 'Active wallet: $walletName • balance $balance';
  }

  @override
  String miningContractRigAvailable(
      String algorithm, String provider, String hashrate, String unit) {
    return '$algorithm • $provider • $hashrate $unit available';
  }

  @override
  String miningContractPricePerUnit(String unit) {
    return 'Price per $unit/day';
  }

  @override
  String miningContractYieldPerUnit(String unit) {
    return 'Yield per $unit/day';
  }

  @override
  String get miningContractBudgetMode => 'BTC amount';

  @override
  String get miningContractHashrateMode => 'Power';

  @override
  String get miningContractBudgetLabel => 'BTC amount';

  @override
  String get miningContractHashrateLabel => 'Desired power';

  @override
  String get miningContractPayoutAddressLabel => 'Receiving address';

  @override
  String get miningContractPoolUrlLabel => 'Mining pool';

  @override
  String get miningContractWorkerNameLabel => 'Miner identifier';

  @override
  String get miningContractEstimateTitle => 'Allocation preview';

  @override
  String get miningContractAllocatedHashrate => 'Allocated power';

  @override
  String get miningContractEstimatedCost => 'Estimated cost';

  @override
  String get miningContractProjectedYield => 'Projected gross yield';

  @override
  String get miningContractTotpAuthorization => 'Code authorization';

  @override
  String get miningContractCost => 'Cost';

  @override
  String get miningContractNetYield => 'Net yield';

  @override
  String get miningContractCancelAllocation => 'Cancel allocation';

  @override
  String get miningContractRetry => 'Try again';

  @override
  String get miningStateOfflineTitle => 'No connectivity';

  @override
  String get miningStateOfflineMessage =>
      'We could not query the Bitcoin network right now.';

  @override
  String get miningStateEmptyTitle => 'No data available';

  @override
  String get miningStateEmptyMessage =>
      'We could not find enough information to build the mining panel right now.';

  @override
  String get miningStateErrorTitle => 'Panel could not start';

  @override
  String get miningStateRetryLater => 'Try syncing again shortly.';

  @override
  String get miningTxInternalTitle => 'Internal flow';

  @override
  String get miningTxInternalSubtitle =>
      'Internal reconciliation. No public settlement.';

  @override
  String get miningTxReference => 'Reference';

  @override
  String get miningTxConfirmations => 'Confirmations';

  @override
  String get miningTxLightningTitle => 'Lightning flow';

  @override
  String get miningTxLightningSubtitle =>
      'Settlement outside the base layer. Local context only.';

  @override
  String get miningTxChannel => 'Channel';

  @override
  String get miningTxRecord => 'Record';

  @override
  String get miningTxNoPublicSummaryTitle =>
      'Transaction without public summary';

  @override
  String get miningTxNoPublicSummaryMessage =>
      'The network did not return a detailed summary.';

  @override
  String get miningTxLookupUnavailableTitle => 'On-chain query unavailable';

  @override
  String get miningTxLocalStatus => 'Local status';

  @override
  String get miningTxOnchainTitle => 'On-chain context';

  @override
  String get miningTxOnchainSubtitle =>
      'Inclusion, position and effective transaction cost.';

  @override
  String get miningTxConfirmed => 'Confirmed';

  @override
  String get miningTxPending => 'Pending';

  @override
  String get miningTxTxid => 'TXID';

  @override
  String get miningTxFeeRate => 'Fee per vByte';

  @override
  String get miningTxBlock => 'Block';

  @override
  String get miningTxAwaiting => 'waiting';

  @override
  String get miningTxPosition => 'Position';

  @override
  String get miningTxNotAvailable => 'n/a';

  @override
  String get miningTxLoadingTitle => 'Transaction context';

  @override
  String get miningTxLoadingSubtitle => 'Checking public transaction data.';

  @override
  String get miningMetricsCurrentHeight => 'Current height';

  @override
  String miningMetricsRetargetInBlocks(int blocks) {
    return 'retarget in $blocks blocks';
  }

  @override
  String get miningMetricsMrr => 'MRR';

  @override
  String get miningMetricsHashrate => 'Hashrate';

  @override
  String get miningMetricsDifficulty => 'Difficulty';

  @override
  String get miningMetricsPace => 'Pace';

  @override
  String get miningMetricsLastUpdated => 'Last update';

  @override
  String get miningMetricsNow => 'now';

  @override
  String get miningMetricsMempool => 'Mempool';

  @override
  String get miningMetricsPriorityFee => 'Priority fee';

  @override
  String get miningMetricsEstimatedTps => 'Estimated TPS';

  @override
  String get miningMetricsMempoolPressureTitle => 'Mempool pressure';

  @override
  String get miningMetricsMempoolPressureSubtitle =>
      'Fee range, pending volume and inclusion pressure.';

  @override
  String get miningMetricsPending => 'Pending';

  @override
  String get miningMetricsVbytes => 'vBytes';

  @override
  String get miningMetricsVolumeMb => 'MB volume';

  @override
  String get miningMetricsAggregatedFees => 'Aggregated fees';

  @override
  String get miningMetricsNetworkHealthTitle => 'Network health';

  @override
  String get miningMetricsNetworkHealthSubtitle =>
      'Difficulty, retarget and recent throughput.';

  @override
  String get miningMetricsThroughput => 'Throughput';

  @override
  String get miningMetricsOccupancy => 'Occupancy';

  @override
  String get miningMetricsFeesInReward => 'Fees in reward';

  @override
  String get miningMetricsNextAdjustment => 'Next adjustment';

  @override
  String get miningMetricsLocalMonitorTitle => 'Local monitor';

  @override
  String get miningMetricsLocalMonitorActiveSubtitle =>
      'Estimated local telemetry for the active operation.';

  @override
  String get miningMetricsLocalMonitorInactiveSubtitle =>
      'No local miner active.';

  @override
  String get miningMetricsMiningStatus => 'Mining';

  @override
  String get miningMetricsOfflineStatus => 'Offline';

  @override
  String get miningMetricsLocalHashrate => 'Local hashrate';

  @override
  String get miningMetricsAcceptedShares => 'Accepted shares';

  @override
  String get miningMetricsRejectedShares => 'Rejected shares';

  @override
  String get miningMetricsTemperature => 'Temperature';

  @override
  String get miningMetricsHashrateTrendTitle => 'Hashrate trend';

  @override
  String get miningMetricsHashrateTrendSubtitle =>
      'Recent curve of network computing power.';

  @override
  String get miningMetricsTrendEmpty =>
      'Not enough time series data to draw the curve.';

  @override
  String get miningMetricsRecentBlocksTitle => 'Recent blocks';

  @override
  String get miningMetricsRecentBlocksSubtitle =>
      'Cadence, volume and occupancy in a short read.';

  @override
  String get miningMetricsDominantPoolsTitle => 'Dominant pools';

  @override
  String get miningMetricsDominantPoolsSubtitle =>
      'Recent share, average match and empty blocks.';

  @override
  String miningMetricsLeadingPool(String percent) {
    return '$percent% leader';
  }

  @override
  String get miningFeesTitle => 'Fee market';

  @override
  String get miningFeesSubtitle => 'Active bands, spread and inclusion window.';

  @override
  String get miningFeesWideSpread => 'wide spread';

  @override
  String get miningFeesControlledSpread => 'controlled spread';

  @override
  String miningFeesWindow(String fee) {
    return 'window $fee+';
  }

  @override
  String get miningFeesPriority => 'Priority';

  @override
  String get miningFeesExpress => 'Express';

  @override
  String get miningFeesStandard => 'Standard';

  @override
  String get miningFeesEconomy => 'Economy';

  @override
  String get miningFeesMinimum => 'Minimum';

  @override
  String get miningFeesMedian => 'Median';

  @override
  String get miningFeesMaximum => 'Maximum';

  @override
  String get miningBlocksTitle => 'Blocks forming';

  @override
  String get miningBlocksSubtitle =>
      'Projected queue beside recent confirmations.';

  @override
  String miningBlocksQueued(int count) {
    return '$count queued';
  }

  @override
  String get miningBlocksQueue => 'Queue';

  @override
  String get miningBlocksConfirmed => 'Confirmed';

  @override
  String get miningBlocksNew => 'New';

  @override
  String get miningBlocksNoBlocks => 'no blocks';

  @override
  String miningBlocksNext(int number) {
    return 'Next $number';
  }

  @override
  String get miningBlocksRange => 'Range';

  @override
  String get miningBlocksFees => 'Fees';

  @override
  String miningBlocksNewHeight(int height) {
    return 'New #$height';
  }

  @override
  String get miningBlocksBitcoinNetwork => 'Bitcoin network';

  @override
  String miningBlocksTransactions(int count) {
    return '$count transactions';
  }

  @override
  String get miningBlocksHash => 'Hash';

  @override
  String get miningBlocksWeight => 'Weight';

  @override
  String get miningBlocksTimestamp => 'Timestamp';

  @override
  String get miningBlocksSize => 'Size';

  @override
  String get miningBlocksFee => 'Fee';

  @override
  String get miningBlocksUnavailable => 'unavailable';
}
