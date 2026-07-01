// ignore_for_file: unused_import, unused_element, use_key_in_widget_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/bitcoin_network.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/movement/domain/entities/fee_estimate.dart';
import 'package:kerosene/features/movement/domain/entities/withdraw_fee_quote_calculation.dart';
import 'package:kerosene/features/movement/flow/movement_flow_coordinator.dart';
import 'package:kerosene/app/providers/kfe_receiving_capabilities_provider.dart';
import 'package:kerosene/features/movement/copy/send_money_copy.dart';

import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/movement/widgets/send_money_components.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';

import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/features/movement/screens/send_payment_confirmation_flow.dart';
import 'package:kerosene/features/movement/screens/send_payment_review_helpers.dart';
import 'package:kerosene/features/movement/screens/send_payment_request_flow.dart';
import 'package:kerosene/features/movement/screens/send_security_profile_resolver.dart';
import 'package:kerosene/features/movement/screens/send_wallet_resolver.dart';
import 'package:kerosene/features/movement/screens/send_wallet_selection_step.dart';

import 'package:kerosene/features/movement/screens/send_destination_models.dart';
import 'package:kerosene/features/movement/screens/send_destination_analyzer.dart';
import 'package:kerosene/features/movement/screens/send_amount_step.dart';
import 'package:kerosene/features/movement/screens/send_destination_step.dart';
import 'package:kerosene/features/movement/widgets/internal_recent_avatar.dart';
import 'package:kerosene/features/movement/screens/send_money_formatters.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? walletId;
  final String? initialAddress;
  final double? initialAmountBtc;

  const SendMoneyScreen({
    super.key,
    this.walletId,
    this.initialAddress,
    this.initialAmountBtc,
  });

  @override
  ConsumerState<SendMoneyScreen> createState() => SendMoneyScreenState();
}

class SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  static const Color internalBlack = KeroseneBrandTokens.background;
  static const Color internalSurface = KeroseneBrandTokens.surface;
  static const Color internalSurfaceHigh = KeroseneBrandTokens.surfaceHigh;
  static const Color internalBorder = KeroseneBrandTokens.border;
  static const Color internalText = KeroseneBrandTokens.textPrimary;
  static const Color internalMutedText = KeroseneBrandTokens.textMuted;
  static const Color internalOutline = KeroseneBrandTokens.borderStrong;
  static const double _defaultLightningRoutingFeeBtc = 0.000001;

  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  String? _recentDestinationAddressForSave;
  double _lockedAmountBtc = 0.0;
  String? _lockedRecipientLabel;
  Wallet? _selectedWallet;
  bool _destinationResolutionBusy = false;
  int _destinationEditVersion = 0;

  final _receiverController = TextEditingController();

  final ValueNotifier<String> _amount = ValueNotifier<String>('0');
  late Currency _selectedCurrency;

  late int _currentStep;
  late final PageController _pageController;

  bool get _hasPreselectedWallet =>
      widget.walletId != null && widget.walletId!.trim().isNotEmpty;

  int get _firstStep => _hasPreselectedWallet ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _currentStep = _firstStep;
    _pageController = PageController(initialPage: _currentStep);
    _selectedCurrency = Currency.btc;
    if (widget.initialAmountBtc != null) {
      _lockedAmountBtc = widget.initialAmountBtc!;
      _amount.value = widget.initialAmountBtc!
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletState = ref.read(walletProvider);
      if (walletState is WalletInitial || walletState is WalletError) {
        unawaited(ref.read(walletProvider.notifier).refresh());
      }
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        unawaited(_parsePaymentRequest(widget.initialAddress!));
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    if (_lockedAmountBtc > 0) return; // Prevent changing locked amount

    _amount.value = value.trim().isEmpty ? '0' : value;
  }

  void _toggleAmountCurrency() {
    if (_lockedAmountBtc > 0 || _pendingPaymentLinkId != null) return;

    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      amountVal: _amount.value,
    );
    final nextCurrency =
        _selectedCurrency == Currency.btc ? Currency.brl : Currency.btc;
    final nextAmount = nextCurrency == Currency.btc
        ? amountBtc
        : MoneyDisplay.convertFromBtcAmount(
            btcAmount: amountBtc,
            currency: nextCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          );

    setState(() => _selectedCurrency = nextCurrency);
    _amount.value = MoneyDisplay.rawInputFromAmount(
      amount: nextAmount,
      currency: nextCurrency,
    );
  }

  double _amountAsDouble(String amountVal) =>
      MoneyDisplay.parseEditableInput(amountVal);

  double _currentAmountBtc({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    required String amountVal,
  }) {
    if (_lockedAmountBtc > 0) {
      return _lockedAmountBtc;
    }
    return MoneyDisplay.convertToBtcAmount(
      amount: _amountAsDouble(amountVal),
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = false;
    if (_currentStep == 2) {
      final isSending = ref.watch(
        sendTransactionProvider.select((state) => state.isLoading),
      );
      final isPayingLink = ref.watch(
        paymentLinkNotifierProvider.select((state) => state.isLoading),
      );
      isLoading = isSending || isPayingLink;
    }
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      amountVal: _amount.value,
    );
    final walletState = ref.watch(walletProvider);

    if (_currentStep != 0 &&
        (walletState is WalletInitial || walletState is WalletLoading)) {
      return const KeroseneLogoLoadingView();
    }

    final currentWallet = _resolveWallet(walletState);
    final destinationAnalysis = _currentDestinationAnalysis();
    final AsyncValue<FeeEstimate>? feeEstimateAsync =
        destinationAnalysis.isOnChain && amountBtc > 0
            ? ref.watch(feeEstimateProvider(amountBtc))
            : null;
    final feeQuote = _resolveFeeQuote(
      wallet: currentWallet,
      destination: destinationAnalysis,
      amountBtc: amountBtc,
      feeEstimateAsync: feeEstimateAsync,
    );

    return Scaffold(
      backgroundColor: internalBlack,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWalletSelectionStep(context, walletState),
            _buildDestinationStep(context),
            _buildAmountStep(
              context,
              btcUsd: btcUsd,
              btcEur: btcEur,
              btcBrl: btcBrl,
              amountBtc: amountBtc,
              wallet: currentWallet,
              destination: destinationAnalysis,
              feeQuote: feeQuote,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    if (_currentStep > _firstStep) {
      _pageController.previousPage(
        duration: KeroseneMotion.medium,
        curve: KeroseneMotion.standard,
      );
      setState(() => _currentStep -= 1);
      return;
    }

    Navigator.pop(context);
  }

  Widget _buildInternalTopBar(BuildContext context) {
    return InternalTopBar(
      onBack: _handleBack,
      textColor: internalText,
    );
  }

  Widget _buildInternalPrimaryButton({
    required String label,
    IconData? icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InternalPrimaryButton(
      label: label,
      icon: icon,
      enabled: enabled,
      onTap: onTap,
      isLoading: isLoading,
      backgroundColor: internalText,
      foregroundColor: internalBlack,
    );
  }

  Future<void> _handleContinue() async {
    final insufficientBalanceMessage =
        SendMoneyCopy.insufficientBalance(context);
    final walletState = ref.read(walletProvider);
    final currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) {
      SnackbarHelper.showError(SendMoneyCopy.walletLoadFailed(context));
      return;
    }
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    var amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      amountVal: _amount.value,
    );
    var destination = _currentDestinationAnalysis();

    HapticFeedback.mediumImpact();

    if (!destination.isValid) {
      SnackbarHelper.showError(
        destination.isEmpty
            ? context.tr.sendMoneyMissingDestination
            : SendMoneyCopy.unrecognizedDestination(context),
      );
      return;
    }

    if (destination.isPaymentLink && _pendingPaymentLinkId == null) {
      final linkId = destination.paymentLinkId;
      if (linkId == null || linkId.isEmpty) {
        SnackbarHelper.showError(context.tr.sendMoneyInvalidPaymentRequest);
        return;
      }
      final loaded = await _fetchPaymentLinkDetails(linkId);
      if (!loaded) return;
      if (!mounted) return;
      amountBtc = _currentAmountBtc(
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
        amountVal: _amount.value,
      );
      destination = _currentDestinationAnalysis();
    }

    if (mounted) {
      setState(() => _destinationResolutionBusy = true);
    }
    final resolvedDestination = await _resolveDestinationForKfe(destination);
    if (!mounted) return;
    if (resolvedDestination == null) {
      setState(() => _destinationResolutionBusy = false);
      return;
    }
    destination = resolvedDestination;

    if (_isOwnInternalDestination(walletState, destination)) {
      setState(() => _destinationResolutionBusy = false);
      SnackbarHelper.showError(context.tr.errLedgerPaymentRequestSelfPay);
      return;
    }

    if (amountBtc <= 0) {
      setState(() => _destinationResolutionBusy = false);
      SnackbarHelper.showError(context.tr.errorAmountRequired);
      return;
    }

    final feeQuote = await _resolveSubmitFeeQuote(
      wallet: currentWallet,
      destination: destination,
      amountBtc: amountBtc,
    );
    if (feeQuote == null) {
      setState(() => _destinationResolutionBusy = false);
      return;
    }

    final totalDebited =
        destination.isExternal ? feeQuote.totalDebitedBtc : amountBtc;

    if (!WithdrawFeeQuoteCalculation.hasSufficientBalance(
      availableBtc: currentWallet.balance,
      totalDebitedBtc: totalDebited,
    )) {
      setState(() => _destinationResolutionBusy = false);
      SnackbarHelper.showError(insufficientBalanceMessage);
      return;
    }

    await _openPaymentConfirmation(
      wallet: currentWallet,
      destination: destination,
      amount: destination.isExternal ? feeQuote.receiverAmountBtc : amountBtc,
      requestedAmount: amountBtc,
      feeQuote: feeQuote,
      toAddress: destination.normalizedValue,
    );
    if (mounted) {
      setState(() => _destinationResolutionBusy = false);
    }
  }

  SendFeeQuote _resolveFeeQuote({
    required Wallet? wallet,
    required SendDestinationAnalysis destination,
    required double amountBtc,
    required AsyncValue<FeeEstimate>? feeEstimateAsync,
  }) {
    if (!destination.isExternal || wallet == null || amountBtc <= 0) {
      return SendFeeQuote(
        requestedAmountBtc: amountBtc,
        receiverAmountBtc: amountBtc,
        platformFeeRate: wallet?.withdrawalFeeRate ?? 0,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: amountBtc,
      );
    }

    final platformFeeRate = wallet.withdrawalFeeRate;
    if (destination.isLightning) {
      return _buildExternalFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        networkFeeBtc: _defaultLightningRoutingFeeBtc,
      );
    }

    if (feeEstimateAsync == null) {
      return SendFeeQuote(
        requestedAmountBtc: amountBtc,
        receiverAmountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: amountBtc,
        isLoading: true,
      );
    }

    double networkFeeBtc = 0;
    double? feeRateSatPerByte;
    bool isLoading = false;
    Object? error;

    feeEstimateAsync.when(
      data: (fee) {
        networkFeeBtc = fee.estimatedStandardBtc;
        feeRateSatPerByte = fee.standardSatPerByte;
      },
      loading: () => isLoading = true,
      error: (err, _) => error = err,
    );

    if (isLoading || error != null) {
      return SendFeeQuote(
        requestedAmountBtc: amountBtc,
        receiverAmountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: amountBtc,
        feeRateSatPerByte: feeRateSatPerByte,
        isLoading: isLoading,
        error: error,
      );
    }

    return _buildExternalFeeQuote(
      amountBtc: amountBtc,
      platformFeeRate: platformFeeRate,
      networkFeeBtc: networkFeeBtc,
      feeRateSatPerByte: feeRateSatPerByte,
    );
  }

  Future<SendFeeQuote?> _resolveSubmitFeeQuote({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amountBtc,
  }) async {
    final networkFeeUnavailableMessage =
        SendMoneyCopy.networkFeeUnavailable(context);
    if (!destination.isExternal) {
      return SendFeeQuote(
        requestedAmountBtc: amountBtc,
        receiverAmountBtc: amountBtc,
        platformFeeRate: 0,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: amountBtc,
      );
    }

    if (destination.isLightning) {
      return _buildExternalFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: wallet.withdrawalFeeRate,
        networkFeeBtc: _defaultLightningRoutingFeeBtc,
      );
    }

    try {
      final fee = await ref.read(feeEstimateProvider(amountBtc).future);
      return _buildExternalFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: wallet.withdrawalFeeRate,
        networkFeeBtc: fee.estimatedStandardBtc,
        feeRateSatPerByte: fee.standardSatPerByte,
      );
    } catch (error) {
      SnackbarHelper.showError(networkFeeUnavailableMessage);
      return null;
    }
  }

  SendFeeQuote _buildExternalFeeQuote({
    required double amountBtc,
    required double platformFeeRate,
    required double networkFeeBtc,
    double? feeRateSatPerByte,
  }) {
    final calculation = WithdrawFeeQuoteCalculation.resolve(
      mode: WithdrawFeeMode.senderPays,
      requestedAmountBtc: amountBtc,
      platformFeeRate: platformFeeRate,
      networkFeeBtc: networkFeeBtc,
    );
    return SendFeeQuote(
      requestedAmountBtc: amountBtc,
      receiverAmountBtc: calculation.receiverAmountBtc,
      platformFeeRate: calculation.platformFeeRate,
      platformFeeBtc: calculation.platformFeeBtc,
      networkFeeBtc: calculation.networkFeeBtc,
      totalDebitedBtc: calculation.totalDebitedBtc,
      feeRateSatPerByte: feeRateSatPerByte,
    );
  }

  Future<AccountSecurityProfile> _resolveSecurityProfile(Wallet wallet) async {
    try {
      return await ref.read(accountSecurityProfileProvider.future);
    } catch (_) {
      return fallbackSendSecurityProfile(wallet.accountSecurity);
    }
  }

  Wallet? _resolveWallet(WalletState walletState) {
    return resolveSendWallet(
      walletState: walletState,
      selectedWallet: _selectedWallet,
      requestedWalletId: widget.walletId,
    );
  }

  Widget _buildWalletSelectionStep(
    BuildContext context,
    WalletState walletState,
  ) {
    final selectedWallet = _resolveWallet(walletState);

    return SendWalletSelectionStep(
      topBar: _buildInternalTopBar(context),
      walletState: walletState,
      selectedWallet: selectedWallet,
      onRefresh: () => ref.read(walletProvider.notifier).refresh(),
      onWalletSelected: (wallet) {
        HapticFeedback.selectionClick();
        setState(() => _selectedWallet = wallet);
      },
      onContinue: () {
        if (selectedWallet == null) {
          SnackbarHelper.showError(
            SendMoneyCopy.chooseWalletToContinue(context),
          );
          return;
        }
        HapticFeedback.selectionClick();
        ref.read(walletProvider.notifier).selectWallet(selectedWallet);
        setState(() {
          _selectedWallet = selectedWallet;
          _currentStep = 1;
        });
        _pageController.nextPage(
          duration: KeroseneMotion.medium,
          curve: KeroseneMotion.standard,
        );
      },
    );
  }

  Widget _buildDestinationStep(BuildContext context) {
    final recentDestinations = ref
        .watch(recentTransactionDestinationsProvider)
        .toList(growable: false);
    final analysis = _currentDestinationAnalysis();

    return SendDestinationStep(
      receiverController: _receiverController,
      analysis: analysis,
      recentDestinations: recentDestinations,
      isLoading: _destinationResolutionBusy,
      onDestinationChanged: () {
        setState(() {
          _destinationEditVersion += 1;
          _destinationResolutionBusy = false;
          _pendingPaymentLinkId = null;
          _lockedRecipientAddress = '';
          _recentDestinationAddressForSave = null;
          _lockedRecipientLabel = null;
          if (widget.initialAmountBtc == null) {
            _lockedAmountBtc = 0;
          }
        });
      },
      onScan: _scanInternalDestination,
      onRecentDestinationSelected: _applyRecentInternalDestination,
      onContinue: () {
        final currentDestination = _receiverController.text.trim();
        final currentAnalysis = _currentDestinationAnalysis();
        if (!currentAnalysis.isValid) {
          SnackbarHelper.showError(
            currentDestination.isEmpty
                ? context.tr.sendMoneyMissingDestination
                : SendMoneyCopy.unrecognizedDestination(context),
          );
          return;
        }
        unawaited(_continueFromDestinationStep(currentAnalysis));
      },
    );
  }

  Future<void> _continueFromDestinationStep(
    SendDestinationAnalysis analysis,
  ) async {
    if (_destinationResolutionBusy) {
      return;
    }

    FocusScope.of(context).unfocus();
    final editVersion = _destinationEditVersion;
    var destination = analysis;

    setState(() => _destinationResolutionBusy = true);
    try {
      if (!destination.isValid) {
        SnackbarHelper.showError(
          destination.isEmpty
              ? context.tr.sendMoneyMissingDestination
              : SendMoneyCopy.unrecognizedDestination(context),
        );
        return;
      }

      if (destination.isPaymentLink) {
        final linkId = destination.paymentLinkId;
        if (linkId == null || linkId.isEmpty) {
          SnackbarHelper.showError(context.tr.sendMoneyInvalidPaymentRequest);
          return;
        }
        final loaded = await _fetchPaymentLinkDetails(
          linkId,
          destinationEditVersion: editVersion,
        );
        if (!loaded || !mounted || editVersion != _destinationEditVersion) {
          return;
        }
        destination = _currentDestinationAnalysis();
      } else {
        final resolvedDestination =
            await _resolveDestinationForKfe(destination);
        if (resolvedDestination == null ||
            !mounted ||
            editVersion != _destinationEditVersion) {
          return;
        }
        destination = resolvedDestination;
      }

      if (destination.hasLockedAmount) {
        _amount.value = destination.amountBtc!
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }

      if (!mounted) return;
      setState(() {
        if (destination.isInternal || destination.hasLockedAmount) {
          _lockedRecipientAddress = destination.normalizedValue;
          if (!destination.isInternal) {
            _recentDestinationAddressForSave = null;
          }
        }
        if (destination.label != null && destination.label!.trim().isNotEmpty) {
          _lockedRecipientLabel = destination.label;
        }
      });

      await _pageController.nextPage(
        duration: KeroseneMotion.medium,
        curve: KeroseneMotion.standard,
      );
      if (!mounted) return;
      setState(() => _currentStep = 2);
    } finally {
      if (mounted && _destinationResolutionBusy) {
        setState(() => _destinationResolutionBusy = false);
      }
    }
  }

  SendDestinationAnalysis _currentDestinationAnalysis() {
    return currentSendDestinationAnalysis(
      pendingPaymentLinkId: _pendingPaymentLinkId,
      lockedRecipientAddress: _lockedRecipientAddress,
      lockedAmountBtc: _lockedAmountBtc,
      lockedRecipientLabel: _lockedRecipientLabel,
      input: _receiverController.text,
    );
  }

  bool _isOwnInternalDestination(
    WalletState walletState,
    SendDestinationAnalysis destination,
  ) {
    if (!destination.isInternal || walletState is! WalletLoaded) {
      return false;
    }
    final normalizedDestination =
        destination.normalizedValue.trim().toLowerCase();
    if (normalizedDestination.isEmpty) {
      return false;
    }
    return walletState.wallets.any((wallet) {
      final walletId = wallet.id.trim().toLowerCase();
      final walletAddress = wallet.address.trim().toLowerCase();
      return normalizedDestination == walletId ||
          (walletAddress.isNotEmpty && normalizedDestination == walletAddress);
    });
  }

  Future<SendDestinationAnalysis?> _resolveDestinationForKfe(
    SendDestinationAnalysis analysis,
  ) async {
    if (!analysis.isInternal) {
      return analysis;
    }

    try {
      final requestedIdentifier = analysis.normalizedValue.trim();
      final capabilities = await ref
          .read(kfeReceivingCapabilitiesServiceProvider)
          .receivingCapabilities(requestedIdentifier);
      if (!mounted) return null;
      final walletId = capabilities.internalWalletId?.trim();
      if (!capabilities.canReceiveInternal ||
          walletId == null ||
          walletId.isEmpty) {
        SnackbarHelper.showError(context.tr.errReceiverNotReady);
        return null;
      }

      final resolved = SendDestinationAnalysis(
        type: SendDestinationType.internal,
        normalizedValue: walletId,
        amountBtc: analysis.amountBtc,
        label: capabilities.receiverDisplayName.trim().isNotEmpty
            ? capabilities.receiverDisplayName.trim()
            : requestedIdentifier,
        message: analysis.message,
      );

      _recentDestinationAddressForSave = requestedIdentifier;
      return resolved;
    } catch (error) {
      if (!mounted) return null;
      SnackbarHelper.showError(
        ErrorTranslator.translate(context.tr, error.toString()),
      );
      return null;
    }
  }

  String _stripLightningPrefix(String value) {
    final trimmed = value.trim();
    return trimmed.toLowerCase().startsWith('lightning:')
        ? trimmed.substring(10).trim()
        : trimmed;
  }

  bool _looksLikeLightningRequest(String value) {
    final trimmed = _stripLightningPrefix(value);
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    return RegExp(r'^(lnbc|lntb|lnbcrt)[0-9][0-9a-z]+$').hasMatch(lower) ||
        RegExp(r'^lnurl[0-9a-z]+$').hasMatch(lower) ||
        _looksLikeLightningAddress(trimmed);
  }

  bool _looksLikeLightningAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.length > 254 || trimmed.contains(RegExp(r'\s'))) {
      return false;
    }
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]{1,64}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$',
    ).hasMatch(trimmed);
  }

  bool looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  double? _extractLightningAmountBtc(String value) {
    final withoutPrefix = _stripLightningPrefix(value);
    final match = RegExp(
      r'^ln(?:bc|tb|bcrt)(\d+)([munp]?)1',
    ).firstMatch(withoutPrefix.toLowerCase());
    if (match == null) return null;
    final amount = double.tryParse(match.group(1) ?? '');
    if (amount == null || amount <= 0) return null;

    final multiplier = switch (match.group(2)) {
      'm' => 0.001,
      'u' => 0.000001,
      'n' => 0.000000001,
      'p' => 0.000000000001,
      _ => 1.0,
    };
    return amount * multiplier;
  }

  Widget _buildAmountStep(
    BuildContext context, {
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    required double amountBtc,
    required Wallet? wallet,
    required SendDestinationAnalysis destination,
    required SendFeeQuote feeQuote,
    required bool isLoading,
  }) {
    return SendAmountStep(
      onBack: _handleBack,
      amount: _amount,
      selectedCurrency: _selectedCurrency,
      lockedAmountBtc: _lockedAmountBtc,
      hasPaymentLink: _pendingPaymentLinkId != null,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      wallet: wallet,
      destination: destination,
      feeQuote: feeQuote,
      isLoading: isLoading,
      onAmountChanged: _onAmountChanged,
      onContinue: _handleContinue,
      resolveAmountBtc: (amountValue) => _currentAmountBtc(
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
        amountVal: amountValue,
      ),
      onFiatReferenceTap: _toggleAmountCurrency,
    );
  }

  String _currentRecipientValue() {
    return _lockedRecipientAddress.isNotEmpty
        ? _lockedRecipientAddress
        : _receiverController.text.trim();
  }

  String _currentRecipientLabel() {
    final label = _lockedRecipientLabel?.trim();
    if (label == null ||
        label.isEmpty ||
        label == context.tr.sendMoneyLockedDestination) {
      return _currentRecipientValue();
    }
    return label;
  }

  Future<void> _openPaymentConfirmation({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required double requestedAmount,
    required SendFeeQuote feeQuote,
    required String toAddress,
  }) async {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final isPaymentLink =
        destination.isPaymentLink || _pendingPaymentLinkId != null;

    final result = await openSendPaymentReview(
      context: context,
      wallet: wallet,
      destination: destination,
      requestedAmount: requestedAmount,
      feeQuote: feeQuote,
      toAddress: toAddress,
      recipientLabel: _currentRecipientLabel(),
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      isPaymentLink: isPaymentLink,
      onConfirm: (confirmationContext) => _confirmPayment(
        confirmationContext: confirmationContext,
        wallet: wallet,
        destination: destination,
        amount: amount,
        feeQuote: feeQuote,
        toAddress: toAddress,
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _showSentTransactionNotification({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) async {}

  Future<dynamic> _confirmPayment({
    required BuildContext confirmationContext,
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required SendFeeQuote feeQuote,
    required String toAddress,
  }) async {
    return confirmSendPayment(
      context: context,
      confirmationContext: confirmationContext,
      ref: ref,
      wallet: wallet,
      destination: destination,
      amount: amount,
      feeQuote: feeQuote,
      toAddress: toAddress,
      pendingPaymentLinkId: _pendingPaymentLinkId,
      resolveSecurityProfile: _resolveSecurityProfile,
      showSentTransactionNotification: _showSentTransactionNotification,
      resolveRecentDestinationLabel: _resolveRecentInternalDestinationLabel,
      resolveRecentDestinationAddress: _resolveRecentInternalDestinationAddress,
      isMounted: () => mounted,
    );
  }

  Future<void> _parsePaymentRequest(String data) async {
    await parseSendPaymentRequest(
      context: context,
      ref: ref,
      data: data,
      isMounted: () => mounted,
      setReceiverText: _setReceiverText,
      setLockedRecipientAddress: (value) => _lockedRecipientAddress = value,
      setLockedAmountBtc: (value) => _lockedAmountBtc = value,
      setAmountText: (value) => _amount.value = value,
      setLockedRecipientLabel: (value) => _lockedRecipientLabel = value,
      incrementDestinationEditVersion: () => _destinationEditVersion += 1,
      fetchPaymentLinkDetails: _fetchPaymentLinkDetails,
    );
  }

  Future<bool> _fetchPaymentLinkDetails(
    String linkId, {
    int? destinationEditVersion,
  }) async {
    return fetchSendPaymentLinkDetails(
      context: context,
      ref: ref,
      linkId: linkId,
      destinationEditVersion: destinationEditVersion,
      currentDestinationEditVersion: () => _destinationEditVersion,
      isMounted: () => mounted,
      incrementDestinationEditVersion: () => _destinationEditVersion += 1,
      setPendingPaymentLinkId: (value) => _pendingPaymentLinkId = value,
      setLockedRecipientLabel: (value) => _lockedRecipientLabel = value,
      setLockedRecipientAddress: (value) => _lockedRecipientAddress = value,
      setLockedAmountBtc: (value) => _lockedAmountBtc = value,
      setAmountText: (value) => _amount.value = value,
    );
  }

  void _setReceiverText(String value) {
    _receiverController.text = value;
    _receiverController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
  }

  void _applyRecentInternalDestination(
    RecentTransactionDestination destination,
  ) {
    final value = destination.address.trim();
    if (value.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _destinationEditVersion += 1;
      _receiverController.text = value;
      _receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });
  }

  String _resolveRecentInternalDestinationAddress(String toAddress) {
    final stableAddress = _recentDestinationAddressForSave?.trim();
    if (stableAddress != null && stableAddress.isNotEmpty) {
      return stableAddress;
    }
    return toAddress;
  }

  String? _resolveRecentInternalDestinationLabel(String toAddress) {
    final label = _lockedRecipientLabel?.trim();
    if (label == null ||
        label.isEmpty ||
        label == toAddress ||
        label == context.tr.sendMoneyLockedDestination) {
      return null;
    }
    return label;
  }

  Future<void> _scanInternalDestination() async {
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    final value = payload?.trim();
    if (!mounted || value == null || value.isEmpty) {
      return;
    }

    await _parsePaymentRequest(value);
  }
}
