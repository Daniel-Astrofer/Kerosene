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
  /// **'No transactions yet'**
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
