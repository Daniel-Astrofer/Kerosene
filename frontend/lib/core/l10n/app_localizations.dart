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
    Locale('pt')
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

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'ADD CARD'**
  String get addCard;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get manual;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @nfc.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get nfc;

  /// No description provided for @howMuchToReceive.
  ///
  /// In en, this message translates to:
  /// **'How much do you want to receive?'**
  String get howMuchToReceive;

  /// No description provided for @fixedAmountByRequest.
  ///
  /// In en, this message translates to:
  /// **'FIXED AMOUNT BY REQUEST'**
  String get fixedAmountByRequest;

  /// No description provided for @recipientData.
  ///
  /// In en, this message translates to:
  /// **'RECIPIENT DATA'**
  String get recipientData;

  /// No description provided for @recipientHint.
  ///
  /// In en, this message translates to:
  /// **'Username or BTC address'**
  String get recipientHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionHint;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @reviewSend.
  ///
  /// In en, this message translates to:
  /// **'REVIEW SEND'**
  String get reviewSend;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get description;

  /// No description provided for @networkFee.
  ///
  /// In en, this message translates to:
  /// **'Network Fee'**
  String get networkFee;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirm;

  /// No description provided for @securityTotp.
  ///
  /// In en, this message translates to:
  /// **'SECURITY (TOTP)'**
  String get securityTotp;

  /// No description provided for @destinationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Destination BTC Address'**
  String get destinationAddressHint;

  /// No description provided for @totpHint.
  ///
  /// In en, this message translates to:
  /// **'6 digits from your authenticator'**
  String get totpHint;

  /// No description provided for @confirmWithdraw.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM WITHDRAW'**
  String get confirmWithdraw;

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
  /// **'DESTINATION ADDRESS'**
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

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloUser(String name);

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

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueButton;

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
  /// **'Your deposit transaction was sent. It will be credited once confirmed.'**
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
  /// **'The world\'s first privacy-focused international Bitcoin bank.'**
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

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get share;

  /// No description provided for @waitingConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection...'**
  String get waitingConnection;

  /// No description provided for @offlineRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down or tap try again.'**
  String get offlineRetryHint;

  /// No description provided for @nfcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'NFC UNAVAILABLE'**
  String get nfcUnavailable;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get processing;

  /// No description provided for @nfcInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'NFC UNAVAILABLE ON THIS DEVICE'**
  String get nfcInDevelopment;

  /// No description provided for @amountToReceive.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT TO RECEIVE'**
  String get amountToReceive;

  /// No description provided for @approachToSend.
  ///
  /// In en, this message translates to:
  /// **'APPROACH TO SEND'**
  String get approachToSend;

  /// No description provided for @approachToRead.
  ///
  /// In en, this message translates to:
  /// **'APPROACH TO READ'**
  String get approachToRead;

  /// No description provided for @nfcInstructions.
  ///
  /// In en, this message translates to:
  /// **'Keep your device close to the reader or another smartphone to process.'**
  String get nfcInstructions;

  /// No description provided for @cancelOperation.
  ///
  /// In en, this message translates to:
  /// **'CANCEL OPERATION'**
  String get cancelOperation;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get confirming;

  /// No description provided for @sendBitcoin.
  ///
  /// In en, this message translates to:
  /// **'SEND BITCOIN'**
  String get sendBitcoin;

  /// No description provided for @receiveBitcoin.
  ///
  /// In en, this message translates to:
  /// **'RECEIVE BITCOIN'**
  String get receiveBitcoin;

  /// No description provided for @onChain.
  ///
  /// In en, this message translates to:
  /// **'ON-CHAIN'**
  String get onChain;

  /// No description provided for @lightning.
  ///
  /// In en, this message translates to:
  /// **'LIGHTNING'**
  String get lightning;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION AMOUNT'**
  String get transactionAmount;

  /// No description provided for @approximateNfc.
  ///
  /// In en, this message translates to:
  /// **'APPROXIMATE NFC'**
  String get approximateNfc;

  /// No description provided for @createLink.
  ///
  /// In en, this message translates to:
  /// **'CREATE LINK'**
  String get createLink;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure Access'**
  String get secureAccess;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpNow;

  /// No description provided for @amountToSend.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT TO SEND'**
  String get amountToSend;

  /// No description provided for @processingDuration.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING: ~15 MINS'**
  String get processingDuration;

  /// No description provided for @withdrawConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM AND SEND'**
  String get withdrawConfirmButton;

  /// No description provided for @secureWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'SECURE WITHDRAWAL'**
  String get secureWithdrawal;

  /// No description provided for @totalToReceive.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TO RECEIVE'**
  String get totalToReceive;

  /// No description provided for @sovereignKeyVerification.
  ///
  /// In en, this message translates to:
  /// **'PASSKEY VERIFICATION'**
  String get sovereignKeyVerification;

  /// No description provided for @readyToScan.
  ///
  /// In en, this message translates to:
  /// **'READY TO SCAN'**
  String get readyToScan;

  /// No description provided for @sovereigntyStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'SECURITY STATUS'**
  String get sovereigntyStatusTitle;

  /// No description provided for @liveAttestationReport.
  ///
  /// In en, this message translates to:
  /// **'SECURITY REPORT'**
  String get liveAttestationReport;

  /// No description provided for @systemSovereign.
  ///
  /// In en, this message translates to:
  /// **'SECURITY SYSTEM'**
  String get systemSovereign;

  /// No description provided for @integrityAlert.
  ///
  /// In en, this message translates to:
  /// **'INTEGRITY ALERT'**
  String get integrityAlert;

  /// No description provided for @hardwareAttestation.
  ///
  /// In en, this message translates to:
  /// **'DEVICE CHECK'**
  String get hardwareAttestation;

  /// No description provided for @networkConsensus.
  ///
  /// In en, this message translates to:
  /// **'NETWORK CONFIRMATIONS'**
  String get networkConsensus;

  /// No description provided for @ledgerIntegrity.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL INTEGRITY'**
  String get ledgerIntegrity;

  /// No description provided for @memoryProtection.
  ///
  /// In en, this message translates to:
  /// **'LOCAL PROTECTION'**
  String get memoryProtection;

  /// No description provided for @serverUptime.
  ///
  /// In en, this message translates to:
  /// **'Service availability'**
  String get serverUptime;

  /// No description provided for @realtimeReportInfo.
  ///
  /// In en, this message translates to:
  /// **'Real-time report generated'**
  String get realtimeReportInfo;

  /// No description provided for @analyzingSovereignty.
  ///
  /// In en, this message translates to:
  /// **'CHECKING SECURITY…'**
  String get analyzingSovereignty;

  /// No description provided for @chooseUniqueHandle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Unique Handle'**
  String get chooseUniqueHandle;

  /// No description provided for @chooseUniqueHandleDesc.
  ///
  /// In en, this message translates to:
  /// **'This will be your unique handle on the Kerosene network. Use it to receive transfers from other users.'**
  String get chooseUniqueHandleDesc;

  /// No description provided for @handleLabel.
  ///
  /// In en, this message translates to:
  /// **'HANDLE (VISIBLE IN APP)'**
  String get handleLabel;

  /// No description provided for @handleHint.
  ///
  /// In en, this message translates to:
  /// **'ex: satoshi_99'**
  String get handleHint;

  /// No description provided for @errUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get errUsernameRequired;

  /// No description provided for @errUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Minimum of 3 characters'**
  String get errUsernameTooShort;

  /// No description provided for @errUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers and underscores (_)'**
  String get errUsernameInvalid;

  /// No description provided for @generatePaymentRequest.
  ///
  /// In en, this message translates to:
  /// **'GENERATE PAYMENT REQUEST'**
  String get generatePaymentRequest;

  /// No description provided for @notificationChannels.
  ///
  /// In en, this message translates to:
  /// **'CHANNELS'**
  String get notificationChannels;

  /// No description provided for @notificationAlerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS'**
  String get notificationAlerts;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts on your device'**
  String get pushNotificationsDesc;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via email'**
  String get emailNotificationsDesc;

  /// No description provided for @transactionUpdates.
  ///
  /// In en, this message translates to:
  /// **'Transaction Updates'**
  String get transactionUpdates;

  /// No description provided for @transactionUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Incoming and outgoing transactions'**
  String get transactionUpdatesDesc;

  /// No description provided for @securityAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get securityAlertsTitle;

  /// No description provided for @securityAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Login attempts and password changes'**
  String get securityAlertsDesc;

  /// No description provided for @marketingNews.
  ///
  /// In en, this message translates to:
  /// **'Marketing & News'**
  String get marketingNews;

  /// No description provided for @marketingNewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with latest features'**
  String get marketingNewsDesc;

  /// No description provided for @sovereigntyStatus.
  ///
  /// In en, this message translates to:
  /// **'Security Status'**
  String get sovereigntyStatus;

  /// No description provided for @sovereigntyStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Account protection and service health'**
  String get sovereigntyStatusDesc;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @biometricAuthDesc.
  ///
  /// In en, this message translates to:
  /// **'Use FaceID or Fingerprint to unlock'**
  String get biometricAuthDesc;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @changePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your 6-digit access code'**
  String get changePinDesc;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordDesc;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorAuthDesc.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorAuthDesc;

  /// No description provided for @enableTwoFactorInfo.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA to protect your assets from unauthorized access.'**
  String get enableTwoFactorInfo;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

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

  /// No description provided for @nfcTagInvalid.
  ///
  /// In en, this message translates to:
  /// **'This tag does not contain a readable payment request.'**
  String get nfcTagInvalid;

  /// No description provided for @nfcPaymentNotFound.
  ///
  /// In en, this message translates to:
  /// **'No compatible payment request was found on this tag.'**
  String get nfcPaymentNotFound;

  /// No description provided for @nfcCouldNotProcess.
  ///
  /// In en, this message translates to:
  /// **'We could not process this NFC tag. Try again.'**
  String get nfcCouldNotProcess;

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
  /// **'Once sent, the fee cannot be recovered. Ensure you are ready before proceeding.'**
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
  /// **'Key 3 of 3 — Emergency / Recovery'**
  String get twoFaBackupBadge;

  /// No description provided for @twoFaBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this 12-word backup separate from your primary phrase. Together, they help you recover access in an emergency.'**
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
  /// **'Device key'**
  String get passkeyTitle;

  /// No description provided for @passkeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account with a biometric hardware key. No password required.'**
  String get passkeySubtitle;

  /// No description provided for @passkeyRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Activate device key'**
  String get passkeyRegisterButton;

  /// No description provided for @passkeySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Device key activated!'**
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
  /// **'Our policy is simple:\n\n• External deposits and withdrawals use the wallet card fee\n• Bronze: 0.9%\n• White: 0.8%\n• Black: 0.7%\n• 0% for internal transfers\n\nTransfers between Kerosene users are instant and free.\n\nNo hidden fees.'**
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
  /// **'Set up biometrics or a screen lock on this device to use the device key.'**
  String get passkeyNoBiometrics;

  /// No description provided for @passkeyErrorStarting.
  ///
  /// In en, this message translates to:
  /// **'Error starting registration: {message}'**
  String passkeyErrorStarting(String message);

  /// No description provided for @passkeyBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock the device key to secure your Kerosene wallet'**
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
  /// **'Activating device key...'**
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
  /// **'We could not finish creating your account. Please restart the setup safely.'**
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

  /// No description provided for @bitcoinAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Accounts'**
  String get bitcoinAccountsTitle;

  /// No description provided for @bitcoinAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your Kerosene card and cold wallets in one simple view. Private keys stay off the app unless you are creating a new cold wallet.'**
  String get bitcoinAccountsSubtitle;

  /// No description provided for @bitcoinAccountsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin accounts unavailable'**
  String get bitcoinAccountsErrorTitle;

  /// No description provided for @bitcoinAccountsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your accounts right now. Try again in a moment.'**
  String get bitcoinAccountsErrorMessage;

  /// No description provided for @bitcoinAccountsCreateColdWallet.
  ///
  /// In en, this message translates to:
  /// **'Create cold wallet'**
  String get bitcoinAccountsCreateColdWallet;

  /// No description provided for @bitcoinAccountsNewKeroseneCard.
  ///
  /// In en, this message translates to:
  /// **'New Kerosene card'**
  String get bitcoinAccountsNewKeroseneCard;

  /// No description provided for @bitcoinAccountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Bitcoin account yet'**
  String get bitcoinAccountsEmptyTitle;

  /// No description provided for @bitcoinAccountsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a cold wallet for long-term storage or add a Kerosene card for daily receiving.'**
  String get bitcoinAccountsEmptyMessage;

  /// No description provided for @bitcoinAccountsKeroseneCardSection.
  ///
  /// In en, this message translates to:
  /// **'Kerosene card'**
  String get bitcoinAccountsKeroseneCardSection;

  /// No description provided for @bitcoinAccountsColdWalletSection.
  ///
  /// In en, this message translates to:
  /// **'Cold wallets'**
  String get bitcoinAccountsColdWalletSection;

  /// No description provided for @bitcoinAccountsNoKeroseneCard.
  ///
  /// In en, this message translates to:
  /// **'No Kerosene card is active yet.'**
  String get bitcoinAccountsNoKeroseneCard;

  /// No description provided for @bitcoinAccountsNoColdWallet.
  ///
  /// In en, this message translates to:
  /// **'No cold wallet is being watched yet.'**
  String get bitcoinAccountsNoColdWallet;

  /// No description provided for @bitcoinAccountsKeroseneCardBadge.
  ///
  /// In en, this message translates to:
  /// **'Kerosene card'**
  String get bitcoinAccountsKeroseneCardBadge;

  /// No description provided for @bitcoinAccountsColdWalletBadge.
  ///
  /// In en, this message translates to:
  /// **'Watch-only'**
  String get bitcoinAccountsColdWalletBadge;

  /// No description provided for @bitcoinAccountsUnnamedAccount.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin account'**
  String get bitcoinAccountsUnnamedAccount;

  /// No description provided for @bitcoinAccountsAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get bitcoinAccountsAvailableBalance;

  /// No description provided for @bitcoinAccountsObservedBalance.
  ///
  /// In en, this message translates to:
  /// **'Observed balance'**
  String get bitcoinAccountsObservedBalance;

  /// No description provided for @bitcoinAccountsKeroseneCardNote.
  ///
  /// In en, this message translates to:
  /// **'Use this card to receive Bitcoin inside Kerosene and move funds quickly.'**
  String get bitcoinAccountsKeroseneCardNote;

  /// No description provided for @bitcoinAccountsColdWalletNote.
  ///
  /// In en, this message translates to:
  /// **'Kerosene only watches this wallet. Spending still requires your recovery words or your offline device.'**
  String get bitcoinAccountsColdWalletNote;

  /// No description provided for @bitcoinAccountsPendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get bitcoinAccountsPendingBalance;

  /// No description provided for @bitcoinAccountsReservedBalance.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get bitcoinAccountsReservedBalance;

  /// No description provided for @bitcoinAccountsReviewBalance.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get bitcoinAccountsReviewBalance;

  /// No description provided for @bitcoinAccountsReceiveBtc.
  ///
  /// In en, this message translates to:
  /// **'Receive BTC'**
  String get bitcoinAccountsReceiveBtc;

  /// No description provided for @bitcoinAccountsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bitcoinAccountsStatusActive;

  /// No description provided for @bitcoinAccountsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Setting up'**
  String get bitcoinAccountsStatusPending;

  /// No description provided for @bitcoinAccountsStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get bitcoinAccountsStatusDisabled;

  /// No description provided for @bitcoinAccountsStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get bitcoinAccountsStatusReady;

  /// No description provided for @bitcoinAccountsCreateCardTitle.
  ///
  /// In en, this message translates to:
  /// **'New Kerosene card'**
  String get bitcoinAccountsCreateCardTitle;

  /// No description provided for @bitcoinAccountsCardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get bitcoinAccountsCardNameLabel;

  /// No description provided for @bitcoinAccountsCardNameHint.
  ///
  /// In en, this message translates to:
  /// **'Daily, Savings, Travel'**
  String get bitcoinAccountsCardNameHint;

  /// No description provided for @bitcoinAccountsCreateCardNotice.
  ///
  /// In en, this message translates to:
  /// **'This card is for funds you want available inside Kerosene.'**
  String get bitcoinAccountsCreateCardNotice;

  /// No description provided for @bitcoinAccountsCreateCardAction.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get bitcoinAccountsCreateCardAction;

  /// No description provided for @bitcoinAccountsCreateCardErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Card not created'**
  String get bitcoinAccountsCreateCardErrorTitle;

  /// No description provided for @bitcoinAccountsCreateCardErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not create this card right now. Check the name and try again.'**
  String get bitcoinAccountsCreateCardErrorMessage;

  /// No description provided for @coldWalletCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create cold wallet'**
  String get coldWalletCreateTitle;

  /// No description provided for @coldWalletCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate the recovery words on this device, write them down, and Kerosene will keep only the information needed to show balances.'**
  String get coldWalletCreateSubtitle;

  /// No description provided for @coldWalletNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get coldWalletNameLabel;

  /// No description provided for @coldWalletNameHint.
  ///
  /// In en, this message translates to:
  /// **'Vault, Family reserve, Long-term'**
  String get coldWalletNameHint;

  /// No description provided for @coldWalletSecurityLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Security level'**
  String get coldWalletSecurityLevelTitle;

  /// No description provided for @coldWalletLevelEssentialTitle.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get coldWalletLevelEssentialTitle;

  /// No description provided for @coldWalletLevelEssentialBody.
  ///
  /// In en, this message translates to:
  /// **'12 recovery words. Easier to write, suitable for smaller balances.'**
  String get coldWalletLevelEssentialBody;

  /// No description provided for @coldWalletLevelRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get coldWalletLevelRecommendedTitle;

  /// No description provided for @coldWalletLevelRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'24 recovery words. Best default for long-term Bitcoin storage.'**
  String get coldWalletLevelRecommendedBody;

  /// No description provided for @coldWalletLevelMaximumTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get coldWalletLevelMaximumTitle;

  /// No description provided for @coldWalletLevelMaximumBody.
  ///
  /// In en, this message translates to:
  /// **'24 words plus one extra word. Losing either one means losing access.'**
  String get coldWalletLevelMaximumBody;

  /// No description provided for @coldWalletExtraWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra word'**
  String get coldWalletExtraWordLabel;

  /// No description provided for @coldWalletExtraWordHint.
  ///
  /// In en, this message translates to:
  /// **'Do not reuse a password'**
  String get coldWalletExtraWordHint;

  /// No description provided for @coldWalletExtraWordWarning.
  ///
  /// In en, this message translates to:
  /// **'The extra word is not recoverable by Kerosene. Store it separately from the recovery words.'**
  String get coldWalletExtraWordWarning;

  /// No description provided for @coldWalletChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Before generating'**
  String get coldWalletChecklistTitle;

  /// No description provided for @coldWalletChecklistPaper.
  ///
  /// In en, this message translates to:
  /// **'I have paper or metal backup ready.'**
  String get coldWalletChecklistPaper;

  /// No description provided for @coldWalletChecklistPrivate.
  ///
  /// In en, this message translates to:
  /// **'I am in a private place with no cameras around.'**
  String get coldWalletChecklistPrivate;

  /// No description provided for @coldWalletChecklistOffline.
  ///
  /// In en, this message translates to:
  /// **'I turned off Wi-Fi and mobile data manually.'**
  String get coldWalletChecklistOffline;

  /// No description provided for @coldWalletChecklistNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'I will not take screenshots or photos.'**
  String get coldWalletChecklistNoPhotos;

  /// No description provided for @coldWalletGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate words'**
  String get coldWalletGenerateAction;

  /// No description provided for @coldWalletBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Write these words down'**
  String get coldWalletBackupTitle;

  /// No description provided for @coldWalletBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These words control the wallet. Kerosene cannot restore them later and will not save them.'**
  String get coldWalletBackupSubtitle;

  /// No description provided for @coldWalletWordsHidden.
  ///
  /// In en, this message translates to:
  /// **'Words are hidden until you choose to reveal them.'**
  String get coldWalletWordsHidden;

  /// No description provided for @coldWalletShowWords.
  ///
  /// In en, this message translates to:
  /// **'Show words'**
  String get coldWalletShowWords;

  /// No description provided for @coldWalletHideWords.
  ///
  /// In en, this message translates to:
  /// **'Hide words'**
  String get coldWalletHideWords;

  /// No description provided for @coldWalletBackupDoneAction.
  ///
  /// In en, this message translates to:
  /// **'I wrote them down'**
  String get coldWalletBackupDoneAction;

  /// No description provided for @coldWalletVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the requested words to confirm your backup before importing the public watch-only key.'**
  String get coldWalletVerifySubtitle;

  /// No description provided for @coldWalletVerifyWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word {index}'**
  String coldWalletVerifyWordLabel(int index);

  /// No description provided for @coldWalletVerifyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup not confirmed'**
  String get coldWalletVerifyFailedTitle;

  /// No description provided for @coldWalletVerifyFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the words and try again.'**
  String get coldWalletVerifyFailedMessage;

  /// No description provided for @coldWalletImportAction.
  ///
  /// In en, this message translates to:
  /// **'Finish and watch wallet'**
  String get coldWalletImportAction;

  /// No description provided for @coldWalletImportingAction.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get coldWalletImportingAction;

  /// No description provided for @coldWalletImportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet added'**
  String get coldWalletImportedTitle;

  /// No description provided for @coldWalletImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the public watch-only key was imported.'**
  String get coldWalletImportedMessage;

  /// No description provided for @coldWalletImportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet not added'**
  String get coldWalletImportErrorTitle;

  /// No description provided for @coldWalletImportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to the internet and try again. Your recovery words were not sent.'**
  String get coldWalletImportErrorMessage;

  /// No description provided for @bitcoinAdvancedTitle.
  String get bitcoinAdvancedTitle;

  /// No description provided for @bitcoinAdvancedNewPsbtAction.
  String get bitcoinAdvancedNewPsbtAction;

  /// No description provided for @bitcoinAdvancedRefreshAction.
  String get bitcoinAdvancedRefreshAction;

  /// No description provided for @bitcoinAdvancedUtxosTitle.
  String get bitcoinAdvancedUtxosTitle;

  /// No description provided for @bitcoinAdvancedUtxosUnavailableTitle.
  String get bitcoinAdvancedUtxosUnavailableTitle;

  /// No description provided for @bitcoinAdvancedUtxosUnavailableMessage.
  String get bitcoinAdvancedUtxosUnavailableMessage;

  /// No description provided for @bitcoinAdvancedPsbtsTitle.
  String get bitcoinAdvancedPsbtsTitle;

  /// No description provided for @bitcoinAdvancedPsbtsUnavailableTitle.
  String get bitcoinAdvancedPsbtsUnavailableTitle;

  /// No description provided for @bitcoinAdvancedPsbtsUnavailableMessage.
  String get bitcoinAdvancedPsbtsUnavailableMessage;

  /// No description provided for @bitcoinAdvancedPsbtCopiedTitle.
  String get bitcoinAdvancedPsbtCopiedTitle;

  /// No description provided for @bitcoinAdvancedSignExternallyMessage.
  String get bitcoinAdvancedSignExternallyMessage;

  /// No description provided for @bitcoinAdvancedNoUtxos.
  String get bitcoinAdvancedNoUtxos;

  /// No description provided for @bitcoinAdvancedSpendableForPsbt.
  String get bitcoinAdvancedSpendableForPsbt;

  /// No description provided for @bitcoinAdvancedHiddenUtxos.
  String bitcoinAdvancedHiddenUtxos(int count);

  /// No description provided for @bitcoinAdvancedNoPsbts.
  String get bitcoinAdvancedNoPsbts;

  /// No description provided for @bitcoinAdvancedHiddenPsbts.
  String bitcoinAdvancedHiddenPsbts(int count);

  /// No description provided for @bitcoinAdvancedFeePrefix.
  String get bitcoinAdvancedFeePrefix;

  /// No description provided for @bitcoinAdvancedCopyUnsignedAction.
  String get bitcoinAdvancedCopyUnsignedAction;

  /// No description provided for @bitcoinAdvancedSubmitSignatureAction.
  String get bitcoinAdvancedSubmitSignatureAction;

  /// No description provided for @bitcoinAdvancedUtxoStatusUnspent.
  String get bitcoinAdvancedUtxoStatusUnspent;

  /// No description provided for @bitcoinAdvancedUtxoStatusLocked.
  String get bitcoinAdvancedUtxoStatusLocked;

  /// No description provided for @bitcoinAdvancedUtxoStatusSpent.
  String get bitcoinAdvancedUtxoStatusSpent;

  /// No description provided for @bitcoinAdvancedPsbtStatusDraft.
  String get bitcoinAdvancedPsbtStatusDraft;

  /// No description provided for @bitcoinAdvancedPsbtStatusUnsignedCreated.
  String get bitcoinAdvancedPsbtStatusUnsignedCreated;

  /// No description provided for @bitcoinAdvancedPsbtStatusWaitingSignature.
  String get bitcoinAdvancedPsbtStatusWaitingSignature;

  /// No description provided for @bitcoinAdvancedPsbtStatusValidated.
  String get bitcoinAdvancedPsbtStatusValidated;

  /// No description provided for @bitcoinAdvancedPsbtStatusBroadcasted.
  String get bitcoinAdvancedPsbtStatusBroadcasted;

  /// No description provided for @bitcoinAdvancedPsbtStatusRejectedTampered.
  String get bitcoinAdvancedPsbtStatusRejectedTampered;

  /// No description provided for @bitcoinAdvancedPsbtStatusRejectedPolicy.
  String get bitcoinAdvancedPsbtStatusRejectedPolicy;

  /// No description provided for @bitcoinAdvancedPsbtStatusFailedSafe.
  String get bitcoinAdvancedPsbtStatusFailedSafe;

  /// No description provided for @bitcoinAdvancedCreatePsbtTitle.
  String get bitcoinAdvancedCreatePsbtTitle;

  /// No description provided for @bitcoinAdvancedPsbtCreatedTitle.
  String get bitcoinAdvancedPsbtCreatedTitle;

  /// No description provided for @bitcoinAdvancedCreatePsbtIntro.
  String get bitcoinAdvancedCreatePsbtIntro;

  /// No description provided for @bitcoinAdvancedDestinationLabel.
  String get bitcoinAdvancedDestinationLabel;

  /// No description provided for @bitcoinAdvancedAmountSatsLabel.
  String get bitcoinAdvancedAmountSatsLabel;

  /// No description provided for @bitcoinAdvancedFeeRateOptionalLabel.
  String get bitcoinAdvancedFeeRateOptionalLabel;

  /// No description provided for @bitcoinAdvancedOptionalUtxosTitle.
  String get bitcoinAdvancedOptionalUtxosTitle;

  /// No description provided for @bitcoinAdvancedAutoUtxosMessage.
  String get bitcoinAdvancedAutoUtxosMessage;

  /// No description provided for @bitcoinAdvancedNoSpendableUtxos.
  String get bitcoinAdvancedNoSpendableUtxos;

  /// No description provided for @bitcoinAdvancedAutoUtxosFallback.
  String get bitcoinAdvancedAutoUtxosFallback;

  /// No description provided for @bitcoinAdvancedCreatePsbtAction.
  String get bitcoinAdvancedCreatePsbtAction;

  /// No description provided for @bitcoinAdvancedCreatingPsbtAction.
  String get bitcoinAdvancedCreatingPsbtAction;

  /// No description provided for @bitcoinAdvancedCreatedReviewMessage.
  String get bitcoinAdvancedCreatedReviewMessage;

  /// No description provided for @bitcoinAdvancedDestinationMetric.
  String get bitcoinAdvancedDestinationMetric;

  /// No description provided for @bitcoinAdvancedAmountMetric.
  String get bitcoinAdvancedAmountMetric;

  /// No description provided for @bitcoinAdvancedEstimatedFeeMetric.
  String get bitcoinAdvancedEstimatedFeeMetric;

  /// No description provided for @bitcoinAdvancedCopyUnsignedPsbtAction.
  String get bitcoinAdvancedCopyUnsignedPsbtAction;

  /// No description provided for @bitcoinAdvancedIncompleteDataTitle.
  String get bitcoinAdvancedIncompleteDataTitle;

  /// No description provided for @bitcoinAdvancedIncompleteDataMessage.
  String get bitcoinAdvancedIncompleteDataMessage;

  /// No description provided for @bitcoinAdvancedCreateFailedTitle.
  String get bitcoinAdvancedCreateFailedTitle;

  /// No description provided for @bitcoinAdvancedCreateFailedMessage.
  String get bitcoinAdvancedCreateFailedMessage;

  /// No description provided for @bitcoinAdvancedSubmitPsbtTitle.
  String get bitcoinAdvancedSubmitPsbtTitle;

  /// No description provided for @bitcoinAdvancedPsbtValidatedTitle.
  String get bitcoinAdvancedPsbtValidatedTitle;

  /// No description provided for @bitcoinAdvancedSubmitPsbtIntro.
  String get bitcoinAdvancedSubmitPsbtIntro;

  /// No description provided for @bitcoinAdvancedSignedPsbtLabel.
  String get bitcoinAdvancedSignedPsbtLabel;

  /// No description provided for @bitcoinAdvancedSignedPsbtHint.
  String get bitcoinAdvancedSignedPsbtHint;

  /// No description provided for @bitcoinAdvancedBroadcastAfterValidationTitle.
  String get bitcoinAdvancedBroadcastAfterValidationTitle;

  /// No description provided for @bitcoinAdvancedBroadcastAfterValidationSubtitle.
  String get bitcoinAdvancedBroadcastAfterValidationSubtitle;

  /// No description provided for @bitcoinAdvancedValidatePsbtAction.
  String get bitcoinAdvancedValidatePsbtAction;

  /// No description provided for @bitcoinAdvancedValidatingPsbtAction.
  String get bitcoinAdvancedValidatingPsbtAction;

  /// No description provided for @bitcoinAdvancedDoneAction.
  String get bitcoinAdvancedDoneAction;

  /// No description provided for @bitcoinAdvancedSignatureRequiredTitle.
  String get bitcoinAdvancedSignatureRequiredTitle;

  /// No description provided for @bitcoinAdvancedSignatureRequiredMessage.
  String get bitcoinAdvancedSignatureRequiredMessage;

  /// No description provided for @bitcoinAdvancedPsbtRejectedTitle.
  String get bitcoinAdvancedPsbtRejectedTitle;

  /// No description provided for @bitcoinAdvancedPsbtRejectedMessage.
  String get bitcoinAdvancedPsbtRejectedMessage;

  /// No description provided for @bitcoinTaxReportsTitle.
  String get bitcoinTaxReportsTitle;

  /// No description provided for @bitcoinTaxEventsUnavailableTitle.
  String get bitcoinTaxEventsUnavailableTitle;

  /// No description provided for @bitcoinTaxEventsUnavailableMessage.
  String get bitcoinTaxEventsUnavailableMessage;

  /// No description provided for @bitcoinTaxNoEventsTitle.
  String get bitcoinTaxNoEventsTitle;

  /// No description provided for @bitcoinTaxNoEventsMessage.
  String get bitcoinTaxNoEventsMessage;

  /// No description provided for @bitcoinTaxHiddenEvents.
  String bitcoinTaxHiddenEvents(int count);

  /// No description provided for @bitcoinTaxClassifyTooltip.
  String get bitcoinTaxClassifyTooltip;

  /// No description provided for @bitcoinTaxClassificationUpdatedTitle.
  String get bitcoinTaxClassificationUpdatedTitle;

  /// No description provided for @bitcoinTaxClassificationNotSavedTitle.
  String get bitcoinTaxClassificationNotSavedTitle;

  /// No description provided for @bitcoinTaxRetryLaterMessage.
  String get bitcoinTaxRetryLaterMessage;

  /// No description provided for @bitcoinTaxExportJsonAction.
  String get bitcoinTaxExportJsonAction;

  /// No description provided for @bitcoinTaxExportCsvAction.
  String get bitcoinTaxExportCsvAction;

  /// No description provided for @bitcoinTaxReportCopiedTitle.
  String get bitcoinTaxReportCopiedTitle;

  /// No description provided for @bitcoinTaxExportUnavailableTitle.
  String get bitcoinTaxExportUnavailableTitle;

  /// No description provided for @bitcoinTaxExportUnavailableMessage.
  String get bitcoinTaxExportUnavailableMessage;

  /// No description provided for @bitcoinTaxEventDepositInternal.
  String get bitcoinTaxEventDepositInternal;

  /// No description provided for @bitcoinTaxEventDepositExternal.
  String get bitcoinTaxEventDepositExternal;

  /// No description provided for @bitcoinTaxEventWithdrawal.
  String get bitcoinTaxEventWithdrawal;

  /// No description provided for @bitcoinTaxEventSpend.
  String get bitcoinTaxEventSpend;

  /// No description provided for @bitcoinTaxEventFee.
  String get bitcoinTaxEventFee;

  /// No description provided for @bitcoinTaxClassSelfTransfer.
  String get bitcoinTaxClassSelfTransfer;

  /// No description provided for @bitcoinTaxClassThirdPartyDeposit.
  String get bitcoinTaxClassThirdPartyDeposit;

  /// No description provided for @bitcoinTaxClassSpend.
  String get bitcoinTaxClassSpend;

  /// No description provided for @bitcoinTaxClassFee.
  String get bitcoinTaxClassFee;

  /// No description provided for @bitcoinTaxClassUnknown.
  String get bitcoinTaxClassUnknown;

  /// No description provided for @bitcoinTaxClassPending.
  String get bitcoinTaxClassPending;

  /// No description provided for @adminLoginMissingFields.
  String get adminLoginMissingFields;

  /// No description provided for @adminLoginApprovalRegistered.
  String get adminLoginApprovalRegistered;

  /// No description provided for @adminLoginAccessNotApproved.
  String get adminLoginAccessNotApproved;

  /// No description provided for @adminLoginInvalidTotp.
  String get adminLoginInvalidTotp;

  /// No description provided for @adminLoginSessionExpired.
  String get adminLoginSessionExpired;

  /// No description provided for @adminLoginUsernameHint.
  String get adminLoginUsernameHint;

  /// No description provided for @adminLoginPassphraseHint.
  String get adminLoginPassphraseHint;

  /// No description provided for @adminLoginAdminKeyHint.
  String get adminLoginAdminKeyHint;

  /// No description provided for @adminLoginSignInAction.
  String get adminLoginSignInAction;

  /// No description provided for @adminLoginSecureAccessFooter.
  String get adminLoginSecureAccessFooter;

  /// No description provided for @adminLoginTotpTitle.
  String get adminLoginTotpTitle;

  /// No description provided for @adminLoginTotpSubtitle.
  String get adminLoginTotpSubtitle;

  /// No description provided for @adminLoginTotpAuthenticatingAs.
  String adminLoginTotpAuthenticatingAs(String username);

  /// No description provided for @adminLoginVerifyAction.
  String get adminLoginVerifyAction;

  /// No description provided for @adminLoginBackToLoginAction.
  String get adminLoginBackToLoginAction;

  /// No description provided for @adminLoginConsoleSubtitle.
  String get adminLoginConsoleSubtitle;

  /// No description provided for @adminLoginApprovalPending.
  String get adminLoginApprovalPending;

  /// No description provided for @adminConnectionOnionBrowser.
  String get adminConnectionOnionBrowser;

  /// No description provided for @adminConnectionOnionApi.
  String get adminConnectionOnionApi;

  /// No description provided for @adminConnectionGateway.
  String get adminConnectionGateway;

  /// No description provided for @adminShellNavOverview.
  String get adminShellNavOverview;

  /// No description provided for @adminShellNavOperations.
  String get adminShellNavOperations;

  /// No description provided for @adminShellNavManagement.
  String get adminShellNavManagement;

  /// No description provided for @adminShellSystemOperational.
  String get adminShellSystemOperational;

  /// No description provided for @adminShellIntegrityOnly.
  String get adminShellIntegrityOnly;

  /// No description provided for @adminRouteDashboard.
  String get adminRouteDashboard;

  /// No description provided for @adminRouteMonitoring.
  String get adminRouteMonitoring;

  /// No description provided for @adminRouteTransactions.
  String get adminRouteTransactions;

  /// No description provided for @adminRouteLightning.
  String get adminRouteLightning;

  /// No description provided for @adminRouteOnchain.
  String get adminRouteOnchain;

  /// No description provided for @adminRouteChecks.
  String get adminRouteChecks;

  /// No description provided for @adminRoutePaymentLinks.
  String get adminRoutePaymentLinks;

  /// No description provided for @adminRouteAnalytics.
  String get adminRouteAnalytics;

  /// No description provided for @adminRouteVolatility.
  String get adminRouteVolatility;

  /// No description provided for @adminRouteCompanies.
  String get adminRouteCompanies;

  /// No description provided for @adminRouteAudit.
  String get adminRouteAudit;

  /// No description provided for @adminRouteAuthenticatedDevices.
  String get adminRouteAuthenticatedDevices;

  /// No description provided for @adminRouteNotifications.
  String get adminRouteNotifications;

  /// No description provided for @adminRouteSettings.
  String get adminRouteSettings;

  /// No description provided for @adminActionRefresh.
  String get adminActionRefresh;

  /// No description provided for @adminValueTor.
  String get adminValueTor;

  /// No description provided for @adminValueDirect.
  String get adminValueDirect;

  /// No description provided for @adminValueAuthenticated.
  String get adminValueAuthenticated;

  /// No description provided for @adminValueChecking.
  String get adminValueChecking;

  /// No description provided for @adminValueAdminContext.
  String get adminValueAdminContext;

  /// No description provided for @adminValueMobileUnknown.
  String get adminValueMobileUnknown;

  /// No description provided for @adminValueCheckingRelease.
  String get adminValueCheckingRelease;

  /// No description provided for @adminValueReleaseUnavailable.
  String get adminValueReleaseUnavailable;

  /// No description provided for @adminValueEnabled.
  String get adminValueEnabled;

  /// No description provided for @adminValueDisabled.
  String get adminValueDisabled;

  /// No description provided for @adminValueNotConfigured.
  String get adminValueNotConfigured;

  /// No description provided for @adminValueNotSet.
  String get adminValueNotSet;

  /// No description provided for @adminValueAbsent.
  String get adminValueAbsent;

  /// No description provided for @adminValueBackend.
  String get adminValueBackend;

  /// No description provided for @adminValueTrue.
  String get adminValueTrue;

  /// No description provided for @adminValueFalse.
  String get adminValueFalse;

  /// No description provided for @adminStatusAuthorized.
  String get adminStatusAuthorized;

  /// No description provided for @adminStatusBlocked.
  String get adminStatusBlocked;

  /// No description provided for @adminWaitingForResponse.
  String get adminWaitingForResponse;

  /// No description provided for @adminBackendError.
  String get adminBackendError;

  /// No description provided for @adminColumnEntity.
  String get adminColumnEntity;

  /// No description provided for @adminColumnRole.
  String get adminColumnRole;

  /// No description provided for @adminColumnEnvironment.
  String get adminColumnEnvironment;

  /// No description provided for @adminColumnHealth.
  String get adminColumnHealth;

  /// No description provided for @adminColumnDetail.
  String get adminColumnDetail;

  /// No description provided for @adminColumnName.
  String get adminColumnName;

  /// No description provided for @adminColumnEndpoint.
  String get adminColumnEndpoint;

  /// No description provided for @adminColumnId.
  String get adminColumnId;

  /// No description provided for @adminColumnReference.
  String get adminColumnReference;

  /// No description provided for @adminColumnAmount.
  String get adminColumnAmount;

  /// No description provided for @adminColumnStatus.
  String get adminColumnStatus;

  /// No description provided for @adminColumnRail.
  String get adminColumnRail;

  /// No description provided for @adminColumnCreated.
  String get adminColumnCreated;

  /// No description provided for @adminColumnSettled.
  String get adminColumnSettled;

  /// No description provided for @adminLabelPrimarySource.
  String get adminLabelPrimarySource;

  /// No description provided for @adminLabelNetwork.
  String get adminLabelNetwork;

  /// No description provided for @adminLabelBlockHeight.
  String get adminLabelBlockHeight;

  /// No description provided for @adminLabelBestHash.
  String get adminLabelBestHash;

  /// No description provided for @adminLabelMempoolTxs.
  String get adminLabelMempoolTxs;

  /// No description provided for @adminLabelIndexer.
  String get adminLabelIndexer;

  /// No description provided for @adminLabelStatus.
  String get adminLabelStatus;

  /// No description provided for @adminLabelSession.
  String get adminLabelSession;

  /// No description provided for @adminLabelAlias.
  String get adminLabelAlias;

  /// No description provided for @adminLabelVersion.
  String get adminLabelVersion;

  /// No description provided for @adminLabelSyncedChain.
  String get adminLabelSyncedChain;

  /// No description provided for @adminLabelSyncedGraph.
  String get adminLabelSyncedGraph;

  /// No description provided for @adminLabelBlockHash.
  String get adminLabelBlockHash;

  /// No description provided for @adminLabelPeers.
  String get adminLabelPeers;

  /// No description provided for @adminLabelActiveChannels.
  String get adminLabelActiveChannels;

  /// No description provided for @adminLabelPendingChannels.
  String get adminLabelPendingChannels;

  /// No description provided for @adminLabelLocalBalance.
  String get adminLabelLocalBalance;

  /// No description provided for @adminLabelRemoteBalance.
  String get adminLabelRemoteBalance;

  /// No description provided for @adminLabelWalletBalance.
  String get adminLabelWalletBalance;

  /// No description provided for @adminLabelManifest.
  String get adminLabelManifest;

  /// No description provided for @adminLabelImageDigest.
  String get adminLabelImageDigest;

  /// No description provided for @adminLabelCodeHash.
  String get adminLabelCodeHash;

  /// No description provided for @adminLabelConfigHash.
  String get adminLabelConfigHash;

  /// No description provided for @adminLabelAuthorized.
  String get adminLabelAuthorized;

  /// No description provided for @adminLabelReason.
  String get adminLabelReason;

  /// No description provided for @adminLabelCommit.
  String get adminLabelCommit;

  /// No description provided for @adminLabelMobileVersion.
  String get adminLabelMobileVersion;

  /// No description provided for @adminLabelPlatform.
  String get adminLabelPlatform;

  /// No description provided for @adminLabelActiveNode.
  String get adminLabelActiveNode;

  /// No description provided for @adminLabelApiRoute.
  String get adminLabelApiRoute;

  /// No description provided for @adminLabelTorEnabled.
  String get adminLabelTorEnabled;

  /// No description provided for @adminLabelChecked.
  String get adminLabelChecked;

  /// No description provided for @adminLabelUser.
  String get adminLabelUser;

  /// No description provided for @adminLabelRole.
  String get adminLabelRole;

  /// No description provided for @adminLabelJwtRefreshHeader.
  String get adminLabelJwtRefreshHeader;

  /// No description provided for @adminLabelPasskeyRp.
  String get adminLabelPasskeyRp;

  /// No description provided for @adminLabelDebugLogs.
  String get adminLabelDebugLogs;

  /// No description provided for @adminLabelApiUrl.
  String get adminLabelApiUrl;

  /// No description provided for @adminLabelOnionBase.
  String get adminLabelOnionBase;

  /// No description provided for @adminLabelConnectionTimeout.
  String get adminLabelConnectionTimeout;

  /// No description provided for @adminLabelReceiveTimeout.
  String get adminLabelReceiveTimeout;

  /// No description provided for @adminLabelPasskeyRelyingParty.
  String get adminLabelPasskeyRelyingParty;

  /// No description provided for @adminSettingsSubtitle.
  String get adminSettingsSubtitle;

  /// No description provided for @adminSettingsApiRoutingTitle.
  String get adminSettingsApiRoutingTitle;

  /// No description provided for @adminSettingsSessionSecurityTitle.
  String get adminSettingsSessionSecurityTitle;

  /// No description provided for @adminSettingsCurrentSessionError.
  String get adminSettingsCurrentSessionError;

  /// No description provided for @adminSettingsReleaseTitle.
  String get adminSettingsReleaseTitle;

  /// No description provided for @adminSettingsReleaseAttestationUnavailable.
  String get adminSettingsReleaseAttestationUnavailable;

  /// No description provided for @adminSettingsMobileReleaseUnavailable.
  String get adminSettingsMobileReleaseUnavailable;

  /// No description provided for @adminMonitoringSubtitle.
  String get adminMonitoringSubtitle;

  /// No description provided for @adminMonitoringMetricServices.
  String get adminMonitoringMetricServices;

  /// No description provided for @adminMonitoringMetricVaultRaft.
  String get adminMonitoringMetricVaultRaft;

  /// No description provided for @adminMonitoringBitcoinPanel.
  String get adminMonitoringBitcoinPanel;

  /// No description provided for @adminMonitoringLightningPanel.
  String get adminMonitoringLightningPanel;

  /// No description provided for @adminMonitoringReleasePanel.
  String get adminMonitoringReleasePanel;

  /// No description provided for @adminMonitoringHealthPanel.
  String get adminMonitoringHealthPanel;

  /// No description provided for @adminMonitoringLogsPanel.
  String get adminMonitoringLogsPanel;

  /// No description provided for @adminMonitoringRelevantTransactions.
  String get adminMonitoringRelevantTransactions;

  /// No description provided for @adminMonitoringNoRelevantTransactions.
  String get adminMonitoringNoRelevantTransactions;

  /// No description provided for @adminMonitoringNoHealthChecks.
  String get adminMonitoringNoHealthChecks;

  /// No description provided for @adminMonitoringNoLogs.
  String get adminMonitoringNoLogs;

  /// No description provided for @adminMonitoringBlockchainError.
  String adminMonitoringBlockchainError(String error);

  /// No description provided for @adminMonitoringLightningError.
  String adminMonitoringLightningError(String error);

  /// No description provided for @adminMonitoringReleaseError.
  String adminMonitoringReleaseError(String error);

  /// No description provided for @adminMonitoringHealthError.
  String adminMonitoringHealthError(String error);

  /// No description provided for @adminMonitoringLogsError.
  String adminMonitoringLogsError(String error);

  /// No description provided for @adminCompaniesSubtitle.
  String get adminCompaniesSubtitle;

  /// No description provided for @adminCompaniesMetricControlPlane.
  String get adminCompaniesMetricControlPlane;

  /// No description provided for @adminCompaniesMetricVaultRaft.
  String get adminCompaniesMetricVaultRaft;

  /// No description provided for @adminCompaniesOperationalEntities.
  String get adminCompaniesOperationalEntities;

  /// No description provided for @adminCompaniesRoutingDependencies.
  String get adminCompaniesRoutingDependencies;

  /// No description provided for @adminCompaniesRemoteNodes.
  String get adminCompaniesRemoteNodes;

  /// No description provided for @adminCompaniesOverviewUnavailable.
  String get adminCompaniesOverviewUnavailable;

  /// No description provided for @adminCompaniesEntityKeroseneApi.
  String get adminCompaniesEntityKeroseneApi;

  /// No description provided for @adminCompaniesEntityReleaseGate.
  String get adminCompaniesEntityReleaseGate;

  /// No description provided for @adminCompaniesRoleControlPlane.
  String get adminCompaniesRoleControlPlane;

  /// No description provided for @adminCompaniesRoleOnchainSource.
  String get adminCompaniesRoleOnchainSource;

  /// No description provided for @adminCompaniesRoleLightningRouting.
  String get adminCompaniesRoleLightningRouting;

  /// No description provided for @adminCompaniesRoleReleaseQuorum.
  String get adminCompaniesRoleReleaseQuorum;

  /// No description provided for @adminCompaniesRoleDeploymentAttestation.
  String get adminCompaniesRoleDeploymentAttestation;

  /// No description provided for @adminPaymentLinksSubtitle.
  String get adminPaymentLinksSubtitle;

  /// No description provided for @adminPaymentLinksLinksCreated.
  String get adminPaymentLinksLinksCreated;

  /// No description provided for @adminPaymentLinksObservedVolume.
  String get adminPaymentLinksObservedVolume;

  /// No description provided for @adminPaymentLinksConversion.
  String get adminPaymentLinksConversion;

  /// No description provided for @adminPaymentLinksFailures.
  String get adminPaymentLinksFailures;

  /// No description provided for @adminPaymentLinksLatestEvents.
  String get adminPaymentLinksLatestEvents;

  /// No description provided for @adminPaymentLinksLoadError.
  String get adminPaymentLinksLoadError;

  /// No description provided for @adminPaymentLinksEmptyTitle.
  String get adminPaymentLinksEmptyTitle;

  /// No description provided for @adminPaymentLinksEmptySubtitle.
  String get adminPaymentLinksEmptySubtitle;

  /// No description provided for @adminPaymentLinksUnlabeled.
  String get adminPaymentLinksUnlabeled;

  /// No description provided for @adminPaymentLinksWaitingList.
  String get adminPaymentLinksWaitingList;

  /// No description provided for @adminPaymentLinksExpiredCancelled.
  String get adminPaymentLinksExpiredCancelled;

  /// No description provided for @adminPaidOpen.
  String adminPaidOpen(String paid, String open);

  /// No description provided for @adminLinksLoaded.
  String adminLinksLoaded(String count);

  /// No description provided for @adminSettledRatio.
  String adminSettledRatio(String paid, String created);

  /// No description provided for @adminHeightValue.
  String adminHeightValue(String height);

  /// No description provided for @adminVotersValue.
  String adminVotersValue(String current, String expected);

  /// No description provided for @adminActiveChannelsValue.
  String adminActiveChannelsValue(String count);

  /// No description provided for @adminPeersValue.
  String adminPeersValue(String alias, String peers);

  /// No description provided for @adminConfirmationsValue.
  String adminConfirmationsValue(String count);

  /// No description provided for @adminLogBody.
  String adminLogBody(
    String createdAt,
    String reference,
    String userRef,
    String payloadRef,
  );

  /// No description provided for @bitcoinReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive BTC'**
  String get bitcoinReceiveTitle;

  /// No description provided for @bitcoinReceiveAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional amount in sats'**
  String get bitcoinReceiveAmountOptional;

  /// No description provided for @bitcoinReceiveOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time address'**
  String get bitcoinReceiveOneTime;

  /// No description provided for @bitcoinReceiveOneTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for privacy and clean tracking.'**
  String get bitcoinReceiveOneTimeSubtitle;

  /// No description provided for @bitcoinReceiveGenerateAddress.
  ///
  /// In en, this message translates to:
  /// **'Generate address'**
  String get bitcoinReceiveGenerateAddress;

  /// No description provided for @bitcoinReceiveGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get bitcoinReceiveGenerating;

  /// No description provided for @bitcoinReceiveRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get bitcoinReceiveRefresh;

  /// No description provided for @bitcoinReceiveCreateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not generate'**
  String get bitcoinReceiveCreateErrorTitle;

  /// No description provided for @bitcoinReceiveCreateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Review the data and try a new address.'**
  String get bitcoinReceiveCreateErrorMessage;

  /// No description provided for @bitcoinReceiveStatusErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get bitcoinReceiveStatusErrorTitle;

  /// No description provided for @bitcoinReceiveStatusErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not update this receiving request right now.'**
  String get bitcoinReceiveStatusErrorMessage;

  /// No description provided for @bitcoinReceiveCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get bitcoinReceiveCopiedTitle;

  /// No description provided for @bitcoinReceiveCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin address copied.'**
  String get bitcoinReceiveCopiedMessage;

  /// No description provided for @bitcoinReceiveStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get bitcoinReceiveStatusActive;

  /// No description provided for @bitcoinReceiveRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive requests'**
  String get bitcoinReceiveRequestsTitle;

  /// No description provided for @bitcoinReceiveRequestsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests.'**
  String get bitcoinReceiveRequestsLoadErrorTitle;

  /// No description provided for @bitcoinReceiveRequestsOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline.'**
  String get bitcoinReceiveRequestsOfflineTitle;

  /// No description provided for @bitcoinReceiveRequestsLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Kerosene could not refresh receive requests for this account.'**
  String get bitcoinReceiveRequestsLoadErrorMessage;

  /// No description provided for @bitcoinReceiveRequestsOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Reconnect and retry to load receive requests.'**
  String get bitcoinReceiveRequestsOfflineMessage;

  /// No description provided for @bitcoinReceiveRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active receive requests.'**
  String get bitcoinReceiveRequestsEmptyTitle;

  /// No description provided for @bitcoinReceiveRequestsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Generated Bitcoin receive requests will appear here.'**
  String get bitcoinReceiveRequestsEmptyMessage;

  /// No description provided for @bitcoinReceiveRequestsFlexibleAmount.
  ///
  /// In en, this message translates to:
  /// **'Flexible amount'**
  String get bitcoinReceiveRequestsFlexibleAmount;

  /// No description provided for @bitcoinReceiveRequestsNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'no expiry'**
  String get bitcoinReceiveRequestsNoExpiry;

  /// No description provided for @paymentIntentScreenTitle.
  String get paymentIntentScreenTitle;

  /// No description provided for @paymentIntentScreenSubtitle.
  String get paymentIntentScreenSubtitle;

  /// No description provided for @paymentIntentRecipientHint.
  String get paymentIntentRecipientHint;

  /// No description provided for @paymentIntentSearchAction.
  String get paymentIntentSearchAction;

  /// No description provided for @paymentIntentAmountFeeTitle.
  String get paymentIntentAmountFeeTitle;

  /// No description provided for @paymentIntentGenerateQuoteAction.
  String get paymentIntentGenerateQuoteAction;

  /// No description provided for @paymentIntentQuoteTitle.
  String get paymentIntentQuoteTitle;

  /// No description provided for @paymentIntentMetricReceiver.
  String get paymentIntentMetricReceiver;

  /// No description provided for @paymentIntentMetricRoute.
  String get paymentIntentMetricRoute;

  /// No description provided for @paymentIntentMetricReceives.
  String get paymentIntentMetricReceives;

  /// No description provided for @paymentIntentMetricNetworkFee.
  String get paymentIntentMetricNetworkFee;

  /// No description provided for @paymentIntentMetricKeroseneFee.
  String get paymentIntentMetricKeroseneFee;

  /// No description provided for @paymentIntentMetricTotalDebit.
  String get paymentIntentMetricTotalDebit;

  /// No description provided for @paymentIntentConfirmPaymentAction.
  String get paymentIntentConfirmPaymentAction;

  /// No description provided for @paymentIntentStatusTitle.
  String get paymentIntentStatusTitle;

  /// No description provided for @paymentIntentNotCompleted.
  String get paymentIntentNotCompleted;

  /// No description provided for @paymentIntentReviewTitle.
  String get paymentIntentReviewTitle;

  /// No description provided for @paymentIntentReviewDebitMessage.
  String paymentIntentReviewDebitMessage(String total, String receiver);

  /// No description provided for @paymentIntentAuthorizeAction.
  String get paymentIntentAuthorizeAction;

  /// No description provided for @paymentIntentValidationRecipientRequired.
  String get paymentIntentValidationRecipientRequired;

  /// No description provided for @paymentIntentValidationAmountRequired.
  String get paymentIntentValidationAmountRequired;

  /// No description provided for @paymentIntentRailInternal.
  String get paymentIntentRailInternal;

  /// No description provided for @paymentIntentRailLightning.
  String get paymentIntentRailLightning;

  /// No description provided for @paymentIntentRailOnchain.
  String get paymentIntentRailOnchain;

  /// No description provided for @paymentIntentFeeSenderPays.
  String get paymentIntentFeeSenderPays;

  /// No description provided for @paymentIntentFeeRecipientPays.
  String get paymentIntentFeeRecipientPays;

  /// No description provided for @paymentIntentSpeedEconomy.
  String get paymentIntentSpeedEconomy;

  /// No description provided for @paymentIntentSpeedNormal.
  String get paymentIntentSpeedNormal;

  /// No description provided for @paymentIntentSpeedFast.
  String get paymentIntentSpeedFast;

  /// No description provided for @paymentIntentStatusCreated.
  String get paymentIntentStatusCreated;

  /// No description provided for @paymentIntentStatusQuoted.
  String get paymentIntentStatusQuoted;

  /// No description provided for @paymentIntentStatusConfirmed.
  String get paymentIntentStatusConfirmed;

  /// No description provided for @paymentIntentStatusProcessing.
  String get paymentIntentStatusProcessing;

  /// No description provided for @paymentIntentStatusAcceptedByProvider.
  String get paymentIntentStatusAcceptedByProvider;

  /// No description provided for @paymentIntentStatusRequiresReconciliation.
  String get paymentIntentStatusRequiresReconciliation;

  /// No description provided for @paymentIntentStatusSettled.
  String get paymentIntentStatusSettled;

  /// No description provided for @paymentIntentStatusFailed.
  String get paymentIntentStatusFailed;

  /// No description provided for @paymentIntentStatusCanceled.
  String get paymentIntentStatusCanceled;

  /// No description provided for @paymentIntentStatusExpired.
  String get paymentIntentStatusExpired;

  /// No description provided for @bitcoinReceiveStatusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get bitcoinReceiveStatusDetected;

  /// No description provided for @bitcoinReceiveStatusConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get bitcoinReceiveStatusConfirming;

  /// No description provided for @bitcoinReceiveStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get bitcoinReceiveStatusPaid;

  /// No description provided for @bitcoinReceiveStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bitcoinReceiveStatusExpired;

  /// No description provided for @bitcoinReceiveStatusLate.
  ///
  /// In en, this message translates to:
  /// **'Late payment'**
  String get bitcoinReceiveStatusLate;

  /// No description provided for @bitcoinReceiveStatusReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get bitcoinReceiveStatusReview;

  /// No description provided for @bitcoinReceiveStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get bitcoinReceiveStatusAction;

  /// No description provided for @bitcoinReceiveStatusProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get bitcoinReceiveStatusProtected;

  /// No description provided for @bitcoinReceiveStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get bitcoinReceiveStatusWaiting;

  /// No description provided for @bitcoinReceiveMessageActive.
  ///
  /// In en, this message translates to:
  /// **'Send BTC to this address. We will update this screen when the network sees the payment.'**
  String get bitcoinReceiveMessageActive;

  /// No description provided for @bitcoinReceiveMessageDetected.
  ///
  /// In en, this message translates to:
  /// **'Payment was seen on the Bitcoin network and is waiting for confirmations.'**
  String get bitcoinReceiveMessageDetected;

  /// No description provided for @bitcoinReceiveMessageConfirming.
  ///
  /// In en, this message translates to:
  /// **'The transaction is in a block and is still confirming.'**
  String get bitcoinReceiveMessageConfirming;

  /// No description provided for @bitcoinReceiveMessagePaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed and added to your Kerosene card balance.'**
  String get bitcoinReceiveMessagePaid;

  /// No description provided for @bitcoinReceiveMessageExpired.
  ///
  /// In en, this message translates to:
  /// **'This request expired. Generate a new address to continue.'**
  String get bitcoinReceiveMessageExpired;

  /// No description provided for @bitcoinReceiveMessageLate.
  ///
  /// In en, this message translates to:
  /// **'A payment arrived after expiration and is being reviewed safely.'**
  String get bitcoinReceiveMessageLate;

  /// No description provided for @bitcoinReceiveMessageReview.
  ///
  /// In en, this message translates to:
  /// **'Your confirmation was received. We are waiting for the safe release condition.'**
  String get bitcoinReceiveMessageReview;

  /// No description provided for @bitcoinReceiveMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm this payment to finish receiving it safely.'**
  String get bitcoinReceiveMessageAction;

  /// No description provided for @bitcoinReceiveMessageProtected.
  ///
  /// In en, this message translates to:
  /// **'This receiving request was protected after a sync problem. Refresh later.'**
  String get bitcoinReceiveMessageProtected;

  /// No description provided for @bitcoinReceiveMessageWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the Bitcoin network.'**
  String get bitcoinReceiveMessageWaiting;

  /// No description provided for @onchainDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain deposit'**
  String get onchainDepositTitle;

  /// No description provided for @onchainDepositSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code or copy the Bitcoin address exactly as shown.'**
  String get onchainDepositSubtitle;

  /// No description provided for @onchainDepositPreparingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your receiving address.'**
  String get onchainDepositPreparingSubtitle;

  /// No description provided for @onchainDepositLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get onchainDepositLoadingTitle;

  /// No description provided for @onchainDepositLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Getting the latest quote before creating the address.'**
  String get onchainDepositLoadingMessage;

  /// No description provided for @onchainDepositAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not create a valid Bitcoin address. Try again.'**
  String get onchainDepositAddressUnavailable;

  /// No description provided for @onchainDepositTrackingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not start tracking this deposit. Try again.'**
  String get onchainDepositTrackingUnavailable;

  /// No description provided for @onchainDepositAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin address copied.'**
  String get onchainDepositAddressCopied;

  /// No description provided for @onchainDepositSelectedWallet.
  ///
  /// In en, this message translates to:
  /// **'Selected wallet'**
  String get onchainDepositSelectedWallet;

  /// No description provided for @onchainDepositLocalNetwork.
  ///
  /// In en, this message translates to:
  /// **'Local test network'**
  String get onchainDepositLocalNetwork;

  /// No description provided for @onchainDepositStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get onchainDepositStatusCompleted;

  /// No description provided for @onchainDepositStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get onchainDepositStatusConfirmed;

  /// No description provided for @onchainDepositStatusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get onchainDepositStatusDetected;

  /// No description provided for @onchainDepositStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get onchainDepositStatusWaiting;

  /// No description provided for @onchainDepositStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get onchainDepositStatusFailed;

  /// No description provided for @onchainDepositStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get onchainDepositStatusCancelled;

  /// No description provided for @onchainDepositStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get onchainDepositStatusExpired;

  /// No description provided for @onchainDepositDescriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'This deposit was cancelled. Create a new address if you still want to deposit.'**
  String get onchainDepositDescriptionCancelled;

  /// No description provided for @onchainDepositDescriptionWaiting.
  ///
  /// In en, this message translates to:
  /// **'This address is reserved for this deposit on {network}.'**
  String onchainDepositDescriptionWaiting(String network);

  /// No description provided for @onchainDepositDescriptionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The Bitcoin network confirmed this deposit.'**
  String get onchainDepositDescriptionConfirmed;

  /// No description provided for @onchainDepositDescriptionConfirming.
  ///
  /// In en, this message translates to:
  /// **'Payment detected. Waiting for {current}/{total} confirmations.'**
  String onchainDepositDescriptionConfirming(int current, int total);

  /// No description provided for @onchainDepositDetectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Payment detected. Tracking {current}/{total} confirmations.'**
  String onchainDepositDetectedNotice(int current, int total);

  /// No description provided for @onchainDepositConfirmedNotice.
  ///
  /// In en, this message translates to:
  /// **'Deposit confirmed.'**
  String get onchainDepositConfirmedNotice;

  /// No description provided for @onchainDepositCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel deposit'**
  String get onchainDepositCancelTitle;

  /// No description provided for @onchainDepositCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'This address will stop being used for this deposit if no payment was detected yet.'**
  String get onchainDepositCancelMessage;

  /// No description provided for @onchainDepositCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel deposit'**
  String get onchainDepositCancelAction;

  /// No description provided for @onchainDepositCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get onchainDepositCancelling;

  /// No description provided for @onchainDepositCancelledNotice.
  ///
  /// In en, this message translates to:
  /// **'Deposit cancelled.'**
  String get onchainDepositCancelledNotice;

  /// No description provided for @onchainDepositGettingAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating address'**
  String get onchainDepositGettingAddressTitle;

  /// No description provided for @onchainDepositGettingAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'After payment, your balance updates when Bitcoin confirmations arrive.'**
  String get onchainDepositGettingAddressMessage;

  /// No description provided for @onchainDepositErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare deposit'**
  String get onchainDepositErrorTitle;

  /// No description provided for @onchainDepositTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total to deposit'**
  String get onchainDepositTotalLabel;

  /// No description provided for @onchainDepositNetworkTag.
  ///
  /// In en, this message translates to:
  /// **'{network} address'**
  String onchainDepositNetworkTag(String network);

  /// No description provided for @onchainDepositTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment tracking'**
  String get onchainDepositTrackingTitle;

  /// No description provided for @onchainDepositConfirmationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get onchainDepositConfirmationsLabel;

  /// No description provided for @onchainDepositTxidLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction code'**
  String get onchainDepositTxidLabel;

  /// No description provided for @onchainDepositObservedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount seen'**
  String get onchainDepositObservedAmountLabel;

  /// No description provided for @onchainDepositAmountCheckLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount check'**
  String get onchainDepositAmountCheckLabel;

  /// No description provided for @onchainDepositAmountCheckOk.
  ///
  /// In en, this message translates to:
  /// **'Amount matches'**
  String get onchainDepositAmountCheckOk;

  /// No description provided for @onchainDepositAmountCheckDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different amount'**
  String get onchainDepositAmountCheckDifferent;

  /// No description provided for @onchainDepositQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin address'**
  String get onchainDepositQrTitle;

  /// No description provided for @onchainDepositQuoteLabel.
  ///
  /// In en, this message translates to:
  /// **'BTC quote'**
  String get onchainDepositQuoteLabel;

  /// No description provided for @onchainDepositDestinationWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Goes to'**
  String get onchainDepositDestinationWalletLabel;

  /// No description provided for @onchainDepositNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get onchainDepositNetworkLabel;

  /// No description provided for @onchainDepositExpectedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected amount'**
  String get onchainDepositExpectedAmountLabel;

  /// No description provided for @onchainDepositReceivedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Received amount'**
  String get onchainDepositReceivedAmountLabel;

  /// No description provided for @onchainDepositMinimumConfirmationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum confirmations'**
  String get onchainDepositMinimumConfirmationsLabel;

  /// No description provided for @onchainDepositMinimumConfirmationsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks'**
  String onchainDepositMinimumConfirmationsValue(int count);

  /// No description provided for @onchainDepositCustodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet type'**
  String get onchainDepositCustodyLabel;

  /// No description provided for @onchainDepositCustodySelf.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet, view only'**
  String get onchainDepositCustodySelf;

  /// No description provided for @onchainDepositCustodyKerosene.
  ///
  /// In en, this message translates to:
  /// **'Kerosene card'**
  String get onchainDepositCustodyKerosene;

  /// No description provided for @onchainDepositSecuritySelf.
  ///
  /// In en, this message translates to:
  /// **'Kerosene only watches this address. Spending stays under your recovery words or your offline device.'**
  String get onchainDepositSecuritySelf;

  /// No description provided for @onchainDepositSecurityKerosene.
  ///
  /// In en, this message translates to:
  /// **'This address is created for your Kerosene card and watched until the deposit is confirmed.'**
  String get onchainDepositSecurityKerosene;

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
  /// **'Address unavailable'**
  String get errLedgerReceiverNotFound;

  /// No description provided for @errLedgerGeneric.
  ///
  /// In en, this message translates to:
  /// **'We could not complete this movement right now.'**
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
  /// **'We could not validate this wallet right now.'**
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
  /// **'Kerosene is temporarily unavailable.'**
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
  /// **'No internet connection. Check your connection and try again.'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Check your internet and try again.'**
  String get errTimeout;

  /// No description provided for @errCommFailure.
  ///
  /// In en, this message translates to:
  /// **'We could not reach Kerosene right now.'**
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

  /// No description provided for @verifyingDevice.
  ///
  /// In en, this message translates to:
  /// **'VERIFYING DEVICE'**
  String get verifyingDevice;

  /// No description provided for @connectingToServer.
  ///
  /// In en, this message translates to:
  /// **'CONNECTING TO SERVER'**
  String get connectingToServer;

  /// No description provided for @sendingData.
  ///
  /// In en, this message translates to:
  /// **'SENDING DATA'**
  String get sendingData;

  /// No description provided for @apiDisplayActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get apiDisplayActive;

  /// No description provided for @apiDisplayWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get apiDisplayWaiting;

  /// No description provided for @apiDisplayBeingChecked.
  ///
  /// In en, this message translates to:
  /// **'Being checked'**
  String get apiDisplayBeingChecked;

  /// No description provided for @apiDisplayDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get apiDisplayDetected;

  /// No description provided for @apiDisplayConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get apiDisplayConfirming;

  /// No description provided for @apiDisplayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get apiDisplayCompleted;

  /// No description provided for @apiDisplayExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get apiDisplayExpired;

  /// No description provided for @apiDisplayCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apiDisplayCancelled;

  /// No description provided for @apiDisplayNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get apiDisplayNotCompleted;

  /// No description provided for @apiDisplayProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get apiDisplayProtected;

  /// No description provided for @apiDisplayAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get apiDisplayAvailable;

  /// No description provided for @apiDisplayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get apiDisplayUnavailable;

  /// No description provided for @apiDisplayHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get apiDisplayHealthy;

  /// No description provided for @apiDisplayNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get apiDisplayNeedsAttention;

  /// No description provided for @apiDisplayActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get apiDisplayActionNeeded;

  /// No description provided for @apiDisplayInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get apiDisplayInReview;

  /// No description provided for @apiDisplayBeingTracked.
  ///
  /// In en, this message translates to:
  /// **'Being tracked'**
  String get apiDisplayBeingTracked;

  /// No description provided for @apiDisplayAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get apiDisplayAutomatic;

  /// No description provided for @apiDisplayManualConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Manual confirmation'**
  String get apiDisplayManualConfirmation;

  /// No description provided for @apiDisplayPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get apiDisplayPrivate;

  /// No description provided for @apiDisplayShareable.
  ///
  /// In en, this message translates to:
  /// **'Shareable'**
  String get apiDisplayShareable;

  /// No description provided for @apiDisplayWatchedColdWallet.
  ///
  /// In en, this message translates to:
  /// **'Watched cold wallet'**
  String get apiDisplayWatchedColdWallet;

  /// No description provided for @apiDisplayKeroseneCard.
  ///
  /// In en, this message translates to:
  /// **'Kerosene card'**
  String get apiDisplayKeroseneCard;

  /// No description provided for @apiDisplayBitcoinWallet.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin wallet'**
  String get apiDisplayBitcoinWallet;

  /// No description provided for @apiDisplayDeviceKey.
  ///
  /// In en, this message translates to:
  /// **'Device key'**
  String get apiDisplayDeviceKey;

  /// No description provided for @apiDisplayAuthenticatorCode.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get apiDisplayAuthenticatorCode;

  /// No description provided for @apiDisplayAccessPassword.
  ///
  /// In en, this message translates to:
  /// **'Access password'**
  String get apiDisplayAccessPassword;

  /// No description provided for @apiDisplayRecoveryCodes.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get apiDisplayRecoveryCodes;

  /// No description provided for @apiDisplaySecureConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Secure confirmation'**
  String get apiDisplaySecureConfirmation;

  /// No description provided for @apiDisplayGenericActionError.
  ///
  /// In en, this message translates to:
  /// **'We could not complete this action right now. Please try again.'**
  String get apiDisplayGenericActionError;

  /// No description provided for @apiDisplayLightningUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lightning is not available for this wallet right now.'**
  String get apiDisplayLightningUnavailable;

  /// No description provided for @apiDisplayDepositAddressCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not create an address for this deposit.'**
  String get apiDisplayDepositAddressCreateFailed;

  /// No description provided for @apiDisplaySecureConfirmationStartFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not start secure confirmation. Please try again.'**
  String get apiDisplaySecureConfirmationStartFailed;

  /// No description provided for @apiDisplayInformationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Information unavailable'**
  String get apiDisplayInformationUnavailable;

  /// No description provided for @apiDisplayAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable'**
  String get apiDisplayAddressUnavailable;

  /// No description provided for @apiDisplayCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get apiDisplayCopied;

  /// No description provided for @apiDisplayDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Data copied'**
  String get apiDisplayDataCopied;

  /// No description provided for @apiDisplayTransactionSummaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Transaction summary copied to the clipboard.'**
  String get apiDisplayTransactionSummaryCopied;

  /// No description provided for @apiDisplayReceiveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Receiving request cancelled.'**
  String get apiDisplayReceiveCancelled;

  /// No description provided for @detailReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get detailReference;

  /// No description provided for @detailRequestCode.
  ///
  /// In en, this message translates to:
  /// **'Request code'**
  String get detailRequestCode;

  /// No description provided for @detailConfirmationCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get detailConfirmationCode;

  /// No description provided for @detailLightningCode.
  ///
  /// In en, this message translates to:
  /// **'Lightning code'**
  String get detailLightningCode;

  /// No description provided for @detailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailBtcAmount.
  ///
  /// In en, this message translates to:
  /// **'BTC'**
  String get detailBtcAmount;

  /// No description provided for @detailPaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get detailPaymentLink;

  /// No description provided for @detailExternalWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'External withdrawal'**
  String get detailExternalWithdrawal;

  /// No description provided for @detailInternalMovement.
  ///
  /// In en, this message translates to:
  /// **'Internal movement'**
  String get detailInternalMovement;

  /// No description provided for @detailBitcoinNetwork.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin network'**
  String get detailBitcoinNetwork;

  /// No description provided for @qrScannerInstruction.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code inside the frame.'**
  String get qrScannerInstruction;

  /// No description provided for @errorPopupSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get errorPopupSuccessTitle;

  /// No description provided for @errorPopupTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not complete the transaction'**
  String get errorPopupTransactionTitle;

  /// No description provided for @errorPopupBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance required'**
  String get errorPopupBalanceTitle;

  /// No description provided for @errorPopupNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection issue'**
  String get errorPopupNetworkTitle;

  /// No description provided for @errorPopupAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Access check failed'**
  String get errorPopupAccessTitle;

  /// No description provided for @errInvalidNetworkAddress.
  ///
  /// In en, this message translates to:
  /// **'This Bitcoin address does not match this wallet network. Check it and try again.'**
  String get errInvalidNetworkAddress;

  /// No description provided for @errCustodyProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This transfer option is not available right now. Try another option or come back later.'**
  String get errCustodyProviderUnavailable;

  /// No description provided for @errPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This content is too large to send safely.'**
  String get errPayloadTooLarge;

  /// No description provided for @errPasskeyDeviceNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This device is not linked to your account for passkey confirmation. Link this device and try again.'**
  String get errPasskeyDeviceNotLinked;

  /// No description provided for @errPasskeyRequired.
  ///
  /// In en, this message translates to:
  /// **'A passkey compatible with this login is required to finish this operation.'**
  String get errPasskeyRequired;

  /// No description provided for @errPasskeyWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'This passkey cannot be used for this login. Sign in with passphrase and authenticator code, then link a new passkey on this device.'**
  String get errPasskeyWrongDevice;

  /// No description provided for @errPasskeyRejected.
  ///
  /// In en, this message translates to:
  /// **'This passkey was rejected for the operation. If the problem persists, link another compatible passkey.'**
  String get errPasskeyRejected;

  /// No description provided for @errPasskeyLinkGuidance.
  ///
  /// In en, this message translates to:
  /// **'Sign in with passphrase and authenticator code, then link a passkey compatible with this device.'**
  String get errPasskeyLinkGuidance;

  /// No description provided for @errReceiverNotReady.
  ///
  /// In en, this message translates to:
  /// **'This user is not ready to receive funds yet.'**
  String get errReceiverNotReady;

  /// No description provided for @errOnchainReceiverMethodNotFound.
  ///
  /// In en, this message translates to:
  /// **'This user does not have an on-chain wallet registered to receive.'**
  String get errOnchainReceiverMethodNotFound;

  /// No description provided for @errOnchainInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'The Bitcoin address is not valid for this network.'**
  String get errOnchainInvalidAddress;

  /// No description provided for @errOnchainAmountBelowDust.
  ///
  /// In en, this message translates to:
  /// **'The amount is too low for on-chain sending after fees.'**
  String get errOnchainAmountBelowDust;

  /// No description provided for @errOnchainInsufficientFundsForFee.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to cover the amount and the network fee.'**
  String get errOnchainInsufficientFundsForFee;

  /// No description provided for @errLightningInsufficientLiquidity.
  ///
  /// In en, this message translates to:
  /// **'There is not enough Lightning liquidity to complete this payment now. Try another method or a lower amount.'**
  String get errLightningInsufficientLiquidity;

  /// No description provided for @errLightningRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find a reliable Lightning route for this payment.'**
  String get errLightningRouteNotFound;

  /// No description provided for @errLightningReceiverMethodNotFound.
  ///
  /// In en, this message translates to:
  /// **'This user has not configured Lightning receiving yet.'**
  String get errLightningReceiverMethodNotFound;

  /// No description provided for @errQuoteExpired.
  ///
  /// In en, this message translates to:
  /// **'The quote expired. Generate a new one before confirming.'**
  String get errQuoteExpired;

  /// No description provided for @errQuoteChanged.
  ///
  /// In en, this message translates to:
  /// **'The quote changed. Review the updated values before confirming.'**
  String get errQuoteChanged;

  /// No description provided for @errNetAmountNegative.
  ///
  /// In en, this message translates to:
  /// **'The net amount would be less than zero after fees.'**
  String get errNetAmountNegative;

  /// No description provided for @errInsufficientBalanceForFees.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to cover the amount and fees.'**
  String get errInsufficientBalanceForFees;

  /// No description provided for @homeTxReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get homeTxReceived;

  /// No description provided for @homeTxSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get homeTxSent;

  /// No description provided for @homeTxPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get homeTxPaid;

  /// No description provided for @homeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get homeNow;

  /// No description provided for @homeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String homeMinutesAgo(int count);

  /// No description provided for @homeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String homeHoursAgo(int count);

  /// No description provided for @homeYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String homeYesterdayAt(String time);

  /// No description provided for @homeWalletRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet required'**
  String get homeWalletRequiredTitle;

  /// No description provided for @homeWalletRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Select or create a wallet before using this action.'**
  String get homeWalletRequiredMessage;

  /// No description provided for @homeNfcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device right now.'**
  String get homeNfcUnavailable;

  /// No description provided for @homeSendInternalLabel.
  ///
  /// In en, this message translates to:
  /// **'Send within Kerosene'**
  String get homeSendInternalLabel;

  /// No description provided for @homeSendInternalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate transfer between accounts'**
  String get homeSendInternalSubtitle;

  /// No description provided for @homeSendOnchainLabel.
  ///
  /// In en, this message translates to:
  /// **'Send on-chain'**
  String get homeSendOnchainLabel;

  /// No description provided for @homeSendOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To a Bitcoin address'**
  String get homeSendOnchainSubtitle;

  /// No description provided for @homeSendLightningLabel.
  ///
  /// In en, this message translates to:
  /// **'Send via Lightning'**
  String get homeSendLightningLabel;

  /// No description provided for @homeSendLightningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice, LNURL, or Lightning Address'**
  String get homeSendLightningSubtitle;

  /// No description provided for @homeSendMethodOnchainLabel.
  ///
  /// In en, this message translates to:
  /// **'On-chain'**
  String get homeSendMethodOnchainLabel;

  /// No description provided for @homeSendMethodOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send to any Bitcoin network address.'**
  String get homeSendMethodOnchainSubtitle;

  /// No description provided for @homeSendMethodLightningLabel.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get homeSendMethodLightningLabel;

  /// No description provided for @homeSendMethodLightningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send instantly over Lightning Network.'**
  String get homeSendMethodLightningSubtitle;

  /// No description provided for @homeSendMethodInternalLabel.
  ///
  /// In en, this message translates to:
  /// **'Kerosene internal'**
  String get homeSendMethodInternalLabel;

  /// No description provided for @homeSendMethodInternalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant transfer with no fee.'**
  String get homeSendMethodInternalSubtitle;

  /// No description provided for @homeScanQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get homeScanQrLabel;

  /// No description provided for @homeScanQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read a request or address'**
  String get homeScanQrSubtitle;

  /// No description provided for @homePaymentLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get homePaymentLinkLabel;

  /// No description provided for @homePaymentLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste an internal link, on-chain URI, Lightning request, or request ID.'**
  String get homePaymentLinkSubtitle;

  /// No description provided for @homeNfcPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay by NFC'**
  String get homeNfcPayLabel;

  /// No description provided for @homeNfcPaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold nearby to start'**
  String get homeNfcPaySubtitle;

  /// No description provided for @homeSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get homeSendTitle;

  /// No description provided for @homePrimaryNoWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your main wallet'**
  String get homePrimaryNoWalletTitle;

  /// No description provided for @homePrimaryNoWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet to receive, send, and track your balance securely.'**
  String get homePrimaryNoWalletSubtitle;

  /// No description provided for @homePrimaryReadyNoBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet ready to use'**
  String get homePrimaryReadyNoBalanceTitle;

  /// No description provided for @homePrimaryReadyNoBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit whenever you want. We track network confirmation in real time.'**
  String get homePrimaryReadyNoBalanceSubtitle;

  /// No description provided for @homePrimaryReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to move funds'**
  String get homePrimaryReadyTitle;

  /// No description provided for @homePrimaryReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access the main wallet actions with clear confirmation before each payment.'**
  String get homePrimaryReadySubtitle;

  /// No description provided for @homeCreateWalletAction.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get homeCreateWalletAction;

  /// No description provided for @homeDepositFundsAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit funds'**
  String get homeDepositFundsAction;

  /// No description provided for @homeSendBtcAction.
  ///
  /// In en, this message translates to:
  /// **'Send BTC'**
  String get homeSendBtcAction;

  /// No description provided for @homeReceiveBtcAction.
  ///
  /// In en, this message translates to:
  /// **'Receive BTC'**
  String get homeReceiveBtcAction;

  /// No description provided for @homeViewDepositsAction.
  ///
  /// In en, this message translates to:
  /// **'View deposits'**
  String get homeViewDepositsAction;

  /// No description provided for @homePendingLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for details'**
  String get homePendingLinkTitle;

  /// No description provided for @homePendingLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, Lightning request, Bitcoin address, or Kerosene code.'**
  String get homePendingLinkMessage;

  /// No description provided for @homeLightningPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment'**
  String get homeLightningPaymentTitle;

  /// No description provided for @homeOnchainPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain payment'**
  String get homeOnchainPaymentTitle;

  /// No description provided for @homeInternalTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Internal transfer'**
  String get homeInternalTransferTitle;

  /// No description provided for @homeInvalidLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get homeInvalidLinkTitle;

  /// No description provided for @homeInvalidLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove spaces or line breaks and try again.'**
  String get homeInvalidLinkMessage;

  /// No description provided for @homeInternalLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Internal link'**
  String get homeInternalLinkTitle;

  /// No description provided for @homeInvoiceOrLnurl.
  ///
  /// In en, this message translates to:
  /// **'Invoice or LNURL'**
  String get homeInvoiceOrLnurl;

  /// No description provided for @homeBitcoinAddress.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin address'**
  String get homeBitcoinAddress;

  /// No description provided for @homeKeroseneUser.
  ///
  /// In en, this message translates to:
  /// **'Kerosene user'**
  String get homeKeroseneUser;

  /// No description provided for @homePaymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get homePaymentId;

  /// No description provided for @homePaymentLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get homePaymentLinkTitle;

  /// No description provided for @homePayloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get homePayloadLabel;

  /// No description provided for @homePayloadHint.
  ///
  /// In en, this message translates to:
  /// **'Kerosene link, bitcoin:..., lightning:..., or ID'**
  String get homePayloadHint;

  /// No description provided for @homePasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get homePasteAction;

  /// No description provided for @homePayloadActionContinueOnchain.
  ///
  /// In en, this message translates to:
  /// **'Continue on-chain'**
  String get homePayloadActionContinueOnchain;

  /// No description provided for @homePayloadActionContinueLightning.
  ///
  /// In en, this message translates to:
  /// **'Continue Lightning'**
  String get homePayloadActionContinueLightning;

  /// No description provided for @homePayloadActionContinueInternal.
  ///
  /// In en, this message translates to:
  /// **'Continue internal'**
  String get homePayloadActionContinueInternal;

  /// No description provided for @homePayloadActionLoadLink.
  ///
  /// In en, this message translates to:
  /// **'Load link'**
  String get homePayloadActionLoadLink;

  /// No description provided for @homePayloadActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homePayloadActionContinue;

  /// No description provided for @homeAmountFromLink.
  ///
  /// In en, this message translates to:
  /// **'Defined by the link'**
  String get homeAmountFromLink;

  /// No description provided for @homeAmountNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get homeAmountNotProvided;

  /// No description provided for @homeDestinationLocked.
  ///
  /// In en, this message translates to:
  /// **'Protected destination'**
  String get homeDestinationLocked;

  /// No description provided for @homeLoadingLinkData.
  ///
  /// In en, this message translates to:
  /// **'Loading link details'**
  String get homeLoadingLinkData;

  /// No description provided for @homeLinkValidationLater.
  ///
  /// In en, this message translates to:
  /// **'Details will be validated when you continue'**
  String get homeLinkValidationLater;

  /// No description provided for @homeNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get homeNetworkLabel;

  /// No description provided for @homeDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get homeDestinationLabel;

  /// No description provided for @homeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get homeAmountLabel;

  /// No description provided for @homeNetworkInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get homeNetworkInternal;

  /// No description provided for @homeNetworkOnchain.
  ///
  /// In en, this message translates to:
  /// **'On-chain'**
  String get homeNetworkOnchain;

  /// No description provided for @homeNetworkLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get homeNetworkLightning;

  /// No description provided for @homeNetworkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get homeNetworkInvalid;

  /// No description provided for @homeNetworkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get homeNetworkWaiting;

  /// No description provided for @homeEmptyNoWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first wallet'**
  String get homeEmptyNoWalletTitle;

  /// No description provided for @homeEmptyNoWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'You need a wallet to start moving funds.'**
  String get homeEmptyNoWalletDescription;

  /// No description provided for @homeEmptyNoBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add funds to begin'**
  String get homeEmptyNoBalanceTitle;

  /// No description provided for @homeEmptyNoBalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Once the first deposit arrives, your activity appears here.'**
  String get homeEmptyNoBalanceDescription;

  /// No description provided for @homeEmptyNoTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get homeEmptyNoTransactionsTitle;

  /// No description provided for @homeEmptyNoTransactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'New activity will appear automatically in this area.'**
  String get homeEmptyNoTransactionsDescription;

  /// No description provided for @homeDepositAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get homeDepositAction;

  /// No description provided for @homeRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeRefreshAction;

  /// No description provided for @homeFullHistory.
  ///
  /// In en, this message translates to:
  /// **'View full history'**
  String get homeFullHistory;

  /// No description provided for @homeLoadingTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get homeLoadingTransactionsTitle;

  /// No description provided for @homeLoadingTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing your activity.'**
  String get homeLoadingTransactionsSubtitle;

  /// No description provided for @homeOpenReceiveScreen.
  ///
  /// In en, this message translates to:
  /// **'Open receive screen'**
  String get homeOpenReceiveScreen;

  /// No description provided for @homeReceiveActionShort.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get homeReceiveActionShort;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String homeGreetingMorning(String name);

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String homeGreetingAfternoon(String name);

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String homeGreetingEvening(String name);

  /// No description provided for @homeBalanceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL BALANCE'**
  String get homeBalanceTotalLabel;

  /// No description provided for @homeLiveQuoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Live quote'**
  String get homeLiveQuoteLabel;

  /// No description provided for @homeKeroseneWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'KEROSENE WALLET'**
  String get homeKeroseneWalletLabel;

  /// No description provided for @homeOnchainWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'ON-CHAIN WALLET'**
  String get homeOnchainWalletLabel;

  /// No description provided for @homeOtherWalletsLabel.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get homeOtherWalletsLabel;

  /// No description provided for @homeSecurityBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin under your control.'**
  String get homeSecurityBannerTitle;

  /// No description provided for @homeSecurityBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end security to protect what is yours.'**
  String get homeSecurityBannerSubtitle;

  /// No description provided for @homeLearnMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get homeLearnMoreAction;

  /// No description provided for @homeSendBitcoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Bitcoin'**
  String get homeSendBitcoinTitle;

  /// No description provided for @homeSendBitcoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to send your bitcoins.'**
  String get homeSendBitcoinSubtitle;

  /// No description provided for @homeTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String homeTodayAt(String time);

  /// No description provided for @homeCounterpartyTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get homeCounterpartyTo;

  /// No description provided for @homeCounterpartyFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get homeCounterpartyFrom;

  /// No description provided for @authAccountAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account access'**
  String get authAccountAccessTitle;

  /// No description provided for @authAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get authAccountPasswordLabel;

  /// No description provided for @authUsernameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the account username.'**
  String get authUsernameRequiredMessage;

  /// No description provided for @authAccessEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Access account'**
  String get authAccessEyebrow;

  /// No description provided for @authUsernameStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First enter your username.'**
  String get authUsernameStepSubtitle;

  /// No description provided for @authUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameHint;

  /// No description provided for @authPasskeyFirstNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected access'**
  String get authPasskeyFirstNoteTitle;

  /// No description provided for @authPasskeyFirstNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Kerosene checks this device key first.'**
  String get authPasskeyFirstNoteBody;

  /// No description provided for @authPrivateAccessEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Private access'**
  String get authPrivateAccessEyebrow;

  /// No description provided for @authAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get authAccountPasswordTitle;

  /// No description provided for @authAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authAccountPasswordHint;

  /// No description provided for @authCredentialSendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get authCredentialSendingTitle;

  /// No description provided for @authCredentialTitle.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get authCredentialTitle;

  /// No description provided for @authCredentialSendingBody.
  ///
  /// In en, this message translates to:
  /// **'We are protecting your sign-in. Please wait a moment.'**
  String get authCredentialSendingBody;

  /// No description provided for @authCredentialBody.
  ///
  /// In en, this message translates to:
  /// **'Use the account password to continue. Your wallet keys are never requested in this sign-in.'**
  String get authCredentialBody;

  /// No description provided for @authSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// No description provided for @authFlowInterruptedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not continue'**
  String get authFlowInterruptedTitle;

  /// No description provided for @authInvalidUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid username'**
  String get authInvalidUsernameTitle;

  /// No description provided for @authWeakPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get authWeakPasswordTitle;

  /// No description provided for @authInvalidConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid confirmation'**
  String get authInvalidConfirmationTitle;

  /// No description provided for @authPasswordMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The password confirmation does not match.'**
  String get authPasswordMismatchMessage;

  /// No description provided for @authConfirmationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation required'**
  String get authConfirmationRequiredTitle;

  /// No description provided for @authPasswordRiskRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you understand the importance of keeping the account password safe.'**
  String get authPasswordRiskRequiredMessage;

  /// No description provided for @authAccountEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authAccountEyebrow;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountTitle;

  /// No description provided for @authCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Kerosene access credentials.'**
  String get authCreateAccountSubtitle;

  /// No description provided for @authSignupUsernameSubtitleDetailed.
  ///
  /// In en, this message translates to:
  /// **'Choose a username. It will be used to identify you in Kerosene.'**
  String get authSignupUsernameSubtitleDetailed;

  /// No description provided for @authSignupUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authSignupUsernameLabel;

  /// No description provided for @authSignupUsernameRuleMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum of 3 characters'**
  String get authSignupUsernameRuleMin;

  /// No description provided for @authSignupUsernameRuleCharset.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters (a-z), numbers (0-9), and underscore (_)'**
  String get authSignupUsernameRuleCharset;

  /// No description provided for @authSignupUsernameRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'It will be shown in lowercase'**
  String get authSignupUsernameRuleLowercase;

  /// No description provided for @authUsernameMinError.
  ///
  /// In en, this message translates to:
  /// **'Use at least 3 characters.'**
  String get authUsernameMinError;

  /// No description provided for @authUsernameCharsError.
  ///
  /// In en, this message translates to:
  /// **'Use only lowercase letters, numbers, and underscores.'**
  String get authUsernameCharsError;

  /// No description provided for @authPasswordStrengthMessage.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters with uppercase, lowercase, number, and symbol.'**
  String get authPasswordStrengthMessage;

  /// No description provided for @authSignupPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a strong passphrase'**
  String get authSignupPassphraseTitle;

  /// No description provided for @authSignupPassphraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It protects your account and assets. Nobody at Kerosene has access to it.'**
  String get authSignupPassphraseSubtitle;

  /// No description provided for @authSignupPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get authSignupPassphraseLabel;

  /// No description provided for @authSignupPassphraseRuleMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum of 12 characters'**
  String get authSignupPassphraseRuleMin;

  /// No description provided for @authSignupPassphraseRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase letter'**
  String get authSignupPassphraseRuleUppercase;

  /// No description provided for @authSignupPassphraseRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 lowercase letter'**
  String get authSignupPassphraseRuleLowercase;

  /// No description provided for @authSignupPassphraseRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'At least 1 number'**
  String get authSignupPassphraseRuleNumber;

  /// No description provided for @authSignupPassphraseRuleSymbol.
  ///
  /// In en, this message translates to:
  /// **'At least 1 symbol'**
  String get authSignupPassphraseRuleSymbol;

  /// No description provided for @authSignupConfirmPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your passphrase'**
  String get authSignupConfirmPassphraseTitle;

  /// No description provided for @authSignupConfirmPassphraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type it again to confirm.'**
  String get authSignupConfirmPassphraseSubtitle;

  /// No description provided for @authSignupConfirmPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get authSignupConfirmPassphraseLabel;

  /// No description provided for @authSignupPassphraseRiskAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand that my passphrase is the only way to access my account. Kerosene cannot reset or recover it. If I lose my passphrase, I may permanently lose access to my assets.'**
  String get authSignupPassphraseRiskAcknowledgement;

  /// No description provided for @authSignupCreatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating your account securely'**
  String get authSignupCreatingTitle;

  /// No description provided for @authSignupCreatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This may take a few seconds.'**
  String get authSignupCreatingSubtitle;

  /// No description provided for @authSignupCreatingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Getting security challenge'**
  String get authSignupCreatingChallenge;

  /// No description provided for @authSignupCreatingPow.
  ///
  /// In en, this message translates to:
  /// **'Solving proof of work'**
  String get authSignupCreatingPow;

  /// No description provided for @authSignupCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get authSignupCreatingAccount;

  /// No description provided for @authSignupPowNote.
  ///
  /// In en, this message translates to:
  /// **'Proof of work helps protect our network from abuse and bots.'**
  String get authSignupPowNote;

  /// No description provided for @authSignupTotpOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your account even more (optional)'**
  String get authSignupTotpOptionalTitle;

  /// No description provided for @authSignupTotpOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable TOTP for an extra security layer.'**
  String get authSignupTotpOptionalSubtitle;

  /// No description provided for @authSignupTotpScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code with your authenticator app'**
  String get authSignupTotpScanInstruction;

  /// No description provided for @authSignupTotpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get authSignupTotpCodeLabel;

  /// No description provided for @authSignupRecoveryCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get authSignupRecoveryCodesTitle;

  /// No description provided for @authSignupRecoveryCodesBody.
  ///
  /// In en, this message translates to:
  /// **'Store them somewhere safe. They can be used to recover your account.'**
  String get authSignupRecoveryCodesBody;

  /// No description provided for @authSignupSkipForNowAction.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get authSignupSkipForNowAction;

  /// No description provided for @authSignupConfirmTotpAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm TOTP'**
  String get authSignupConfirmTotpAction;

  /// No description provided for @authSignupPasskeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Register passkey on this device'**
  String get authSignupPasskeyTitle;

  /// No description provided for @authSignupPasskeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A passkey is required to guarantee secure access to your account.'**
  String get authSignupPasskeySubtitle;

  /// No description provided for @authSignupPasskeyBiometricBullet.
  ///
  /// In en, this message translates to:
  /// **'Use your biometrics or screen lock'**
  String get authSignupPasskeyBiometricBullet;

  /// No description provided for @authSignupPasskeyPasswordBullet.
  ///
  /// In en, this message translates to:
  /// **'More secure than traditional passwords'**
  String get authSignupPasskeyPasswordBullet;

  /// No description provided for @authSignupPasskeyDeviceBullet.
  ///
  /// In en, this message translates to:
  /// **'Only this device will have access'**
  String get authSignupPasskeyDeviceBullet;

  /// No description provided for @authSignupRegisterPasskeyAction.
  ///
  /// In en, this message translates to:
  /// **'Register passkey'**
  String get authSignupRegisterPasskeyAction;

  /// No description provided for @authSignupSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get authSignupSuccessTitle;

  /// No description provided for @authSignupSuccessPreparingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your access securely.'**
  String get authSignupSuccessPreparingSubtitle;

  /// No description provided for @authSignupSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to your wallet...'**
  String get authSignupSuccessSubtitle;

  /// No description provided for @authSignupTotpCodeRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit TOTP code to confirm.'**
  String get authSignupTotpCodeRequiredMessage;

  /// No description provided for @authAccountCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and credentials'**
  String get authAccountCredentialsTitle;

  /// No description provided for @authAccountCredentialsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your public identifier. The password comes in the next step.'**
  String get authAccountCredentialsBody;

  /// No description provided for @authCustodyNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it carefully'**
  String get authCustodyNoteTitle;

  /// No description provided for @authCustodyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'If you lose the password without recovery codes, account access may be lost. Keep the codes in a safe place.'**
  String get authCustodyNoteBody;

  /// No description provided for @authStrongPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get authStrongPasswordTitle;

  /// No description provided for @authStrongPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Use a long, unique password that is hard to guess.'**
  String get authStrongPasswordBody;

  /// No description provided for @authPasswordReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get authPasswordReadyTitle;

  /// No description provided for @authPasswordMinimumTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum rule'**
  String get authPasswordMinimumTitle;

  /// No description provided for @authPasswordRuleBody.
  ///
  /// In en, this message translates to:
  /// **'12 characters or more, with uppercase, lowercase, number, and symbol.'**
  String get authPasswordRuleBody;

  /// No description provided for @authBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBackAction;

  /// No description provided for @authReadyAction.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get authReadyAction;

  /// No description provided for @authConfirmPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordTitle;

  /// No description provided for @authConfirmPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password and confirm that you know where to keep it.'**
  String get authConfirmPasswordBody;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authPasswordRiskAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand that losing the password may prevent my account access.'**
  String get authPasswordRiskAcknowledgement;

  /// No description provided for @authCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get authCreateAction;

  /// No description provided for @authPasskeyRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register device key'**
  String get authPasskeyRegisterTitle;

  /// No description provided for @authPasskeyRegisterBody.
  ///
  /// In en, this message translates to:
  /// **'Finish by creating this device\'s secure key to protect access.'**
  String get authPasskeyRegisterBody;

  /// No description provided for @authDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get authDeviceTitle;

  /// No description provided for @authDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'This device key helps confirm it is you when signing in.'**
  String get authDeviceBody;

  /// No description provided for @authRegisterPasskeyAction.
  ///
  /// In en, this message translates to:
  /// **'Register key'**
  String get authRegisterPasskeyAction;

  /// No description provided for @authPasskeyStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get authPasskeyStepLabel;

  /// No description provided for @authSignupStepFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get authSignupStepFallbackLabel;

  /// No description provided for @authSignupStepUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authSignupStepUsernameTitle;

  /// No description provided for @authSignupStepPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authSignupStepPasswordTitle;

  /// No description provided for @authSignupStepConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get authSignupStepConfirmationTitle;

  /// No description provided for @authSignupStepCreationTitle.
  ///
  /// In en, this message translates to:
  /// **'Creation'**
  String get authSignupStepCreationTitle;

  /// No description provided for @authPasswordLongHint.
  ///
  /// In en, this message translates to:
  /// **'12 characters or more'**
  String get authPasswordLongHint;

  /// No description provided for @authSessionInterruptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session interrupted'**
  String get authSessionInterruptedTitle;

  /// No description provided for @authSignupSessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your signup session expired. Restart account creation to continue safely.'**
  String get authSignupSessionExpiredMessage;

  /// No description provided for @authSecurityPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing security'**
  String get authSecurityPreparingTitle;

  /// No description provided for @authSecurityPreparingMessage.
  ///
  /// In en, this message translates to:
  /// **'Account protection is still being prepared. Try again in a few seconds.'**
  String get authSecurityPreparingMessage;

  /// No description provided for @homeFallbackUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get homeFallbackUser;

  /// No description provided for @walletEditNameAction.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get walletEditNameAction;

  /// No description provided for @securityCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get securityCopiedTitle;

  /// No description provided for @securityCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to the clipboard.'**
  String securityCopiedMessage(String label);

  /// No description provided for @securityTotpFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not update the authenticator'**
  String get securityTotpFailureTitle;

  /// No description provided for @securityInvalidCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get securityInvalidCodeTitle;

  /// No description provided for @securityTotpCodeRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6 digits from the authenticator.'**
  String get securityTotpCodeRequiredMessage;

  /// No description provided for @securityTotpEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticator enabled'**
  String get securityTotpEnabledTitle;

  /// No description provided for @securityTotpEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account now has an additional protection layer.'**
  String get securityTotpEnabledMessage;

  /// No description provided for @securityTotpDisableFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not disable the authenticator'**
  String get securityTotpDisableFailedTitle;

  /// No description provided for @securityTotpDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticator disabled'**
  String get securityTotpDisabledTitle;

  /// No description provided for @securityTotpDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Authenticator protection was removed from this account.'**
  String get securityTotpDisabledMessage;

  /// No description provided for @securityBackupRegenerateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not generate new codes'**
  String get securityBackupRegenerateFailedTitle;

  /// No description provided for @securityBackupCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get securityBackupCodesTitle;

  /// No description provided for @securityBackupCodesBody.
  ///
  /// In en, this message translates to:
  /// **'Keep these codes outside this device. They can help recover access.'**
  String get securityBackupCodesBody;

  /// No description provided for @securityBackupCodesCopyLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get securityBackupCodesCopyLabel;

  /// No description provided for @securityBackupCodesCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy codes'**
  String get securityBackupCodesCopyAction;

  /// No description provided for @securityRegisterDeviceFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not register the device'**
  String get securityRegisterDeviceFailedTitle;

  /// No description provided for @securityDeviceRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Device registered'**
  String get securityDeviceRegisteredTitle;

  /// No description provided for @securityDeviceRegisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'This device is now linked to your account.'**
  String get securityDeviceRegisteredMessage;

  /// No description provided for @securityDeviceInventoryLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The account has an authenticated device, but details are still loading.'**
  String get securityDeviceInventoryLoadingSubtitle;

  /// No description provided for @securityRegisterDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register this device as an authenticated device.'**
  String get securityRegisterDeviceSubtitle;

  /// No description provided for @securityCompatibleDeviceOne.
  ///
  /// In en, this message translates to:
  /// **'There is 1 device compatible with this sign-in.'**
  String get securityCompatibleDeviceOne;

  /// No description provided for @securityCompatibleDeviceMany.
  ///
  /// In en, this message translates to:
  /// **'There are {count} devices compatible with this sign-in.'**
  String securityCompatibleDeviceMany(int count);

  /// No description provided for @securityLegacyDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Some older devices have limited compatibility. Link this device again if access fails.'**
  String get securityLegacyDeviceSubtitle;

  /// No description provided for @securityNoCompatibleDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Registered devices are not compatible with this sign-in. Sign in with password and authenticator to link another.'**
  String get securityNoCompatibleDeviceSubtitle;

  /// No description provided for @securityScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityScreenTitle;

  /// No description provided for @securityScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticated devices, authenticator, recovery codes, and this device PIN.'**
  String get securityScreenSubtitle;

  /// No description provided for @securityUnprotectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not protected'**
  String get securityUnprotectedTitle;

  /// No description provided for @securityUnprotectedFallback.
  ///
  /// In en, this message translates to:
  /// **'Enable the authenticator to add an optional protection layer.'**
  String get securityUnprotectedFallback;

  /// No description provided for @securityPinEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry PIN'**
  String get securityPinEntryTitle;

  /// No description provided for @securityPinLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not check the PIN for this device.'**
  String get securityPinLoadError;

  /// No description provided for @securityAuthenticatedDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticated devices'**
  String get securityAuthenticatedDevicesTitle;

  /// No description provided for @securityRegisteredDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This device is registered for this account.'**
  String get securityRegisteredDeviceSubtitle;

  /// No description provided for @securityRegisterThisDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register this device.'**
  String get securityRegisterThisDeviceSubtitle;

  /// No description provided for @securityLinkNewDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Link new device'**
  String get securityLinkNewDeviceAction;

  /// No description provided for @securityRegisterDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Register device'**
  String get securityRegisterDeviceAction;

  /// No description provided for @securityDeviceCompatibilityError.
  ///
  /// In en, this message translates to:
  /// **'We could not check device compatibility for this sign-in.'**
  String get securityDeviceCompatibilityError;

  /// No description provided for @securityTotpOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional authenticator'**
  String get securityTotpOptionalTitle;

  /// No description provided for @securityTotpEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticator active. The unprotected account notice is hidden.'**
  String get securityTotpEnabledSubtitle;

  /// No description provided for @securityTotpDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No authenticator. The account is marked as not protected.'**
  String get securityTotpDisabledSubtitle;

  /// No description provided for @securityDisableTotpAction.
  ///
  /// In en, this message translates to:
  /// **'Disable authenticator'**
  String get securityDisableTotpAction;

  /// No description provided for @securityEnableTotpAction.
  ///
  /// In en, this message translates to:
  /// **'Enable authenticator'**
  String get securityEnableTotpAction;

  /// No description provided for @securityBackupCodesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} codes remaining. Keep them in a safe place.'**
  String securityBackupCodesRemaining(int count);

  /// No description provided for @securityBackupCodesLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable the authenticator to unlock recovery codes.'**
  String get securityBackupCodesLockedSubtitle;

  /// No description provided for @securityRegenerateCodesAction.
  ///
  /// In en, this message translates to:
  /// **'Generate new codes'**
  String get securityRegenerateCodesAction;

  /// No description provided for @securityWaitingTotpAction.
  ///
  /// In en, this message translates to:
  /// **'Waiting for authenticator'**
  String get securityWaitingTotpAction;

  /// No description provided for @securityViewLatestAction.
  ///
  /// In en, this message translates to:
  /// **'View latest'**
  String get securityViewLatestAction;

  /// No description provided for @securityBackupCodesLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not check recovery codes.'**
  String get securityBackupCodesLoadError;

  /// No description provided for @securityStatusLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not check account security status.'**
  String get securityStatusLoadError;

  /// No description provided for @securityCurrentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get securityCurrentStatusTitle;

  /// No description provided for @securityStrongPasswordPill.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get securityStrongPasswordPill;

  /// No description provided for @securityDevicePill.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get securityDevicePill;

  /// No description provided for @securityInboundPill.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get securityInboundPill;

  /// No description provided for @securityAppPinPill.
  ///
  /// In en, this message translates to:
  /// **'Entry PIN'**
  String get securityAppPinPill;

  /// No description provided for @securityLocalBiometricsPill.
  ///
  /// In en, this message translates to:
  /// **'Local biometrics'**
  String get securityLocalBiometricsPill;

  /// No description provided for @securityCurrentHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Current device'**
  String get securityCurrentHostLabel;

  /// No description provided for @securityCurrentRpLabel.
  ///
  /// In en, this message translates to:
  /// **'Access domain'**
  String get securityCurrentRpLabel;

  /// No description provided for @securityLegacyCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Older credentials detected'**
  String get securityLegacyCredentialsTitle;

  /// No description provided for @securityLegacyCredentialsBody.
  ///
  /// In en, this message translates to:
  /// **'Some older devices have incomplete details. Replace them with a new key when possible.'**
  String get securityLegacyCredentialsBody;

  /// No description provided for @securityNoAuthenticatedDevice.
  ///
  /// In en, this message translates to:
  /// **'No authenticated device has been linked for this account in this context.'**
  String get securityNoAuthenticatedDevice;

  /// No description provided for @securityDeviceDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The device is active, but details are not available yet.'**
  String get securityDeviceDetailsUnavailable;

  /// No description provided for @securityInventoryNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Device details have not loaded yet.'**
  String get securityInventoryNotLoaded;

  /// No description provided for @securityInventoryNone.
  ///
  /// In en, this message translates to:
  /// **'No authenticated device registered for this account.'**
  String get securityInventoryNone;

  /// No description provided for @securityInventoryCompatible.
  ///
  /// In en, this message translates to:
  /// **'At least one authenticated device can be used for this sign-in.'**
  String get securityInventoryCompatible;

  /// No description provided for @securityInventoryLegacy.
  ///
  /// In en, this message translates to:
  /// **'Some devices have incomplete details. Review the list before relying on them.'**
  String get securityInventoryLegacy;

  /// No description provided for @securityInventoryIncompatible.
  ///
  /// In en, this message translates to:
  /// **'The currently linked devices cannot be used for this sign-in.'**
  String get securityInventoryIncompatible;

  /// No description provided for @securityInventoryUnknownBanner.
  ///
  /// In en, this message translates to:
  /// **'We could not determine whether this sign-in has a usable device.'**
  String get securityInventoryUnknownBanner;

  /// No description provided for @securityInventoryRegisterBanner.
  ///
  /// In en, this message translates to:
  /// **'Link this device to enable compatible confirmations and sign-in.'**
  String get securityInventoryRegisterBanner;

  /// No description provided for @securityInventoryCompatibleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices can confirm this sign-in now.'**
  String securityInventoryCompatibleCount(int count);

  /// No description provided for @securityInventoryCompatibleFallback.
  ///
  /// In en, this message translates to:
  /// **'There is at least one device compatible with this sign-in.'**
  String get securityInventoryCompatibleFallback;

  /// No description provided for @securityInventoryLegacyBanner.
  ///
  /// In en, this message translates to:
  /// **'There are older credentials. If this sign-in fails, use password and authenticator to link this device again.'**
  String get securityInventoryLegacyBanner;

  /// No description provided for @securityInventoryIncompatibleBanner.
  ///
  /// In en, this message translates to:
  /// **'No compatible device was found for this access. Sign in with password and authenticator to link another.'**
  String get securityInventoryIncompatibleBanner;

  /// No description provided for @securityPinActiveLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entry PIN is active. It is temporarily locked on this device.'**
  String get securityPinActiveLockedSubtitle;

  /// No description provided for @securityPinActiveAttemptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entry PIN is active. {count} attempts remain before lockout.'**
  String securityPinActiveAttemptsSubtitle(int count);

  /// No description provided for @securityPinDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect app entry on this device with a PIN independent from your main password.'**
  String get securityPinDisabledSubtitle;

  /// No description provided for @securityChangePinAction.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePinAction;

  /// No description provided for @securityEnablePinAction.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN'**
  String get securityEnablePinAction;

  /// No description provided for @securityDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get securityDisableAction;

  /// No description provided for @securityPinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'The new PIN and confirmation must match.'**
  String get securityPinMismatchError;

  /// No description provided for @securityPinEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable entry PIN'**
  String get securityPinEnableTitle;

  /// No description provided for @securityPinChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change this device PIN'**
  String get securityPinChangeTitle;

  /// No description provided for @securityPinDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable entry PIN'**
  String get securityPinDisableTitle;

  /// No description provided for @securityPinEnableBody.
  ///
  /// In en, this message translates to:
  /// **'The PIN will be required whenever the app opens with this session on this device.'**
  String get securityPinEnableBody;

  /// No description provided for @securityPinChangeBody.
  ///
  /// In en, this message translates to:
  /// **'Use the current PIN or an authenticator code to set a new PIN.'**
  String get securityPinChangeBody;

  /// No description provided for @securityPinDisableBody.
  ///
  /// In en, this message translates to:
  /// **'Use the current PIN or an authenticator code to remove this device entry barrier.'**
  String get securityPinDisableBody;

  /// No description provided for @securityCurrentPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN or authenticator code'**
  String get securityCurrentPinLabel;

  /// No description provided for @securityTotpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get securityTotpCodeLabel;

  /// No description provided for @securityNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN ({min}-{max} digits)'**
  String securityNewPinLabel(int min, int max);

  /// No description provided for @securityConfirmNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get securityConfirmNewPinLabel;

  /// No description provided for @securityDisablePinAction.
  ///
  /// In en, this message translates to:
  /// **'Disable PIN'**
  String get securityDisablePinAction;

  /// No description provided for @securitySavePinAction.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get securitySavePinAction;

  /// No description provided for @securityDeviceBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get securityDeviceBrandLabel;

  /// No description provided for @securityDeviceModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get securityDeviceModelLabel;

  /// No description provided for @securityDeviceSerialLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get securityDeviceSerialLabel;

  /// No description provided for @securityDeviceInstallIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Installation ID'**
  String get securityDeviceInstallIdLabel;

  /// No description provided for @securityDeviceBrowserLabel.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get securityDeviceBrowserLabel;

  /// No description provided for @securityDeviceSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get securityDeviceSystemLabel;

  /// No description provided for @securityDeviceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get securityDeviceStatusLabel;

  /// No description provided for @securityDeviceFirstAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'First access'**
  String get securityDeviceFirstAccessLabel;

  /// No description provided for @securityDeviceLastAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Last access'**
  String get securityDeviceLastAccessLabel;

  /// No description provided for @securityDeviceOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get securityDeviceOriginLabel;

  /// No description provided for @securityDeviceRelyingPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access domain'**
  String get securityDeviceRelyingPartyLabel;

  /// No description provided for @securityDeviceCanUse.
  ///
  /// In en, this message translates to:
  /// **'Can be used for this sign-in.'**
  String get securityDeviceCanUse;

  /// No description provided for @securityDeviceCannotUse.
  ///
  /// In en, this message translates to:
  /// **'Cannot be used for the current sign-in.'**
  String get securityDeviceCannotUse;

  /// No description provided for @securityDeviceUnknownUse.
  ///
  /// In en, this message translates to:
  /// **'Compatibility has not been determined for this credential yet.'**
  String get securityDeviceUnknownUse;

  /// No description provided for @securityDeviceBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get securityDeviceBlockAction;

  /// No description provided for @securityDeviceRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get securityDeviceRevokeAction;

  /// No description provided for @securityDeviceBlockFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not block the device'**
  String get securityDeviceBlockFailedTitle;

  /// No description provided for @securityDeviceRevokeFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not revoke the device'**
  String get securityDeviceRevokeFailedTitle;

  /// No description provided for @securityDeviceBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Device blocked'**
  String get securityDeviceBlockedTitle;

  /// No description provided for @securityDeviceBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This credential cannot confirm new sign-ins until it is reactivated in the backend.'**
  String get securityDeviceBlockedMessage;

  /// No description provided for @securityDeviceRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Device revoked'**
  String get securityDeviceRevokedTitle;

  /// No description provided for @securityDeviceRevokedMessage.
  ///
  /// In en, this message translates to:
  /// **'This credential was removed from the authenticated device set.'**
  String get securityDeviceRevokedMessage;

  /// No description provided for @securityStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get securityStatusPending;

  /// No description provided for @securityStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get securityStatusBlocked;

  /// No description provided for @securityStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get securityStatusRevoked;

  /// No description provided for @securityStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get securityStatusActive;

  /// No description provided for @securityCompatibleBadge.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get securityCompatibleBadge;

  /// No description provided for @securityIncompatibleBadge.
  ///
  /// In en, this message translates to:
  /// **'Incompatible'**
  String get securityIncompatibleBadge;

  /// No description provided for @securityUnknownBadge.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get securityUnknownBadge;

  /// No description provided for @securityTotpSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable authenticator'**
  String get securityTotpSetupTitle;

  /// No description provided for @securityCopySecretAction.
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get securityCopySecretAction;

  /// No description provided for @securityValidateTotpAction.
  ///
  /// In en, this message translates to:
  /// **'Validate code'**
  String get securityValidateTotpAction;

  /// No description provided for @settingsUiSecurityAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Security and access'**
  String get settingsUiSecurityAccessSection;

  /// No description provided for @settingsUiEnterpriseAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Enterprise access'**
  String get settingsUiEnterpriseAccessSection;

  /// No description provided for @settingsUiPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsUiPrivacySection;

  /// No description provided for @settingsUiAccountAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Account and access'**
  String get settingsUiAccountAccessSection;

  /// No description provided for @settingsUiNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsUiNotificationsSection;

  /// No description provided for @settingsUiAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsUiAppearanceSection;

  /// No description provided for @settingsUiLocaleCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'Language and currency'**
  String get settingsUiLocaleCurrencySection;

  /// No description provided for @settingsUiSessionSection.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get settingsUiSessionSection;

  /// No description provided for @settingsUiOperationalSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational summary'**
  String get settingsUiOperationalSummaryTitle;

  /// No description provided for @settingsUiAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsUiAlertsLabel;

  /// No description provided for @settingsUiAlertsBackgroundActive.
  ///
  /// In en, this message translates to:
  /// **'Background active'**
  String get settingsUiAlertsBackgroundActive;

  /// No description provided for @settingsUiDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsUiDisabled;

  /// No description provided for @settingsUiThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsUiThemeLabel;

  /// No description provided for @settingsUiChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get settingsUiChecking;

  /// No description provided for @settingsUiActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsUiActive;

  /// No description provided for @settingsUiInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get settingsUiInactive;

  /// No description provided for @settingsUiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settingsUiUnavailable;

  /// No description provided for @settingsUiDecimalPrecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Decimal precision'**
  String get settingsUiDecimalPrecisionTitle;

  /// No description provided for @settingsUiDecimalPrecisionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} decimal places'**
  String settingsUiDecimalPrecisionSubtitle(int count);

  /// No description provided for @settingsUiHideBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get settingsUiHideBalanceTitle;

  /// No description provided for @settingsUiBalanceHiddenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Values are masked on the main interface'**
  String get settingsUiBalanceHiddenSubtitle;

  /// No description provided for @settingsUiBalanceVisibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Values are visible on operational screens'**
  String get settingsUiBalanceVisibleSubtitle;

  /// No description provided for @settingsUiSovereigntyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereignty report'**
  String get settingsUiSovereigntyReportTitle;

  /// No description provided for @settingsUiSovereigntyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the attestation, consensus, and operational integrity panel'**
  String get settingsUiSovereigntyReportSubtitle;

  /// No description provided for @settingsUiSecurityUnprotectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account not protected. Review authenticator and recovery codes.'**
  String get settingsUiSecurityUnprotectedSubtitle;

  /// No description provided for @settingsUiSecurityProtectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account protected with strong password, authenticated devices, and optional factors.'**
  String get settingsUiSecurityProtectedSubtitle;

  /// No description provided for @settingsUiSecurityLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking account status'**
  String get settingsUiSecurityLoadingSubtitle;

  /// No description provided for @settingsUiSecurityErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We could not check account security'**
  String get settingsUiSecurityErrorSubtitle;

  /// No description provided for @settingsUiPasskeyRegisteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticated device already registered for this account'**
  String get settingsUiPasskeyRegisteredSubtitle;

  /// No description provided for @settingsUiPasskeyRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register this device with biometrics'**
  String get settingsUiPasskeyRegisterSubtitle;

  /// No description provided for @settingsUiPasskeyLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking devices'**
  String get settingsUiPasskeyLoadingSubtitle;

  /// No description provided for @settingsUiPasskeyErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We could not check devices'**
  String get settingsUiPasskeyErrorSubtitle;

  /// No description provided for @settingsUiUnprotectedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not protected'**
  String get settingsUiUnprotectedBannerTitle;

  /// No description provided for @settingsUiUnprotectedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'The authenticator is off. Open Security Center to enable protection and review recovery codes.'**
  String get settingsUiUnprotectedBannerBody;

  /// No description provided for @settingsUiBiometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settingsUiBiometricUnlockTitle;

  /// No description provided for @settingsUiBiometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to unlock'**
  String get settingsUiBiometricUnlockSubtitle;

  /// No description provided for @settingsUiSecurityCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Security center'**
  String get settingsUiSecurityCenterTitle;

  /// No description provided for @settingsUiSessionsActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get settingsUiSessionsActiveTitle;

  /// No description provided for @settingsUiSessionsActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and revoke device sessions'**
  String get settingsUiSessionsActiveSubtitle;

  /// No description provided for @settingsUiSessionsActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your sessions are protected automatically. End access on this device if it is no longer with you.'**
  String get settingsUiSessionsActiveMessage;

  /// No description provided for @settingsUiEnterpriseIntro.
  ///
  /// In en, this message translates to:
  /// **'For enterprise use, generate an access key on this device and keep it safe.'**
  String get settingsUiEnterpriseIntro;

  /// No description provided for @settingsUiEnterpriseKeyLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking enterprise key...'**
  String get settingsUiEnterpriseKeyLoading;

  /// No description provided for @settingsUiEnterpriseKeyLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not check the enterprise key.'**
  String get settingsUiEnterpriseKeyLoadError;

  /// No description provided for @settingsUiEnterpriseCreateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create enterprise key'**
  String get settingsUiEnterpriseCreateKeyTitle;

  /// No description provided for @settingsUiEnterpriseCreateKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generates a strong key on this device and registers only the secure confirmation'**
  String get settingsUiEnterpriseCreateKeySubtitle;

  /// No description provided for @settingsUiEnterpriseRotateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change key'**
  String get settingsUiEnterpriseRotateKeyTitle;

  /// No description provided for @settingsUiEnterpriseRotateKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revokes the current key and creates a new one'**
  String get settingsUiEnterpriseRotateKeySubtitle;

  /// No description provided for @settingsUiEnterpriseRevokeKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke key'**
  String get settingsUiEnterpriseRevokeKeyTitle;

  /// No description provided for @settingsUiEnterpriseRevokeKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blocks new enterprise access until a new key is created'**
  String get settingsUiEnterpriseRevokeKeySubtitle;

  /// No description provided for @settingsUiEnterpriseCreateDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This key authorizes enterprise access together with username and password. Keep it safe. Kerosene will never ask for your seed or recovery phrase.'**
  String get settingsUiEnterpriseCreateDialogMessage;

  /// No description provided for @settingsUiEnterpriseCreateKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Create key'**
  String get settingsUiEnterpriseCreateKeyAction;

  /// No description provided for @settingsUiEnterpriseCreateKeyFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not create the key'**
  String get settingsUiEnterpriseCreateKeyFailed;

  /// No description provided for @settingsUiEnterpriseRevokeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The current key will no longer authorize enterprise access. Create a new one on this device when you need to reactivate it.'**
  String get settingsUiEnterpriseRevokeDialogMessage;

  /// No description provided for @settingsUiEnterpriseRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get settingsUiEnterpriseRevokeAction;

  /// No description provided for @settingsUiEnterpriseRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not revoke'**
  String get settingsUiEnterpriseRevokeFailed;

  /// No description provided for @settingsUiEnterpriseKeyRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key revoked'**
  String get settingsUiEnterpriseKeyRevokedTitle;

  /// No description provided for @settingsUiEnterpriseKeyRevokedMessage.
  ///
  /// In en, this message translates to:
  /// **'Enterprise access will require a new key.'**
  String get settingsUiEnterpriseKeyRevokedMessage;

  /// No description provided for @settingsUiEnterpriseDecisionFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not register the decision'**
  String get settingsUiEnterpriseDecisionFailed;

  /// No description provided for @settingsUiEnterpriseAccessAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access allowed'**
  String get settingsUiEnterpriseAccessAllowedTitle;

  /// No description provided for @settingsUiEnterpriseDeviceBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Device blocked'**
  String get settingsUiEnterpriseDeviceBlockedTitle;

  /// No description provided for @settingsUiEnterpriseAccessAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'Enterprise access can continue in the browser.'**
  String get settingsUiEnterpriseAccessAllowedMessage;

  /// No description provided for @settingsUiEnterpriseDeviceBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'New attempts from this device were blocked.'**
  String get settingsUiEnterpriseDeviceBlockedMessage;

  /// No description provided for @settingsUiEnterpriseKeyCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key created'**
  String get settingsUiEnterpriseKeyCreatedTitle;

  /// No description provided for @settingsUiEnterpriseKeyCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'This key will only be shown now. Keep it safe.'**
  String get settingsUiEnterpriseKeyCreatedMessage;

  /// No description provided for @settingsUiEnterpriseKeyCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Enterprise key copied.'**
  String get settingsUiEnterpriseKeyCopiedMessage;

  /// No description provided for @settingsUiCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get settingsUiCopyAction;

  /// No description provided for @settingsUiCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsUiCloseAction;

  /// No description provided for @settingsUiEnterpriseKeyActive.
  ///
  /// In en, this message translates to:
  /// **'Key active for enterprise access.'**
  String get settingsUiEnterpriseKeyActive;

  /// No description provided for @settingsUiEnterpriseKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'No active enterprise key.'**
  String get settingsUiEnterpriseKeyMissing;

  /// No description provided for @settingsUiEnterpriseAttemptTitle.
  ///
  /// In en, this message translates to:
  /// **'There was an enterprise access attempt.'**
  String get settingsUiEnterpriseAttemptTitle;

  /// No description provided for @settingsUiBrowserLabel.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get settingsUiBrowserLabel;

  /// No description provided for @settingsUiDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsUiDeviceLabel;

  /// No description provided for @settingsUiTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsUiTimeLabel;

  /// No description provided for @settingsUiAllowAction.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsUiAllowAction;

  /// No description provided for @settingsUiBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get settingsUiBlockAction;

  /// No description provided for @settingsUiAuthenticatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Authenticated'**
  String get settingsUiAuthenticatedLabel;

  /// No description provided for @settingsUiDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsUiDeleteAccountTitle;

  /// No description provided for @settingsUiDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes all data'**
  String get settingsUiDeleteAccountSubtitle;

  /// No description provided for @settingsUiDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsUiDeleteAccountDialogTitle;

  /// No description provided for @settingsUiDeleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account, wallets, and funds. This action cannot be undone.\n\nTo protect your funds, withdraw all balances before deleting the account.'**
  String get settingsUiDeleteAccountDialogMessage;

  /// No description provided for @settingsUiDeleteForeverAction.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get settingsUiDeleteForeverAction;

  /// No description provided for @settingsUiTransactionSecurityAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction and security alerts'**
  String get settingsUiTransactionSecurityAlertsTitle;

  /// No description provided for @settingsUiBackgroundAlertsOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active. The app stays in the background to show transactions and security alerts.'**
  String get settingsUiBackgroundAlertsOnSubtitle;

  /// No description provided for @settingsUiBackgroundAlertsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable to keep the app in the background and receive transaction and security alerts.'**
  String get settingsUiBackgroundAlertsOffSubtitle;

  /// No description provided for @settingsUiInAppBannersTitle.
  ///
  /// In en, this message translates to:
  /// **'In-app banners'**
  String get settingsUiInAppBannersTitle;

  /// No description provided for @settingsUiInAppBannersOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows contextual alerts in the current session.'**
  String get settingsUiInAppBannersOnSubtitle;

  /// No description provided for @settingsUiInAppBannersOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeps the feed, but does not interrupt navigation with banners.'**
  String get settingsUiInAppBannersOffSubtitle;

  /// No description provided for @settingsUiFinancialEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial events'**
  String get settingsUiFinancialEventsTitle;

  /// No description provided for @settingsUiFinancialEventsOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receives, sends, deposits, and links appear in the feed.'**
  String get settingsUiFinancialEventsOnSubtitle;

  /// No description provided for @settingsUiFinancialEventsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides financial operation alerts from the session feed.'**
  String get settingsUiFinancialEventsOffSubtitle;

  /// No description provided for @settingsUiSecurityEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security events'**
  String get settingsUiSecurityEventsTitle;

  /// No description provided for @settingsUiSecurityEventsOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-ins, recovery, and sensitive events remain highlighted.'**
  String get settingsUiSecurityEventsOnSubtitle;

  /// No description provided for @settingsUiSecurityEventsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides only security alerts from the session inbox.'**
  String get settingsUiSecurityEventsOffSubtitle;

  /// No description provided for @settingsUiUpdatingBackgroundAlerts.
  ///
  /// In en, this message translates to:
  /// **'Updating background monitoring.'**
  String get settingsUiUpdatingBackgroundAlerts;

  /// No description provided for @settingsUiBackgroundAlertsInfo.
  ///
  /// In en, this message translates to:
  /// **'When active, Kerosene keeps a background service to monitor sends, receives, and critical security events. On Android, a persistent system notification remains visible while monitoring is on. {count} alerts have not been read in this session.'**
  String settingsUiBackgroundAlertsInfo(int count);

  /// No description provided for @settingsUiPermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get settingsUiPermissionRequiredTitle;

  /// No description provided for @settingsUiPermissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'The system did not allow notifications. Authorize the app to enable background monitoring.'**
  String get settingsUiPermissionRequiredMessage;

  /// No description provided for @settingsUiMonitoringActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring active'**
  String get settingsUiMonitoringActiveTitle;

  /// No description provided for @settingsUiMonitoringInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring disabled'**
  String get settingsUiMonitoringInactiveTitle;

  /// No description provided for @settingsUiMonitoringActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'The app will continue in the background to show transactions and security alerts.'**
  String get settingsUiMonitoringActiveMessage;

  /// No description provided for @settingsUiMonitoringInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Kerosene will no longer keep the background alert service running.'**
  String get settingsUiMonitoringInactiveMessage;

  /// No description provided for @settingsUiAlertsUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not update alerts'**
  String get settingsUiAlertsUpdateFailedTitle;

  /// No description provided for @settingsUiAlertsUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not change background monitoring right now.'**
  String get settingsUiAlertsUpdateFailedMessage;

  /// No description provided for @settingsUiLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsUiLogoutTitle;

  /// No description provided for @settingsUiLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ends the current session'**
  String get settingsUiLogoutSubtitle;

  /// No description provided for @settingsUiLogoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsUiLogoutDialogTitle;

  /// No description provided for @settingsUiLogoutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to authenticate again to access the account.'**
  String get settingsUiLogoutDialogMessage;

  /// No description provided for @settingsUiAuthenticatedDevicesBody.
  ///
  /// In en, this message translates to:
  /// **'This registration uses the device biometric sensor as a physical security key. The details shown use auditable device data without exposing sensitive information.'**
  String get settingsUiAuthenticatedDevicesBody;

  /// No description provided for @settingsUiRegisterNewDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Register new device'**
  String get settingsUiRegisterNewDeviceAction;

  /// No description provided for @settingsUiLearnMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get settingsUiLearnMoreAction;

  /// No description provided for @settingsUiBackgroundAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Background alerts'**
  String get settingsUiBackgroundAlertsTitle;

  /// No description provided for @settingsUiBackgroundAlertsConsentBody.
  ///
  /// In en, this message translates to:
  /// **'When enabled, Kerosene will continue running in the background to show received and sent transactions and critical security alerts. On Android, the system will keep a persistent notification while monitoring is active.'**
  String get settingsUiBackgroundAlertsConsentBody;

  /// No description provided for @settingsUiEnableMonitoringAction.
  ///
  /// In en, this message translates to:
  /// **'Enable monitoring'**
  String get settingsUiEnableMonitoringAction;

  /// No description provided for @settingsUiUnderstoodAction.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get settingsUiUnderstoodAction;

  /// No description provided for @transactionVisualCancelled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get transactionVisualCancelled;

  /// No description provided for @transactionVisualRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get transactionVisualRefund;

  /// No description provided for @transactionVisualFailed.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get transactionVisualFailed;

  /// No description provided for @transactionVisualSwap.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get transactionVisualSwap;

  /// No description provided for @transactionVisualFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get transactionVisualFee;

  /// No description provided for @transactionVisualLightningDeposit.
  ///
  /// In en, this message translates to:
  /// **'Lightning deposit'**
  String get transactionVisualLightningDeposit;

  /// No description provided for @transactionVisualLightningPayment.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment'**
  String get transactionVisualLightningPayment;

  /// No description provided for @transactionVisualLightningReceive.
  ///
  /// In en, this message translates to:
  /// **'Lightning receive'**
  String get transactionVisualLightningReceive;

  /// No description provided for @transactionVisualDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get transactionVisualDeposit;

  /// No description provided for @transactionVisualWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get transactionVisualWithdrawal;

  /// No description provided for @transactionVisualNfcReceive.
  ///
  /// In en, this message translates to:
  /// **'NFC receive'**
  String get transactionVisualNfcReceive;

  /// No description provided for @transactionVisualNfcPayment.
  ///
  /// In en, this message translates to:
  /// **'NFC payment'**
  String get transactionVisualNfcPayment;

  /// No description provided for @transactionVisualQrReceive.
  ///
  /// In en, this message translates to:
  /// **'QR receive'**
  String get transactionVisualQrReceive;

  /// No description provided for @transactionVisualQrPayment.
  ///
  /// In en, this message translates to:
  /// **'QR payment'**
  String get transactionVisualQrPayment;

  /// No description provided for @transactionVisualPaymentLinkReceive.
  ///
  /// In en, this message translates to:
  /// **'Payment link receive'**
  String get transactionVisualPaymentLinkReceive;

  /// No description provided for @transactionVisualPaymentLinkPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment link payment'**
  String get transactionVisualPaymentLinkPayment;

  /// No description provided for @transactionVisualInternalReceive.
  ///
  /// In en, this message translates to:
  /// **'Kerosene receive'**
  String get transactionVisualInternalReceive;

  /// No description provided for @transactionVisualInternalSend.
  ///
  /// In en, this message translates to:
  /// **'Kerosene send'**
  String get transactionVisualInternalSend;

  /// No description provided for @transactionVisualEvent.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get transactionVisualEvent;

  /// No description provided for @transactionVisualOnChainReceive.
  ///
  /// In en, this message translates to:
  /// **'On-chain receive'**
  String get transactionVisualOnChainReceive;

  /// No description provided for @transactionVisualOnChainSend.
  ///
  /// In en, this message translates to:
  /// **'On-chain send'**
  String get transactionVisualOnChainSend;

  /// No description provided for @withdrawUiColdWalletSendBlocked.
  ///
  /// In en, this message translates to:
  /// **'This cold wallet is only monitored in the app. To send, sign the transaction on the device where your keys are kept.'**
  String get withdrawUiColdWalletSendBlocked;

  /// No description provided for @withdrawUiLightningDestinationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a Lightning request or LNURL to continue.'**
  String get withdrawUiLightningDestinationRequired;

  /// No description provided for @withdrawUiLightningDestinationRequiredForFlow.
  ///
  /// In en, this message translates to:
  /// **'Enter a Lightning request or LNURL for this send.'**
  String get withdrawUiLightningDestinationRequiredForFlow;

  /// No description provided for @withdrawUiLightningDestinationWrongFlow.
  ///
  /// In en, this message translates to:
  /// **'The destination is Lightning. Open Lightning send to continue.'**
  String get withdrawUiLightningDestinationWrongFlow;

  /// No description provided for @withdrawUiOnchainDestinationWrongFlow.
  ///
  /// In en, this message translates to:
  /// **'This field received an on-chain address. Use a Lightning request or LNURL.'**
  String get withdrawUiOnchainDestinationWrongFlow;

  /// No description provided for @withdrawUiLightningFieldWrongFlow.
  ///
  /// In en, this message translates to:
  /// **'This field received a Lightning request. Use Lightning send to continue.'**
  String get withdrawUiLightningFieldWrongFlow;

  /// No description provided for @withdrawUiConfiguredNetworkMismatch.
  ///
  /// In en, this message translates to:
  /// **'The address does not belong to the {network} network configured for this wallet.'**
  String withdrawUiConfiguredNetworkMismatch(String network);

  /// No description provided for @withdrawUiNetworkMismatch.
  ///
  /// In en, this message translates to:
  /// **'This address belongs to {detected}, but the wallet is operating on {expected}.'**
  String withdrawUiNetworkMismatch(String detected, String expected);

  /// No description provided for @withdrawUiWaitFeeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Wait for the network fee estimate before reviewing the total send amount.'**
  String get withdrawUiWaitFeeEstimate;

  /// No description provided for @withdrawUiFeeEstimateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not estimate the network fee right now. Try again shortly.'**
  String get withdrawUiFeeEstimateUnavailable;

  /// No description provided for @withdrawUiSecurityTotpRequired.
  ///
  /// In en, this message translates to:
  /// **'This transaction requires your authenticator code and the security factors configured on your account.'**
  String get withdrawUiSecurityTotpRequired;

  /// No description provided for @withdrawUiSecurityPasskeyRequired.
  ///
  /// In en, this message translates to:
  /// **'This transaction requires passkey confirmation before sending.'**
  String get withdrawUiSecurityPasskeyRequired;

  /// No description provided for @withdrawUiDetailNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get withdrawUiDetailNetwork;

  /// No description provided for @withdrawUiDetailSourceWallet.
  ///
  /// In en, this message translates to:
  /// **'Source wallet'**
  String get withdrawUiDetailSourceWallet;

  /// No description provided for @withdrawUiDetailCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get withdrawUiDetailCard;

  /// No description provided for @withdrawUiDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get withdrawUiDetailType;

  /// No description provided for @withdrawUiDetailExecution.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get withdrawUiDetailExecution;

  /// No description provided for @withdrawUiLightningPayment.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment'**
  String get withdrawUiLightningPayment;

  /// No description provided for @withdrawUiOnchainWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'On-chain withdrawal'**
  String get withdrawUiOnchainWithdrawal;

  /// No description provided for @withdrawUiLightningLiquidityChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking Lightning liquidity'**
  String get withdrawUiLightningLiquidityChecking;

  /// No description provided for @withdrawUiSecureWalletSignature.
  ///
  /// In en, this message translates to:
  /// **'Secure wallet signature'**
  String get withdrawUiSecureWalletSignature;

  /// No description provided for @withdrawUiAmountBtc.
  ///
  /// In en, this message translates to:
  /// **'Amount in BTC'**
  String get withdrawUiAmountBtc;

  /// No description provided for @withdrawUiPlatformFeeWithRate.
  ///
  /// In en, this message translates to:
  /// **'Kerosene fee ({rate})'**
  String withdrawUiPlatformFeeWithRate(String rate);

  /// No description provided for @withdrawUiRoutingFeeCap.
  ///
  /// In en, this message translates to:
  /// **'Routing limit'**
  String get withdrawUiRoutingFeeCap;

  /// No description provided for @withdrawUiEstimatedNetworkFee.
  ///
  /// In en, this message translates to:
  /// **'Estimated network fee'**
  String get withdrawUiEstimatedNetworkFee;

  /// No description provided for @withdrawUiNetworkFeeRate.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get withdrawUiNetworkFeeRate;

  /// No description provided for @withdrawUiTotalDebited.
  ///
  /// In en, this message translates to:
  /// **'Total debited'**
  String get withdrawUiTotalDebited;

  /// No description provided for @withdrawUiBalanceBefore.
  ///
  /// In en, this message translates to:
  /// **'Balance before'**
  String get withdrawUiBalanceBefore;

  /// No description provided for @withdrawUiBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Estimated balance after'**
  String get withdrawUiBalanceAfter;

  /// No description provided for @withdrawUiFinalReview.
  ///
  /// In en, this message translates to:
  /// **'Final review'**
  String get withdrawUiFinalReview;

  /// No description provided for @withdrawUiSourceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get withdrawUiSourceFrom;

  /// No description provided for @withdrawUiLightningReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Review the Lightning request and routing limit. The payment will be sent through the best available route.'**
  String get withdrawUiLightningReviewNotice;

  /// No description provided for @withdrawUiOnchainReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Check the on-chain address carefully. After broadcast, a Bitcoin transaction cannot be reversed.'**
  String get withdrawUiOnchainReviewNotice;

  /// No description provided for @withdrawUiAuthIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Authentication was canceled or incomplete.'**
  String get withdrawUiAuthIncomplete;

  /// No description provided for @withdrawUiWalletLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loading wallet to start the send.'**
  String get withdrawUiWalletLoadingSubtitle;

  /// No description provided for @withdrawUiLightningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the Lightning request, review the amount, and confirm the payment.'**
  String get withdrawUiLightningSubtitle;

  /// No description provided for @withdrawUiOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the Bitcoin address, review fees, and confirm the withdrawal.'**
  String get withdrawUiOnchainSubtitle;

  /// No description provided for @withdrawUiRecentLightning.
  ///
  /// In en, this message translates to:
  /// **'Recent Lightning requests'**
  String get withdrawUiRecentLightning;

  /// No description provided for @withdrawUiRecentOnchain.
  ///
  /// In en, this message translates to:
  /// **'Recent addresses'**
  String get withdrawUiRecentOnchain;

  /// No description provided for @withdrawUiContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get withdrawUiContinue;

  /// No description provided for @withdrawUiTreasuryLiquidity.
  ///
  /// In en, this message translates to:
  /// **'Lightning liquidity'**
  String get withdrawUiTreasuryLiquidity;

  /// No description provided for @withdrawUiTreasuryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not validate liquidity in real time on this attempt. Try again shortly.'**
  String get withdrawUiTreasuryUnavailable;

  /// No description provided for @withdrawUiTreasuryState.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get withdrawUiTreasuryState;

  /// No description provided for @withdrawUiTreasuryAvailableLightning.
  ///
  /// In en, this message translates to:
  /// **'Available LN'**
  String get withdrawUiTreasuryAvailableLightning;

  /// No description provided for @withdrawUiTreasuryOutbound.
  ///
  /// In en, this message translates to:
  /// **'Available outbound'**
  String get withdrawUiTreasuryOutbound;

  /// No description provided for @withdrawUiTreasuryOnchainReserve.
  ///
  /// In en, this message translates to:
  /// **'On-chain reserve'**
  String get withdrawUiTreasuryOnchainReserve;

  /// No description provided for @withdrawUiFeeEstimating.
  ///
  /// In en, this message translates to:
  /// **'Estimating...'**
  String get withdrawUiFeeEstimating;

  /// No description provided for @withdrawUiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get withdrawUiUnavailable;

  /// No description provided for @withdrawUiFeeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for fee'**
  String get withdrawUiFeeWaiting;

  /// No description provided for @withdrawUiSelectedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Selected network'**
  String get withdrawUiSelectedNetwork;

  /// No description provided for @withdrawUiRoutingFeeMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum routing fee'**
  String get withdrawUiRoutingFeeMax;

  /// No description provided for @withdrawUiFeeEstimateUnavailableLong.
  ///
  /// In en, this message translates to:
  /// **'We could not estimate the network fee right now. Review again shortly before confirming the send.'**
  String get withdrawUiFeeEstimateUnavailableLong;

  /// No description provided for @withdrawUiEnterAmountForFees.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to calculate the total cost before confirming.'**
  String get withdrawUiEnterAmountForFees;

  /// No description provided for @withdrawUiEquivalentTo.
  ///
  /// In en, this message translates to:
  /// **'Equivalent to {amount}'**
  String withdrawUiEquivalentTo(String amount);

  /// No description provided for @withdrawUiColdWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet'**
  String get withdrawUiColdWalletTitle;

  /// No description provided for @withdrawUiColdWalletBody.
  ///
  /// In en, this message translates to:
  /// **'This cold wallet is monitored for receiving, but withdrawal keys remain outside Kerosene.'**
  String get withdrawUiColdWalletBody;

  /// No description provided for @withdrawUiOperationalExecution.
  ///
  /// In en, this message translates to:
  /// **'Operational execution'**
  String get withdrawUiOperationalExecution;

  /// No description provided for @withdrawUiOnchainOperationalBody.
  ///
  /// In en, this message translates to:
  /// **'On-chain sends are prepared for secure signing before being sent to the Bitcoin network.'**
  String get withdrawUiOnchainOperationalBody;

  /// No description provided for @withdrawUiTreasuryLoadingBody.
  ///
  /// In en, this message translates to:
  /// **'Loading liquidity and reserve before enabling the Lightning payment.'**
  String get withdrawUiTreasuryLoadingBody;

  /// No description provided for @withdrawUiDestinationEmptyOnchain.
  ///
  /// In en, this message translates to:
  /// **'Enter an on-chain Bitcoin address or bitcoin: URI to continue.'**
  String get withdrawUiDestinationEmptyOnchain;

  /// No description provided for @withdrawUiDestinationValidLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning request or LNURL is valid for this send.'**
  String get withdrawUiDestinationValidLightning;

  /// No description provided for @withdrawUiDestinationValidOnchain.
  ///
  /// In en, this message translates to:
  /// **'On-chain address is valid for this send.'**
  String get withdrawUiDestinationValidOnchain;

  /// No description provided for @withdrawUiDestinationValidOnchainNetwork.
  ///
  /// In en, this message translates to:
  /// **'On-chain address is valid for {network}.'**
  String withdrawUiDestinationValidOnchainNetwork(String network);

  /// No description provided for @withdrawUiScreenTitleOnchain.
  ///
  /// In en, this message translates to:
  /// **'Send on-chain'**
  String get withdrawUiScreenTitleOnchain;

  /// No description provided for @withdrawUiScreenTitleLightning.
  ///
  /// In en, this message translates to:
  /// **'Send Lightning'**
  String get withdrawUiScreenTitleLightning;

  /// No description provided for @withdrawUiLiquidityHealthy.
  ///
  /// In en, this message translates to:
  /// **'Lightning sends available'**
  String get withdrawUiLiquidityHealthy;

  /// No description provided for @withdrawUiLiquidityRebalanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Liquidity adjustment recommended'**
  String get withdrawUiLiquidityRebalanceRequired;

  /// No description provided for @withdrawUiLiquidityBlocked.
  ///
  /// In en, this message translates to:
  /// **'Lightning sends paused'**
  String get withdrawUiLiquidityBlocked;

  /// No description provided for @withdrawUiLiquidityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Operational status unavailable'**
  String get withdrawUiLiquidityUnknown;

  /// No description provided for @withdrawUiLiquidityHealthyMessage.
  ///
  /// In en, this message translates to:
  /// **'The Bitcoin reserve covers the Lightning liquidity available for sending.'**
  String get withdrawUiLiquidityHealthyMessage;

  /// No description provided for @withdrawUiLiquidityRebalanceMessage.
  ///
  /// In en, this message translates to:
  /// **'The reserve is adequate, but Lightning liquidity needs adjustment before larger sends.'**
  String get withdrawUiLiquidityRebalanceMessage;

  /// No description provided for @withdrawUiLiquidityBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Lightning payments are paused until the reserve returns to the required level.'**
  String get withdrawUiLiquidityBlockedMessage;

  /// No description provided for @withdrawUiLiquidityUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'We cannot classify liquidity right now. Review the amounts before continuing.'**
  String get withdrawUiLiquidityUnknownMessage;

  /// No description provided for @withdrawUiDestinationHintOnchain.
  ///
  /// In en, this message translates to:
  /// **'Paste the Bitcoin address'**
  String get withdrawUiDestinationHintOnchain;

  /// No description provided for @withdrawUiDestinationHintLightning.
  ///
  /// In en, this message translates to:
  /// **'Paste the Lightning request or LNURL'**
  String get withdrawUiDestinationHintLightning;

  /// No description provided for @withdrawUiPasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get withdrawUiPasteAction;

  /// No description provided for @withdrawUiScanQrTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get withdrawUiScanQrTooltip;

  /// No description provided for @withdrawUiExternalDestinationInstructionLightning.
  ///
  /// In en, this message translates to:
  /// **'Enter a Lightning invoice, LNURL or Lightning address to start the transfer.'**
  String get withdrawUiExternalDestinationInstructionLightning;

  /// No description provided for @withdrawUiExternalDestinationInstructionOnchain.
  ///
  /// In en, this message translates to:
  /// **'Enter the destination Bitcoin address to start the transfer.'**
  String get withdrawUiExternalDestinationInstructionOnchain;

  /// No description provided for @withdrawUiExternalDestinationHintLightning.
  ///
  /// In en, this message translates to:
  /// **'lnbc...'**
  String get withdrawUiExternalDestinationHintLightning;

  /// No description provided for @withdrawUiExternalDestinationHintOnchain.
  ///
  /// In en, this message translates to:
  /// **'bc1...'**
  String get withdrawUiExternalDestinationHintOnchain;

  /// No description provided for @withdrawUiDestinationFallback.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get withdrawUiDestinationFallback;

  /// No description provided for @withdrawUiEstimatedSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get withdrawUiEstimatedSeconds;

  /// No description provided for @withdrawUiEstimatedTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'~10 min'**
  String get withdrawUiEstimatedTenMinutes;

  /// No description provided for @withdrawUiReviewPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Review payment'**
  String get withdrawUiReviewPaymentTitle;

  /// No description provided for @withdrawUiReviewSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Review send'**
  String get withdrawUiReviewSendTitle;

  /// No description provided for @withdrawUiReviewDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the details before confirming.'**
  String get withdrawUiReviewDetailsSubtitle;

  /// No description provided for @withdrawUiAmountToSendLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT TO SEND'**
  String get withdrawUiAmountToSendLabel;

  /// No description provided for @withdrawUiReviewInvoiceDestination.
  ///
  /// In en, this message translates to:
  /// **'To (Invoice)'**
  String get withdrawUiReviewInvoiceDestination;

  /// No description provided for @withdrawUiReviewAddressDestination.
  ///
  /// In en, this message translates to:
  /// **'To (Address)'**
  String get withdrawUiReviewAddressDestination;

  /// No description provided for @withdrawUiLightningFee.
  ///
  /// In en, this message translates to:
  /// **'Lightning fee'**
  String get withdrawUiLightningFee;

  /// No description provided for @withdrawUiPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Kerosene fee'**
  String get withdrawUiPlatformFee;

  /// No description provided for @withdrawUiConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get withdrawUiConfirmPayment;

  /// No description provided for @withdrawUiConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm send'**
  String get withdrawUiConfirmSend;

  /// No description provided for @withdrawUiSendingFromPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sending from:'**
  String get withdrawUiSendingFromPrefix;

  /// No description provided for @withdrawUiSendingToPrefix.
  ///
  /// In en, this message translates to:
  /// **'to:'**
  String get withdrawUiSendingToPrefix;

  /// No description provided for @withdrawUiCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get withdrawUiCurrentBalance;

  /// No description provided for @withdrawUiEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get withdrawUiEstimatedTime;

  /// No description provided for @withdrawUiCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating'**
  String get withdrawUiCalculating;

  /// No description provided for @depositLedgerAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get depositLedgerAddressCopied;

  /// No description provided for @depositLedgerMovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get depositLedgerMovementsTitle;

  /// No description provided for @depositLedgerPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String depositLedgerPage(int page);

  /// No description provided for @depositLedgerBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get depositLedgerBackTooltip;

  /// No description provided for @depositLedgerRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get depositLedgerRefreshTooltip;

  /// No description provided for @depositLedgerStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get depositLedgerStatementTitle;

  /// No description provided for @depositLedgerAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account activity'**
  String get depositLedgerAccountSubtitle;

  /// No description provided for @depositLedgerBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get depositLedgerBalance;

  /// No description provided for @depositLedgerHideBalance.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get depositLedgerHideBalance;

  /// No description provided for @depositLedgerShowBalance.
  ///
  /// In en, this message translates to:
  /// **'Show balance'**
  String get depositLedgerShowBalance;

  /// No description provided for @depositLedgerItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get depositLedgerItems;

  /// No description provided for @depositLedgerPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get depositLedgerPending;

  /// No description provided for @depositLedgerOpenCharges.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get depositLedgerOpenCharges;

  /// No description provided for @depositLedgerNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get depositLedgerNetwork;

  /// No description provided for @depositLedgerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get depositLedgerActive;

  /// No description provided for @depositLedgerManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get depositLedgerManual;

  /// No description provided for @depositLedgerCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get depositLedgerCopyAddress;

  /// No description provided for @depositLedgerLoadingCharges.
  ///
  /// In en, this message translates to:
  /// **'Loading requests'**
  String get depositLedgerLoadingCharges;

  /// No description provided for @depositLedgerOpenChargesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get depositLedgerOpenChargesTitle;

  /// No description provided for @depositLedgerPaymentLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get depositLedgerPaymentLinkTitle;

  /// No description provided for @depositLedgerExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String depositLedgerExpiresIn(String time);

  /// No description provided for @depositLedgerNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get depositLedgerNow;

  /// No description provided for @depositLedgerCopyAction.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get depositLedgerCopyAction;

  /// No description provided for @depositLedgerManageAction.
  ///
  /// In en, this message translates to:
  /// **'manage'**
  String get depositLedgerManageAction;

  /// No description provided for @depositLedgerUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating statement'**
  String get depositLedgerUpdating;

  /// No description provided for @depositLedgerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get depositLedgerEmptyTitle;

  /// No description provided for @depositLedgerEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this page.'**
  String get depositLedgerEmptyMessage;

  /// No description provided for @depositLedgerCancelReceive.
  ///
  /// In en, this message translates to:
  /// **'Cancel receive'**
  String get depositLedgerCancelReceive;

  /// No description provided for @depositLedgerCancelReceiveMessage.
  ///
  /// In en, this message translates to:
  /// **'This receive will be canceled in Kerosene. If someone has already sent BTC to the address, the Bitcoin network may still confirm the transaction.'**
  String get depositLedgerCancelReceiveMessage;

  /// No description provided for @depositLedgerBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get depositLedgerBackAction;

  /// No description provided for @depositLedgerReceiveCanceled.
  ///
  /// In en, this message translates to:
  /// **'Receive canceled.'**
  String get depositLedgerReceiveCanceled;

  /// No description provided for @depositLedgerPreviousTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get depositLedgerPreviousTooltip;

  /// No description provided for @depositLedgerNextTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get depositLedgerNextTooltip;

  /// No description provided for @depositLedgerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get depositLedgerAlerts;

  /// No description provided for @depositLedgerUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get depositLedgerUpdateAction;

  /// No description provided for @depositLedgerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not update'**
  String get depositLedgerErrorTitle;

  /// No description provided for @depositLedgerPageShort.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String depositLedgerPageShort(int page);

  /// No description provided for @depositLedgerRowsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{count} per page'**
  String depositLedgerRowsPerPage(int count);

  /// No description provided for @depositLedgerNoCounterparty.
  ///
  /// In en, this message translates to:
  /// **'No counterparty'**
  String get depositLedgerNoCounterparty;

  /// No description provided for @depositLedgerStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get depositLedgerStatusCompleted;

  /// No description provided for @depositLedgerStatusConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get depositLedgerStatusConfirming;

  /// No description provided for @depositLedgerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get depositLedgerStatusPending;

  /// No description provided for @depositLedgerStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get depositLedgerStatusFailed;

  /// No description provided for @depositLedgerStatusVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying'**
  String get depositLedgerStatusVerifying;

  /// No description provided for @depositLedgerStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get depositLedgerStatusPaid;

  /// No description provided for @depositLedgerStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get depositLedgerStatusExpired;

  /// No description provided for @depositLedgerRelativeSoon.
  ///
  /// In en, this message translates to:
  /// **'shortly'**
  String get depositLedgerRelativeSoon;

  /// No description provided for @depositLedgerRelativeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} min'**
  String depositLedgerRelativeInMinutes(int count);

  /// No description provided for @depositLedgerRelativeInHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} h'**
  String depositLedgerRelativeInHours(int count);

  /// No description provided for @depositLedgerRelativeInDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} d'**
  String depositLedgerRelativeInDays(int count);

  /// No description provided for @depositLedgerRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get depositLedgerRelativeNow;

  /// No description provided for @depositLedgerRelativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String depositLedgerRelativeMinutesAgo(int count);

  /// No description provided for @depositLedgerRelativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String depositLedgerRelativeHoursAgo(int count);

  /// No description provided for @paymentConfirmationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm'**
  String get paymentConfirmationErrorTitle;

  /// No description provided for @paymentConfirmationReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the details and confirm with your security factors.'**
  String get paymentConfirmationReviewSubtitle;

  /// No description provided for @paymentConfirmationDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get paymentConfirmationDateTime;

  /// No description provided for @paymentConfirmationNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get paymentConfirmationNetwork;

  /// No description provided for @paymentConfirmationCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get paymentConfirmationCopyAction;

  /// No description provided for @paymentConfirmationCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied.'**
  String paymentConfirmationCopied(String label);

  /// No description provided for @depositFlowDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositFlowDepositTitle;

  /// No description provided for @depositFlowAmountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount and choose how you want to receive it.'**
  String get depositFlowAmountSubtitle;

  /// No description provided for @depositFlowSelectedCurrency.
  ///
  /// In en, this message translates to:
  /// **'Selected currency'**
  String get depositFlowSelectedCurrency;

  /// No description provided for @depositFlowAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit amount'**
  String get depositFlowAmountLabel;

  /// No description provided for @depositFlowContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get depositFlowContinue;

  /// No description provided for @depositFlowEquivalentTo.
  ///
  /// In en, this message translates to:
  /// **'Equivalent to {amount}'**
  String depositFlowEquivalentTo(String amount);

  /// No description provided for @depositFlowYouReceive.
  ///
  /// In en, this message translates to:
  /// **'You receive {amount}'**
  String depositFlowYouReceive(String amount);

  /// No description provided for @depositFlowMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit method'**
  String get depositFlowMethodTitle;

  /// No description provided for @depositFlowMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to receive this Bitcoin amount.'**
  String get depositFlowMethodSubtitle;

  /// No description provided for @depositFlowSelectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Selected amount'**
  String get depositFlowSelectedAmount;

  /// No description provided for @depositFlowChooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get depositFlowChooseOption;

  /// No description provided for @depositFlowLightningFastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast receive with short validity and one-tap copy.'**
  String get depositFlowLightningFastSubtitle;

  /// No description provided for @depositFlowLightningUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lightning is not available for this wallet right now.'**
  String get depositFlowLightningUnavailable;

  /// No description provided for @depositFlowLightningChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking availability for this wallet.'**
  String get depositFlowLightningChecking;

  /// No description provided for @depositFlowLightningCheckError.
  ///
  /// In en, this message translates to:
  /// **'We could not check Lightning right now. You can still use on-chain.'**
  String get depositFlowLightningCheckError;

  /// No description provided for @depositFlowLightningInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get depositFlowLightningInstant;

  /// No description provided for @depositFlowUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get depositFlowUnavailable;

  /// No description provided for @depositFlowValidating.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get depositFlowValidating;

  /// No description provided for @depositFlowOnchainColdTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet Bitcoin on-chain'**
  String get depositFlowOnchainColdTitle;

  /// No description provided for @depositFlowOnchainTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin on-chain'**
  String get depositFlowOnchainTitle;

  /// No description provided for @depositFlowOnchainColdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cold wallet address for tracking the deposit securely.'**
  String get depositFlowOnchainColdSubtitle;

  /// No description provided for @depositFlowOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unique Bitcoin address tracked until confirmation.'**
  String get depositFlowOnchainSubtitle;

  /// No description provided for @depositFlowColdWalletTag.
  ///
  /// In en, this message translates to:
  /// **'Cold wallet'**
  String get depositFlowColdWalletTag;

  /// No description provided for @depositFlowConfirmationsTag.
  ///
  /// In en, this message translates to:
  /// **'3 confirmations'**
  String get depositFlowConfirmationsTag;

  /// No description provided for @depositFlowProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase provider'**
  String get depositFlowProviderTitle;

  /// No description provided for @depositFlowProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the checkout to buy Bitcoin securely.'**
  String get depositFlowProviderSubtitle;

  /// No description provided for @depositFlowRequestedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Requested purchase'**
  String get depositFlowRequestedPurchase;

  /// No description provided for @depositFlowProviderSecurityHint.
  ///
  /// In en, this message translates to:
  /// **'You will continue in a secure environment and the Bitcoin address will already be filled in for this payment.'**
  String get depositFlowProviderSecurityHint;

  /// No description provided for @depositFlowProvidersLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading providers'**
  String get depositFlowProvidersLoadingTitle;

  /// No description provided for @depositFlowProvidersLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Preparing purchase options with this wallet address.'**
  String get depositFlowProvidersLoadingMessage;

  /// No description provided for @depositFlowProvidersErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not load providers'**
  String get depositFlowProvidersErrorTitle;

  /// No description provided for @depositFlowUnknownError.
  ///
  /// In en, this message translates to:
  /// **'We could not complete this right now.'**
  String get depositFlowUnknownError;

  /// No description provided for @depositFlowRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get depositFlowRetry;

  /// No description provided for @depositFlowNoProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'No provider available'**
  String get depositFlowNoProvidersTitle;

  /// No description provided for @depositFlowNoProvidersMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not find purchase options right now.'**
  String get depositFlowNoProvidersMessage;

  /// No description provided for @depositFlowSecureAddress.
  ///
  /// In en, this message translates to:
  /// **'Secure address'**
  String get depositFlowSecureAddress;

  /// No description provided for @depositFlowCheckoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout in the app.'**
  String get depositFlowCheckoutSubtitle;

  /// No description provided for @depositFlowDepositAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Deposit address copied.'**
  String get depositFlowDepositAddressCopied;

  /// No description provided for @depositFlowEstimatedPurchase.
  ///
  /// In en, this message translates to:
  /// **'Estimated purchase in {amount}'**
  String depositFlowEstimatedPurchase(String amount);

  /// No description provided for @depositFlowProviderLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load the provider'**
  String get depositFlowProviderLoadError;

  /// No description provided for @depositFlowCheckoutAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'BTC address linked to checkout'**
  String get depositFlowCheckoutAddressTitle;

  /// No description provided for @depositFlowAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable'**
  String get depositFlowAddressUnavailable;

  /// No description provided for @depositFlowCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get depositFlowCopy;

  /// No description provided for @depositLightningLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get depositLightningLoading;

  /// No description provided for @depositLightningGoesTo.
  ///
  /// In en, this message translates to:
  /// **'Goes to'**
  String get depositLightningGoesTo;

  /// No description provided for @depositLightningSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get depositLightningSummary;

  /// No description provided for @depositInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit instructions'**
  String get depositInstructionsTitle;

  /// No description provided for @depositInstructionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short, direct read in the same flow pattern.'**
  String get depositInstructionsSubtitle;

  /// No description provided for @depositInstructionsUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get depositInstructionsUnderstood;

  /// No description provided for @depositInstructionsNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get depositInstructionsNetworkLabel;

  /// No description provided for @depositInstructionsNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit BTC only through'**
  String get depositInstructionsNetworkTitle;

  /// No description provided for @depositInstructionsMinimumLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get depositInstructionsMinimumLabel;

  /// No description provided for @depositInstructionsMinimumTitle.
  ///
  /// In en, this message translates to:
  /// **'The minimum deposit is'**
  String get depositInstructionsMinimumTitle;

  /// No description provided for @depositInstructionsMinimumNote.
  ///
  /// In en, this message translates to:
  /// **'Deposits below this amount will be lost.'**
  String get depositInstructionsMinimumNote;

  /// No description provided for @depositInstructionsMaximumLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get depositInstructionsMaximumLabel;

  /// No description provided for @depositInstructionsMaximumTitle.
  ///
  /// In en, this message translates to:
  /// **'The maximum deposit is'**
  String get depositInstructionsMaximumTitle;

  /// No description provided for @depositInstructionsMaximumSuffix.
  ///
  /// In en, this message translates to:
  /// **' per transaction.'**
  String get depositInstructionsMaximumSuffix;

  /// No description provided for @depositInstructionsProcessingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get depositInstructionsProcessingLabel;

  /// No description provided for @depositInstructionsProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated time:'**
  String get depositInstructionsProcessingTitle;

  /// No description provided for @depositInstructionsProcessingHighlight.
  ///
  /// In en, this message translates to:
  /// **'< 1 minute'**
  String get depositInstructionsProcessingHighlight;

  /// No description provided for @depositInstructionsProcessingSuffix.
  ///
  /// In en, this message translates to:
  /// **' via Lightning.'**
  String get depositInstructionsProcessingSuffix;

  /// No description provided for @depositQrReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive BTC'**
  String get depositQrReceiveTitle;

  /// No description provided for @depositQrReceiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple, secure deposit QR.'**
  String get depositQrReceiveSubtitle;

  /// No description provided for @depositQrSetAmount.
  ///
  /// In en, this message translates to:
  /// **'Set amount'**
  String get depositQrSetAmount;

  /// No description provided for @depositQrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to receive Bitcoin'**
  String get depositQrScanTitle;

  /// No description provided for @depositQrBitcoinOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'Send only Bitcoin (BTC) to this address.\nSending other assets will result in permanent loss.'**
  String get depositQrBitcoinOnlyWarning;

  /// No description provided for @depositQrAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Your BTC address'**
  String get depositQrAddressLabel;

  /// No description provided for @depositQrCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get depositQrCopy;

  /// No description provided for @depositQrCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get depositQrCopied;

  /// No description provided for @depositQrShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get depositQrShare;

  /// No description provided for @depositQrSave.
  ///
  /// In en, this message translates to:
  /// **'Save QR'**
  String get depositQrSave;

  /// No description provided for @receiveQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive by QR'**
  String get receiveQrTitle;

  /// No description provided for @receiveQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compact monochrome QR for display.'**
  String get receiveQrSubtitle;

  /// No description provided for @receiveQrCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get receiveQrCopied;

  /// No description provided for @withdrawReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt with amount, destination and payment identifier.'**
  String get withdrawReceiptSubtitle;

  /// No description provided for @receiveHubNfcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device right now.'**
  String get receiveHubNfcUnavailable;

  /// No description provided for @receiveHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveHubTitle;

  /// No description provided for @receiveHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit, request and QR in one simple flow.'**
  String get receiveHubSubtitle;

  /// No description provided for @receiveHubActions.
  ///
  /// In en, this message translates to:
  /// **'Available actions'**
  String get receiveHubActions;

  /// No description provided for @receiveHubIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to receive. Each option keeps the focus on amount, destination and confirmation.'**
  String get receiveHubIntro;

  /// No description provided for @receiveHubDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get receiveHubDeposit;

  /// No description provided for @receiveHubDepositSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add balance by purchase, Lightning or on-chain'**
  String get receiveHubDepositSubtitle;

  /// No description provided for @receiveHubOnchain.
  ///
  /// In en, this message translates to:
  /// **'Receive on-chain'**
  String get receiveHubOnchain;

  /// No description provided for @receiveHubOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a Bitcoin QR with optional amount'**
  String get receiveHubOnchainSubtitle;

  /// No description provided for @receiveHubLightning.
  ///
  /// In en, this message translates to:
  /// **'Receive Lightning'**
  String get receiveHubLightning;

  /// No description provided for @receiveHubLightningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an instant request for the wallet'**
  String get receiveHubLightningSubtitle;

  /// No description provided for @receiveHubPaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get receiveHubPaymentLink;

  /// No description provided for @receiveHubPaymentLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tracked request with protected destination'**
  String get receiveHubPaymentLinkSubtitle;

  /// No description provided for @receiveHubNfc.
  ///
  /// In en, this message translates to:
  /// **'Receive by NFC'**
  String get receiveHubNfc;

  /// No description provided for @receiveHubNfcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare a tap-to-pay request'**
  String get receiveHubNfcSubtitle;

  /// No description provided for @receiveHubNoWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallet available'**
  String get receiveHubNoWalletTitle;

  /// No description provided for @receiveHubNoWalletMessage.
  ///
  /// In en, this message translates to:
  /// **'Create or select a wallet before starting a receive flow.'**
  String get receiveHubNoWalletMessage;

  /// No description provided for @receiveWalletInternalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No internal Kerosene wallet is available for receiving.'**
  String get receiveWalletInternalUnavailable;

  /// No description provided for @receiveWalletOnchainUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No on-chain cold wallet is available for receiving.'**
  String get receiveWalletOnchainUnavailable;

  /// No description provided for @receiveWalletSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want\nto receive?'**
  String get receiveWalletSelectionTitle;

  /// No description provided for @receiveWalletSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether funds enter your internal Kerosene wallet or your on-chain cold wallet.'**
  String get receiveWalletSelectionSubtitle;

  /// No description provided for @receiveWalletKeroseneTitle.
  ///
  /// In en, this message translates to:
  /// **'Main wallet'**
  String get receiveWalletKeroseneTitle;

  /// No description provided for @receiveWalletKeroseneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive directly in your Kerosene wallet'**
  String get receiveWalletKeroseneSubtitle;

  /// No description provided for @receiveWalletOnchainTitle.
  ///
  /// In en, this message translates to:
  /// **'Home wallet'**
  String get receiveWalletOnchainTitle;

  /// No description provided for @receiveWalletOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive directly at your home wallet Bitcoin address'**
  String get receiveWalletOnchainSubtitle;

  /// No description provided for @receiveMethodKeroseneTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive in Kerosene'**
  String get receiveMethodKeroseneTitle;

  /// No description provided for @receiveMethodKeroseneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose QR Code, payment link or NFC for your internal wallet.'**
  String get receiveMethodKeroseneSubtitle;

  /// No description provided for @receiveMethodOnchainTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive on-chain'**
  String get receiveMethodOnchainTitle;

  /// No description provided for @receiveMethodOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose QR Code, payment link or NFC for your cold wallet.'**
  String get receiveMethodOnchainSubtitle;

  /// No description provided for @receiveMethodGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment gateway'**
  String get receiveMethodGatewayTitle;

  /// No description provided for @receiveMethodGatewaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider to buy Bitcoin'**
  String get receiveMethodGatewaySubtitle;

  /// No description provided for @receiveMethodQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get receiveMethodQrTitle;

  /// No description provided for @receiveMethodQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a code to show the payer'**
  String get receiveMethodQrSubtitle;

  /// No description provided for @receiveMethodPaymentLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get receiveMethodPaymentLinkTitle;

  /// No description provided for @receiveMethodPaymentLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a shareable request'**
  String get receiveMethodPaymentLinkSubtitle;

  /// No description provided for @receiveMethodNfcTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get receiveMethodNfcTitle;

  /// No description provided for @receiveMethodNfcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare tap-to-receive'**
  String get receiveMethodNfcSubtitle;

  /// No description provided for @receiveGatewayProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get receiveGatewayProvidersTitle;

  /// No description provided for @receiveGatewayRecommendedBrazil.
  ///
  /// In en, this message translates to:
  /// **'Recommended for Brazil'**
  String get receiveGatewayRecommendedBrazil;

  /// No description provided for @receiveGatewayInstitutional.
  ///
  /// In en, this message translates to:
  /// **'Institutional'**
  String get receiveGatewayInstitutional;

  /// No description provided for @receiveGatewayAggregators.
  ///
  /// In en, this message translates to:
  /// **'Aggregators'**
  String get receiveGatewayAggregators;

  /// No description provided for @receiveGatewayOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get receiveGatewayOther;

  /// No description provided for @receiveGatewayInstitutionalBadge.
  ///
  /// In en, this message translates to:
  /// **'INSTITUTIONAL'**
  String get receiveGatewayInstitutionalBadge;

  /// No description provided for @receiveGatewayMoonPayMethods.
  ///
  /// In en, this message translates to:
  /// **'Pix, card, Apple Pay • Instant'**
  String get receiveGatewayMoonPayMethods;

  /// No description provided for @receiveGatewayMoonPayFees.
  ///
  /// In en, this message translates to:
  /// **'Fees: 1% to 4.5%'**
  String get receiveGatewayMoonPayFees;

  /// No description provided for @receiveGatewayBanxaMethods.
  ///
  /// In en, this message translates to:
  /// **'Card, Apple Pay, Google Pay • Instant'**
  String get receiveGatewayBanxaMethods;

  /// No description provided for @receiveGatewayBanxaFees.
  ///
  /// In en, this message translates to:
  /// **'Fee: 1.99% + network fee'**
  String get receiveGatewayBanxaFees;

  /// No description provided for @receiveGatewayMercuryoMethods.
  ///
  /// In en, this message translates to:
  /// **'Pix, card, Apple Pay • Minutes'**
  String get receiveGatewayMercuryoMethods;

  /// No description provided for @receiveGatewayMercuryoFees.
  ///
  /// In en, this message translates to:
  /// **'Fee: 3.95% to 4%'**
  String get receiveGatewayMercuryoFees;

  /// No description provided for @receiveGatewayRampMethods.
  ///
  /// In en, this message translates to:
  /// **'Card, Apple Pay, transfer • Minutes'**
  String get receiveGatewayRampMethods;

  /// No description provided for @receiveGatewayRampFees.
  ///
  /// In en, this message translates to:
  /// **'Dynamic fees at checkout'**
  String get receiveGatewayRampFees;

  /// No description provided for @receiveGatewayStripeMethods.
  ///
  /// In en, this message translates to:
  /// **'Card, Apple Pay, ACH • 1 to 5 min'**
  String get receiveGatewayStripeMethods;

  /// No description provided for @receiveGatewayStripeFees.
  ///
  /// In en, this message translates to:
  /// **'Dynamic fees'**
  String get receiveGatewayStripeFees;

  /// No description provided for @receiveGatewayCoinbaseMethods.
  ///
  /// In en, this message translates to:
  /// **'Debit/credit card • Minutes'**
  String get receiveGatewayCoinbaseMethods;

  /// No description provided for @receiveGatewayCoinbaseFees.
  ///
  /// In en, this message translates to:
  /// **'Dynamic fees'**
  String get receiveGatewayCoinbaseFees;

  /// No description provided for @receiveGatewayOnramperMethods.
  ///
  /// In en, this message translates to:
  /// **'More than 130 methods and 30 providers'**
  String get receiveGatewayOnramperMethods;

  /// No description provided for @receiveGatewayOnramperFees.
  ///
  /// In en, this message translates to:
  /// **'Best available route • Ideal fallback'**
  String get receiveGatewayOnramperFees;

  /// No description provided for @receiveGatewayTransakMethods.
  ///
  /// In en, this message translates to:
  /// **'Card, digital wallets • Minutes'**
  String get receiveGatewayTransakMethods;

  /// No description provided for @receiveGatewayTransakFees.
  ///
  /// In en, this message translates to:
  /// **'Variable limits and fees by coverage'**
  String get receiveGatewayTransakFees;

  /// No description provided for @receiveGatewayWertMethods.
  ///
  /// In en, this message translates to:
  /// **'Card, Apple Pay, Google Pay • < 60 sec'**
  String get receiveGatewayWertMethods;

  /// No description provided for @receiveGatewayWertFees.
  ///
  /// In en, this message translates to:
  /// **'US$30 minimum for BTC'**
  String get receiveGatewayWertFees;

  /// No description provided for @receiveGatewayGateFiMethods.
  ///
  /// In en, this message translates to:
  /// **'E-wallets, QR Code, cash • Variable'**
  String get receiveGatewayGateFiMethods;

  /// No description provided for @receiveGatewayGateFiFees.
  ///
  /// In en, this message translates to:
  /// **'Broad global coverage'**
  String get receiveGatewayGateFiFees;

  /// No description provided for @receiveGatewayComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get receiveGatewayComingSoon;

  /// No description provided for @receiveGatewayLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'{provider} link copied for {wallet}.'**
  String receiveGatewayLinkCopied(String provider, String wallet);

  /// No description provided for @receiveGatewayProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{provider} is not available for this wallet yet.'**
  String receiveGatewayProviderUnavailable(String provider);

  /// No description provided for @financialStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get financialStatementTitle;

  /// No description provided for @financialStatementLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get financialStatementLoadErrorTitle;

  /// No description provided for @financialStatementEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get financialStatementEmptyTitle;

  /// No description provided for @financialStatementEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Account activity will appear here.'**
  String get financialStatementEmptyMessage;

  /// No description provided for @financialStatementSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get financialStatementSearchHint;

  /// No description provided for @financialStatementFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get financialStatementFilterAll;

  /// No description provided for @financialStatementFilterIncoming.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get financialStatementFilterIncoming;

  /// No description provided for @financialStatementFilterOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get financialStatementFilterOutgoing;

  /// No description provided for @receiveScreenQrEyebrow.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get receiveScreenQrEyebrow;

  /// No description provided for @receiveScreenPaymentLinkEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get receiveScreenPaymentLinkEyebrow;

  /// No description provided for @receiveScreenOnchainEyebrow.
  ///
  /// In en, this message translates to:
  /// **'On-chain'**
  String get receiveScreenOnchainEyebrow;

  /// No description provided for @receiveScreenLightningEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get receiveScreenLightningEyebrow;

  /// No description provided for @receiveScreenQrDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate an internal QR with protected amount and destination for confirmation.'**
  String get receiveScreenQrDescription;

  /// No description provided for @receiveScreenNfcDescription.
  ///
  /// In en, this message translates to:
  /// **'Prepare a tap-to-pay request with a protected destination.'**
  String get receiveScreenNfcDescription;

  /// No description provided for @receiveScreenPaymentLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a tracked link that opens directly on confirmation.'**
  String get receiveScreenPaymentLinkDescription;

  /// No description provided for @receiveScreenOnchainDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate an on-chain Bitcoin QR with amount and destination set.'**
  String get receiveScreenOnchainDescription;

  /// No description provided for @receiveScreenLightningDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate a Lightning request for fast receive.'**
  String get receiveScreenLightningDescription;

  /// No description provided for @receiveScreenGenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get receiveScreenGenerateQr;

  /// No description provided for @receiveScreenPrepareNfc.
  ///
  /// In en, this message translates to:
  /// **'Prepare NFC'**
  String get receiveScreenPrepareNfc;

  /// No description provided for @receiveScreenCreateLink.
  ///
  /// In en, this message translates to:
  /// **'Create link'**
  String get receiveScreenCreateLink;

  /// No description provided for @receiveScreenGenerateOnchainQr.
  ///
  /// In en, this message translates to:
  /// **'Generate on-chain QR'**
  String get receiveScreenGenerateOnchainQr;

  /// No description provided for @receiveScreenGenerateLightningInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Lightning invoice'**
  String get receiveScreenGenerateLightningInvoice;

  /// No description provided for @receiveScreenSelectDepositWallet.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet to deposit.'**
  String get receiveScreenSelectDepositWallet;

  /// No description provided for @receiveScreenQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the amount and generate an internal QR with protected destination.'**
  String get receiveScreenQrSubtitle;

  /// No description provided for @receiveScreenNfcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the amount and prepare a tap-to-pay request.'**
  String get receiveScreenNfcSubtitle;

  /// No description provided for @receiveScreenPaymentLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the amount and generate a tracked request.'**
  String get receiveScreenPaymentLinkSubtitle;

  /// No description provided for @receiveScreenOnchainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the amount and generate a compatible Bitcoin QR.'**
  String get receiveScreenOnchainSubtitle;

  /// No description provided for @receiveScreenLightningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the amount and continue to a Lightning request.'**
  String get receiveScreenLightningSubtitle;

  /// No description provided for @receiveScreenInboundBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive unavailable'**
  String get receiveScreenInboundBlockedTitle;

  /// No description provided for @receiveScreenInboundBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activate a wallet or add balance to receive through the platform.'**
  String get receiveScreenInboundBlockedMessage;

  /// No description provided for @receiveScreenRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get receiveScreenRefreshStatus;

  /// No description provided for @receiveScreenEquivalentTo.
  ///
  /// In en, this message translates to:
  /// **'Equivalent to {amount}'**
  String receiveScreenEquivalentTo(String amount);

  /// No description provided for @receiveScreenDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination {walletName}'**
  String receiveScreenDestination(String walletName);

  /// No description provided for @receiveScreenPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'The payer will see only the details needed to confirm the receive.'**
  String get receiveScreenPrivacyHint;

  /// No description provided for @receiveScreenSelectReceiveWallet.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet to receive.'**
  String get receiveScreenSelectReceiveWallet;

  /// No description provided for @receiveScreenInvalidPaymentLink.
  ///
  /// In en, this message translates to:
  /// **'We could not create a valid payment link right now.'**
  String get receiveScreenInvalidPaymentLink;

  /// No description provided for @receiveScreenPaymentLinkError.
  ///
  /// In en, this message translates to:
  /// **'We could not generate the payment link: {error}'**
  String receiveScreenPaymentLinkError(String error);

  /// No description provided for @receiveScreenDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive {walletName}'**
  String receiveScreenDefaultDescription(String walletName);

  /// No description provided for @receiveScreenConfigureLinkEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Configure link'**
  String get receiveScreenConfigureLinkEyebrow;

  /// No description provided for @receiveScreenConfigureLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get receiveScreenConfigureLinkTitle;

  /// No description provided for @receiveScreenConfigureLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set validity, visibility and identification before generating the link.'**
  String get receiveScreenConfigureLinkSubtitle;

  /// No description provided for @receiveScreenDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get receiveScreenDescriptionLabel;

  /// No description provided for @receiveScreenReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get receiveScreenReferenceLabel;

  /// No description provided for @receiveScreen15Minutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get receiveScreen15Minutes;

  /// No description provided for @receiveScreen1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get receiveScreen1Hour;

  /// No description provided for @receiveScreen3Hours.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get receiveScreen3Hours;

  /// No description provided for @receiveScreen24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get receiveScreen24Hours;

  /// No description provided for @receiveScreenValidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get receiveScreenValidityLabel;

  /// No description provided for @receiveScreenPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get receiveScreenPrivate;

  /// No description provided for @receiveScreenPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get receiveScreenPublic;

  /// No description provided for @receiveScreenVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get receiveScreenVisibilityLabel;

  /// No description provided for @receiveScreenUserActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Finish with your confirmation'**
  String get receiveScreenUserActionRequired;

  /// No description provided for @receiveScreenAutoComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete automatically'**
  String get receiveScreenAutoComplete;

  /// No description provided for @receiveScreenCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get receiveScreenCompletionLabel;

  /// No description provided for @receiveScreenCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get receiveScreenCustomerLabel;

  /// No description provided for @receiveScreenNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get receiveScreenNoteLabel;

  /// No description provided for @receiveScreenGenerateLink.
  ///
  /// In en, this message translates to:
  /// **'Generate link'**
  String get receiveScreenGenerateLink;

  /// No description provided for @receivePaymentLinkCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment link cancelled.'**
  String get receivePaymentLinkCancelled;

  /// No description provided for @receivePaymentLinkCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel link'**
  String get receivePaymentLinkCancelTitle;

  /// No description provided for @receivePaymentLinkCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'You can add a reason to show in your history.'**
  String get receivePaymentLinkCancelMessage;

  /// No description provided for @receivePaymentLinkCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get receivePaymentLinkCancelReason;

  /// No description provided for @receivePaymentLinkConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get receivePaymentLinkConfirmCancel;

  /// No description provided for @receivePaymentLinkNotInformed.
  ///
  /// In en, this message translates to:
  /// **'Not informed'**
  String get receivePaymentLinkNotInformed;

  /// No description provided for @receivePaymentLinkStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Payment under review'**
  String get receivePaymentLinkStatusChecking;

  /// No description provided for @receivePaymentLinkStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get receivePaymentLinkStatusReceived;

  /// No description provided for @receivePaymentLinkStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Link cancelled'**
  String get receivePaymentLinkStatusCancelled;

  /// No description provided for @receivePaymentLinkStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Link expired'**
  String get receivePaymentLinkStatusExpired;

  /// No description provided for @receivePaymentLinkStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get receivePaymentLinkStatusWaiting;

  /// No description provided for @receivePaymentLinkCheckingMessage.
  ///
  /// In en, this message translates to:
  /// **'The network has detected the payment. We are completing the final review.'**
  String get receivePaymentLinkCheckingMessage;

  /// No description provided for @receivePaymentLinkReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'This link amount has been received and your history was updated.'**
  String get receivePaymentLinkReceivedMessage;

  /// No description provided for @receivePaymentLinkCancelledReason.
  ///
  /// In en, this message translates to:
  /// **'This link was cancelled: {reason}.'**
  String receivePaymentLinkCancelledReason(String reason);

  /// No description provided for @receivePaymentLinkCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This link was cancelled and no longer accepts payments.'**
  String get receivePaymentLinkCancelledMessage;

  /// No description provided for @receivePaymentLinkExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This link no longer accepts payments. Generate a new QR to continue receiving.'**
  String get receivePaymentLinkExpiredMessage;

  /// No description provided for @receivePaymentLinkLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Anyone who opens this QR will see a simple confirmation with protected amount and destination.'**
  String get receivePaymentLinkLockedMessage;

  /// No description provided for @receivePaymentLinkWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the QR Code or copy the payment link below. Status updates automatically.'**
  String get receivePaymentLinkWaitingMessage;

  /// No description provided for @receivePaymentLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receivePaymentLinkTitle;

  /// No description provided for @receivePaymentLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'QR, link and tracking in one simple screen.'**
  String get receivePaymentLinkSubtitle;

  /// No description provided for @receivePaymentLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get receivePaymentLinkExpired;

  /// No description provided for @receivePaymentLinkExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {duration}'**
  String receivePaymentLinkExpiresIn(String duration);

  /// No description provided for @receivePaymentLinkDepositFee.
  ///
  /// In en, this message translates to:
  /// **'deposit {amount}'**
  String receivePaymentLinkDepositFee(String amount);

  /// No description provided for @receivePaymentLinkNetAmount.
  ///
  /// In en, this message translates to:
  /// **'net {amount}'**
  String receivePaymentLinkNetAmount(String amount);

  /// No description provided for @receivePaymentLinkExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get receivePaymentLinkExpires;

  /// No description provided for @receivePaymentLinkTransactionCode.
  ///
  /// In en, this message translates to:
  /// **'Transaction code'**
  String get receivePaymentLinkTransactionCode;

  /// No description provided for @receivePaymentLinkState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get receivePaymentLinkState;

  /// No description provided for @receivePaymentLinkPaymentLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment link'**
  String get receivePaymentLinkPaymentLinkTitle;

  /// No description provided for @receivePaymentLinkLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'This link opens payment confirmation with protected amount and destination.'**
  String get receivePaymentLinkLockedHelper;

  /// No description provided for @receivePaymentLinkShareHelper.
  ///
  /// In en, this message translates to:
  /// **'Share this link to receive the defined amount.'**
  String get receivePaymentLinkShareHelper;

  /// No description provided for @receivePaymentLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Payment link copied to clipboard.'**
  String get receivePaymentLinkCopied;

  /// No description provided for @receivePaymentLinkDepositAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Unique Bitcoin address for this payment.'**
  String get receivePaymentLinkDepositAddressHelper;

  /// No description provided for @receivePaymentLinkDepositAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Deposit address copied to clipboard.'**
  String get receivePaymentLinkDepositAddressCopied;

  /// No description provided for @receivePaymentLinkRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get receivePaymentLinkRefresh;

  /// No description provided for @receivePaymentLinkConfigurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive configuration'**
  String get receivePaymentLinkConfigurationTitle;

  /// No description provided for @receivePaymentLinkVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get receivePaymentLinkVisibility;

  /// No description provided for @receivePaymentLinkCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get receivePaymentLinkCompletion;

  /// No description provided for @receivePaymentLinkAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receivePaymentLinkAmount;

  /// No description provided for @receivePaymentLinkAmountSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get receivePaymentLinkAmountSet;

  /// No description provided for @receivePaymentLinkAmountFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get receivePaymentLinkAmountFlexible;

  /// No description provided for @receivePaymentLinkReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get receivePaymentLinkReference;

  /// No description provided for @receivePaymentLinkCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get receivePaymentLinkCreatedAt;

  /// No description provided for @receivePaymentLinkPaidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
  String get receivePaymentLinkPaidAt;

  /// No description provided for @receivePaymentLinkConfirmedAt.
  ///
  /// In en, this message translates to:
  /// **'Confirmed at'**
  String get receivePaymentLinkConfirmedAt;

  /// No description provided for @receivePaymentLinkCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get receivePaymentLinkCancelledAt;

  /// No description provided for @receivePaymentLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get receivePaymentLinkCopy;

  /// No description provided for @sendMoneyDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get sendMoneyDestinationLabel;

  /// No description provided for @sendMoneyDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'Address or username'**
  String get sendMoneyDestinationHint;

  /// No description provided for @sendMoneyRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent before'**
  String get sendMoneyRecentTitle;

  /// No description provided for @sendMoneyGoToAmount.
  ///
  /// In en, this message translates to:
  /// **'Go to amount'**
  String get sendMoneyGoToAmount;

  /// No description provided for @sendMoneyMissingDestination.
  ///
  /// In en, this message translates to:
  /// **'Enter the address or username.'**
  String get sendMoneyMissingDestination;

  /// No description provided for @sendMoneyExternalUseWithdraw.
  ///
  /// In en, this message translates to:
  /// **'On-chain payments must use the withdraw flow.'**
  String get sendMoneyExternalUseWithdraw;

  /// No description provided for @sendMoneyReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get sendMoneyReview;

  /// No description provided for @sendMoneyDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sendMoneyDetailType;

  /// No description provided for @sendMoneyTypePaymentLink.
  ///
  /// In en, this message translates to:
  /// **'Internal payment link'**
  String get sendMoneyTypePaymentLink;

  /// No description provided for @sendMoneyTypeInternalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Internal Kerosene transfer'**
  String get sendMoneyTypeInternalTransfer;

  /// No description provided for @sendMoneyDetailValue.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sendMoneyDetailValue;

  /// No description provided for @sendMoneyDetailValueBtc.
  ///
  /// In en, this message translates to:
  /// **'Amount in BTC'**
  String get sendMoneyDetailValueBtc;

  /// No description provided for @sendMoneyDetailTotalBtc.
  ///
  /// In en, this message translates to:
  /// **'Total in BTC'**
  String get sendMoneyDetailTotalBtc;

  /// No description provided for @sendMoneyDetailBalanceBefore.
  ///
  /// In en, this message translates to:
  /// **'Balance before sending'**
  String get sendMoneyDetailBalanceBefore;

  /// No description provided for @sendMoneyDetailLinkId.
  ///
  /// In en, this message translates to:
  /// **'Link ID'**
  String get sendMoneyDetailLinkId;

  /// No description provided for @sendMoneyDetailDestinationHash.
  ///
  /// In en, this message translates to:
  /// **'Destination hash'**
  String get sendMoneyDetailDestinationHash;

  /// No description provided for @sendMoneyDestinationHashCopied.
  ///
  /// In en, this message translates to:
  /// **'Destination hash copied.'**
  String get sendMoneyDestinationHashCopied;

  /// No description provided for @sendMoneyConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get sendMoneyConfirmPayment;

  /// No description provided for @sendMoneyLockedRequestEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Protected request'**
  String get sendMoneyLockedRequestEyebrow;

  /// No description provided for @sendMoneyFinalReviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Final review'**
  String get sendMoneyFinalReviewEyebrow;

  /// No description provided for @sendMoneySourceLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get sendMoneySourceLabel;

  /// No description provided for @sendMoneyDestinationToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sendMoneyDestinationToLabel;

  /// No description provided for @sendMoneyInternalNetwork.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get sendMoneyInternalNetwork;

  /// No description provided for @sendMoneyLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Amount and destination were set by the link. Confirm only if you recognize this request.'**
  String get sendMoneyLockedNotice;

  /// No description provided for @sendMoneyReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Review the details before confirming. After authorization, the payment will be processed.'**
  String get sendMoneyReviewNotice;

  /// No description provided for @sendMoneySecurityMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirmation uses your current session and the security factors configured on your account before sending the payment.'**
  String get sendMoneySecurityMessage;

  /// No description provided for @sendMoneyAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication was cancelled or could not be completed.'**
  String get sendMoneyAuthFailed;

  /// No description provided for @sendMoneyInvalidPaymentRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid payment request.'**
  String get sendMoneyInvalidPaymentRequest;

  /// No description provided for @sendMoneyExternalQrUseWithdraw.
  ///
  /// In en, this message translates to:
  /// **'External QR detected. Use the withdraw flow for on-chain payments.'**
  String get sendMoneyExternalQrUseWithdraw;

  /// No description provided for @sendMoneyRequestDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Request details loaded.'**
  String get sendMoneyRequestDataLoaded;

  /// No description provided for @sendMoneyInvalidQrRequest.
  ///
  /// In en, this message translates to:
  /// **'This QR or NFC does not look like a valid request.'**
  String get sendMoneyInvalidQrRequest;

  /// No description provided for @sendMoneyRequestAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'This request has already been paid.'**
  String get sendMoneyRequestAlreadyPaid;

  /// No description provided for @sendMoneyRequestExpired.
  ///
  /// In en, this message translates to:
  /// **'This payment request has expired.'**
  String get sendMoneyRequestExpired;

  /// No description provided for @sendMoneyLockedDestination.
  ///
  /// In en, this message translates to:
  /// **'Protected destination'**
  String get sendMoneyLockedDestination;

  /// No description provided for @sendMoneyPaymentRequestLoaded.
  ///
  /// In en, this message translates to:
  /// **'Payment request loaded.'**
  String get sendMoneyPaymentRequestLoaded;

  /// No description provided for @walletConfigAddressCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied successfully.'**
  String get walletConfigAddressCopiedMessage;

  /// No description provided for @walletConfigAddressCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get walletConfigAddressCopiedTitle;

  /// No description provided for @walletConfigExportNoticeMessage.
  ///
  /// In en, this message translates to:
  /// **'Private key export depends on device security verification.'**
  String get walletConfigExportNoticeMessage;

  /// No description provided for @walletConfigExportNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification required'**
  String get walletConfigExportNoticeTitle;

  /// No description provided for @walletConfigAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet address'**
  String get walletConfigAddressTitle;

  /// No description provided for @walletConfigAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use this address for on-chain deposits to this wallet.'**
  String get walletConfigAddressSubtitle;

  /// No description provided for @walletConfigCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get walletConfigCopy;

  /// No description provided for @walletConfigFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet fees'**
  String get walletConfigFeesTitle;

  /// No description provided for @walletConfigFeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updated values for external movements from this wallet.'**
  String get walletConfigFeesSubtitle;

  /// No description provided for @walletConfigControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get walletConfigControlsTitle;

  /// No description provided for @walletConfigControlsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage and visual privacy settings for this wallet in the app.'**
  String get walletConfigControlsSubtitle;

  /// No description provided for @walletConfigFreezeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeze card'**
  String get walletConfigFreezeCardTitle;

  /// No description provided for @walletConfigFreezeCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disables this wallet in the visual flow.'**
  String get walletConfigFreezeCardSubtitle;

  /// No description provided for @walletConfigHideBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide balance on home'**
  String get walletConfigHideBalanceTitle;

  /// No description provided for @walletConfigHideBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeps the wallet visible while reducing balance exposure.'**
  String get walletConfigHideBalanceSubtitle;

  /// No description provided for @walletConfigExportKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Export private key'**
  String get walletConfigExportKeyTitle;

  /// No description provided for @walletConfigExportKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires additional verification before revealing sensitive material.'**
  String get walletConfigExportKeySubtitle;

  /// No description provided for @walletConfigCardRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Card rule'**
  String get walletConfigCardRuleTitle;

  /// No description provided for @walletConfigCardRuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The profile considers account relationship and eligible volume from the last 30 days.'**
  String get walletConfigCardRuleSubtitle;

  /// No description provided for @walletConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet card'**
  String get walletConfigTitle;

  /// No description provided for @walletConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual setup, address and wallet fees.'**
  String get walletConfigSubtitle;

  /// No description provided for @walletConfigHeroSummary.
  ///
  /// In en, this message translates to:
  /// **'Level {level} • {cardType}. External withdrawals use {withdrawRate} and external deposits use {depositRate}.'**
  String walletConfigHeroSummary(
      int level, String cardType, String withdrawRate, String depositRate);

  /// No description provided for @walletConfigNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get walletConfigNetworkLabel;

  /// No description provided for @walletConfigPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get walletConfigPathLabel;

  /// No description provided for @walletConfigStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get walletConfigStatusLabel;

  /// No description provided for @walletConfigStatusFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get walletConfigStatusFrozen;

  /// No description provided for @walletConfigStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletConfigStatusActive;

  /// No description provided for @walletConfigLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get walletConfigLevelLabel;

  /// No description provided for @walletConfigWithdrawLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletConfigWithdrawLabel;

  /// No description provided for @walletConfigWithdrawHelper.
  ///
  /// In en, this message translates to:
  /// **'External outgoing'**
  String get walletConfigWithdrawHelper;

  /// No description provided for @walletConfigDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletConfigDepositLabel;

  /// No description provided for @walletConfigDepositHelper.
  ///
  /// In en, this message translates to:
  /// **'External incoming'**
  String get walletConfigDepositHelper;

  /// No description provided for @walletConfigInternalLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get walletConfigInternalLabel;

  /// No description provided for @walletConfigInternalHelper.
  ///
  /// In en, this message translates to:
  /// **'Between Kerosene wallets'**
  String get walletConfigInternalHelper;

  /// No description provided for @walletCardUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Card unavailable'**
  String get walletCardUnavailableTitle;

  /// No description provided for @walletCardNoActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active card'**
  String get walletCardNoActiveTitle;

  /// No description provided for @walletCardNoActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet to enable the account card.'**
  String get walletCardNoActiveMessage;

  /// No description provided for @walletCardAccountCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account cards'**
  String get walletCardAccountCardsTitle;

  /// No description provided for @walletCardAccountCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to view cards, fees and requirements for account {walletName}.'**
  String walletCardAccountCardsSubtitle(String walletName);

  /// No description provided for @walletCardCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get walletCardCurrentLabel;

  /// No description provided for @walletCardUpgradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get walletCardUpgradeLabel;

  /// No description provided for @walletCardAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get walletCardAutomatic;

  /// No description provided for @walletCardValidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get walletCardValidityLabel;

  /// No description provided for @walletCardRotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get walletCardRotationLabel;

  /// No description provided for @walletCardPreviousLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get walletCardPreviousLabel;

  /// No description provided for @walletCardRotating.
  ///
  /// In en, this message translates to:
  /// **'Rotating'**
  String get walletCardRotating;

  /// No description provided for @walletCardExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get walletCardExpiring;

  /// No description provided for @walletCardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletCardActive;

  /// No description provided for @walletCardNotInformed.
  ///
  /// In en, this message translates to:
  /// **'Not informed'**
  String get walletCardNotInformed;

  /// No description provided for @walletCardRotationTitle.
  ///
  /// In en, this message translates to:
  /// **'Card rotation'**
  String get walletCardRotationTitle;

  /// No description provided for @walletCardRotationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Card validity is real and the next issue happens automatically when the window expires.'**
  String get walletCardRotationSubtitle;

  /// No description provided for @walletCardCurrentExpires.
  ///
  /// In en, this message translates to:
  /// **'{cardNumber} • expires {date}'**
  String walletCardCurrentExpires(String cardNumber, String date);

  /// No description provided for @walletCardLastRotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Last rotation'**
  String get walletCardLastRotationLabel;

  /// No description provided for @walletCardPreviousExpired.
  ///
  /// In en, this message translates to:
  /// **'{cardNumber} • expired {date}'**
  String walletCardPreviousExpired(String cardNumber, String date);

  /// No description provided for @walletCardYourCard.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get walletCardYourCard;

  /// No description provided for @walletCardDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletCardDepositLabel;

  /// No description provided for @walletCardWithdrawLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletCardWithdrawLabel;

  /// No description provided for @walletCardHowToGet.
  ///
  /// In en, this message translates to:
  /// **'How to get it'**
  String get walletCardHowToGet;

  /// No description provided for @walletCardRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'How cards change'**
  String get walletCardRulesTitle;

  /// No description provided for @walletCardRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When your account meets the requirements, the card changes automatically.'**
  String get walletCardRulesSubtitle;

  /// No description provided for @walletCardGraphiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get walletCardGraphiteTitle;

  /// No description provided for @walletCardSilverTitle.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get walletCardSilverTitle;

  /// No description provided for @walletCardBlackTitle.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get walletCardBlackTitle;

  /// No description provided for @walletCardHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get walletCardHiddenTitle;

  /// No description provided for @walletCardGraphiteTier.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get walletCardGraphiteTier;

  /// No description provided for @walletCardSilverTier.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get walletCardSilverTier;

  /// No description provided for @walletCardBlackTier.
  ///
  /// In en, this message translates to:
  /// **'Top tier'**
  String get walletCardBlackTier;

  /// No description provided for @walletCardGraphiteDescription.
  ///
  /// In en, this message translates to:
  /// **'Initial card for new users. It is the default account level.'**
  String get walletCardGraphiteDescription;

  /// No description provided for @walletCardSilverDescription.
  ///
  /// In en, this message translates to:
  /// **'Intermediate upgrade with lower fees for deposits and withdrawals.'**
  String get walletCardSilverDescription;

  /// No description provided for @walletCardBlackDescription.
  ///
  /// In en, this message translates to:
  /// **'Lowest platform cost for accounts with more time and higher volume.'**
  String get walletCardBlackDescription;

  /// No description provided for @walletCardGraphiteQualification.
  ///
  /// In en, this message translates to:
  /// **'Available automatically for new accounts.'**
  String get walletCardGraphiteQualification;

  /// No description provided for @walletCardSilverQualification.
  ///
  /// In en, this message translates to:
  /// **'Movement above 1500 per month and at least 6 months of account history.'**
  String get walletCardSilverQualification;

  /// No description provided for @walletCardBlackQualification.
  ///
  /// In en, this message translates to:
  /// **'Movement above 4000 per month and at least 1 year of account history.'**
  String get walletCardBlackQualification;

  /// No description provided for @walletCardGraphiteEligibility.
  ///
  /// In en, this message translates to:
  /// **'New users.'**
  String get walletCardGraphiteEligibility;

  /// No description provided for @walletCardSilverEligibility.
  ///
  /// In en, this message translates to:
  /// **'Movements above 1500 per month and 6 months of account history.'**
  String get walletCardSilverEligibility;

  /// No description provided for @walletCardBlackEligibility.
  ///
  /// In en, this message translates to:
  /// **'Movements above 4000 per month and 1 year of account history.'**
  String get walletCardBlackEligibility;

  /// No description provided for @walletCardHashCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hash copied'**
  String get walletCardHashCopiedTitle;

  /// No description provided for @walletCardHashCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet hash copied.'**
  String get walletCardHashCopiedMessage;

  /// No description provided for @appEntryPinUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN unavailable'**
  String get appEntryPinUnavailableTitle;

  /// No description provided for @appEntryPinUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not validate entry protection. Refresh the status and try again.'**
  String get appEntryPinUnavailableMessage;

  /// No description provided for @appEntryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get appEntryRefresh;

  /// No description provided for @appEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get appEntryConfirm;

  /// No description provided for @appEntryReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get appEntryReset;

  /// No description provided for @appEntryExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get appEntryExit;

  /// No description provided for @appEntryTotpLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTP code'**
  String get appEntryTotpLabel;

  /// No description provided for @appEntryNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New numeric PIN'**
  String get appEntryNewPinLabel;

  /// No description provided for @appEntryPinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Use {min} to {max} digits.'**
  String appEntryPinLengthError(int min, int max);

  /// No description provided for @appEntryRetryIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in {duration}.'**
  String appEntryRetryIn(String duration);

  /// No description provided for @appEntryUnlockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter this device PIN to open your wallet.'**
  String get appEntryUnlockPrompt;

  /// No description provided for @appEntryLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Entry is temporarily blocked.'**
  String get appEntryLockedHelper;

  /// No description provided for @appEntryAttemptsHelper.
  ///
  /// In en, this message translates to:
  /// **'Attempts remaining before lock: {count}.'**
  String appEntryAttemptsHelper(int count);

  /// No description provided for @appEntryLocalPinHelper.
  ///
  /// In en, this message translates to:
  /// **'This PIN protects only this device.'**
  String get appEntryLocalPinHelper;

  /// No description provided for @appEntryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Entry PIN'**
  String get appEntryEyebrow;

  /// No description provided for @appEntryResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get appEntryResetTitle;

  /// No description provided for @appEntryResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the account authenticator code to set a new PIN on this device.'**
  String get appEntryResetMessage;

  /// No description provided for @appEntrySavePin.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get appEntrySavePin;

  /// No description provided for @sessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionEndedTitle;

  /// No description provided for @primaryNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get primaryNavHome;

  /// No description provided for @primaryNavCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get primaryNavCard;

  /// No description provided for @primaryNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get primaryNavHistory;

  /// No description provided for @primaryNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get primaryNavSettings;

  /// No description provided for @securityTreasuryBuffer.
  ///
  /// In en, this message translates to:
  /// **'Buffer'**
  String get securityTreasuryBuffer;

  /// No description provided for @securityTreasuryConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get securityTreasuryConfirmations;

  /// No description provided for @securityTreasuryLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get securityTreasuryLightning;

  /// No description provided for @securityTreasuryProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get securityTreasuryProfit;

  /// No description provided for @landingNavProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get landingNavProduct;

  /// No description provided for @landingNavSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get landingNavSecurity;

  /// No description provided for @landingNavBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get landingNavBusiness;

  /// No description provided for @landingNavInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get landingNavInfrastructure;

  /// No description provided for @landingNavFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get landingNavFaq;

  /// No description provided for @landingLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get landingLoginAction;

  /// No description provided for @landingCreateAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get landingCreateAccountAction;

  /// No description provided for @landingBusinessPanelAction.
  ///
  /// In en, this message translates to:
  /// **'View business panel'**
  String get landingBusinessPanelAction;

  /// No description provided for @landingSalesAction.
  ///
  /// In en, this message translates to:
  /// **'Talk to sales'**
  String get landingSalesAction;

  /// No description provided for @landingHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Private Bitcoin financial infrastructure'**
  String get landingHeroEyebrow;

  /// No description provided for @landingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Bitcoin bank.'**
  String get landingHeroTitle;

  /// No description provided for @landingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kerosene makes Bitcoin safer, more accessible, and more useful for people and businesses, with privacy, operational transparency, and real control over your assets.'**
  String get landingHeroSubtitle;

  /// No description provided for @landingHeroFeatureOnchainTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain + Lightning'**
  String get landingHeroFeatureOnchainTitle;

  /// No description provided for @landingHeroFeatureOnchainBody.
  ///
  /// In en, this message translates to:
  /// **'Liquidity and speed in one place.'**
  String get landingHeroFeatureOnchainBody;

  /// No description provided for @landingHeroFeatureInternalTitle.
  ///
  /// In en, this message translates to:
  /// **'Internal transfers'**
  String get landingHeroFeatureInternalTitle;

  /// No description provided for @landingHeroFeatureInternalBody.
  ///
  /// In en, this message translates to:
  /// **'Move balances between Kerosene users.'**
  String get landingHeroFeatureInternalBody;

  /// No description provided for @landingHeroFeatureSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Institutional security'**
  String get landingHeroFeatureSecurityTitle;

  /// No description provided for @landingHeroFeatureSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Private architecture with continuous audit.'**
  String get landingHeroFeatureSecurityBody;

  /// No description provided for @landingWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What Kerosene does'**
  String get landingWhatTitle;

  /// No description provided for @landingFeatureWalletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin wallets'**
  String get landingFeatureWalletsTitle;

  /// No description provided for @landingFeatureWalletsBody.
  ///
  /// In en, this message translates to:
  /// **'Create and manage accounts and wallets with autonomy and security.'**
  String get landingFeatureWalletsBody;

  /// No description provided for @landingFeatureOnchainReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'On-chain receiving'**
  String get landingFeatureOnchainReceiveTitle;

  /// No description provided for @landingFeatureOnchainReceiveBody.
  ///
  /// In en, this message translates to:
  /// **'Receive Bitcoin by on-chain address with full control over your assets.'**
  String get landingFeatureOnchainReceiveBody;

  /// No description provided for @landingFeatureLightningTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get landingFeatureLightningTitle;

  /// No description provided for @landingFeatureLightningBody.
  ///
  /// In en, this message translates to:
  /// **'Create and pay Lightning invoices with speed and low cost.'**
  String get landingFeatureLightningBody;

  /// No description provided for @landingFeatureInternalTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Internal transfers'**
  String get landingFeatureInternalTransfersTitle;

  /// No description provided for @landingFeatureInternalTransfersBody.
  ///
  /// In en, this message translates to:
  /// **'Move balances between Kerosene users instantly and privately.'**
  String get landingFeatureInternalTransfersBody;

  /// No description provided for @landingFeaturePaymentLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment links'**
  String get landingFeaturePaymentLinksTitle;

  /// No description provided for @landingFeaturePaymentLinksBody.
  ///
  /// In en, this message translates to:
  /// **'Create links and payment requests to receive Bitcoin easily.'**
  String get landingFeaturePaymentLinksBody;

  /// No description provided for @landingFeatureRealtimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Real time'**
  String get landingFeatureRealtimeTitle;

  /// No description provided for @landingFeatureRealtimeBody.
  ///
  /// In en, this message translates to:
  /// **'Track balances and transactions in real time with full transparency.'**
  String get landingFeatureRealtimeBody;

  /// No description provided for @landingAudienceTitle.
  ///
  /// In en, this message translates to:
  /// **'For people and businesses'**
  String get landingAudienceTitle;

  /// No description provided for @landingPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'For people'**
  String get landingPeopleTitle;

  /// No description provided for @landingPeopleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily use with privacy and control.'**
  String get landingPeopleDaily;

  /// No description provided for @landingPeopleCustody.
  ///
  /// In en, this message translates to:
  /// **'Secure custody with institutional standards.'**
  String get landingPeopleCustody;

  /// No description provided for @landingPeopleSeparation.
  ///
  /// In en, this message translates to:
  /// **'Separation between operational balance and observable cold wallets.'**
  String get landingPeopleSeparation;

  /// No description provided for @landingPeopleLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with passkey or TOTP.'**
  String get landingPeopleLogin;

  /// No description provided for @landingBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'For businesses'**
  String get landingBusinessTitle;

  /// No description provided for @landingBusinessPanel.
  ///
  /// In en, this message translates to:
  /// **'Complete web panel for teams and admins.'**
  String get landingBusinessPanel;

  /// No description provided for @landingBusinessOperations.
  ///
  /// In en, this message translates to:
  /// **'Operational management of wallets and users.'**
  String get landingBusinessOperations;

  /// No description provided for @landingBusinessMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure and liquidity monitoring.'**
  String get landingBusinessMonitoring;

  /// No description provided for @landingBusinessVision.
  ///
  /// In en, this message translates to:
  /// **'Real-time financial and operational view.'**
  String get landingBusinessVision;

  /// No description provided for @landingArchitectureTitle.
  ///
  /// In en, this message translates to:
  /// **'Architecture prepared for sensitive scenarios.'**
  String get landingArchitectureTitle;

  /// No description provided for @landingArchitectureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kerosene was designed beyond superficial integrations. A private, resilient, auditable Bitcoin infrastructure built for the long term.'**
  String get landingArchitectureSubtitle;

  /// No description provided for @landingArchitectureBitcoinCoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Core'**
  String get landingArchitectureBitcoinCoreTitle;

  /// No description provided for @landingArchitectureBitcoinCoreBody.
  ///
  /// In en, this message translates to:
  /// **'Base layer for validation and consensus.'**
  String get landingArchitectureBitcoinCoreBody;

  /// No description provided for @landingArchitectureLightningTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get landingArchitectureLightningTitle;

  /// No description provided for @landingArchitectureLightningBody.
  ///
  /// In en, this message translates to:
  /// **'Instant and efficient payments.'**
  String get landingArchitectureLightningBody;

  /// No description provided for @landingArchitectureVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get landingArchitectureVaultTitle;

  /// No description provided for @landingArchitectureVaultBody.
  ///
  /// In en, this message translates to:
  /// **'Cold storage with security policy.'**
  String get landingArchitectureVaultBody;

  /// No description provided for @landingArchitectureMpcTitle.
  ///
  /// In en, this message translates to:
  /// **'MPC'**
  String get landingArchitectureMpcTitle;

  /// No description provided for @landingArchitectureMpcBody.
  ///
  /// In en, this message translates to:
  /// **'Distributed signatures without a single point of failure.'**
  String get landingArchitectureMpcBody;

  /// No description provided for @landingArchitectureTorTitle.
  ///
  /// In en, this message translates to:
  /// **'Tor'**
  String get landingArchitectureTorTitle;

  /// No description provided for @landingArchitectureTorBody.
  ///
  /// In en, this message translates to:
  /// **'Privacy and anonymous routing.'**
  String get landingArchitectureTorBody;

  /// No description provided for @landingArchitectureShardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Regional shards'**
  String get landingArchitectureShardsTitle;

  /// No description provided for @landingArchitectureShardsBody.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure distributed by regions.'**
  String get landingArchitectureShardsBody;

  /// No description provided for @landingArchitectureLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Internal ledger'**
  String get landingArchitectureLedgerTitle;

  /// No description provided for @landingArchitectureLedgerBody.
  ///
  /// In en, this message translates to:
  /// **'Private and consistent accounting.'**
  String get landingArchitectureLedgerBody;

  /// No description provided for @landingArchitectureAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get landingArchitectureAuditTitle;

  /// No description provided for @landingArchitectureAuditBody.
  ///
  /// In en, this message translates to:
  /// **'Continuous audit and operational transparency.'**
  String get landingArchitectureAuditBody;

  /// No description provided for @landingSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security at every layer.'**
  String get landingSecurityTitle;

  /// No description provided for @landingSecurityPasskeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Passkeys and TOTP'**
  String get landingSecurityPasskeysTitle;

  /// No description provided for @landingSecurityPasskeysBody.
  ///
  /// In en, this message translates to:
  /// **'Modern authentication with passkeys and TOTP 2FA to protect access.'**
  String get landingSecurityPasskeysBody;

  /// No description provided for @landingSecurityVaultMpcTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault and MPC'**
  String get landingSecurityVaultMpcTitle;

  /// No description provided for @landingSecurityVaultMpcBody.
  ///
  /// In en, this message translates to:
  /// **'Custody with MPC and distributed vaults for maximum resilience.'**
  String get landingSecurityVaultMpcBody;

  /// No description provided for @landingSecurityPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy by default'**
  String get landingSecurityPrivacyTitle;

  /// No description provided for @landingSecurityPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Privacy incorporated across the whole operation, by design.'**
  String get landingSecurityPrivacyBody;

  /// No description provided for @landingSecurityAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational audit'**
  String get landingSecurityAuditTitle;

  /// No description provided for @landingSecurityAuditBody.
  ///
  /// In en, this message translates to:
  /// **'Continuous monitoring, private logs, and independent audit.'**
  String get landingSecurityAuditBody;

  /// No description provided for @landingFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'More control. Less exposure. More predictability.'**
  String get landingFinalTitle;

  /// No description provided for @landingFinalBody.
  ///
  /// In en, this message translates to:
  /// **'Kerosene is private Bitcoin financial infrastructure for people and businesses that want to store, use, and move value with more control, security, and independence.'**
  String get landingFinalBody;

  /// No description provided for @landingFooterRights.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Kerosene. All rights reserved.'**
  String get landingFooterRights;

  /// No description provided for @landingFooterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get landingFooterStatus;

  /// No description provided for @landingStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get landingStatusOnline;

  /// No description provided for @landingStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get landingStatusChecking;

  /// No description provided for @landingStatusDegraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get landingStatusDegraded;

  /// No description provided for @landingStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get landingStatusUnavailable;

  /// No description provided for @landingStatusAuthorized.
  ///
  /// In en, this message translates to:
  /// **'authorized'**
  String get landingStatusAuthorized;

  /// No description provided for @landingStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get landingStatusUnknown;

  /// No description provided for @landingStatusPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Kerosene public status'**
  String get landingStatusPageTitle;

  /// No description provided for @landingStatusPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness and release published without secrets, tokens, or sensitive configuration.'**
  String get landingStatusPageSubtitle;

  /// No description provided for @landingStatusRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get landingStatusRelease;

  /// No description provided for @landingStatusService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get landingStatusService;

  /// No description provided for @landingStatusRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get landingStatusRegion;

  /// No description provided for @landingStatusBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get landingStatusBuild;

  /// No description provided for @landingStatusManifest.
  ///
  /// In en, this message translates to:
  /// **'Manifest'**
  String get landingStatusManifest;

  /// No description provided for @homeFundsDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund Distribution'**
  String get homeFundsDistributionTitle;

  /// No description provided for @homeRecentActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get homeRecentActivitiesTitle;

  /// No description provided for @homeViewStatementShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get homeViewStatementShortLabel;

  /// No description provided for @homeOnchainFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'On-chain'**
  String get homeOnchainFilterLabel;

  /// No description provided for @homePlatformFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get homePlatformFilterLabel;

  /// No description provided for @homeNoticesFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get homeNoticesFilterLabel;

  /// No description provided for @homeEducationInternalTitle.
  ///
  /// In en, this message translates to:
  /// **'Kerosene'**
  String get homeEducationInternalTitle;

  /// No description provided for @homeEducationInternalBody.
  ///
  /// In en, this message translates to:
  /// **'Use internal transfers when the destination also uses Kerosene. Sending is fast and has no network fee.'**
  String get homeEducationInternalBody;

  /// No description provided for @homeEducationInternalTag.
  ///
  /// In en, this message translates to:
  /// **'Internal use'**
  String get homeEducationInternalTag;

  /// No description provided for @homeEducationWalletHashTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet hash'**
  String get homeEducationWalletHashTitle;

  /// No description provided for @homeEducationWalletHashBody.
  ///
  /// In en, this message translates to:
  /// **'To receive internally, share only the hash made available by your own wallet.'**
  String get homeEducationWalletHashBody;

  /// No description provided for @homeEducationWalletHashTag.
  ///
  /// In en, this message translates to:
  /// **'Wallet identity'**
  String get homeEducationWalletHashTag;

  /// No description provided for @homeEducationLightningTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get homeEducationLightningTitle;

  /// No description provided for @homeEducationLightningBody.
  ///
  /// In en, this message translates to:
  /// **'Use Lightning to pay invoices or lightning addresses with near-instant confirmation.'**
  String get homeEducationLightningBody;

  /// No description provided for @homeEducationLightningTag.
  ///
  /// In en, this message translates to:
  /// **'Fast payments'**
  String get homeEducationLightningTag;

  /// No description provided for @homeEducationOnchainTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin on-chain'**
  String get homeEducationOnchainTitle;

  /// No description provided for @homeEducationOnchainBody.
  ///
  /// In en, this message translates to:
  /// **'Use on-chain to store value, move to self-custody, or send to an external Bitcoin wallet.'**
  String get homeEducationOnchainBody;

  /// No description provided for @homeEducationOnchainTag.
  ///
  /// In en, this message translates to:
  /// **'Main network'**
  String get homeEducationOnchainTag;

  /// No description provided for @homeEducationConfirmationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get homeEducationConfirmationsTitle;

  /// No description provided for @homeEducationConfirmationsBody.
  ///
  /// In en, this message translates to:
  /// **'On-chain transactions enter blocks. Larger values usually require more confirmations.'**
  String get homeEducationConfirmationsBody;

  /// No description provided for @homeEducationConfirmationsTag.
  ///
  /// In en, this message translates to:
  /// **'Network time'**
  String get homeEducationConfirmationsTag;

  /// No description provided for @homeEducationFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get homeEducationFeesTitle;

  /// No description provided for @homeEducationFeesBody.
  ///
  /// In en, this message translates to:
  /// **'Fees vary with the network. Before confirming, review the total debited and the amount received.'**
  String get homeEducationFeesBody;

  /// No description provided for @homeEducationFeesTag.
  ///
  /// In en, this message translates to:
  /// **'Network cost'**
  String get homeEducationFeesTag;

  /// No description provided for @homeEducationBitcoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin'**
  String get homeEducationBitcoinTitle;

  /// No description provided for @homeEducationBitcoinBody.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin is scarce digital money. You can use different paths depending on urgency and destination.'**
  String get homeEducationBitcoinBody;

  /// No description provided for @homeEducationBitcoinTag.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get homeEducationBitcoinTag;

  /// No description provided for @homeEducationLightningGeneralBody.
  ///
  /// In en, this message translates to:
  /// **'Lightning is useful for smaller and faster payments using invoices, LNURL, or lightning addresses.'**
  String get homeEducationLightningGeneralBody;

  /// No description provided for @homeEducationLightningGeneralTag.
  ///
  /// In en, this message translates to:
  /// **'Instant payment'**
  String get homeEducationLightningGeneralTag;

  /// No description provided for @homeEducationKeroseneGeneralBody.
  ///
  /// In en, this message translates to:
  /// **'Kerosene separates internal, Lightning, and on-chain flows to reduce payment mistakes.'**
  String get homeEducationKeroseneGeneralBody;

  /// No description provided for @homeEducationKeroseneGeneralTag.
  ///
  /// In en, this message translates to:
  /// **'How to choose'**
  String get homeEducationKeroseneGeneralTag;

  /// No description provided for @designSystemTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Design system'**
  String get designSystemTemplateTitle;

  /// No description provided for @designSystemTemplateIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'01. Visual identity and title'**
  String get designSystemTemplateIdentitySection;

  /// No description provided for @designSystemTemplateHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Kerosene Sovereign Core'**
  String get designSystemTemplateHeroTitle;

  /// No description provided for @designSystemTemplatePanelsSection.
  ///
  /// In en, this message translates to:
  /// **'02. Panels and monochrome box'**
  String get designSystemTemplatePanelsSection;

  /// No description provided for @designSystemTemplateInputSection.
  ///
  /// In en, this message translates to:
  /// **'03. Formatted data input'**
  String get designSystemTemplateInputSection;

  /// No description provided for @designSystemTemplateButtonsSection.
  ///
  /// In en, this message translates to:
  /// **'04. Standard buttons'**
  String get designSystemTemplateButtonsSection;

  /// No description provided for @designSystemTemplateStatusSection.
  ///
  /// In en, this message translates to:
  /// **'05. Status labels'**
  String get designSystemTemplateStatusSection;
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
      'that was used.');
}
