import 'app_copy_parts/app_copy_part_1.dart';
import 'app_copy_parts/app_copy_part_2.dart';
import 'app_copy_parts/app_copy_part_3.dart';
import 'app_copy_parts/app_copy_part_4.dart';

export 'localized_copy.dart';

/// Legacy source for copy that has not yet been migrated to ARB-backed l10n.
///
/// New active UI copy must be added to ARB files and accessed through
/// `context.tr`. Existing entries should be migrated or moved to legacy/roadmap
/// with the feature that still needs them.
class AppCopy {
  AppCopy._();

  static const signupUsernameValidationRequired =
      AppCopyPart1.signupUsernameValidationRequired;
  static const signupUsernameValidationMin =
      AppCopyPart1.signupUsernameValidationMin;
  static const signupUsernameValidationMax =
      AppCopyPart1.signupUsernameValidationMax;
  static const signupUsernameValidationCharset =
      AppCopyPart1.signupUsernameValidationCharset;
  static const signupUsernamePreviewPlaceholder =
      AppCopyPart1.signupUsernamePreviewPlaceholder;
  static const signupUsernameEyebrow = AppCopyPart1.signupUsernameEyebrow;
  static const signupUsernameTitle = AppCopyPart1.signupUsernameTitle;
  static const signupUsernameSubtitle = AppCopyPart1.signupUsernameSubtitle;
  static const signupUsernameHighlightLabel =
      AppCopyPart1.signupUsernameHighlightLabel;
  static const signupUsernameHighlightReady =
      AppCopyPart1.signupUsernameHighlightReady;
  static const signupUsernameHighlightPending =
      AppCopyPart1.signupUsernameHighlightPending;
  static const signupUsernameChipLength = AppCopyPart1.signupUsernameChipLength;
  static const signupUsernameChipCharset =
      AppCopyPart1.signupUsernameChipCharset;
  static const signupUsernameChipUnderscore =
      AppCopyPart1.signupUsernameChipUnderscore;
  static const signupUsernameLabel = AppCopyPart1.signupUsernameLabel;
  static const signupUsernameHint = AppCopyPart1.signupUsernameHint;
  static const signupUsernameGenerateTooltip =
      AppCopyPart1.signupUsernameGenerateTooltip;
  static const signupUsernameValidTag = AppCopyPart1.signupUsernameValidTag;
  static const signupUsernameAdjustTag = AppCopyPart1.signupUsernameAdjustTag;
  static const signupUsernameNoSpaces = AppCopyPart1.signupUsernameNoSpaces;
  static const signupUsernameNoUppercase =
      AppCopyPart1.signupUsernameNoUppercase;
  static const signupUsernameSpeedTitle = AppCopyPart1.signupUsernameSpeedTitle;
  static const signupUsernameSpeedBody = AppCopyPart1.signupUsernameSpeedBody;
  static const signupUsernameSuggestNow = AppCopyPart1.signupUsernameSuggestNow;
  static const signupUsernameNoticeTitle =
      AppCopyPart1.signupUsernameNoticeTitle;
  static const signupUsernameNoticeBody = AppCopyPart1.signupUsernameNoticeBody;
  static const signupUsernameContinue = AppCopyPart1.signupUsernameContinue;
  static const signupHardwareEyebrow = AppCopyPart1.signupHardwareEyebrow;
  static const signupHardwareTitle = AppCopyPart1.signupHardwareTitle;
  static const signupHardwareSubtitle = AppCopyPart1.signupHardwareSubtitle;
  static const signupHardwareHighlightLabel =
      AppCopyPart1.signupHardwareHighlightLabel;
  static const signupHardwareHighlightValue =
      AppCopyPart1.signupHardwareHighlightValue;
  static const signupHardwareHighlightHint =
      AppCopyPart1.signupHardwareHighlightHint;
  static const signupHardwareChipBiometric =
      AppCopyPart1.signupHardwareChipBiometric;
  static const signupHardwareChipDeviceLock =
      AppCopyPart1.signupHardwareChipDeviceLock;
  static const signupHardwareChipSaferAccess =
      AppCopyPart1.signupHardwareChipSaferAccess;
  static const signupHardwareBenefitExposure =
      AppCopyPart1.signupHardwareBenefitExposure;
  static const signupHardwareBenefitBinding =
      AppCopyPart1.signupHardwareBenefitBinding;
  static const signupHardwareBenefitLock =
      AppCopyPart1.signupHardwareBenefitLock;
  static const signupHardwareNoticeTitle =
      AppCopyPart1.signupHardwareNoticeTitle;
  static const signupHardwareNoticeBody = AppCopyPart1.signupHardwareNoticeBody;
  static const signupHardwareCta = AppCopyPart1.signupHardwareCta;
  static const signupPaymentSecurityLabelMultisig =
      AppCopyPart1.signupPaymentSecurityLabelMultisig;
  static const signupPaymentSecurityLabelStandard =
      AppCopyPart1.signupPaymentSecurityLabelStandard;
  static const signupPaymentSecuritySummarySlip39 =
      AppCopyPart1.signupPaymentSecuritySummarySlip39;
  static const signupPaymentSecuritySummaryMultisig =
      AppCopyPart1.signupPaymentSecuritySummaryMultisig;
  static const signupPaymentSecuritySummaryStandard =
      AppCopyPart1.signupPaymentSecuritySummaryStandard;
  static const signupPaymentEyebrow = AppCopyPart1.signupPaymentEyebrow;
  static const signupPaymentTitle = AppCopyPart1.signupPaymentTitle;
  static const signupPaymentSubtitle = AppCopyPart1.signupPaymentSubtitle;
  static const signupPaymentHighlightLabel =
      AppCopyPart1.signupPaymentHighlightLabel;
  static const signupPaymentChip2fa = AppCopyPart1.signupPaymentChip2fa;
  static const signupPaymentChipPasskey = AppCopyPart1.signupPaymentChipPasskey;
  static const signupPaymentChipActivation =
      AppCopyPart1.signupPaymentChipActivation;
  static const signupPaymentReviewUsernameLabel =
      AppCopyPart1.signupPaymentReviewUsernameLabel;
  static const signupPaymentReviewUsernameHint =
      AppCopyPart1.signupPaymentReviewUsernameHint;
  static const signupPaymentReviewProtectionLabel =
      AppCopyPart1.signupPaymentReviewProtectionLabel;
  static const signupPaymentSectionTitle =
      AppCopyPart1.signupPaymentSectionTitle;
  static const signupPaymentStepPrepareTitle =
      AppCopyPart1.signupPaymentStepPrepareTitle;
  static const signupPaymentStepPrepareBody =
      AppCopyPart1.signupPaymentStepPrepareBody;
  static const signupPaymentStepTotpTitle =
      AppCopyPart1.signupPaymentStepTotpTitle;
  static const signupPaymentStepTotpBody =
      AppCopyPart1.signupPaymentStepTotpBody;
  static const signupPaymentStepPasskeyTitle =
      AppCopyPart1.signupPaymentStepPasskeyTitle;
  static const signupPaymentStepPasskeyBody =
      AppCopyPart1.signupPaymentStepPasskeyBody;
  static const signupPaymentNoticeTitle = AppCopyPart1.signupPaymentNoticeTitle;
  static const signupPaymentNoticeBody = AppCopyPart1.signupPaymentNoticeBody;
  static const signupPaymentCta = AppCopyPart1.signupPaymentCta;
  static const presentationPrivacyEyebrow =
      AppCopyPart1.presentationPrivacyEyebrow;
  static const presentationPrivacyTitle = AppCopyPart1.presentationPrivacyTitle;
  static const presentationPrivacySummary =
      AppCopyPart1.presentationPrivacySummary;
  static const presentationPrivacyHighlightOnion =
      AppCopyPart1.presentationPrivacyHighlightOnion;
  static const presentationPrivacyHighlightExposure =
      AppCopyPart1.presentationPrivacyHighlightExposure;
  static const presentationPrivacyHighlightArchitecture =
      AppCopyPart1.presentationPrivacyHighlightArchitecture;
  static const presentationPrivacyHeroLabel =
      AppCopyPart1.presentationPrivacyHeroLabel;
  static const presentationPrivacyHeroCaption =
      AppCopyPart1.presentationPrivacyHeroCaption;
  static const presentationRecoveryEyebrow =
      AppCopyPart1.presentationRecoveryEyebrow;
  static const presentationRecoveryTitle =
      AppCopyPart1.presentationRecoveryTitle;
  static const presentationRecoverySummary =
      AppCopyPart1.presentationRecoverySummary;
  static const presentationRecoveryHighlightSeed =
      AppCopyPart1.presentationRecoveryHighlightSeed;
  static const presentationRecoveryHighlightTotp =
      AppCopyPart1.presentationRecoveryHighlightTotp;
  static const presentationRecoveryHighlightPasskey =
      AppCopyPart1.presentationRecoveryHighlightPasskey;
  static const presentationRecoveryHeroLabel =
      AppCopyPart1.presentationRecoveryHeroLabel;
  static const presentationRecoveryHeroCaption =
      AppCopyPart1.presentationRecoveryHeroCaption;
  static const presentationActivationEyebrow =
      AppCopyPart1.presentationActivationEyebrow;
  static const presentationActivationTitle =
      AppCopyPart1.presentationActivationTitle;
  static const presentationActivationSummary =
      AppCopyPart1.presentationActivationSummary;
  static const presentationActivationHighlightLivePending =
      AppCopyPart1.presentationActivationHighlightLivePending;
  static const presentationActivationHighlightFees =
      AppCopyPart1.presentationActivationHighlightFees;
  static const presentationActivationHighlightConfirmations =
      AppCopyPart1.presentationActivationHighlightConfirmations;
  static const presentationActivationHeroLabel =
      AppCopyPart1.presentationActivationHeroLabel;
  static const presentationActivationHeroLive =
      AppCopyPart1.presentationActivationHeroLive;
  static const presentationActivationHeroCurrentAmount =
      AppCopyPart1.presentationActivationHeroCurrentAmount;
  static const presentationActivationHeroPendingAmount =
      AppCopyPart1.presentationActivationHeroPendingAmount;
  static const homeLoadingAuthFailure = AppCopyPart1.homeLoadingAuthFailure;
  static const homeLoadingQuoteUnavailable =
      AppCopyPart1.homeLoadingQuoteUnavailable;
  static const homeLoadingSlowConnection =
      AppCopyPart1.homeLoadingSlowConnection;
  static const homeLoadingSyncing = AppCopyPart1.homeLoadingSyncing;
  static const homeLoadingAccessDenied = AppCopyPart1.homeLoadingAccessDenied;
  static const homeLoadingQuoteBlockingBody =
      AppCopyPart1.homeLoadingQuoteBlockingBody;
  static const homeLoadingTorRetryBody = AppCopyPart1.homeLoadingTorRetryBody;
  static const homeLoadingSecureAssetsBody =
      AppCopyPart2.homeLoadingSecureAssetsBody;
  static const homeLoadingTryAgain = AppCopyPart2.homeLoadingTryAgain;
  static const homeLoadingReloadQuotes = AppCopyPart2.homeLoadingReloadQuotes;
  static const homeLoadingRepeatSync = AppCopyPart2.homeLoadingRepeatSync;
  static const createWalletNameRequired = AppCopyPart2.createWalletNameRequired;
  static const createWalletSuccess = AppCopyPart2.createWalletSuccess;
  static const createWalletScreenTitle = AppCopyPart2.createWalletScreenTitle;
  static const createWalletGenerateStructure =
      AppCopyPart2.createWalletGenerateStructure;
  static const createWalletFinish = AppCopyPart2.createWalletFinish;
  static const createWalletBackAndEdit = AppCopyPart2.createWalletBackAndEdit;
  static const createWalletProtectSeed = AppCopyPart2.createWalletProtectSeed;
  static const createWalletDefineParameters =
      AppCopyPart2.createWalletDefineParameters;
  static const createWalletProtectSeedBody =
      AppCopyPart2.createWalletProtectSeedBody;
  static const createWalletDefineParametersBody =
      AppCopyPart2.createWalletDefineParametersBody;
  static const createWalletNameLabel = AppCopyPart2.createWalletNameLabel;
  static const createWalletNameHint = AppCopyPart2.createWalletNameHint;
  static const createWalletPassphraseSize =
      AppCopyPart2.createWalletPassphraseSize;
  static const createWalletProtocolSecurity =
      AppCopyPart2.createWalletProtocolSecurity;
  static const createWalletStandardTitle =
      AppCopyPart2.createWalletStandardTitle;
  static const createWalletStandardBody = AppCopyPart2.createWalletStandardBody;
  static const createWalletShamirTitle = AppCopyPart2.createWalletShamirTitle;
  static const createWalletShamirBody = AppCopyPart2.createWalletShamirBody;
  static const createWalletPaperOnly = AppCopyPart2.createWalletPaperOnly;
  static const createWalletColdPublicKeyLabel =
      AppCopyPart2.createWalletColdPublicKeyLabel;
  static const createWalletColdPublicKeyHint =
      AppCopyPart2.createWalletColdPublicKeyHint;
  static const createWalletManagementPassphraseLabel =
      AppCopyPart2.createWalletManagementPassphraseLabel;
  static const createWalletManagementPassphraseHint =
      AppCopyPart2.createWalletManagementPassphraseHint;
  static const createWalletModeLabel = AppCopyPart2.createWalletModeLabel;
  static const createWalletKeroseneModeTitle =
      AppCopyPart2.createWalletKeroseneModeTitle;
  static const createWalletKeroseneModeSubtitle =
      AppCopyPart2.createWalletKeroseneModeSubtitle;
  static const createWalletColdModeTitle =
      AppCopyPart2.createWalletColdModeTitle;
  static const createWalletColdModeSubtitle =
      AppCopyPart2.createWalletColdModeSubtitle;
  static const depositAmountZero = AppCopyPart2.depositAmountZero;
  static const withdrawReviewLightningEmpty =
      AppCopyPart2.withdrawReviewLightningEmpty;
  static const withdrawReviewOnChainEmpty =
      AppCopyPart2.withdrawReviewOnChainEmpty;
  static const withdrawReviewAuthReason = AppCopyPart2.withdrawReviewAuthReason;
  static const withdrawReviewAuthFailed = AppCopyPart2.withdrawReviewAuthFailed;
  static const withdrawReviewInvalidTotp =
      AppCopyPart2.withdrawReviewInvalidTotp;
  static const withdrawReviewLightningTitle =
      AppCopyPart2.withdrawReviewLightningTitle;
  static const withdrawReviewOnChainTitle =
      AppCopyPart2.withdrawReviewOnChainTitle;
  static const withdrawReviewPasteLightning =
      AppCopyPart2.withdrawReviewPasteLightning;
  static const withdrawReviewPasteBitcoinAddress =
      AppCopyPart2.withdrawReviewPasteBitcoinAddress;
  static const withdrawReviewContinue = AppCopyPart2.withdrawReviewContinue;
  static const withdrawReviewSecurityTitle =
      AppCopyPart2.withdrawReviewSecurityTitle;
  static const withdrawReviewShamirLabel =
      AppCopyPart2.withdrawReviewShamirLabel;
  static const withdrawReviewVerified = AppCopyPart2.withdrawReviewVerified;
  static const withdrawReviewPending = AppCopyPart2.withdrawReviewPending;
  static const withdrawReviewPasskeyLabel =
      AppCopyPart2.withdrawReviewPasskeyLabel;
  static const withdrawReviewRequired = AppCopyPart2.withdrawReviewRequired;
  static const withdrawReviewEnterTotp = AppCopyPart2.withdrawReviewEnterTotp;
  static const withdrawReviewConfirm = AppCopyPart2.withdrawReviewConfirm;
  static const withdrawDestinationDetectedOnChain =
      AppCopyPart2.withdrawDestinationDetectedOnChain;
  static const withdrawDestinationDetectedLightning =
      AppCopyPart2.withdrawDestinationDetectedLightning;
  static const withdrawDestinationInvalid =
      AppCopyPart2.withdrawDestinationInvalid;
  static const withdrawDestinationLightningUnsupported =
      AppCopyPart2.withdrawDestinationLightningUnsupported;
  static const withdrawDestinationPaste = AppCopyPart2.withdrawDestinationPaste;
  static const withdrawDestinationPasteHint =
      AppCopyPart2.withdrawDestinationPasteHint;
  static const withdrawWalletBalanceLabel =
      AppCopyPart2.withdrawWalletBalanceLabel;
  static const withdrawDestinationLabel = AppCopyPart2.withdrawDestinationLabel;
  static const withdrawNetworkAutoLabel = AppCopyPart2.withdrawNetworkAutoLabel;
  static const withdrawSecurityTotpHint = AppCopyPart2.withdrawSecurityTotpHint;
  static const withdrawDescriptionLabel = AppCopyPart2.withdrawDescriptionLabel;
  static const withdrawReviewSummaryLabel =
      AppCopyPart2.withdrawReviewSummaryLabel;
  static const withdrawInsufficientBalance =
      AppCopyPart2.withdrawInsufficientBalance;
  static const withdrawNetworkOnChainChip =
      AppCopyPart2.withdrawNetworkOnChainChip;
  static const withdrawNetworkReviewChip =
      AppCopyPart2.withdrawNetworkReviewChip;
  static const withdrawFeeModeTitle = AppCopyPart2.withdrawFeeModeTitle;
  static const withdrawFeeModeSenderPaysTitle =
      AppCopyPart2.withdrawFeeModeSenderPaysTitle;
  static const withdrawFeeModeSenderPaysBody =
      AppCopyPart2.withdrawFeeModeSenderPaysBody;
  static const withdrawFeeModeRecipientPaysTitle =
      AppCopyPart2.withdrawFeeModeRecipientPaysTitle;
  static const withdrawFeeModeRecipientPaysBody =
      AppCopyPart2.withdrawFeeModeRecipientPaysBody;
  static const withdrawReceiverReceivesLabel =
      AppCopyPart2.withdrawReceiverReceivesLabel;
  static const withdrawYouPayTotalLabel = AppCopyPart2.withdrawYouPayTotalLabel;
  static const withdrawFeesDeductedLabel =
      AppCopyPart2.withdrawFeesDeductedLabel;
  static const withdrawFeesAddedLabel = AppCopyPart2.withdrawFeesAddedLabel;
  static const withdrawFeeModeDeductedHint =
      AppCopyPart2.withdrawFeeModeDeductedHint;
  static const withdrawFeeModeAddedHint = AppCopyPart2.withdrawFeeModeAddedHint;
  static const withdrawReceiptWallet = AppCopyPart2.withdrawReceiptWallet;
  static const withdrawReceiptInvoice = AppCopyPart2.withdrawReceiptInvoice;
  static const withdrawReceiptTime = AppCopyPart2.withdrawReceiptTime;
  static const withdrawReceiptFee = AppCopyPart2.withdrawReceiptFee;
  static const withdrawReceiptStatus = AppCopyPart2.withdrawReceiptStatus;
  static const withdrawReceiptConfirmed = AppCopyPart2.withdrawReceiptConfirmed;
  static const withdrawReceiptTransactionId =
      AppCopyPart2.withdrawReceiptTransactionId;
  static const settingsOverviewSummary = AppCopyPart2.settingsOverviewSummary;
  static const settingsRouting = AppCopyPart2.settingsRouting;
  static const settingsOnionActive = AppCopyPart2.settingsOnionActive;
  static const settingsDirectConnection = AppCopyPart2.settingsDirectConnection;
  static const settingsBiometrics = AppCopyPart2.settingsBiometrics;
  static const settingsBalance = AppCopyPart2.settingsBalance;
  static const settingsHidden = AppCopyPart2.settingsHidden;
  static const settingsVisible = AppCopyPart2.settingsVisible;
  static const settingsLocation = AppCopyPart2.settingsLocation;
  static const loginPassphraseIntro = AppCopyPart2.loginPassphraseIntro;
  static const loginPassphraseHint = AppCopyPart2.loginPassphraseHint;
  static const loginPassphraseValidationAllWords =
      AppCopyPart2.loginPassphraseValidationAllWords;
  static const loginPassphraseTitle = AppCopyPart2.loginPassphraseTitle;
  static const loginPassphraseManualMode =
      AppCopyPart2.loginPassphraseManualMode;
  static const loginPassphraseDescription =
      AppCopyPart2.loginPassphraseDescription;
  static const loginPassphraseRecoveryHint =
      AppCopyPart2.loginPassphraseRecoveryHint;
  static const loginPassphraseWordHint = AppCopyPart3.loginPassphraseWordHint;
  static const loginManualModePassphrase =
      AppCopyPart3.loginManualModePassphrase;
  static const loginManualModeShamir = AppCopyPart3.loginManualModeShamir;
  static const loginPassphraseDescriptionShamir =
      AppCopyPart3.loginPassphraseDescriptionShamir;
  static const loginShamirShareCountLabel =
      AppCopyPart3.loginShamirShareCountLabel;
  static const loginShamirShareCountHint =
      AppCopyPart3.loginShamirShareCountHint;
  static const loginShamirContinue = AppCopyPart3.loginShamirContinue;
  static const loginPassphraseInvalidWord =
      AppCopyPart3.loginPassphraseInvalidWord;
  static const loginShamirInvalidShare = AppCopyPart3.loginShamirInvalidShare;
  static const loginMultisigTitle = AppCopyPart3.loginMultisigTitle;
  static const loginMultisigDescription = AppCopyPart3.loginMultisigDescription;
  static const loginMultisigShardCountLabel =
      AppCopyPart3.loginMultisigShardCountLabel;
  static const loginMultisigShardCountHint =
      AppCopyPart3.loginMultisigShardCountHint;
  static const loginMultisigShardIncomplete =
      AppCopyPart3.loginMultisigShardIncomplete;
  static const authReasonWalletAccess = AppCopyPart3.authReasonWalletAccess;
  static const authReasonSovereignKeyAccess =
      AppCopyPart3.authReasonSovereignKeyAccess;
  static const authReasonTransactionConfirm =
      AppCopyPart3.authReasonTransactionConfirm;
  static const signupRequirementsEyebrow =
      AppCopyPart3.signupRequirementsEyebrow;
  static const signupRequirementsTitle = AppCopyPart3.signupRequirementsTitle;
  static const signupRequirementsSubtitle =
      AppCopyPart3.signupRequirementsSubtitle;
  static const signupRequirementsHighlightLabel =
      AppCopyPart3.signupRequirementsHighlightLabel;
  static const signupRequirementsHighlightLiveHint =
      AppCopyPart3.signupRequirementsHighlightLiveHint;
  static const signupRequirementsHighlightPendingHint =
      AppCopyPart3.signupRequirementsHighlightPendingHint;
  static const signupRequirementsChip2fa =
      AppCopyPart3.signupRequirementsChip2fa;
  static const signupRequirementsChipPasskey =
      AppCopyPart3.signupRequirementsChipPasskey;
  static const signupRequirementsChipConfirmations =
      AppCopyPart3.signupRequirementsChipConfirmations;
  static const signupRequirementsPanelTitle =
      AppCopyPart3.signupRequirementsPanelTitle;
  static const signupRequirementsTimeTitle =
      AppCopyPart3.signupRequirementsTimeTitle;
  static const signupRequirementsTimeBody =
      AppCopyPart3.signupRequirementsTimeBody;
  static const signupRequirementsAuthenticatorTitle =
      AppCopyPart3.signupRequirementsAuthenticatorTitle;
  static const signupRequirementsAuthenticatorBody =
      AppCopyPart3.signupRequirementsAuthenticatorBody;
  static const signupRequirementsBackupTitle =
      AppCopyPart3.signupRequirementsBackupTitle;
  static const signupRequirementsBackupBody =
      AppCopyPart3.signupRequirementsBackupBody;
  static const signupRequirementsNoticeTitle =
      AppCopyPart3.signupRequirementsNoticeTitle;
  static const signupRequirementsNoticeBody =
      AppCopyPart3.signupRequirementsNoticeBody;
  static const signupRequirementsCta = AppCopyPart3.signupRequirementsCta;
  static const signupRequirementsCaption =
      AppCopyPart3.signupRequirementsCaption;
  static const signupSecurityStandardTitle =
      AppCopyPart3.signupSecurityStandardTitle;
  static const signupSecurityStandardBadge =
      AppCopyPart3.signupSecurityStandardBadge;
  static const signupSecurityStandardDescription =
      AppCopyPart3.signupSecurityStandardDescription;
  static const signupSecurityStandardBulletStore =
      AppCopyPart3.signupSecurityStandardBulletStore;
  static const signupSecurityStandardBulletFit =
      AppCopyPart3.signupSecurityStandardBulletFit;
  static const signupSecurityStandardBulletFriction =
      AppCopyPart3.signupSecurityStandardBulletFriction;
  static const signupSecuritySlip39Badge =
      AppCopyPart3.signupSecuritySlip39Badge;
  static const signupSecuritySlip39Title =
      AppCopyPart3.signupSecuritySlip39Title;
  static const signupSecuritySlip39Description =
      AppCopyPart3.signupSecuritySlip39Description;
  static const signupSecuritySlip39BulletStorage =
      AppCopyPart3.signupSecuritySlip39BulletStorage;
  static const signupSecuritySlip39BulletQuorum =
      AppCopyPart3.signupSecuritySlip39BulletQuorum;
  static const signupSecuritySlip39BulletDiscipline =
      AppCopyPart3.signupSecuritySlip39BulletDiscipline;
  static const signupSecurityMultisigTitle =
      AppCopyPart3.signupSecurityMultisigTitle;
  static const signupSecurityMultisigBadge =
      AppCopyPart3.signupSecurityMultisigBadge;
  static const signupSecurityMultisigDescription =
      AppCopyPart3.signupSecurityMultisigDescription;
  static const signupSecurityMultisigBulletAdvanced =
      AppCopyPart3.signupSecurityMultisigBulletAdvanced;
  static const signupSecurityMultisigBulletRigor =
      AppCopyPart3.signupSecurityMultisigBulletRigor;
  static const signupSecurityMultisigBulletBeginners =
      AppCopyPart3.signupSecurityMultisigBulletBeginners;
  static const signupSecurityMultisigConfigTitle =
      AppCopyPart3.signupSecurityMultisigConfigTitle;
  static const signupSecurityMultisigConfigBody =
      AppCopyPart3.signupSecurityMultisigConfigBody;
  static const signupSecurityMultisigRequiredFactors =
      AppCopyPart3.signupSecurityMultisigRequiredFactors;
  static const signupSecurityMultisigRequiredFactorsHint =
      AppCopyPart3.signupSecurityMultisigRequiredFactorsHint;
  static const signupSecurityEyebrow = AppCopyPart3.signupSecurityEyebrow;
  static const signupSecurityTitle = AppCopyPart3.signupSecurityTitle;
  static const signupSecuritySubtitle = AppCopyPart3.signupSecuritySubtitle;
  static const signupSecurityHighlightLabel =
      AppCopyPart3.signupSecurityHighlightLabel;
  static const signupSecurityChipFriction =
      AppCopyPart3.signupSecurityChipFriction;
  static const signupSecurityChipGuidedBackup =
      AppCopyPart3.signupSecurityChipGuidedBackup;
  static const signupSecuritySlip39ConfigIntro =
      AppCopyPart3.signupSecuritySlip39ConfigIntro;
  static const signupSecuritySlip39TotalSharesHint =
      AppCopyPart3.signupSecuritySlip39TotalSharesHint;
  static const signupSecuritySlip39ThresholdHint =
      AppCopyPart3.signupSecuritySlip39ThresholdHint;
  static const signupSecurityNextScreenTitle =
      AppCopyPart3.signupSecurityNextScreenTitle;
  static const signupSecurityNextScreenSlip39 =
      AppCopyPart3.signupSecurityNextScreenSlip39;
  static const signupSecurityNextScreenStandard =
      AppCopyPart3.signupSecurityNextScreenStandard;
  static const signupSecurityNextScreenMultisig =
      AppCopyPart3.signupSecurityNextScreenMultisig;
  static const signupSeedWordCountRecommended =
      AppCopyPart3.signupSeedWordCountRecommended;
  static const signupSeedTitleSlip39 = AppCopyPart3.signupSeedTitleSlip39;
  static const signupSeedTitleStandard = AppCopyPart3.signupSeedTitleStandard;
  static const signupSeedSubtitleSlip39 = AppCopyPart3.signupSeedSubtitleSlip39;
  static const signupSeedSubtitleStandard =
      AppCopyPart3.signupSeedSubtitleStandard;
  static const signupSeedWarningSlip39 = AppCopyPart3.signupSeedWarningSlip39;
  static const signupSeedWarningStandard =
      AppCopyPart3.signupSeedWarningStandard;
  static const signupSeedGenerateNewShares =
      AppCopyPart3.signupSeedGenerateNewShares;
  static const signupSeedGenerateNewPhrase =
      AppCopyPart3.signupSeedGenerateNewPhrase;
  static const signupSeedConfirmationStandard =
      AppCopyPart3.signupSeedConfirmationStandard;
  static const signupSeedContinueSlip39 = AppCopyPart3.signupSeedContinueSlip39;
  static const signupSeedContinueMultisig =
      AppCopyPart3.signupSeedContinueMultisig;
  static const signupSeedContinueStandard =
      AppCopyPart3.signupSeedContinueStandard;
  static const signupVerificationError = AppCopyPart3.signupVerificationError;
  static const signupVerificationTitle = AppCopyPart3.signupVerificationTitle;
  static const signupVerificationFillHighlighted =
      AppCopyPart3.signupVerificationFillHighlighted;
  static const signupVerificationContinue =
      AppCopyPart3.signupVerificationContinue;
  static const signupVerificationSlip39Title =
      AppCopyPart3.signupVerificationSlip39Title;
  static const signupTotpEyebrow = AppCopyPart3.signupTotpEyebrow;
  static const signupTotpTitle = AppCopyPart3.signupTotpTitle;
  static const signupTotpSubtitle = AppCopyPart3.signupTotpSubtitle;
  static const signupTotpHighlightLabel = AppCopyPart3.signupTotpHighlightLabel;
  static const signupTotpHighlightReady = AppCopyPart3.signupTotpHighlightReady;
  static const signupTotpHighlightPending =
      AppCopyPart3.signupTotpHighlightPending;
  static const signupTotpHighlightHint = AppCopyPart3.signupTotpHighlightHint;
  static const signupTotpChipQr = AppCopyPart3.signupTotpChipQr;
  static const signupTotpChipBackup = AppCopyPart3.signupTotpChipBackup;
  static const signupTotpChipCode = AppCopyPart3.signupTotpChipCode;
  static const signupTotpStepScan = AppCopyPart4.signupTotpStepScan;
  static const signupTotpStepStore = AppCopyPart4.signupTotpStepStore;
  static const signupTotpSecretLabel = AppCopyPart4.signupTotpSecretLabel;
  static const signupTotpBackupCodesLabel =
      AppCopyPart4.signupTotpBackupCodesLabel;
  static const signupTotpBackupConfirm = AppCopyPart4.signupTotpBackupConfirm;
  static const signupTotpStepEnter = AppCopyPart4.signupTotpStepEnter;
  static const signupPowPhaseRequestTitle =
      AppCopyPart4.signupPowPhaseRequestTitle;
  static const signupPowPhaseRequestBody =
      AppCopyPart4.signupPowPhaseRequestBody;
  static const signupPowPhaseSolveTitle = AppCopyPart4.signupPowPhaseSolveTitle;
  static const signupPowPhaseSolveBody = AppCopyPart4.signupPowPhaseSolveBody;
  static const signupPowPhaseProvisionTitle =
      AppCopyPart4.signupPowPhaseProvisionTitle;
  static const signupPowPhaseProvisionBody =
      AppCopyPart4.signupPowPhaseProvisionBody;
  static const signupPowErrorTitle = AppCopyPart4.signupPowErrorTitle;
  static const signupPowEyebrow = AppCopyPart4.signupPowEyebrow;
  static const signupPowSubtitle = AppCopyPart4.signupPowSubtitle;
  static const signupPowHighlightLabel = AppCopyPart4.signupPowHighlightLabel;
  static const signupPowChipAutomatic = AppCopyPart4.signupPowChipAutomatic;
  static const signupPowChipKeepOpen = AppCopyPart4.signupPowChipKeepOpen;
  static const signupPowChipAutoAdvance = AppCopyPart4.signupPowChipAutoAdvance;
  static const signupPowDeviceTitle = AppCopyPart4.signupPowDeviceTitle;
  static const signupPowDeviceSubtitle = AppCopyPart4.signupPowDeviceSubtitle;
  static const signupPowNoticeTitle = AppCopyPart4.signupPowNoticeTitle;
  static const signupPowNoticeLoading = AppCopyPart4.signupPowNoticeLoading;
  static const signupPowNoticeReady = AppCopyPart4.signupPowNoticeReady;
  static const signupPowStatusInProgress =
      AppCopyPart4.signupPowStatusInProgress;
  static const signupPowStatusCompleted = AppCopyPart4.signupPowStatusCompleted;
  static const passkeyVerificationUserNotFound =
      AppCopyPart4.passkeyVerificationUserNotFound;
  static const passkeyVerificationNoLocal =
      AppCopyPart4.passkeyVerificationNoLocal;
  static const passkeyVerificationCancelled =
      AppCopyPart4.passkeyVerificationCancelled;
  static const passkeyVerificationChallengeExpired =
      AppCopyPart4.passkeyVerificationChallengeExpired;
  static const passkeyVerificationRejected =
      AppCopyPart4.passkeyVerificationRejected;
  static const passkeyVerificationFailed =
      AppCopyPart4.passkeyVerificationFailed;
  static const passkeyVerificationHeadlinePreparing =
      AppCopyPart4.passkeyVerificationHeadlinePreparing;
  static const passkeyVerificationHeadlineSending =
      AppCopyPart4.passkeyVerificationHeadlineSending;
  static const passkeyVerificationHeadlineDevice =
      AppCopyPart4.passkeyVerificationHeadlineDevice;
  static const passkeyVerificationHeadlineSuccess =
      AppCopyPart4.passkeyVerificationHeadlineSuccess;
  static const passkeyVerificationBodyPreparing =
      AppCopyPart4.passkeyVerificationBodyPreparing;
  static const passkeyVerificationBodySending =
      AppCopyPart4.passkeyVerificationBodySending;
  static const passkeyVerificationBodyDevice =
      AppCopyPart4.passkeyVerificationBodyDevice;
  static const passkeyVerificationBodySuccess =
      AppCopyPart4.passkeyVerificationBodySuccess;
  static const passkeyVerificationScreenTitle =
      AppCopyPart4.passkeyVerificationScreenTitle;
  static const passkeyVerificationLocalChip =
      AppCopyPart4.passkeyVerificationLocalChip;
  static const passkeyVerificationRetry = AppCopyPart4.passkeyVerificationRetry;
  static const passkeyVerificationUsePassphrase =
      AppCopyPart4.passkeyVerificationUsePassphrase;
  static const passkeyVerificationBack = AppCopyPart4.passkeyVerificationBack;
  static const passkeyVerificationFallbackHint =
      AppCopyPart4.passkeyVerificationFallbackHint;
  static const signupFinalPaymentAddressCopiedTitle =
      AppCopyPart4.signupFinalPaymentAddressCopiedTitle;
  static const signupFinalPaymentAddressCopiedBody =
      AppCopyPart4.signupFinalPaymentAddressCopiedBody;
  static const signupFinalPaymentAmountCopiedTitle =
      AppCopyPart4.signupFinalPaymentAmountCopiedTitle;
  static const signupFinalPaymentAmountCopiedBody =
      AppCopyPart4.signupFinalPaymentAmountCopiedBody;
  static const signupFinalPaymentEyebrow =
      AppCopyPart4.signupFinalPaymentEyebrow;
  static const signupFinalPaymentLoading =
      AppCopyPart4.signupFinalPaymentLoading;
  static const signupFinalPaymentHighlightExactAmount =
      AppCopyPart4.signupFinalPaymentHighlightExactAmount;
  static const signupFinalPaymentHighlightStatus =
      AppCopyPart4.signupFinalPaymentHighlightStatus;
  static const signupFinalPaymentChipAddress =
      AppCopyPart4.signupFinalPaymentChipAddress;
  static const signupFinalPaymentChipTxid =
      AppCopyPart4.signupFinalPaymentChipTxid;
  static const signupFinalPaymentChipConfirmations =
      AppCopyPart4.signupFinalPaymentChipConfirmations;
  static const signupFinalPaymentSectionCopy =
      AppCopyPart4.signupFinalPaymentSectionCopy;
  static const signupFinalPaymentExactAmountLabel =
      AppCopyPart4.signupFinalPaymentExactAmountLabel;
  static const signupFinalPaymentBtcAddressLabel =
      AppCopyPart4.signupFinalPaymentBtcAddressLabel;
  static const signupFinalPaymentSectionTxid =
      AppCopyPart4.signupFinalPaymentSectionTxid;
  static const signupFinalPaymentPaste = AppCopyPart4.signupFinalPaymentPaste;
  static const signupFinalPaymentTxidBody =
      AppCopyPart4.signupFinalPaymentTxidBody;
  static const signupFinalPaymentTxidHint =
      AppCopyPart4.signupFinalPaymentTxidHint;
  static const signupFinalPaymentValidationTitle =
      AppCopyPart4.signupFinalPaymentValidationTitle;
  static const signupFinalPaymentTrackTitle =
      AppCopyPart4.signupFinalPaymentTrackTitle;
  static const signupFinalPaymentPollingExpired =
      AppCopyPart4.signupFinalPaymentPollingExpired;
  static const signupFinalPaymentPollingDetected =
      AppCopyPart4.signupFinalPaymentPollingDetected;
  static const signupFinalPaymentPollingRunning =
      AppCopyPart4.signupFinalPaymentPollingRunning;
  static const signupFinalPaymentPollingBody =
      AppCopyPart4.signupFinalPaymentPollingBody;
  static const transactionAuthPassphraseTitle =
      AppCopyPart4.transactionAuthPassphraseTitle;
  static const transactionAuthPassphraseSubtitle =
      AppCopyPart4.transactionAuthPassphraseSubtitle;
  static const transactionAuthVaultTitle =
      AppCopyPart4.transactionAuthVaultTitle;
  static const transactionAuthVaultSubtitle =
      AppCopyPart4.transactionAuthVaultSubtitle;
  static const transactionAuthTotpTitle = AppCopyPart4.transactionAuthTotpTitle;
  static const transactionAuthTotpSubtitle =
      AppCopyPart4.transactionAuthTotpSubtitle;
  static const transactionAuthTotpLabel = AppCopyPart4.transactionAuthTotpLabel;
  static const transactionAuthPassphraseLabel =
      AppCopyPart4.transactionAuthPassphraseLabel;
  static const transactionAuthPassphraseRequired =
      AppCopyPart4.transactionAuthPassphraseRequired;
  static const transactionAuthCodeInvalid =
      AppCopyPart4.transactionAuthCodeInvalid;
  static const transactionAuthVerify = AppCopyPart4.transactionAuthVerify;
  static const transactionAuthOperationTitle =
      AppCopyPart4.transactionAuthOperationTitle;
  static const transactionAuthConfirmationPassphraseLabel =
      AppCopyPart4.transactionAuthConfirmationPassphraseLabel;
  static const transactionAuthEnterPassphrase =
      AppCopyPart4.transactionAuthEnterPassphrase;
  static const transactionAuthTotpCodeLabel =
      AppCopyPart4.transactionAuthTotpCodeLabel;
  static const transactionAuthEnterAuthenticatorDigits =
      AppCopyPart4.transactionAuthEnterAuthenticatorDigits;
  static const transactionAuthPasskeyChallengeTitle =
      AppCopyPart4.transactionAuthPasskeyChallengeTitle;
  static const transactionAuthPasskeyChallengeMessage =
      AppCopyPart4.transactionAuthPasskeyChallengeMessage;
  static const transactionAuthContinue = AppCopyPart4.transactionAuthContinue;
  static const transactionAuthShamirTitle =
      AppCopyPart4.transactionAuthShamirTitle;
  static const transactionAuthReconstructAndContinue =
      AppCopyPart4.transactionAuthReconstructAndContinue;
  static const transactionAuthShareHint = AppCopyPart4.transactionAuthShareHint;
  static const signupFlowCreateAccount = AppCopyPart4.signupFlowCreateAccount;
  static const signupFlowPhasePreparation =
      AppCopyPart4.signupFlowPhasePreparation;
  static const signupFlowPhaseProtection =
      AppCopyPart4.signupFlowPhaseProtection;
  static const signupFlowPhaseActivation =
      AppCopyPart4.signupFlowPhaseActivation;
  static const signupFlowGuidedStepsChip =
      AppCopyPart4.signupFlowGuidedStepsChip;
  static const signupFlowRequired2faChip =
      AppCopyPart4.signupFlowRequired2faChip;
  static const signupFlowDevicePasskeyChip =
      AppCopyPart4.signupFlowDevicePasskeyChip;
  static const signupFlowThreeConfirmationsChip =
      AppCopyPart4.signupFlowThreeConfirmationsChip;
}
