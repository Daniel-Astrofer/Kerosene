import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/recent_transaction_destinations_section.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/bitcoin_network.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/core/widgets/transaction_auth_gate.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/domain/entities/treasury_overview.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/fee_estimate.dart';
import 'package:teste/features/transactions/domain/entities/withdraw_fee_quote_calculation.dart';
import 'package:teste/features/transactions/presentation/screens/payment_confirmation_screen.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

enum WithdrawEntryMode { onChain, lightning }

enum _WithdrawDestinationType { empty, onChain, lightning, invalid }

class _WithdrawDestinationAnalysis {
  final _WithdrawDestinationType type;
  final String normalizedValue;
  final BitcoinNetworkKind detectedOnchainNetwork;
  final bool isNetworkMismatch;

  const _WithdrawDestinationAnalysis({
    required this.type,
    required this.normalizedValue,
    this.detectedOnchainNetwork = BitcoinNetworkKind.unknown,
    this.isNetworkMismatch = false,
  });

  bool get isOnChain => type == _WithdrawDestinationType.onChain;
  bool get isLightning => type == _WithdrawDestinationType.lightning;
  bool get isInvalid => type == _WithdrawDestinationType.invalid;
}

class _WithdrawFeeQuote {
  final WithdrawFeeMode feeMode;
  final double requestedAmountBtc;
  final double amountBtc;
  final double platformFeeRate;
  final double platformFeeBtc;
  final double networkFeeBtc;
  final double totalDebitedBtc;
  final double? feeRateSatPerByte;
  final bool isLoading;
  final Object? error;
  final bool usesMaximumRoutingFee;
  final bool isEstimated;

  const _WithdrawFeeQuote({
    required this.feeMode,
    required this.requestedAmountBtc,
    required this.amountBtc,
    required this.platformFeeRate,
    required this.platformFeeBtc,
    required this.networkFeeBtc,
    required this.totalDebitedBtc,
    this.feeRateSatPerByte,
    this.isLoading = false,
    this.error,
    this.usesMaximumRoutingFee = false,
    this.isEstimated = false,
  });

  bool get hasAmount => requestedAmountBtc > 0;
  bool get isReady =>
      amountBtc > 0 && !isLoading && error == null && networkFeeBtc > 0;
  double get totalFeesBtc => platformFeeBtc + networkFeeBtc;
  bool get deductsFees => feeMode == WithdrawFeeMode.recipientPays;
}

class WithdrawScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;
  final bool showBackButton;
  final WithdrawEntryMode entryMode;
  final String? initialDestination;
  final double? initialAmountBtc;
  final String? initialDescription;

  const WithdrawScreen({
    super.key,
    this.wallet,
    this.showBackButton = true,
    this.entryMode = WithdrawEntryMode.onChain,
    this.initialDestination,
    this.initialAmountBtc,
    this.initialDescription,
  });

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  static const double _defaultLightningRoutingFeeBtc = 0.00000100;
  static const Duration _feeEstimateDebounceDuration =
      Duration(milliseconds: 280);

  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _amountInput = '0';
  late Currency _selectedCurrency;
  Timer? _feeEstimateDebounce;
  double _debouncedAmountBtc = 0;
  bool _feeEstimatePending = false;
  WithdrawFeeMode _feeMode = WithdrawFeeMode.senderPays;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencyProvider);
    if (widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      _addressController.text = widget.initialDestination!.trim();
    }
    if (widget.initialDescription != null &&
        widget.initialDescription!.trim().isNotEmpty) {
      _descriptionController.text = widget.initialDescription!.trim();
    }
    if (widget.initialAmountBtc != null && widget.initialAmountBtc! > 0) {
      _selectedCurrency = Currency.btc;
      _amountInput = widget.initialAmountBtc!
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleFeeEstimate();
    });
  }

  @override
  void dispose() {
    _feeEstimateDebounce?.cancel();
    _pageController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    return MoneyDisplay.parseEditableInput(_amountInput);
  }

  String get _displayAmount {
    return MoneyDisplay.formatEditableInput(
      rawValue: _amountInput,
      currency: _selectedCurrency,
      withSymbol: false,
    );
  }

  double _parsedAmountBtc({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return MoneyDisplay.convertToBtcAmount(
      amount: _parsedAmount,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  _WithdrawFeeQuote _resolveFeeQuote({
    required double requestedAmountBtc,
    required double platformFeeRate,
    required AsyncValue<FeeEstimate>? feeEstimateAsync,
  }) {
    if (requestedAmountBtc <= 0) {
      return _WithdrawFeeQuote(
        feeMode: _feeMode,
        requestedAmountBtc: requestedAmountBtc,
        amountBtc: 0,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: 0,
        usesMaximumRoutingFee: widget.entryMode == WithdrawEntryMode.lightning,
        isEstimated: widget.entryMode == WithdrawEntryMode.onChain,
      );
    }

    if (widget.entryMode == WithdrawEntryMode.lightning) {
      final networkFeeBtc = _defaultLightningRoutingFeeBtc;
      final calculation = WithdrawFeeQuoteCalculation.resolve(
        mode: _feeMode,
        requestedAmountBtc: requestedAmountBtc,
        platformFeeRate: platformFeeRate,
        networkFeeBtc: networkFeeBtc,
      );
      return _WithdrawFeeQuote(
        feeMode: _feeMode,
        requestedAmountBtc: requestedAmountBtc,
        amountBtc: calculation.receiverAmountBtc,
        platformFeeRate: calculation.platformFeeRate,
        platformFeeBtc: calculation.platformFeeBtc,
        networkFeeBtc: calculation.networkFeeBtc,
        totalDebitedBtc: calculation.totalDebitedBtc,
        usesMaximumRoutingFee: true,
      );
    }

    if (feeEstimateAsync == null) {
      return _WithdrawFeeQuote(
        feeMode: _feeMode,
        requestedAmountBtc: requestedAmountBtc,
        amountBtc:
            _feeMode == WithdrawFeeMode.recipientPays ? 0 : requestedAmountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: 0,
        isLoading: true,
        isEstimated: true,
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

    final amountBtc = error == null && !isLoading
        ? WithdrawFeeQuoteCalculation.resolve(
            mode: _feeMode,
            requestedAmountBtc: requestedAmountBtc,
            platformFeeRate: platformFeeRate,
            networkFeeBtc: networkFeeBtc,
          ).receiverAmountBtc
        : (_feeMode == WithdrawFeeMode.recipientPays
            ? 0.0
            : requestedAmountBtc);
    final calculation = WithdrawFeeQuoteCalculation.resolve(
      mode: _feeMode,
      requestedAmountBtc: requestedAmountBtc,
      platformFeeRate: platformFeeRate,
      networkFeeBtc: networkFeeBtc,
    );

    return _WithdrawFeeQuote(
      feeMode: _feeMode,
      requestedAmountBtc: requestedAmountBtc,
      amountBtc: amountBtc,
      platformFeeRate: calculation.platformFeeRate,
      platformFeeBtc: calculation.platformFeeBtc,
      networkFeeBtc: calculation.networkFeeBtc,
      totalDebitedBtc: calculation.totalDebitedBtc,
      feeRateSatPerByte: feeRateSatPerByte,
      isLoading: isLoading,
      error: error,
      isEstimated: true,
    );
  }

  _WithdrawDestinationAnalysis _analyzeDestination(
    String raw, {
    required BitcoinNetworkKind expectedOnchainNetwork,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const _WithdrawDestinationAnalysis(
        type: _WithdrawDestinationType.empty,
        normalizedValue: '',
      );
    }

    final lower = trimmed.toLowerCase();
    final withoutLightningPrefix =
        lower.startsWith('lightning:') ? trimmed.substring(10).trim() : trimmed;
    final invoiceLower = withoutLightningPrefix.toLowerCase();

    if (RegExp(r'^(lnbc|lntb|lnbcrt)[0-9][0-9a-z]+$').hasMatch(invoiceLower) ||
        RegExp(r'^lnurl[0-9a-z]+$').hasMatch(invoiceLower)) {
      return _WithdrawDestinationAnalysis(
        type: _WithdrawDestinationType.lightning,
        normalizedValue: withoutLightningPrefix,
      );
    }

    final decoded = QrPaymentParser.decode(trimmed);
    final normalized = decoded?.address ?? trimmed;
    if (_looksLikeBitcoinAddress(normalized)) {
      final detectedOnchainNetwork = inferBitcoinNetworkFromAddress(normalized);
      return _WithdrawDestinationAnalysis(
        type: _WithdrawDestinationType.onChain,
        normalizedValue: normalized,
        detectedOnchainNetwork: detectedOnchainNetwork,
        isNetworkMismatch:
            expectedOnchainNetwork != BitcoinNetworkKind.unknown &&
                !isBitcoinAddressCompatibleWithNetwork(
                  normalized,
                  expectedOnchainNetwork,
                ),
      );
    }

    return _WithdrawDestinationAnalysis(
      type: _WithdrawDestinationType.invalid,
      normalizedValue: normalized,
    );
  }

  bool _looksLikeBitcoinAddress(String value) {
    return looksLikeBitcoinAddress(value);
  }

  String _destinationLabel(
    BuildContext context,
    _WithdrawDestinationAnalysis d,
    BitcoinNetworkKind expectedOnchainNetwork,
  ) {
    switch (d.type) {
      case _WithdrawDestinationType.onChain:
        if (expectedOnchainNetwork == BitcoinNetworkKind.unknown) {
          return AppCopy.withdrawNetworkOnChainChip.resolve(context);
        }
        return '${AppCopy.withdrawNetworkOnChainChip.resolve(context)} • ${bitcoinNetworkDisplayName(expectedOnchainNetwork)}';
      case _WithdrawDestinationType.lightning:
        return context.l10n.lightning;
      case _WithdrawDestinationType.invalid:
        return AppCopy.withdrawNetworkReviewChip.resolve(context);
      case _WithdrawDestinationType.empty:
        return widget.entryMode == WithdrawEntryMode.lightning
            ? context.l10n.lightning
            : expectedOnchainNetwork == BitcoinNetworkKind.unknown
                ? AppCopy.withdrawNetworkOnChainChip.resolve(context)
                : '${AppCopy.withdrawNetworkOnChainChip.resolve(context)} • ${bitcoinNetworkDisplayName(expectedOnchainNetwork)}';
    }
  }

  bool _destinationMatchesFlow(_WithdrawDestinationAnalysis d) {
    return switch (widget.entryMode) {
      WithdrawEntryMode.onChain => d.isOnChain,
      WithdrawEntryMode.lightning => d.isLightning,
    };
  }

  Color _destinationValidationColor(
    BuildContext context,
    _WithdrawDestinationAnalysis d,
  ) {
    if (d.type == _WithdrawDestinationType.empty) {
      return receiveFlowFaintTextColor;
    }
    if (d.isInvalid || d.isNetworkMismatch) {
      return receiveFlowTextColor;
    }
    if (!_destinationMatchesFlow(d)) {
      return receiveFlowMutedTextColor;
    }
    return receiveFlowTextColor.withValues(alpha: 0.82);
  }

  List<RecentTransactionDestination> _recentDestinationsForCurrentFlow() {
    final kind = switch (widget.entryMode) {
      WithdrawEntryMode.onChain => RecentTransactionDestinationKind.onChain,
      WithdrawEntryMode.lightning => RecentTransactionDestinationKind.lightning,
    };

    return ref
        .watch(recentTransactionDestinationsProvider)
        .where((destination) => destination.kind == kind)
        .toList(growable: false);
  }

  IconData _destinationValidationIcon(_WithdrawDestinationAnalysis d) {
    if (d.type == _WithdrawDestinationType.empty) {
      return LucideIcons.arrowUpRight;
    }
    if (d.isInvalid || d.isNetworkMismatch || !_destinationMatchesFlow(d)) {
      return LucideIcons.alertCircle;
    }
    return LucideIcons.checkCircle2;
  }

  String _destinationValidationText(
    BuildContext context,
    _WithdrawDestinationAnalysis d,
    BitcoinNetworkKind expectedOnchainNetwork,
  ) {
    if (d.type == _WithdrawDestinationType.empty) {
      return widget.entryMode == WithdrawEntryMode.lightning
          ? context.l10n.withdrawUiLightningDestinationRequired
          : context.l10n.withdrawUiDestinationEmptyOnchain;
    }
    if (d.isNetworkMismatch) {
      return context.l10n.withdrawUiNetworkMismatch(
        bitcoinNetworkDisplayName(d.detectedOnchainNetwork),
        bitcoinNetworkDisplayName(expectedOnchainNetwork),
      );
    }
    if (d.isInvalid) {
      return AppCopy.withdrawDestinationInvalid.resolve(context);
    }
    if (!_destinationMatchesFlow(d)) {
      return widget.entryMode == WithdrawEntryMode.lightning
          ? context.l10n.withdrawUiOnchainDestinationWrongFlow
          : context.l10n.withdrawUiLightningFieldWrongFlow;
    }
    return d.isLightning
        ? context.l10n.withdrawUiDestinationValidLightning
        : expectedOnchainNetwork == BitcoinNetworkKind.unknown
            ? context.l10n.withdrawUiDestinationValidOnchain
            : context.l10n.withdrawUiDestinationValidOnchainNetwork(
                bitcoinNetworkDisplayName(expectedOnchainNetwork),
              );
  }

  String _screenTitle(BuildContext context) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        return context.l10n.withdrawUiScreenTitleOnchain;
      case WithdrawEntryMode.lightning:
        return context.l10n.withdrawUiScreenTitleLightning;
    }
  }

  String _selectedNetworkLabel(
    BuildContext context,
    BitcoinNetworkKind expectedOnchainNetwork,
  ) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        if (expectedOnchainNetwork == BitcoinNetworkKind.unknown) {
          return AppCopy.withdrawNetworkOnChainChip.resolve(context);
        }
        return '${AppCopy.withdrawNetworkOnChainChip.resolve(context)} • ${bitcoinNetworkDisplayName(expectedOnchainNetwork)}';
      case WithdrawEntryMode.lightning:
        return context.l10n.lightning;
    }
  }

  String _treasuryLiquidityStateLabel(
    BuildContext context,
    TreasuryOverview overview,
  ) {
    switch (overview.liquidityState.trim().toUpperCase()) {
      case 'HEALTHY':
        return context.l10n.withdrawUiLiquidityHealthy;
      case 'REBALANCE_REQUIRED':
        return context.l10n.withdrawUiLiquidityRebalanceRequired;
      case 'BLOCKED_ONCHAIN_RESERVE':
        return context.l10n.withdrawUiLiquidityBlocked;
      default:
        return context.l10n.withdrawUiLiquidityUnknown;
    }
  }

  String _treasuryLiquidityMessage(
    BuildContext context,
    TreasuryOverview overview,
  ) {
    switch (overview.liquidityState.trim().toUpperCase()) {
      case 'HEALTHY':
        return context.l10n.withdrawUiLiquidityHealthyMessage;
      case 'REBALANCE_REQUIRED':
        return context.l10n.withdrawUiLiquidityRebalanceMessage;
      case 'BLOCKED_ONCHAIN_RESERVE':
        return context.l10n.withdrawUiLiquidityBlockedMessage;
      default:
        return context.l10n.withdrawUiLiquidityUnknownMessage;
    }
  }

  String _destinationHint(BuildContext context) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        return context.l10n.withdrawUiDestinationHintOnchain;
      case WithdrawEntryMode.lightning:
        return context.l10n.withdrawUiDestinationHintLightning;
    }
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _amountInput = MoneyDisplay.applyKeypadInput(
        currentValue: _amountInput,
        key: key,
        currency: _selectedCurrency,
        maxLength: _selectedCurrency == Currency.btc ? 16 : 12,
      );
    });
    _scheduleFeeEstimate();
  }

  void _scheduleFeeEstimate() {
    if (widget.entryMode != WithdrawEntryMode.onChain) {
      if (!mounted || (!_feeEstimatePending && _debouncedAmountBtc == 0)) {
        return;
      }
      setState(() {
        _feeEstimatePending = false;
        _debouncedAmountBtc = 0;
      });
      return;
    }

    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final nextAmountBtc = _parsedAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    _feeEstimateDebounce?.cancel();

    if (nextAmountBtc <= 0) {
      if (!mounted || (!_feeEstimatePending && _debouncedAmountBtc == 0)) {
        return;
      }
      setState(() {
        _feeEstimatePending = false;
        _debouncedAmountBtc = 0;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _feeEstimatePending = true;
      });
    }

    _feeEstimateDebounce = Timer(_feeEstimateDebounceDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _debouncedAmountBtc = nextAmountBtc;
        _feeEstimatePending = false;
      });
    });
  }

  Future<void> _pasteDestination() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _addressController.text = text;
      _addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });
  }

  Future<void> _onContinue({
    required Wallet wallet,
    required _WithdrawDestinationAnalysis destination,
    required _WithdrawFeeQuote feeQuote,
    required BitcoinNetworkKind expectedOnchainNetwork,
    required TreasuryOverview? treasuryOverview,
  }) async {
    if (wallet.isSelfCustody) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawConfirmButton,
        message: context.l10n.withdrawUiColdWalletSendBlocked,
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.lightning &&
        treasuryOverview != null &&
        !treasuryOverview.lightningSendsAllowed) {
      AppNotice.showWarning(
        context,
        title: context.l10n.lightning,
        message: _treasuryLiquidityMessage(context, treasuryOverview),
      );
      return;
    }

    if (_parsedAmount <= 0 || !feeQuote.hasAmount) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawConfirmButton,
        message: context.l10n.errorAmountRequired,
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.lightning &&
        !destination.isLightning) {
      AppNotice.showWarning(
        context,
        title: context.l10n.lightning,
        message: context.l10n.withdrawUiLightningDestinationRequiredForFlow,
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.onChain &&
        destination.isLightning) {
      AppNotice.showWarning(
        context,
        title: context.l10n.lightning,
        message: context.l10n.withdrawUiLightningDestinationWrongFlow,
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.onChain &&
        !destination.isOnChain) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawAddressLabel,
        message: AppCopy.withdrawDestinationInvalid.resolve(context),
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.onChain &&
        destination.isNetworkMismatch) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawAddressLabel,
        message: context.l10n.withdrawUiConfiguredNetworkMismatch(
          bitcoinNetworkDisplayName(expectedOnchainNetwork),
        ),
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.onChain && !feeQuote.isReady) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawFeeSection,
        message: feeQuote.isLoading
            ? context.l10n.withdrawUiWaitFeeEstimate
            : context.l10n.withdrawUiFeeEstimateUnavailable,
      );
      return;
    }

    final totalDebit = feeQuote.totalDebitedBtc;
    if (wallet.balance > 0 && totalDebit > wallet.balance) {
      AppNotice.showWarning(
        context,
        title: AppCopy.withdrawWalletBalanceLabel.resolve(context),
        message: AppCopy.withdrawInsufficientBalance.resolve(context),
      );
      return;
    }

    if (_addressController.text.trim() != destination.normalizedValue) {
      _addressController.text = destination.normalizedValue;
    }

    await _openWithdrawConfirmation(
      wallet: wallet,
      destination: destination,
      feeQuote: feeQuote,
      expectedOnchainNetwork: expectedOnchainNetwork,
      treasuryOverview: treasuryOverview,
    );
  }

  Future<void> _openWithdrawConfirmation({
    required Wallet wallet,
    required _WithdrawDestinationAnalysis destination,
    required _WithdrawFeeQuote feeQuote,
    required BitcoinNetworkKind expectedOnchainNetwork,
    required TreasuryOverview? treasuryOverview,
  }) async {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final networkLabel = _destinationLabel(
      context,
      destination,
      expectedOnchainNetwork,
    );
    final description = _descriptionController.text.trim();
    final primaryAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.amountBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final secondaryAmount = MoneyDisplay.format(
      amount: feeQuote.amountBtc,
      currency: Currency.btc,
    );
    final requestedAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.requestedAmountBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final platformFeeAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.platformFeeBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final totalFeesAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.totalFeesBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final networkFeeAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.networkFeeBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final totalDebitedAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.totalDebitedBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final balanceBeforeAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: wallet.balance,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final balanceAfterBtc = (wallet.balance - feeQuote.totalDebitedBtc)
        .clamp(0.0, double.infinity)
        .toDouble();
    final balanceAfterAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: balanceAfterBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final securityProfile = await _resolveSecurityProfile(wallet);
    if (!mounted) return;
    final requiresTotp = securityProfile.requiresTotp;
    final securityMessage = requiresTotp
        ? context.l10n.withdrawUiSecurityTotpRequired
        : context.l10n.withdrawUiSecurityPasskeyRequired;

    final details = <PaymentConfirmationDetail>[
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiDetailNetwork,
        value: networkLabel,
        icon: destination.isLightning ? LucideIcons.zap : LucideIcons.link,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiDetailSourceWallet,
        value: wallet.name,
        icon: LucideIcons.wallet,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiDetailCard,
        value:
            '${wallet.cardType.label} • ${WalletCardType.formatRate(wallet.withdrawalFeeRate)}',
        icon: LucideIcons.percent,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiDetailType,
        value: destination.isLightning
            ? context.l10n.withdrawUiLightningPayment
            : context.l10n.withdrawUiOnchainWithdrawal,
        icon: destination.isLightning ? LucideIcons.zap : LucideIcons.link,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiDetailExecution,
        value: destination.isLightning
            ? (treasuryOverview == null
                ? context.l10n.withdrawUiLightningLiquidityChecking
                : _treasuryLiquidityStateLabel(context, treasuryOverview))
            : context.l10n.withdrawUiSecureWalletSignature,
        icon: destination.isLightning
            ? LucideIcons.activity
            : LucideIcons.shieldCheck,
      ),
      PaymentConfirmationDetail(
        label: feeQuote.deductsFees
            ? AppCopy.withdrawYouPayTotalLabel.resolve(context)
            : AppCopy.withdrawReceiverReceivesLabel.resolve(context),
        value: requestedAmount,
        icon: LucideIcons.bitcoin,
        emphasized: true,
      ),
      PaymentConfirmationDetail(
        label: AppCopy.withdrawReceiverReceivesLabel.resolve(context),
        value: primaryAmount,
        icon: LucideIcons.bitcoin,
        emphasized: true,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiAmountBtc,
        value: secondaryAmount,
        icon: LucideIcons.coins,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiPlatformFeeWithRate(
          WalletCardType.formatRate(feeQuote.platformFeeRate),
        ),
        value: platformFeeAmount,
        icon: LucideIcons.percent,
      ),
      PaymentConfirmationDetail(
        label: destination.isLightning
            ? context.l10n.withdrawUiRoutingFeeCap
            : context.l10n.withdrawUiEstimatedNetworkFee,
        value: networkFeeAmount,
        icon: destination.isLightning
            ? LucideIcons.arrowLeftRight
            : LucideIcons.gauge,
      ),
      if (!destination.isLightning && feeQuote.feeRateSatPerByte != null)
        PaymentConfirmationDetail(
          label: context.l10n.withdrawUiNetworkFeeRate,
          value: '${feeQuote.feeRateSatPerByte!.toStringAsFixed(0)} sat/vB',
          icon: LucideIcons.activity,
        ),
      PaymentConfirmationDetail(
        label: feeQuote.deductsFees
            ? AppCopy.withdrawFeesDeductedLabel.resolve(context)
            : AppCopy.withdrawFeesAddedLabel.resolve(context),
        value: totalFeesAmount,
        icon: LucideIcons.receipt,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiTotalDebited,
        value: totalDebitedAmount,
        icon: LucideIcons.receipt,
        emphasized: true,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiBalanceBefore,
        value: balanceBeforeAmount,
        icon: LucideIcons.wallet,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.withdrawUiBalanceAfter,
        value: balanceAfterAmount,
        icon: LucideIcons.walletCards,
      ),
      if (description.isNotEmpty)
        PaymentConfirmationDetail(
          label: AppCopy.withdrawDescriptionLabel.resolve(context),
          value: description,
          icon: LucideIcons.fileText,
        ),
    ];

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen<dynamic>(
          title: AppCopy.withdrawReviewSummaryLabel.resolve(context),
          eyebrow: context.l10n.withdrawUiFinalReview,
          amountPrimary: primaryAmount,
          amountSecondary: secondaryAmount,
          sourceLabel: context.l10n.withdrawUiSourceFrom,
          sourceValue: wallet.name,
          destinationLabel: AppCopy.withdrawDestinationLabel.resolve(context),
          destinationValue: destination.normalizedValue,
          networkLabel: networkLabel,
          notice: destination.isLightning
              ? context.l10n.withdrawUiLightningReviewNotice
              : context.l10n.withdrawUiOnchainReviewNotice,
          securityMessage: securityMessage,
          confirmText: AppCopy.withdrawReviewConfirm.resolve(context),
          cancelText: context.l10n.withdrawCancel,
          requiresTotp: requiresTotp,
          totpTitle: AppCopy.withdrawReviewEnterTotp.resolve(context),
          totpHint: AppCopy.withdrawSecurityTotpHint.resolve(context),
          details: details,
          onConfirm: (confirmationContext, totpCode) => _handleWithdraw(
            confirmationContext: confirmationContext,
            wallet: wallet,
            destination: destination,
            feeQuote: feeQuote,
            securityProfile: securityProfile,
            totpCode: totpCode,
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  Future<dynamic> _handleWithdraw({
    required BuildContext confirmationContext,
    required Wallet wallet,
    required _WithdrawDestinationAnalysis destination,
    required _WithdrawFeeQuote feeQuote,
    required AccountSecurityProfile securityProfile,
    required String? totpCode,
  }) async {
    if (securityProfile.requiresTotp &&
        (totpCode == null || totpCode.trim().length != 6)) {
      AppNotice.showWarning(
        confirmationContext,
        title: AppCopy.withdrawReviewEnterTotp.resolve(confirmationContext),
        message: AppCopy.withdrawReviewInvalidTotp.resolve(confirmationContext),
      );
      return null;
    }

    final authProfile = _buildWithdrawAuthProfile(securityProfile);
    final authResult = await TransactionAuthGate.show(
      confirmationContext,
      profile: authProfile,
      allowDeviceAuthUnavailable: true,
    );

    if (!authResult.isAuthenticated) {
      if (confirmationContext.mounted) {
        AppNotice.showWarning(
          confirmationContext,
          title: confirmationContext.l10n.withdrawConfirmButton,
          message: confirmationContext.l10n.withdrawUiAuthIncomplete,
        );
      }
      return null;
    }

    if (!mounted || !confirmationContext.mounted) {
      return null;
    }

    final result = await ref.read(withdrawProvider.notifier).withdraw(
          fromWalletName: wallet.name,
          toAddress: destination.isOnChain ? destination.normalizedValue : null,
          paymentRequest:
              destination.isLightning ? destination.normalizedValue : null,
          amount: feeQuote.amountBtc,
          totpCode: securityProfile.requiresTotp ? totpCode?.trim() : null,
          isLightning: destination.isLightning,
          maxRoutingFeeBtc: _defaultLightningRoutingFeeBtc,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          confirmationPassphrase: authResult.confirmationPassphrase,
          passkeyAssertionJson: authResult.passkeyAssertionJson,
        );

    if (!mounted || !confirmationContext.mounted) return null;

    if (result == null) {
      final error = ref.read(withdrawProvider).error;
      AppNotice.showError(
        confirmationContext,
        title: confirmationContext.l10n.withdrawConfirmButton,
        message:
            ErrorTranslator.translate(confirmationContext.l10n, error ?? ''),
      );
      ref.read(withdrawProvider.notifier).reset();
      return null;
    }

    await ref
        .read(recentTransactionDestinationsProvider.notifier)
        .saveDestination(
          address: destination.normalizedValue,
          kind: destination.isLightning
              ? RecentTransactionDestinationKind.lightning
              : RecentTransactionDestinationKind.onChain,
          label: _resolveRecentDestinationLabel(),
        );
    ref.read(withdrawProvider.notifier).reset();
    return result;
  }

  Future<AccountSecurityProfile> _resolveSecurityProfile(Wallet wallet) async {
    try {
      return await ref.read(accountSecurityProfileProvider.future);
    } catch (_) {
      return _fallbackSecurityProfile(wallet.accountSecurity);
    }
  }

  int _currentStep = 0;
  final _pageController = PageController();

  AccountSecurityProfile _fallbackSecurityProfile(String rawSecurity) {
    final mode = accountSecurityModeFromApi(rawSecurity);
    final requiredFactors = switch (mode) {
      AccountSecurityMode.shamir => const ['SLIP39_SHARES', 'TOTP'],
      AccountSecurityMode.multisig2fa => const ['PASSPHRASE', 'TOTP'],
      AccountSecurityMode.passkey => const ['PASSKEY'],
      AccountSecurityMode.standard => const ['PASSKEY'],
    };

    return AccountSecurityProfile(
      mode: mode,
      passkeyAvailable: mode == AccountSecurityMode.standard,
      passkeyEnabledForTransactions: mode == AccountSecurityMode.standard,
      requiredFactors: requiredFactors,
    );
  }

  AccountSecurityProfile _buildWithdrawAuthProfile(
    AccountSecurityProfile profile,
  ) {
    return profile.copyWith(
      requiredFactors:
          profile.requiredFactors.where((factor) => factor != 'TOTP').toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final isSubmittingWithdraw = ref.watch(
      withdrawProvider.select((state) => state.isLoading),
    );
    final wallet = widget.wallet ??
        (walletState is WalletLoaded ? walletState.selectedWallet : null);

    if (wallet == null) {
      return ReceiveFlowScaffold(
        title: _screenTitle(context),
        subtitle: context.l10n.withdrawUiWalletLoadingSubtitle,
        scrollable: false,
        showBackButton: widget.showBackButton,
        child: const Center(
          child: CircularProgressIndicator(color: receiveFlowMutedTextColor),
        ),
      );
    }

    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final walletNetworkProfileAsync =
        ref.watch(walletNetworkProfileProvider(wallet.name));
    final treasuryOverviewAsync = ref.watch(treasuryOverviewProvider);
    final treasuryOverview = treasuryOverviewAsync.asData?.value;
    final expectedOnchainNetwork = walletNetworkProfileAsync.maybeWhen(
      data: (profile) => parseBitcoinNetwork(
        profile.network,
        fallbackAddress: profile.onchainAddress,
      ),
      orElse: () => parseBitcoinNetwork(
        null,
        fallbackAddress: wallet.address,
      ),
    );
    final amountBtc = _parsedAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final destination = _analyzeDestination(
      _addressController.text,
      expectedOnchainNetwork: expectedOnchainNetwork,
    );
    final feeEstimateAsync = amountBtc > 0 &&
            widget.entryMode == WithdrawEntryMode.onChain &&
            !_feeEstimatePending &&
            _debouncedAmountBtc > 0
        ? ref.watch(feeEstimateProvider(_debouncedAmountBtc))
        : null;

    final feeQuote = _resolveFeeQuote(
      requestedAmountBtc: amountBtc,
      platformFeeRate: wallet.withdrawalFeeRate,
      feeEstimateAsync: feeEstimateAsync,
    );
    final selfCustodyBlocked = wallet.isSelfCustody;
    final treasuryLightningBlocked =
        widget.entryMode == WithdrawEntryMode.lightning &&
            treasuryOverview != null &&
            !treasuryOverview.lightningSendsAllowed;
    final canContinueAmount = _destinationMatchesFlow(destination) &&
        !destination.isNetworkMismatch &&
        !selfCustodyBlocked &&
        !treasuryLightningBlocked &&
        (widget.entryMode == WithdrawEntryMode.lightning
            ? feeQuote.hasAmount
            : feeQuote.isReady);
    final canGoToAmountStep = _destinationMatchesFlow(destination) &&
        !destination.isNetworkMismatch &&
        !selfCustodyBlocked &&
        !destination.isInvalid &&
        destination.type != _WithdrawDestinationType.empty;
    final recentDestinations = _recentDestinationsForCurrentFlow();

    return ReceiveFlowScaffold(
      title: _screenTitle(context),
      subtitle: widget.entryMode == WithdrawEntryMode.lightning
          ? context.l10n.withdrawUiLightningSubtitle
          : context.l10n.withdrawUiOnchainSubtitle,
      scrollable: false,
      showBackButton: widget.showBackButton,
      bodyPadding: EdgeInsets.zero,
      onBack: _handleBack,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                _buildDestinationCard(
                  context,
                  destination,
                  expectedOnchainNetwork: expectedOnchainNetwork,
                ),
                if (selfCustodyBlocked) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSelfCustodyBlockedCard(context),
                ],
                if (recentDestinations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  RecentTransactionDestinationsSection(
                    title: widget.entryMode == WithdrawEntryMode.lightning
                        ? context.l10n.withdrawUiRecentLightning
                        : context.l10n.withdrawUiRecentOnchain,
                    destinations: recentDestinations,
                    onSelect: _applyRecentDestination,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildDescriptionCard(context),
                const SizedBox(height: AppSpacing.xl),
                ReceiveFlowPrimaryButton(
                  label: context.l10n.withdrawUiContinue,
                  icon: LucideIcons.arrowRight,
                  onTap: canGoToAmountStep
                      ? () {
                          FocusScope.of(context).unfocus();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                          );
                          setState(() => _currentStep = 1);
                        }
                      : null,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                _buildAmountCard(
                  context,
                  wallet: wallet,
                  btcUsd: btcUsd,
                  btcEur: btcEur,
                  btcBrl: btcBrl,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildFeeModeCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildOperationalRouteCard(
                  context,
                  wallet: wallet,
                  treasuryOverviewAsync: treasuryOverviewAsync,
                  treasuryOverview: treasuryOverview,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildFeeCard(
                  context,
                  wallet: wallet,
                  destination: destination,
                  feeQuote: feeQuote,
                  expectedOnchainNetwork: expectedOnchainNetwork,
                  btcUsd: btcUsd,
                  btcEur: btcEur,
                  btcBrl: btcBrl,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_selectedCurrency != Currency.btc && amountBtc > 0) ...[
                  _buildFiatReferenceLine(amountBtc: amountBtc),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildKeypad(context),
                const SizedBox(height: AppSpacing.lg),
                ReceiveFlowPrimaryButton(
                  label: context.l10n.withdrawConfirmButton,
                  isLoading: isSubmittingWithdraw,
                  icon: LucideIcons.arrowUpRight,
                  onTap: canContinueAmount
                      ? () => _onContinue(
                            wallet: wallet,
                            destination: destination,
                            feeQuote: feeQuote,
                            expectedOnchainNetwork: expectedOnchainNetwork,
                            treasuryOverview: treasuryOverview,
                          )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_currentStep == 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep = 0);
      return;
    }

    Navigator.pop(context);
  }

  Widget _buildAmountCard(
    BuildContext context, {
    required Wallet wallet,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    final amountBtc = _parsedAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            context.l10n.amountToSend,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                MoneyDisplay.tickerSymbolFor(_selectedCurrency),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: receiveFlowMutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _displayAmount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amountInput(
                    isBtc: _selectedCurrency == Currency.btc,
                    color: receiveFlowTextColor,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: wallet.balance <= 0
                ? 0
                : (amountBtc / wallet.balance).clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(0),
            color: receiveFlowTextColor,
            backgroundColor: receiveFlowDividerColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeModeCard(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(
            AppCopy.withdrawFeeModeTitle.resolve(context),
          ),
          const SizedBox(height: AppSpacing.md),
          _FeeModeOption(
            selected: _feeMode == WithdrawFeeMode.senderPays,
            title: AppCopy.withdrawFeeModeSenderPaysTitle.resolve(context),
            body: AppCopy.withdrawFeeModeSenderPaysBody.resolve(context),
            icon: LucideIcons.plusCircle,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _feeMode = WithdrawFeeMode.senderPays);
              _scheduleFeeEstimate();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeModeOption(
            selected: _feeMode == WithdrawFeeMode.recipientPays,
            title: AppCopy.withdrawFeeModeRecipientPaysTitle.resolve(context),
            body: AppCopy.withdrawFeeModeRecipientPaysBody.resolve(context),
            icon: LucideIcons.minusCircle,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _feeMode = WithdrawFeeMode.recipientPays);
              _scheduleFeeEstimate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiatReferenceLine({required double amountBtc}) {
    return Text(
      context.l10n.withdrawUiEquivalentTo(
        MoneyDisplay.format(amount: amountBtc, currency: Currency.btc),
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: receiveFlowMutedTextColor,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    _WithdrawDestinationAnalysis destination, {
    required BitcoinNetworkKind expectedOnchainNetwork,
  }) {
    final accent = _destinationValidationColor(context, destination);
    final isEmpty = destination.type == _WithdrawDestinationType.empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReceiveFlowSectionLabel(
              AppCopy.withdrawDestinationLabel.resolve(context),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pasteDestination,
              icon: const Icon(LucideIcons.clipboard, size: 15),
              label: Text(
                AppCopy.withdrawDestinationPaste.resolve(context),
              ),
              style: TextButton.styleFrom(
                foregroundColor: receiveFlowMutedTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: receiveFlowPanelColor,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: receiveFlowBorderStrongColor),
          ),
          child: TextField(
            controller: _addressController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            minLines: 1,
            maxLines: 1,
            cursorColor: accent,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: receiveFlowTextColor,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              prefixIcon: Icon(
                widget.entryMode == WithdrawEntryMode.lightning
                    ? LucideIcons.zap
                    : LucideIcons.link,
                size: 18,
                color: isEmpty ? receiveFlowFaintTextColor : accent,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 24,
              ),
              suffixIcon: isEmpty
                  ? null
                  : Icon(
                      _destinationValidationIcon(destination),
                      size: 18,
                      color: accent,
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 24,
              ),
              hintText: _destinationHint(context),
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: receiveFlowFaintTextColor,
                    fontWeight: FontWeight.w500,
                  ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _destinationValidationIcon(destination),
              size: 15,
              color: accent,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _destinationValidationText(
                  context,
                  destination,
                  expectedOnchainNetwork,
                ),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: accent,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(
            AppCopy.withdrawDescriptionLabel.resolve(context),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: receiveFlowTextColor,
                ),
            decoration: InputDecoration(
              hintText: context.l10n.withdrawDescHint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: receiveFlowFaintTextColor,
                  ),
              filled: true,
              fillColor: receiveFlowPanelAltColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
                borderSide:
                    const BorderSide(color: receiveFlowBorderStrongColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
                borderSide:
                    const BorderSide(color: receiveFlowBorderStrongColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
                borderSide: const BorderSide(color: receiveFlowMutedTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCustodyBlockedCard(BuildContext context) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.shieldAlert,
                color: receiveFlowTextColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.withdrawUiColdWalletTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: receiveFlowTextColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.withdrawUiColdWalletBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalRouteCard(
    BuildContext context, {
    required Wallet wallet,
    required AsyncValue<TreasuryOverview> treasuryOverviewAsync,
    required TreasuryOverview? treasuryOverview,
  }) {
    if (wallet.isSelfCustody) {
      return _buildSelfCustodyBlockedCard(context);
    }

    if (widget.entryMode == WithdrawEntryMode.onChain) {
      return ReceiveFlowPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReceiveFlowSectionLabel(
                context.l10n.withdrawUiOperationalExecution),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.withdrawUiOnchainOperationalBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      );
    }

    return treasuryOverviewAsync.when(
      loading: () => ReceiveFlowPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReceiveFlowSectionLabel(context.l10n.withdrawUiTreasuryLiquidity),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.withdrawUiTreasuryLoadingBody,
              style: const TextStyle(
                color: receiveFlowMutedTextColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => ReceiveFlowPanel(
        backgroundColor: receiveFlowPanelAltColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReceiveFlowSectionLabel(context.l10n.withdrawUiTreasuryLiquidity),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.withdrawUiTreasuryUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
      data: (overview) => ReceiveFlowPanel(
        backgroundColor: receiveFlowPanelAltColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReceiveFlowSectionLabel(context.l10n.withdrawUiTreasuryLiquidity),
            const SizedBox(height: AppSpacing.md),
            ReceiveFlowMetricRow(
              label: context.l10n.withdrawUiTreasuryState,
              value: _treasuryLiquidityStateLabel(context, overview),
            ),
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.withdrawUiTreasuryAvailableLightning,
              value: MoneyDisplay.format(
                amount: overview.availableLightningBtc,
                currency: Currency.btc,
              ),
            ),
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.withdrawUiTreasuryOutbound,
              value: MoneyDisplay.format(
                amount: overview.outboundLiquidityBtc,
                currency: Currency.btc,
              ),
            ),
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.withdrawUiTreasuryOnchainReserve,
              value: MoneyDisplay.format(
                amount: overview.availableOnchainBtc,
                currency: Currency.btc,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _treasuryLiquidityMessage(context, treasuryOverview ?? overview),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyRecentDestination(RecentTransactionDestination destination) {
    final value = destination.address.trim();
    if (value.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _addressController.text = value;
      _addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });
    _scheduleFeeEstimate();
  }

  String? _resolveRecentDestinationLabel() {
    final label = _descriptionController.text.trim();
    if (label.isEmpty) {
      return null;
    }
    return label;
  }

  String _formatTransactionBtcAmount({
    required double btcAmount,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    final primary = MoneyDisplay.formatAmountFromBtc(
      btcAmount: btcAmount,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    if (_selectedCurrency == Currency.btc) {
      return primary;
    }
    final btc = MoneyDisplay.format(
      amount: btcAmount,
      currency: Currency.btc,
    );
    return '$primary / $btc';
  }

  Widget _buildFeeCard(
    BuildContext context, {
    required Wallet wallet,
    required _WithdrawDestinationAnalysis destination,
    required _WithdrawFeeQuote feeQuote,
    required BitcoinNetworkKind expectedOnchainNetwork,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    const quoteColor = receiveFlowTextColor;

    final amountValue = _formatTransactionBtcAmount(
      btcAmount: feeQuote.amountBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final requestedValue = _formatTransactionBtcAmount(
      btcAmount: feeQuote.requestedAmountBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final platformFeeValue = _formatTransactionBtcAmount(
      btcAmount: feeQuote.platformFeeBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final totalFeesValue = _formatTransactionBtcAmount(
      btcAmount: feeQuote.totalFeesBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final hasAmount = feeQuote.hasAmount;
    final hasFinalTotals =
        hasAmount && !feeQuote.isLoading && feeQuote.error == null;
    final networkValue = !hasAmount
        ? '--'
        : feeQuote.isLoading
            ? context.l10n.withdrawUiFeeEstimating
            : feeQuote.error != null
                ? context.l10n.withdrawUiUnavailable
                : _formatTransactionBtcAmount(
                    btcAmount: feeQuote.networkFeeBtc,
                    btcUsd: btcUsd,
                    btcEur: btcEur,
                    btcBrl: btcBrl,
                  );
    final totalValue = !hasAmount
        ? '--'
        : feeQuote.isLoading
            ? context.l10n.withdrawUiFeeWaiting
            : feeQuote.error != null
                ? context.l10n.withdrawUiUnavailable
                : _formatTransactionBtcAmount(
                    btcAmount: feeQuote.totalDebitedBtc,
                    btcUsd: btcUsd,
                    btcEur: btcEur,
                    btcBrl: btcBrl,
                  );
    final balanceBeforeValue = _formatTransactionBtcAmount(
      btcAmount: wallet.balance,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final balanceAfterBtc = hasFinalTotals
        ? (wallet.balance - feeQuote.totalDebitedBtc)
            .clamp(0.0, double.infinity)
            .toDouble()
        : wallet.balance;
    final balanceAfterValue = hasFinalTotals
        ? _formatTransactionBtcAmount(
            btcAmount: balanceAfterBtc,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          )
        : '--';
    final destinationValue = destination.normalizedValue.trim().isEmpty
        ? '--'
        : destination.normalizedValue.trim();
    final feeRateValue = feeQuote.feeRateSatPerByte == null
        ? null
        : '${feeQuote.feeRateSatPerByte!.toStringAsFixed(0)} sat/vB';

    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(
            context.l10n.withdrawFeeSection,
          ),
          const SizedBox(height: AppSpacing.md),
          if (feeQuote.isLoading)
            const LinearProgressIndicator(
              minHeight: 4,
              color: receiveFlowTextColor,
              backgroundColor: receiveFlowDividerColor,
            ),
          _FeeRow(
            label: context.l10n.withdrawUiDetailSourceWallet,
            value: wallet.name,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: context.l10n.withdrawUiDetailCard,
            value:
                '${wallet.cardType.label} • ${WalletCardType.formatRate(wallet.withdrawalFeeRate)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: context.l10n.withdrawUiSelectedNetwork,
            value: _selectedNetworkLabel(context, expectedOnchainNetwork),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: AppCopy.withdrawDestinationLabel.resolve(context),
            value: destinationValue,
            monospace: destinationValue != '--',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          const ReceiveFlowDivider(),
          _FeeRow(
            label: feeQuote.deductsFees
                ? AppCopy.withdrawYouPayTotalLabel.resolve(context)
                : AppCopy.withdrawReceiverReceivesLabel.resolve(context),
            value: requestedValue,
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: context.l10n.withdrawUiPlatformFeeWithRate(
              WalletCardType.formatRate(feeQuote.platformFeeRate),
            ),
            value: platformFeeValue,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: widget.entryMode == WithdrawEntryMode.lightning
                ? context.l10n.withdrawUiRoutingFeeMax
                : context.l10n.withdrawUiEstimatedNetworkFee,
            value: networkValue,
          ),
          if (feeRateValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _FeeRow(
              label: context.l10n.withdrawUiNetworkFeeRate,
              value: feeRateValue,
              valueColor: quoteColor,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: feeQuote.deductsFees
                ? AppCopy.withdrawFeesDeductedLabel.resolve(context)
                : AppCopy.withdrawFeesAddedLabel.resolve(context),
            value: totalFeesValue,
            valueColor: quoteColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: AppCopy.withdrawYouPayTotalLabel.resolve(context),
            value: totalValue,
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: AppCopy.withdrawReceiverReceivesLabel.resolve(context),
            value: amountValue,
            valueColor: quoteColor,
            emphasize: feeQuote.deductsFees,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: AppCopy.withdrawWalletBalanceLabel.resolve(context),
            value: balanceBeforeValue,
            valueColor: quoteColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: context.l10n.withdrawUiBalanceAfter,
            value: balanceAfterValue,
            valueColor: quoteColor,
          ),
          const SizedBox(height: AppSpacing.md),
          if (feeQuote.error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: receiveFlowPanelAltColor,
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: receiveFlowBorderStrongColor),
              ),
              child: Text(
                context.l10n.withdrawUiFeeEstimateUnavailableLong,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: receiveFlowTextColor,
                      height: 1.45,
                    ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: receiveFlowPanelAltColor,
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: receiveFlowBorderStrongColor),
              ),
              child: Text(
                !hasAmount
                    ? context.l10n.withdrawUiEnterAmountForFees
                    : feeQuote.deductsFees
                        ? AppCopy.withdrawFeeModeDeductedHint.resolve(context)
                        : AppCopy.withdrawFeeModeAddedHint.resolve(context),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: receiveFlowMutedTextColor,
                      height: 1.45,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(children: [
            _buildKey(context, '1'),
            _buildKey(context, '2'),
            _buildKey(context, '3')
          ]),
          Row(children: [
            _buildKey(context, '4'),
            _buildKey(context, '5'),
            _buildKey(context, '6')
          ]),
          Row(children: [
            _buildKey(context, '7'),
            _buildKey(context, '8'),
            _buildKey(context, '9')
          ]),
          Row(children: [
            _buildKey(context, '.'),
            _buildKey(context, '0'),
            _buildKey(context, '←')
          ]),
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final isBackspace = key == '←';
    return ReceiveFlowKeypadButton(
      onTap: () => _onKeyTap(key),
      child: isBackspace
          ? const Icon(
              LucideIcons.delete,
              color: receiveFlowTextColor,
              size: 18,
            )
          : Text(
              key,
              style: AppTypography.number.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: receiveFlowTextColor,
              ),
            ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;
  final bool monospace;
  final int maxLines;

  const _FeeRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
    this.monospace = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = receiveFlowTextColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ?? textColor,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              fontFamily: monospace ? 'JetBrainsMono' : null,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeeModeOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  const _FeeModeOption({
    required this.selected,
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? receiveFlowTextColor : receiveFlowBorderStrongColor;
    final iconColor =
        selected ? receiveFlowTextColor : receiveFlowMutedTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? receiveFlowPanelAltColor : receiveFlowPanelColor,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: receiveFlowTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 18,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
