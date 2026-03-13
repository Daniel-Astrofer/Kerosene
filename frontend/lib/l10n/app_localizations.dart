import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Kerosene'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance (BTC)'**
  String get totalBalance;

  /// No description provided for @totalBalanceGeneric.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalanceGeneric;

  /// No description provided for @myWallets.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get myWallets;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFunds;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactions;

  /// No description provided for @bitcoinTrading.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Trading'**
  String get bitcoinTrading;

  /// No description provided for @marketStats.
  ///
  /// In en, this message translates to:
  /// **'Market Stats'**
  String get marketStats;

  /// No description provided for @high24h.
  ///
  /// In en, this message translates to:
  /// **'24h High'**
  String get high24h;

  /// No description provided for @low24h.
  ///
  /// In en, this message translates to:
  /// **'24h Low'**
  String get low24h;

  /// No description provided for @totalVolume24h.
  ///
  /// In en, this message translates to:
  /// **'Total Volume (24h)'**
  String get totalVolume24h;

  /// No description provided for @fiatVolume.
  ///
  /// In en, this message translates to:
  /// **'Fiat Volume'**
  String get fiatVolume;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// No description provided for @depositAddress.
  ///
  /// In en, this message translates to:
  /// **'Deposit Address'**
  String get depositAddress;

  /// No description provided for @platformDepositAddress.
  ///
  /// In en, this message translates to:
  /// **'Platform Deposit Address'**
  String get platformDepositAddress;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @sourceWallet.
  ///
  /// In en, this message translates to:
  /// **'Source Wallet'**
  String get sourceWallet;

  /// No description provided for @generatePaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Generate Payment Link'**
  String get generatePaymentLink;

  /// No description provided for @paymentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Payment Instructions'**
  String get paymentInstructions;

  /// No description provided for @sendExactAmount.
  ///
  /// In en, this message translates to:
  /// **'Send exactly this amount to the address below:'**
  String get sendExactAmount;

  /// No description provided for @fundsWillBeCredited.
  ///
  /// In en, this message translates to:
  /// **'Funds will be credited after network confirmation'**
  String get fundsWillBeCredited;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied!'**
  String get addressCopied;

  /// No description provided for @destinationAddress.
  ///
  /// In en, this message translates to:
  /// **'Destination Address'**
  String get destinationAddress;

  /// No description provided for @estimatedFee.
  ///
  /// In en, this message translates to:
  /// **'Estimated Fee'**
  String get estimatedFee;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @confirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmSend;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @pasteAddress.
  ///
  /// In en, this message translates to:
  /// **'Paste Address'**
  String get pasteAddress;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @hash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get hash;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFunds;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get pleaseCompleteFields;

  /// No description provided for @depositInitiated.
  ///
  /// In en, this message translates to:
  /// **'Deposit Initiated!'**
  String get depositInitiated;

  /// No description provided for @depositSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your deposit transaction has been broadcasted. It will be credited once confirmed.'**
  String get depositSuccess;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noChartData.
  ///
  /// In en, this message translates to:
  /// **'No chart data'**
  String get noChartData;

  /// No description provided for @walletSettings.
  ///
  /// In en, this message translates to:
  /// **'Wallet Settings'**
  String get walletSettings;

  /// No description provided for @spendingLimit.
  ///
  /// In en, this message translates to:
  /// **'Spending Limit'**
  String get spendingLimit;

  /// No description provided for @exportPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Export Private Key'**
  String get exportPrivateKey;

  /// No description provided for @removeWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove Wallet'**
  String get removeWallet;

  /// No description provided for @currencyQuotation.
  ///
  /// In en, this message translates to:
  /// **'1 BRL = {value} USD'**
  String currencyQuotation(Object value);

  /// No description provided for @approximateValue.
  ///
  /// In en, this message translates to:
  /// **'≈ {value} {currency}'**
  String approximateValue(Object currency, Object value);

  /// No description provided for @paymentLinks.
  ///
  /// In en, this message translates to:
  /// **'Payment Links'**
  String get paymentLinks;

  /// No description provided for @networkFee.
  ///
  /// In en, this message translates to:
  /// **'Network Fee'**
  String get networkFee;

  /// No description provided for @youWillReceive.
  ///
  /// In en, this message translates to:
  /// **'You will receive'**
  String get youWillReceive;

  /// No description provided for @confirmationTime.
  ///
  /// In en, this message translates to:
  /// **'Confirmation time'**
  String get confirmationTime;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @setSpendingLimit.
  ///
  /// In en, this message translates to:
  /// **'Set Spending Limit'**
  String get setSpendingLimit;

  /// No description provided for @amountInBtc.
  ///
  /// In en, this message translates to:
  /// **'Amount in BTC'**
  String get amountInBtc;

  /// No description provided for @getStartedDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first Bitcoin wallet to get started.'**
  String get getStartedDescription;

  /// No description provided for @welcomeSlogan.
  ///
  /// In en, this message translates to:
  /// **'The decentralized financial platform\nbuilt on Bitcoin.'**
  String get welcomeSlogan;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your wallet'**
  String get signInToAccess;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @selectWalletToSend.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet to send.'**
  String get selectWalletToSend;

  /// No description provided for @errorLoadingWallets.
  ///
  /// In en, this message translates to:
  /// **'Error loading wallets'**
  String get errorLoadingWallets;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @nfc.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get nfc;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get sentTo;

  /// No description provided for @receivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get receivedFrom;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get confirming;

  /// No description provided for @typeSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get typeSend;

  /// No description provided for @typeReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get typeReceive;

  /// No description provided for @typeSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get typeSwap;

  /// No description provided for @typeFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get typeFee;

  /// No description provided for @hashCopied.
  ///
  /// In en, this message translates to:
  /// **'Hash copied!'**
  String get hashCopied;

  /// No description provided for @transactionSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction sent successfully!'**
  String get transactionSentSuccess;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @selectRecipient.
  ///
  /// In en, this message translates to:
  /// **'Select Recipient'**
  String get selectRecipient;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search or paste address'**
  String get searchAddress;

  /// No description provided for @noRecentContacts.
  ///
  /// In en, this message translates to:
  /// **'No recent contacts'**
  String get noRecentContacts;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String fromWallet(Object name);

  /// No description provided for @yourBitcoinAddress.
  ///
  /// In en, this message translates to:
  /// **'Your Bitcoin Address'**
  String get yourBitcoinAddress;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy Address'**
  String get copyAddress;

  /// No description provided for @howMuchToReceive.
  ///
  /// In en, this message translates to:
  /// **'How much do you want to receive?'**
  String get howMuchToReceive;

  /// No description provided for @receiveMethod.
  ///
  /// In en, this message translates to:
  /// **'Receive Method'**
  String get receiveMethod;

  /// No description provided for @generateQrCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate a code to be scanned'**
  String get generateQrCodeDescription;

  /// No description provided for @nfcBeam.
  ///
  /// In en, this message translates to:
  /// **'NFC Beam'**
  String get nfcBeam;

  /// No description provided for @nfcTagDescription.
  ///
  /// In en, this message translates to:
  /// **'Write the request to an NFC tag'**
  String get nfcTagDescription;

  /// No description provided for @scanToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan to Pay'**
  String get scanToPay;

  /// No description provided for @approachPhoneToNfc.
  ///
  /// In en, this message translates to:
  /// **'Bring phone close to NFC tag'**
  String get approachPhoneToNfc;

  /// No description provided for @nfcTagNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Tag does not support NDEF'**
  String get nfcTagNotSupported;

  /// No description provided for @nfcTagNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Tag not writable'**
  String get nfcTagNotWritable;

  /// No description provided for @nfcTagCapacityError.
  ///
  /// In en, this message translates to:
  /// **'Request larger than tag capacity'**
  String get nfcTagCapacityError;

  /// No description provided for @nfcTagWrittenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tag written successfully!'**
  String get nfcTagWrittenSuccess;

  /// No description provided for @writeNfcTag.
  ///
  /// In en, this message translates to:
  /// **'Write NFC Tag'**
  String get writeNfcTag;

  /// No description provided for @errorWriting.
  ///
  /// In en, this message translates to:
  /// **'Error writing: {error}'**
  String errorWriting(Object error);

  /// No description provided for @typeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get typeWithdrawal;

  /// No description provided for @typeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get typeDeposit;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @torOnionActive.
  ///
  /// In en, this message translates to:
  /// **'Onion Protocol Active (Kerosene Core)'**
  String get torOnionActive;

  /// No description provided for @signupFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Activation Fee'**
  String get signupFeeTitle;

  /// No description provided for @signupFeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A one-time fee of 0.003 BTC is required to activate your account and prevent spam.'**
  String get signupFeeSubtitle;

  /// No description provided for @signupFeeWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a fee?'**
  String get signupFeeWhyTitle;

  /// No description provided for @signupFeeWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Kerosene has no registration form or email. The fee is a Proof-of-Work that protects the network from bots and fake accounts.'**
  String get signupFeeWhyBody;

  /// No description provided for @signupFeeNotRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get signupFeeNotRefundable;

  /// No description provided for @signupFeeNotRefundableBody.
  ///
  /// In en, this message translates to:
  /// **'Once broadcasted, the fee cannot be recovered. Ensure you are ready before proceeding.'**
  String get signupFeeNotRefundableBody;

  /// No description provided for @signupFeeContinue.
  ///
  /// In en, this message translates to:
  /// **'Understood, Continue'**
  String get signupFeeContinue;

  /// No description provided for @seedSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Security'**
  String get seedSecurityTitle;

  /// No description provided for @seedSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to protect your wallet recovery phrase. Kerosene offers advanced security options for high-net-worth setups.'**
  String get seedSecuritySubtitle;

  /// No description provided for @seedStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get seedStandardTitle;

  /// No description provided for @seedStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'A single 12, 18, or 24-word recovery phrase. Best for general use and simplicity.'**
  String get seedStandardDesc;

  /// No description provided for @seedSlip39Title.
  ///
  /// In en, this message translates to:
  /// **'Shamir SLIP-39 (Multi-part)'**
  String get seedSlip39Title;

  /// No description provided for @seedSlip39Desc.
  ///
  /// In en, this message translates to:
  /// **'Split your seed into multiple pieces. Requires a minimum threshold of pieces to recover (e.g., 3-of-5). Best for distributed physical storage.'**
  String get seedSlip39Desc;

  /// No description provided for @seedMultisigTitle.
  ///
  /// In en, this message translates to:
  /// **'2FA Multisig Vault'**
  String get seedMultisigTitle;

  /// No description provided for @seedMultisigDesc.
  ///
  /// In en, this message translates to:
  /// **'A 2-of-3 Multisig wallet. Kerosene acts as a co-signer and requires TOTP authorization for withdrawals. Protects against local device theft.'**
  String get seedMultisigDesc;

  /// No description provided for @seedSlip39ConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'SLIP-39 Configuration'**
  String get seedSlip39ConfigTitle;

  /// No description provided for @seedSlip39TotalShares.
  ///
  /// In en, this message translates to:
  /// **'Total Shares (Pieces)'**
  String get seedSlip39TotalShares;

  /// No description provided for @seedSlip39Threshold.
  ///
  /// In en, this message translates to:
  /// **'Required Threshold'**
  String get seedSlip39Threshold;

  /// No description provided for @seedSlip39Summary.
  ///
  /// In en, this message translates to:
  /// **'Requires {threshold} out of {total} shares to restore the wallet.'**
  String seedSlip39Summary(Object threshold, Object total);

  /// No description provided for @passphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Secret Phrase'**
  String get passphraseTitle;

  /// No description provided for @passphraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write down these 18 words on a physical piece of paper. Never save this digitally.'**
  String get passphraseSubtitle;

  /// No description provided for @passphraseWrittenDown.
  ///
  /// In en, this message translates to:
  /// **'I Have Written It Down'**
  String get passphraseWrittenDown;

  /// No description provided for @passphraseWarning.
  ///
  /// In en, this message translates to:
  /// **'If you lose these words, you will permanently lose access to your account and funds.'**
  String get passphraseWarning;

  /// No description provided for @passphraseVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Phrase'**
  String get passphraseVerifyTitle;

  /// No description provided for @passphraseVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type your secret phrase to confirm you have backed it up correctly.'**
  String get passphraseVerifySubtitle;

  /// No description provided for @passphraseVerifyHint.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3...'**
  String get passphraseVerifyHint;

  /// No description provided for @passphraseVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passphrase. Please try again.'**
  String get passphraseVerifyError;

  /// No description provided for @passphraseVerifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get passphraseVerifyContinue;

  /// No description provided for @passphraseGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back to view phrase again'**
  String get passphraseGoBack;

  /// No description provided for @passphraseEnterWords.
  ///
  /// In en, this message translates to:
  /// **'Enter your 18 words'**
  String get passphraseEnterWords;

  /// No description provided for @slip39SharesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your SLIP-39 Shares'**
  String get slip39SharesTitle;

  /// No description provided for @slip39SharesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your seed is split into {total} pieces. You need {threshold} of them to recover your wallet. Write each share on a separate piece of paper and store them in different locations.'**
  String slip39SharesSubtitle(Object threshold, Object total);

  /// No description provided for @slip39ShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share {index} of {total}'**
  String slip39ShareLabel(Object index, Object total);

  /// No description provided for @slip39ShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Share {index} copied'**
  String slip39ShareCopied(Object index);

  /// No description provided for @slip39VerifyShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Share {index}'**
  String slip39VerifyShareTitle(Object index);

  /// No description provided for @slip39VerifyShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type the words for Share {index} exactly as you wrote them down.'**
  String slip39VerifyShareSubtitle(Object index);

  /// No description provided for @slip39ConfirmShare.
  ///
  /// In en, this message translates to:
  /// **'Confirm Share {index}'**
  String slip39ConfirmShare(Object index);

  /// No description provided for @slip39AllConfirmedContinue.
  ///
  /// In en, this message translates to:
  /// **'All Shares Confirmed — Continue'**
  String get slip39AllConfirmedContinue;

  /// No description provided for @slip39ConfirmAllPending.
  ///
  /// In en, this message translates to:
  /// **'Confirm all {total} shares to continue'**
  String slip39ConfirmAllPending(Object total);

  /// No description provided for @slip39Warning.
  ///
  /// In en, this message translates to:
  /// **'Do NOT store all shares in the same place. If an attacker finds {threshold} pieces they can recover your wallet.'**
  String slip39Warning(Object threshold);

  /// No description provided for @twoFaPrimaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Primary Seed'**
  String get twoFaPrimaryTitle;

  /// No description provided for @twoFaPrimaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Key 1 of 3 — Stays on your device only'**
  String get twoFaPrimaryBadge;

  /// No description provided for @twoFaPrimarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This 18-word phrase is your primary private key. It alone is NOT enough to sign transactions — a secondary TOTP authorization is always required from Kerosene. Write these words on paper and store them securely.'**
  String get twoFaPrimarySubtitle;

  /// No description provided for @twoFaPrimaryWritten.
  ///
  /// In en, this message translates to:
  /// **'I Have Written It Down'**
  String get twoFaPrimaryWritten;

  /// No description provided for @twoFaBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recovery Seed'**
  String get twoFaBackupTitle;

  /// No description provided for @twoFaBackupBadge.
  ///
  /// In en, this message translates to:
  /// **'Key 3 of 3 — Emergency / Sovereignty Bypass'**
  String get twoFaBackupBadge;

  /// No description provided for @twoFaBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is your sovereignty guarantee. If Kerosene ever shuts down, use this 12-word backup seed together with your primary seed to recover your funds without any server involvement. Store this SEPARATELY from your primary seed.'**
  String get twoFaBackupSubtitle;

  /// No description provided for @twoFaCoSignerNote.
  ///
  /// In en, this message translates to:
  /// **'Key 2 of 3 is held encrypted by Kerosene and is only used to co-sign trasactions when you provide a valid TOTP code.'**
  String get twoFaCoSignerNote;

  /// No description provided for @twoFaBothStored.
  ///
  /// In en, this message translates to:
  /// **'I Have Stored Both Seeds'**
  String get twoFaBothStored;

  /// No description provided for @twoFaBackToPrimary.
  ///
  /// In en, this message translates to:
  /// **'Back to Primary Seed'**
  String get twoFaBackToPrimary;

  /// No description provided for @twoFaVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Primary Seed'**
  String get twoFaVerifyTitle;

  /// No description provided for @twoFaVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your Primary Key (18 words) to prove you have it safely stored.'**
  String get twoFaVerifySubtitle;

  /// No description provided for @twoFaVerifyHint.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3...'**
  String get twoFaVerifyHint;

  /// No description provided for @twoFaVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect. Please re-check your Primary Seed.'**
  String get twoFaVerifyError;

  /// No description provided for @twoFaVerifyActivate.
  ///
  /// In en, this message translates to:
  /// **'Verify & Activate 2FA Vault'**
  String get twoFaVerifyActivate;

  /// No description provided for @twoFaBackToBackup.
  ///
  /// In en, this message translates to:
  /// **'Back to Recovery Seed'**
  String get twoFaBackToBackup;

  /// No description provided for @totpSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Authenticator'**
  String get totpSetupTitle;

  /// No description provided for @totpSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code with your authenticator app, then enter the 6-digit code to verify.'**
  String get totpSetupSubtitle;

  /// No description provided for @totpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get totpCodeLabel;

  /// No description provided for @totpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get totpVerifyButton;

  /// No description provided for @totpErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get totpErrorInvalid;

  /// No description provided for @passkeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign Key'**
  String get passkeyTitle;

  /// No description provided for @passkeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account with a biometric hardware key. No password required.'**
  String get passkeySubtitle;

  /// No description provided for @passkeyRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Activate Sovereign Key'**
  String get passkeyRegisterButton;

  /// No description provided for @passkeySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Sovereign Key activated!'**
  String get passkeySuccessMessage;

  /// No description provided for @passkeySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get passkeySkip;

  /// No description provided for @usernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Handle'**
  String get usernameTitle;

  /// No description provided for @usernameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a unique username. This is your public identity on Kerosene.'**
  String get usernameSubtitle;

  /// No description provided for @usernameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameFieldLabel;

  /// No description provided for @usernameFieldHint.
  ///
  /// In en, this message translates to:
  /// **'@your_handle'**
  String get usernameFieldHint;

  /// No description provided for @usernameCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get usernameCheckButton;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username available!'**
  String get usernameAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already in use.'**
  String get usernameTaken;

  /// No description provided for @usernameContinue.
  ///
  /// In en, this message translates to:
  /// **'Reserve Handle & Continue'**
  String get usernameContinue;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Activation Payment'**
  String get paymentTitle;

  /// No description provided for @paymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send exactly the amount shown below to activate your account.'**
  String get paymentSubtitle;

  /// No description provided for @paymentTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get paymentTimeLeft;

  /// No description provided for @paymentExpired.
  ///
  /// In en, this message translates to:
  /// **'Payment window expired'**
  String get paymentExpired;

  /// No description provided for @paymentExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You did not complete the payment within the 15-minute window. Your temporary data will be cleared and you must start over.'**
  String get paymentExpiredMessage;

  /// No description provided for @paymentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment...'**
  String get paymentWaiting;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paymentAmountLabel;

  /// No description provided for @paymentAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit Address'**
  String get paymentAddressLabel;

  /// No description provided for @paymentCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy Address'**
  String get paymentCopyAddress;

  /// No description provided for @paymentAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied!'**
  String get paymentAddressCopied;

  /// No description provided for @confirmationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Confirmations'**
  String get confirmationsTitle;

  /// No description provided for @confirmationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment was detected. Waiting for 3 bitcoin network confirmations to finalize your account.'**
  String get confirmationsSubtitle;

  /// No description provided for @confirmationsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} confirmations'**
  String confirmationsProgress(Object current, Object total);

  /// No description provided for @confirmationsDone.
  ///
  /// In en, this message translates to:
  /// **'Account Activated!'**
  String get confirmationsDone;

  /// No description provided for @presentationSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Secure Infrastructure from the First Access'**
  String get presentationSlide1Title;

  /// No description provided for @presentationSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Kerosene operates with advanced technological architecture in a protected environment via the onion network. This structure reinforces privacy, resilience, and protection against external interference.\n\nSecurity is not an add-on.\nIt is the foundation of the system.'**
  String get presentationSlide1Body;

  /// No description provided for @presentationSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Account Creation with Structural Protection Mechanism'**
  String get presentationSlide2Title;

  /// No description provided for @presentationSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'To preserve infrastructure integrity, account creation requires sending 0.003 BTC.\nThis amount remains entirely in your account.\nDuring registration, only the network transaction fee necessary for operation confirmation is deducted.\nThis technical requirement exists to:\n\n• Prevent automated account creation\n• Reduce distributed attack vectors\n• Maintain operational stability\n• Protect all platform users\n\nIt is not a monthly fee.\nIt is not a recurring charge.\nIt is a structural protection mechanism.'**
  String get presentationSlide2Body;

  /// No description provided for @presentationSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Clear and Objective Fee Structure'**
  String get presentationSlide3Title;

  /// No description provided for @presentationSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Our policy is simple:\n\n• 0.9% on deposits\n• 0.9% on withdrawals\n• 0% for internal transfers\n\nTransfers between Kerosene users are instant and free.\n\nNo hidden fees.\nNo unexpected variations.'**
  String get presentationSlide3Body;

  /// No description provided for @presentationSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'Commitment to Predictability'**
  String get presentationSlide4Title;

  /// No description provided for @presentationSlide4Body.
  ///
  /// In en, this message translates to:
  /// **'Kerosene was designed to operate with:\n\n• Technical stability\n• Operational transparency\n• Structural security\n• Cost predictability\n\nOur priority is to maintain a solid, protected, and long-term sustainable infrastructure.'**
  String get presentationSlide4Body;

  /// No description provided for @presentationSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get presentationSkip;

  /// No description provided for @presentationNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get presentationNext;

  /// No description provided for @presentationStart.
  ///
  /// In en, this message translates to:
  /// **'Access Kerosene'**
  String get presentationStart;

  /// No description provided for @signupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get signupScreenTitle;

  /// No description provided for @signupScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Setup your username and secure key.'**
  String get signupScreenSubtitle;

  /// No description provided for @signupUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'Only a-z, 0-9 and _'**
  String get signupUsernameHelper;

  /// No description provided for @signupUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'lower case letters, numbers and _'**
  String get signupUsernameHint;

  /// No description provided for @signupUsernameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Min 3 chars'**
  String get signupUsernameMinChars;

  /// No description provided for @signupUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid characters'**
  String get signupUsernameInvalid;

  /// No description provided for @signupMnemonicLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR SECRET PHRASE (BIP39)'**
  String get signupMnemonicLabel;

  /// No description provided for @signupMnemonicWarning.
  ///
  /// In en, this message translates to:
  /// **'Save this phrase securely. It is the ONLY way to recover your account.'**
  String get signupMnemonicWarning;

  /// No description provided for @signupMnemonicCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Phrase copied securely!'**
  String get signupMnemonicCopySuccess;

  /// No description provided for @signupMnemonicCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get signupMnemonicCopy;

  /// No description provided for @signupMnemonicGenerateNew.
  ///
  /// In en, this message translates to:
  /// **'Generate New'**
  String get signupMnemonicGenerateNew;

  /// No description provided for @signupMnemonicError.
  ///
  /// In en, this message translates to:
  /// **'Error generating phrase, try again'**
  String get signupMnemonicError;

  /// No description provided for @feeExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Network Fee'**
  String get feeExplanationTitle;

  /// No description provided for @feeExplanationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To prevent spam and ensure the robustness of the Kerosene network, account creation requires a small anti-spam fee of 0.003 BTC.'**
  String get feeExplanationSubtitle;

  /// No description provided for @feeExplanationWhereGoesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where does it go?'**
  String get feeExplanationWhereGoesTitle;

  /// No description provided for @feeExplanationWhereGoesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The full 0.003 BTC goes directly into your wallet balance once the account is created.'**
  String get feeExplanationWhereGoesSubtitle;

  /// No description provided for @feeExplanationContinue.
  ///
  /// In en, this message translates to:
  /// **'I Understand, Continue'**
  String get feeExplanationContinue;

  /// No description provided for @seedSecurityContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get seedSecurityContinue;

  /// No description provided for @totpTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get totpTitle;

  /// No description provided for @totpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code with your authenticator app (e.g. Google Authenticator, Authy).'**
  String get totpSubtitle;

  /// No description provided for @totpSecretCopied.
  ///
  /// In en, this message translates to:
  /// **'Secret copied to clipboard'**
  String get totpSecretCopied;

  /// No description provided for @totpEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get totpEnterCodeHint;

  /// No description provided for @totpEnter6Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter 6 digits'**
  String get totpEnter6Digits;

  /// No description provided for @totpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Try again.'**
  String get totpInvalidCode;

  /// No description provided for @totpVerifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get totpVerifyContinue;

  /// No description provided for @totpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying code...'**
  String get totpVerifying;

  /// No description provided for @totpAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get totpAuthenticating;

  /// No description provided for @totpEstablishingSession.
  ///
  /// In en, this message translates to:
  /// **'Establishing Session...'**
  String get totpEstablishingSession;

  /// No description provided for @passkeySessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found. Please restart the process.'**
  String get passkeySessionNotFound;

  /// No description provided for @passkeyNoBiometrics.
  ///
  /// In en, this message translates to:
  /// **'No biometric hardware available on this device.'**
  String get passkeyNoBiometrics;

  /// No description provided for @passkeyErrorStarting.
  ///
  /// In en, this message translates to:
  /// **'Error starting registration: {message}'**
  String passkeyErrorStarting(String message);

  /// No description provided for @passkeyBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Sovereign Key to secure your Kerosene wallet'**
  String get passkeyBiometricReason;

  /// No description provided for @passkeyErrorFinishing.
  ///
  /// In en, this message translates to:
  /// **'Error finishing registration: {message}'**
  String passkeyErrorFinishing(String message);

  /// No description provided for @passkeyAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled or failed.'**
  String get passkeyAuthFailed;

  /// No description provided for @passkeyUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String passkeyUnexpectedError(String error);

  /// No description provided for @passkeyLoadingInitBiom.
  ///
  /// In en, this message translates to:
  /// **'Initializing Biometrics...'**
  String get passkeyLoadingInitBiom;

  /// No description provided for @passkeyLoadingSecuring.
  ///
  /// In en, this message translates to:
  /// **'Securing Device...'**
  String get passkeyLoadingSecuring;

  /// No description provided for @passkeyLoadingRegistering.
  ///
  /// In en, this message translates to:
  /// **'Activating Sovereign Key...'**
  String get passkeyLoadingRegistering;

  /// No description provided for @usernameHintChars.
  ///
  /// In en, this message translates to:
  /// **'a-z, 0-9 and _'**
  String get usernameHintChars;

  /// No description provided for @usernameHelperLength.
  ///
  /// In en, this message translates to:
  /// **'Must be between 3 and 15 characters'**
  String get usernameHelperLength;

  /// No description provided for @usernameErrorMin.
  ///
  /// In en, this message translates to:
  /// **'Min 3 chars'**
  String get usernameErrorMin;

  /// No description provided for @usernameErrorMax.
  ///
  /// In en, this message translates to:
  /// **'Max 15 chars'**
  String get usernameErrorMax;

  /// No description provided for @usernameErrorInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Invalid characters'**
  String get usernameErrorInvalidChars;

  /// No description provided for @usernameLoadingPow.
  ///
  /// In en, this message translates to:
  /// **'Calculating Proof of Work...'**
  String get usernameLoadingPow;

  /// No description provided for @usernameLoadingKeys.
  ///
  /// In en, this message translates to:
  /// **'Securing Keys...'**
  String get usernameLoadingKeys;

  /// No description provided for @usernameLoadingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generating Invoice...'**
  String get usernameLoadingInvoice;

  /// No description provided for @usernameLoadingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Network...'**
  String get usernameLoadingNetwork;

  /// No description provided for @paymentExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get paymentExpiredLabel;

  /// No description provided for @confNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get confNetworkError;

  /// No description provided for @confNetworkVerified.
  ///
  /// In en, this message translates to:
  /// **'Network Verified!'**
  String get confNetworkVerified;

  /// No description provided for @confConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming on Blockchain'**
  String get confConfirming;

  /// No description provided for @confErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while finalizing your account creation on the server. Please safely restart the configuration process.'**
  String get confErrorMsg;

  /// No description provided for @confVerifiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account has been officially created and your fee added to your balance. Entering gateway...'**
  String get confVerifiedMsg;

  /// No description provided for @confWaitingMsg.
  ///
  /// In en, this message translates to:
  /// **'Waiting for 3 Bitcoin network confirmations. This can take roughly 30 minutes, but you can safely leave the app; we will notify you when it is ready.'**
  String get confWaitingMsg;

  /// No description provided for @confRestartSignup.
  ///
  /// In en, this message translates to:
  /// **'Restart Signup'**
  String get confRestartSignup;

  /// No description provided for @confNotificationNotice.
  ///
  /// In en, this message translates to:
  /// **'You will receive a push notification once the 3rd confirmation lands.'**
  String get confNotificationNotice;

  /// No description provided for @homePlatformLiquidity.
  ///
  /// In en, this message translates to:
  /// **'PLATFORM LIQUIDITY'**
  String get homePlatformLiquidity;

  /// No description provided for @homeDeposits.
  ///
  /// In en, this message translates to:
  /// **'DEPOSITS'**
  String get homeDeposits;

  /// No description provided for @homeWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWALS'**
  String get homeWithdrawals;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authRequired;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @pendingDeposits.
  ///
  /// In en, this message translates to:
  /// **'Pending Deposits'**
  String get pendingDeposits;

  /// No description provided for @saqueAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get saqueAction;

  /// No description provided for @detailsTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get detailsTransaction;

  /// No description provided for @detailsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get detailsClose;

  /// No description provided for @noWalletsFound.
  ///
  /// In en, this message translates to:
  /// **'No wallets found'**
  String get noWalletsFound;

  /// No description provided for @createWalletPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet to start monitoring transactions'**
  String get createWalletPrompt;

  /// No description provided for @createWalletAction.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWalletAction;

  /// No description provided for @withdrawExternalBtc.
  ///
  /// In en, this message translates to:
  /// **'External BTC Withdrawal'**
  String get withdrawExternalBtc;

  /// No description provided for @withdrawExternalBtcDesc.
  ///
  /// In en, this message translates to:
  /// **'Move funds from your Kerosene wallet to an external Bitcoin address.'**
  String get withdrawExternalBtcDesc;

  /// No description provided for @withdrawAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Address (toAddress)'**
  String get withdrawAddressLabel;

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount in BTC'**
  String get withdrawAmountLabel;

  /// No description provided for @withdrawDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get withdrawDescLabel;

  /// No description provided for @withdrawDescHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Transfer to Hardware Wallet'**
  String get withdrawDescHint;

  /// No description provided for @withdrawCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get withdrawCancel;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW NOW'**
  String get withdrawAction;

  /// No description provided for @errorAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get errorAddressRequired;

  /// No description provided for @errorAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get errorAmountRequired;

  /// No description provided for @errorAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get errorAmountInvalid;

  /// No description provided for @txSent.
  ///
  /// In en, this message translates to:
  /// **'Transfer Sent'**
  String get txSent;

  /// No description provided for @txReceived.
  ///
  /// In en, this message translates to:
  /// **'Transfer Received'**
  String get txReceived;

  /// No description provided for @loginTotpTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Verification'**
  String get loginTotpTitle;

  /// No description provided for @loginTotpDesc.
  ///
  /// In en, this message translates to:
  /// **'This device is new. Please enter the 6-digit code from your authenticator app to authorize it.'**
  String get loginTotpDesc;

  /// No description provided for @loginTotpAction.
  ///
  /// In en, this message translates to:
  /// **'VERIFY & LOGIN'**
  String get loginTotpAction;

  /// No description provided for @createWalletNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get createWalletNameRequired;

  /// No description provided for @createWalletNameChars.
  ///
  /// In en, this message translates to:
  /// **'Only letters and numbers are allowed'**
  String get createWalletNameChars;

  /// No description provided for @sendDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional, e.g. Pizza payment)'**
  String get sendDescriptionLabel;

  /// No description provided for @sendInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Missing {amount} BTC to complete this send.'**
  String sendInsufficientBalance(String amount);

  /// No description provided for @sendSelectWallet.
  ///
  /// In en, this message translates to:
  /// **'Select Wallet'**
  String get sendSelectWallet;

  /// No description provided for @sendReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Transaction'**
  String get sendReviewTitle;

  /// No description provided for @sendTrackedReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Tracked Payment'**
  String get sendTrackedReviewTitle;

  /// No description provided for @sendRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get sendRecipientLabel;

  /// No description provided for @sendNetworkFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Network Fee'**
  String get sendNetworkFeeLabel;

  /// No description provided for @sendTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sendTotalLabel;

  /// No description provided for @sendConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get sendConfirmAction;

  /// No description provided for @sendPayNowAction.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get sendPayNowAction;

  /// No description provided for @sendEnterAddressError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid recipient username or address'**
  String get sendEnterAddressError;

  /// No description provided for @sendEnterAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get sendEnterAmountError;

  /// No description provided for @sendPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get sendPaymentSuccess;

  /// No description provided for @receiveReceivingWallet.
  ///
  /// In en, this message translates to:
  /// **'Receiving Wallet'**
  String get receiveReceivingWallet;

  /// No description provided for @receiveExpirationLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Link Expiration'**
  String get receiveExpirationLabel;

  /// No description provided for @receiveNoExpiration.
  ///
  /// In en, this message translates to:
  /// **'No Expiration'**
  String get receiveNoExpiration;

  /// No description provided for @receive15Min.
  ///
  /// In en, this message translates to:
  /// **'15 Minutes'**
  String get receive15Min;

  /// No description provided for @receive1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get receive1Hour;

  /// No description provided for @receive24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 Hours'**
  String get receive24Hours;

  /// No description provided for @receiveGenAction.
  ///
  /// In en, this message translates to:
  /// **'Generate Payment Link'**
  String get receiveGenAction;

  /// No description provided for @receiveQrMethod.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get receiveQrMethod;

  /// No description provided for @receiveNfcMethod.
  ///
  /// In en, this message translates to:
  /// **'NFC Beam'**
  String get receiveNfcMethod;

  /// No description provided for @receiveScanToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan to Pay'**
  String get receiveScanToPay;

  /// No description provided for @receiveReadyToBeam.
  ///
  /// In en, this message translates to:
  /// **'Ready to Beam'**
  String get receiveReadyToBeam;

  /// No description provided for @receiveWriteNfc.
  ///
  /// In en, this message translates to:
  /// **'Write to NFC Tag'**
  String get receiveWriteNfc;

  /// No description provided for @unknownDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorize New Device'**
  String get unknownDeviceTitle;

  /// No description provided for @unknownDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'This device has not been linked to your account.\nEnter the 6-digit code from your authenticator app to authorize it.'**
  String get unknownDeviceDesc;

  /// No description provided for @unknownDeviceBanner.
  ///
  /// In en, this message translates to:
  /// **'New device detected'**
  String get unknownDeviceBanner;

  /// No description provided for @unknownDeviceInputHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get unknownDeviceInputHint;

  /// No description provided for @unknownDeviceInputErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get unknownDeviceInputErrorEmpty;

  /// No description provided for @unknownDeviceInputErrorLength.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get unknownDeviceInputErrorLength;

  /// No description provided for @unknownDeviceHelper.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and enter the current code.'**
  String get unknownDeviceHelper;

  /// No description provided for @unknownDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZE & SIGN IN'**
  String get unknownDeviceAction;

  /// No description provided for @unknownDeviceSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'If you did not attempt to log in, your credentials may be compromised. Change your passphrase immediately.'**
  String get unknownDeviceSecurityNote;

  /// No description provided for @createWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'New Wallet'**
  String get createWalletTitle;

  /// No description provided for @createWalletSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet created successfully!'**
  String get createWalletSuccess;

  /// No description provided for @createWalletErrorGenFirst.
  ///
  /// In en, this message translates to:
  /// **'Please generate a passphrase first.'**
  String get createWalletErrorGenFirst;

  /// No description provided for @createWalletIdentity.
  ///
  /// In en, this message translates to:
  /// **'WALLET IDENTITY'**
  String get createWalletIdentity;

  /// No description provided for @createWalletNameHint.
  ///
  /// In en, this message translates to:
  /// **'Savings, Daily, etc.'**
  String get createWalletNameHint;

  /// No description provided for @createWalletSecurity.
  ///
  /// In en, this message translates to:
  /// **'PASSPHRASE SECURITY'**
  String get createWalletSecurity;

  /// No description provided for @createWalletWords.
  ///
  /// In en, this message translates to:
  /// **'{count} Words'**
  String createWalletWords(int count);

  /// No description provided for @createWalletActionGen.
  ///
  /// In en, this message translates to:
  /// **'Generate Security Key'**
  String get createWalletActionGen;

  /// No description provided for @createWalletActionCreate.
  ///
  /// In en, this message translates to:
  /// **'CREATE WALLET'**
  String get createWalletActionCreate;

  /// No description provided for @createWalletCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get createWalletCopyAction;

  /// No description provided for @createWalletCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get createWalletCopySuccess;

  /// No description provided for @createWalletNewAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get createWalletNewAction;

  /// No description provided for @createWalletWarning.
  ///
  /// In en, this message translates to:
  /// **'Keep these words safe. Without them, your funds will be lost.'**
  String get createWalletWarning;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errUnexpected;

  /// No description provided for @errAuthUserAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This username is already in use.'**
  String get errAuthUserAlreadyExists;

  /// No description provided for @errAuthUsernameMissing.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get errAuthUsernameMissing;

  /// No description provided for @errAuthPassphraseMissing.
  ///
  /// In en, this message translates to:
  /// **'Passphrase is required.'**
  String get errAuthPassphraseMissing;

  /// No description provided for @errAuthInvalidUsernameFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid username format.'**
  String get errAuthInvalidUsernameFormat;

  /// No description provided for @errAuthCharLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Character limit exceeded.'**
  String get errAuthCharLimitExceeded;

  /// No description provided for @errAuthUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found. Please check your spelling.'**
  String get errAuthUserNotFound;

  /// No description provided for @errAuthInvalidPassphraseFormat.
  ///
  /// In en, this message translates to:
  /// **'Passphrase does not meet requirements.'**
  String get errAuthInvalidPassphraseFormat;

  /// No description provided for @errAuthIncorrectTotp.
  ///
  /// In en, this message translates to:
  /// **'The TOTP code is incorrect or has expired.'**
  String get errAuthIncorrectTotp;

  /// No description provided for @errAuthInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or passphrase.'**
  String get errAuthInvalidCredentials;

  /// No description provided for @errAuthUnrecognizedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized device. Please authorize it.'**
  String get errAuthUnrecognizedDevice;

  /// No description provided for @errAuthTotpTimeout.
  ///
  /// In en, this message translates to:
  /// **'The time to enter the code has expired.'**
  String get errAuthTotpTimeout;

  /// No description provided for @errLedgerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Financial account not found. Please ensure your registration is complete.'**
  String get errLedgerNotFound;

  /// No description provided for @errLedgerAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Account already has financial records.'**
  String get errLedgerAlreadyExists;

  /// No description provided for @errLedgerInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough balance to perform this transaction.'**
  String get errLedgerInsufficientBalance;

  /// No description provided for @errLedgerInvalidOperation.
  ///
  /// In en, this message translates to:
  /// **'Invalid operation attempt.'**
  String get errLedgerInvalidOperation;

  /// No description provided for @errLedgerReceiverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction recipient not found.'**
  String get errLedgerReceiverNotFound;

  /// No description provided for @errLedgerGeneric.
  ///
  /// In en, this message translates to:
  /// **'Internal error in financial account.'**
  String get errLedgerGeneric;

  /// No description provided for @errLedgerPaymentRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payment link not found.'**
  String get errLedgerPaymentRequestNotFound;

  /// No description provided for @errLedgerPaymentRequestExpired.
  ///
  /// In en, this message translates to:
  /// **'This payment link has expired.'**
  String get errLedgerPaymentRequestExpired;

  /// No description provided for @errLedgerPaymentRequestAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'This payment link has already been paid.'**
  String get errLedgerPaymentRequestAlreadyPaid;

  /// No description provided for @errLedgerPaymentRequestSelfPay.
  ///
  /// In en, this message translates to:
  /// **'You cannot pay a link created by yourself.'**
  String get errLedgerPaymentRequestSelfPay;

  /// No description provided for @errWalletAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A wallet with this name already exists.'**
  String get errWalletAlreadyExists;

  /// No description provided for @errWalletNotFound.
  ///
  /// In en, this message translates to:
  /// **'The specified wallet was not found.'**
  String get errWalletNotFound;

  /// No description provided for @errWalletGeneric.
  ///
  /// In en, this message translates to:
  /// **'Wallet validation error.'**
  String get errWalletGeneric;

  /// No description provided for @errNotifMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Notification token missing.'**
  String get errNotifMissingToken;

  /// No description provided for @errNotifMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Required notification fields missing.'**
  String get errNotifMissingFields;

  /// No description provided for @errInternalServer.
  ///
  /// In en, this message translates to:
  /// **'Our servers are temporarily unavailable.'**
  String get errInternalServer;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errSessionExpired;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied or unrecognized device.'**
  String get errForbidden;

  /// No description provided for @errTooManySignupAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many signup attempts. Please try again later.'**
  String get errTooManySignupAttempts;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection or server is down.'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Check your internet and try again.'**
  String get errTimeout;

  /// No description provided for @errCommFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to communicate with Kerosene server.'**
  String get errCommFailure;

  /// No description provided for @errInvalidBtcAddress.
  ///
  /// In en, this message translates to:
  /// **'The provided Bitcoin address is invalid.'**
  String get errInvalidBtcAddress;

  /// No description provided for @withdrawInvalidFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid address and amount.'**
  String get withdrawInvalidFields;

  /// No description provided for @withdrawAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to confirm withdrawal.'**
  String get withdrawAuthReason;

  /// No description provided for @withdrawAuthCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled.'**
  String get withdrawAuthCancelled;

  /// No description provided for @withdrawSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal successfully sent to the Bitcoin network!'**
  String get withdrawSuccess;

  /// No description provided for @withdrawFeeSection.
  ///
  /// In en, this message translates to:
  /// **'NETWORK DIFFICULTY (FEE)'**
  String get withdrawFeeSection;

  /// No description provided for @withdrawFeeFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get withdrawFeeFast;

  /// No description provided for @withdrawFeeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get withdrawFeeMedium;

  /// No description provided for @withdrawFeeSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get withdrawFeeSlow;

  /// No description provided for @withdrawErrorFee.
  ///
  /// In en, this message translates to:
  /// **'Error estimating network fees.'**
  String get withdrawErrorFee;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
