import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:uuid/uuid.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/bitcoin_network.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/services/audio_service.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/transactions/domain/entities/fee_estimate.dart';
import 'package:kerosene/features/transactions/domain/entities/withdraw_fee_quote_calculation.dart';
import 'package:kerosene/features/transactions/presentation/widgets/transaction_amount_surface.dart';
import 'package:kerosene/features/wallet/data/kfe_receiving_capabilities_service.dart';
import 'package:kerosene/features/wallet/presentation/send/send_money_copy.dart';

import '../../../../core/utils/qr_payment_parser.dart';
import '../../../../core/widgets/transaction_auth_gate.dart';

import '../providers/wallet_provider.dart' hide transactionRepositoryProvider;
import '../state/wallet_state.dart';
import '../widgets/send_money_components.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';

import 'package:kerosene/core/theme/app_typography.dart';
part 'send_money_screen_review.dart';

enum _SendDestinationType {
  empty,
  internal,
  paymentLink,
  onChain,
  lightning,
  invalid,
}

class _SendDestinationAnalysis {
  final _SendDestinationType type;
  final String normalizedValue;
  final String? paymentLinkId;
  final double? amountBtc;
  final String? label;
  final String? message;
  final BitcoinNetworkKind detectedOnchainNetwork;

  const _SendDestinationAnalysis({
    required this.type,
    required this.normalizedValue,
    this.paymentLinkId,
    this.amountBtc,
    this.label,
    this.message,
    this.detectedOnchainNetwork = BitcoinNetworkKind.unknown,
  });

  bool get isEmpty => type == _SendDestinationType.empty;
  bool get isValid => type != _SendDestinationType.empty && !isInvalid;
  bool get isInvalid => type == _SendDestinationType.invalid;
  bool get isInternal => type == _SendDestinationType.internal;
  bool get isPaymentLink => type == _SendDestinationType.paymentLink;
  bool get isOnChain => type == _SendDestinationType.onChain;
  bool get isLightning => type == _SendDestinationType.lightning;
  bool get isExternal => isOnChain || isLightning;
  bool get hasLockedAmount => amountBtc != null && amountBtc! > 0;
}

class _SendFeeQuote {
  final double requestedAmountBtc;
  final double receiverAmountBtc;
  final double platformFeeRate;
  final double platformFeeBtc;
  final double networkFeeBtc;
  final double totalDebitedBtc;
  final double? feeRateSatPerByte;
  final bool isLoading;
  final Object? error;

  const _SendFeeQuote({
    required this.requestedAmountBtc,
    required this.receiverAmountBtc,
    required this.platformFeeRate,
    required this.platformFeeBtc,
    required this.networkFeeBtc,
    required this.totalDebitedBtc,
    this.feeRateSatPerByte,
    this.isLoading = false,
    this.error,
  });

  bool get hasAmount => requestedAmountBtc > 0;
  bool get isReady => hasAmount && !isLoading && error == null;
  double get totalFeesBtc => platformFeeBtc + networkFeeBtc;
}

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
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  static const Color _internalBlack = KeroseneBrandTokens.background;
  static const Color _internalSurface = KeroseneBrandTokens.surface;
  static const Color _internalSurfaceHigh = KeroseneBrandTokens.surfaceHigh;
  static const Color _internalBorder = KeroseneBrandTokens.border;
  static const Color _internalText = KeroseneBrandTokens.textPrimary;
  static const Color _internalMutedText = KeroseneBrandTokens.textMuted;
  static const Color _internalOutline = KeroseneBrandTokens.borderStrong;
  static const double _defaultLightningRoutingFeeBtc = 0.000001;

  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  double _lockedAmountBtc = 0.0;
  String? _lockedRecipientLabel;
  Wallet? _selectedWallet;
  bool _destinationResolutionBusy = false;

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

  void _onKeyTap(String key) {
    if (_lockedAmountBtc > 0) return; // Prevent changing locked amount

    HapticFeedback.lightImpact();
    _amount.value = MoneyDisplay.applyKeypadInput(
      currentValue: _amount.value,
      key: key,
      currency: _selectedCurrency,
      maxLength: _selectedCurrency == Currency.btc ? 16 : 12,
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
      backgroundColor: _internalBlack,
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
      textColor: _internalText,
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
      backgroundColor: _internalText,
      foregroundColor: _internalBlack,
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

    if (amountBtc <= 0) {
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

  _SendFeeQuote _resolveFeeQuote({
    required Wallet? wallet,
    required _SendDestinationAnalysis destination,
    required double amountBtc,
    required AsyncValue<FeeEstimate>? feeEstimateAsync,
  }) {
    if (!destination.isExternal || wallet == null || amountBtc <= 0) {
      return _SendFeeQuote(
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
      return _SendFeeQuote(
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
      return _SendFeeQuote(
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

  Future<_SendFeeQuote?> _resolveSubmitFeeQuote({
    required Wallet wallet,
    required _SendDestinationAnalysis destination,
    required double amountBtc,
  }) async {
    final networkFeeUnavailableMessage =
        SendMoneyCopy.networkFeeUnavailable(context);
    if (!destination.isExternal) {
      return _SendFeeQuote(
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

  _SendFeeQuote _buildExternalFeeQuote({
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
    return _SendFeeQuote(
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
      return _fallbackSecurityProfile(wallet.accountSecurity);
    }
  }

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

  Wallet? _resolveWallet(WalletState walletState) {
    if (walletState is! WalletLoaded) return null;

    final selected = _selectedWallet;
    if (selected != null) {
      for (final wallet in walletState.wallets) {
        if (wallet.id == selected.id || wallet.name == selected.name) {
          return wallet;
        }
      }
    }

    if (widget.walletId != null) {
      for (final wallet in walletState.wallets) {
        if (wallet.id == widget.walletId || wallet.name == widget.walletId) {
          return wallet;
        }
      }
    }

    return walletState.selectedWallet ??
        (walletState.wallets.isNotEmpty ? walletState.wallets.first : null);
  }

  Widget _buildWalletSelectionStep(
    BuildContext context,
    WalletState walletState,
  ) {
    final selectedWallet = _resolveWallet(walletState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInternalTopBar(context),
        Expanded(
          child: walletState is WalletLoading || walletState is WalletInitial
              ? const Center(
                  child: CircularProgressIndicator(color: _internalText),
                )
              : walletState is WalletError
                  ? _buildWalletLoadError(context, walletState.message)
                  : walletState is WalletLoaded
                      ? _buildWalletList(context, walletState, selectedWallet)
                      : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: _buildInternalPrimaryButton(
            label: context.tr.continueButton,
            icon: KeroseneIcons.next,
            enabled: selectedWallet != null,
            onTap: () {
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
          ),
        ),
      ],
    );
  }

  Widget _buildWalletLoadError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            KeroseneIcons.warning,
            color: _internalMutedText,
            size: 34,
          ),
          const SizedBox(height: 16),
          Text(
            SendMoneyCopy.walletLoadFailed(context),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _internalText,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ErrorTranslator.translate(context.tr, message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _internalMutedText,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => ref.read(walletProvider.notifier).refresh(),
            icon: const Icon(KeroseneIcons.refresh, size: 18),
            label: Text(context.tr.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletList(
    BuildContext context,
    WalletLoaded walletState,
    Wallet? selectedWallet,
  ) {
    if (walletState.wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            SendMoneyCopy.noWalletsForSend(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _internalMutedText,
                  height: 1.5,
                ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                SendMoneyCopy.sendTitle(context),
                style: AppTypography.newsreader(
                  color: _internalText,
                  fontSize: 42,
                  fontWeight: FontWeight.w400,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                SendMoneyCopy.walletSelectionSubtitle(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _internalMutedText,
                      fontSize: 14,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              for (final wallet in walletState.wallets)
                _buildWalletOption(context, wallet, selectedWallet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletOption(
    BuildContext context,
    Wallet wallet,
    Wallet? selectedWallet,
  ) {
    final selected = selectedWallet?.id == wallet.id;
    const defaultWalletMode = 'KEROSENE';
    const availableBalanceLabel = 'SALDO DISPONÍVEL';
    final walletMode = wallet.walletMode.trim().isEmpty
        ? defaultWalletMode
        : wallet.walletMode.trim().replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedWallet = wallet);
          },
          child: AnimatedContainer(
            duration: KeroseneMotion.short,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _internalSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _internalText : _internalBorder,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _internalSurfaceHigh,
                        border: Border.all(color: _internalBorder),
                      ),
                      child: const Icon(
                        KeroseneIcons.wallet,
                        color: _internalText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _internalText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            walletMode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _internalMutedText,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: KeroseneMotion.short,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _internalText : Colors.transparent,
                        border: Border.all(
                          color: selected ? _internalText : _internalOutline,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              KeroseneIcons.check,
                              color: _internalBlack,
                              size: 14,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _internalBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      availableBalanceLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _internalMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _walletBalanceLabel(wallet.balance),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _internalText,
                            fontFamily: AppTypography.financialFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationStep(BuildContext context) {
    final recentDestinations = ref
        .watch(recentTransactionDestinationsProvider)
        .toList(growable: false);
    final destination = _receiverController.text.trim();
    final analysis = _currentDestinationAnalysis();
    final isValidDestination = analysis.isValid;
    final hasContacts = recentDestinations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, hasContacts ? 12 : 0, 24, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDestinationHeader(context, hasContacts: hasContacts),
                    SizedBox(height: hasContacts ? 32 : 26),
                    _buildDestinationInputSection(
                      context,
                      analysis: analysis,
                      largeLabel: !hasContacts,
                    ),
                    if (destination.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _destinationHelperText(analysis),
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isValidDestination
                                  ? _internalMutedText
                                  : _internalText,
                              height: 1.35,
                            ),
                      ),
                    ],
                    if (recentDestinations.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _buildInternalFrequentContactsSection(
                        recentDestinations.take(3).toList(growable: false),
                      ),
                      const SizedBox(height: 36),
                      _buildInternalAllContactsSection(recentDestinations),
                    ] else ...[
                      const SizedBox(height: 42),
                      _buildEmptyContactsState(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildDestinationBottomAction(
          context,
          hasContacts: hasContacts,
          onTap: () {
            if (!isValidDestination) {
              SnackbarHelper.showError(
                destination.isEmpty
                    ? context.tr.sendMoneyMissingDestination
                    : SendMoneyCopy.unrecognizedDestination(context),
              );
              return;
            }
            unawaited(_continueFromDestinationStep(analysis));
          },
        ),
      ],
    );
  }

  Widget _buildDestinationHeader(
    BuildContext context, {
    required bool hasContacts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: context.tr.close,
            icon: const Icon(KeroseneIcons.close, size: 24),
            color: _internalText,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        SizedBox(height: hasContacts ? 18 : 20),
        Text(
          SendMoneyCopy.destinationTitle(context),
          textAlign: TextAlign.left,
          style: AppTypography.newsreader(
            color: _internalText,
            fontSize: hasContacts ? 30 : 28,
            fontWeight: hasContacts ? FontWeight.w700 : FontWeight.w500,
            height: hasContacts ? 1.12 : 1.2,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationBottomAction(
    BuildContext context, {
    required bool hasContacts,
    required VoidCallback onTap,
  }) {
    final backgroundColor = hasContacts ? _internalSurfaceHigh : _internalText;
    final foregroundColor = hasContacts ? _internalText : _internalBlack;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        color: _internalBlack,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(hasContacts ? 8 : 28),
              ),
              textStyle: AppTypography.inter(
                fontSize: hasContacts ? 14 : 11,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: hasContacts ? 1.4 : 1.1,
              ),
            ),
            child: Text(context.tr.continueButton),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContactsState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _internalSurfaceHigh,
            ),
            child: const Center(
              child: Icon(
                KeroseneIcons.userAdd,
                color: _internalMutedText,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            SendMoneyCopy.noRecentDestinations(context),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _internalText,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SendMoneyCopy.noRecentDestinationsBody(context),
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: _internalMutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueFromDestinationStep(
    _SendDestinationAnalysis analysis,
  ) async {
    FocusScope.of(context).unfocus();
    var destination = analysis;

    if (destination.isPaymentLink) {
      final linkId = destination.paymentLinkId;
      if (linkId == null || linkId.isEmpty) {
        SnackbarHelper.showError(context.tr.sendMoneyInvalidPaymentRequest);
        return;
      }
      final loaded = await _fetchPaymentLinkDetails(linkId);
      if (!loaded || !mounted) return;
    } else {
      final resolvedDestination = await _resolveDestinationForKfe(destination);
      if (resolvedDestination == null || !mounted) return;
      destination = resolvedDestination;
    }

    if (destination.hasLockedAmount) {
      _amount.value = destination.amountBtc!
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      setState(() {
        _lockedRecipientLabel = destination.label;
        _lockedRecipientAddress = destination.normalizedValue;
      });
    } else if (destination.label != null &&
        destination.label!.trim().isNotEmpty) {
      setState(() {
        _lockedRecipientLabel = destination.label;
      });
    }

    _pageController.nextPage(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
    );
    setState(() => _currentStep = 2);
  }

  _SendDestinationAnalysis _currentDestinationAnalysis() {
    if (_pendingPaymentLinkId != null) {
      return _SendDestinationAnalysis(
        type: _SendDestinationType.paymentLink,
        normalizedValue: _lockedRecipientAddress.isNotEmpty
            ? _lockedRecipientAddress
            : _pendingPaymentLinkId!,
        paymentLinkId: _pendingPaymentLinkId,
        amountBtc: _lockedAmountBtc > 0 ? _lockedAmountBtc : null,
        label: _lockedRecipientLabel,
      );
    }

    final locked = _lockedRecipientAddress.trim();
    if (locked.isNotEmpty) {
      final lockedAnalysis = _analyzeDestination(locked);
      return _SendDestinationAnalysis(
        type: lockedAnalysis.type,
        normalizedValue: lockedAnalysis.normalizedValue,
        paymentLinkId: lockedAnalysis.paymentLinkId,
        amountBtc:
            _lockedAmountBtc > 0 ? _lockedAmountBtc : lockedAnalysis.amountBtc,
        label: _lockedRecipientLabel ?? lockedAnalysis.label,
        message: lockedAnalysis.message,
        detectedOnchainNetwork: lockedAnalysis.detectedOnchainNetwork,
      );
    }

    return _analyzeDestination(_receiverController.text);
  }

  _SendDestinationAnalysis _analyzeDestination(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const _SendDestinationAnalysis(
        type: _SendDestinationType.empty,
        normalizedValue: '',
      );
    }

    final linkId = QrPaymentParser.extractPaymentLinkId(trimmed);
    if (linkId != null) {
      return _SendDestinationAnalysis(
        type: _SendDestinationType.paymentLink,
        normalizedValue: linkId,
        paymentLinkId: linkId,
      );
    }

    final parsed = QrPaymentParser.decode(trimmed);
    final normalized = parsed?.preferredDestination.trim().isNotEmpty == true
        ? parsed!.preferredDestination.trim()
        : _stripLightningPrefix(trimmed);

    if (_looksLikeLightningRequest(normalized)) {
      return _SendDestinationAnalysis(
        type: _SendDestinationType.lightning,
        normalizedValue: normalized,
        amountBtc: parsed?.amountBtc ?? _extractLightningAmountBtc(normalized),
        label: parsed?.label,
        message: parsed?.message,
      );
    }

    if (looksLikeBitcoinAddress(normalized)) {
      return _SendDestinationAnalysis(
        type: _SendDestinationType.onChain,
        normalizedValue: normalized,
        amountBtc: parsed?.amountBtc,
        label: parsed?.label,
        message: parsed?.message,
        detectedOnchainNetwork: inferBitcoinNetworkFromAddress(normalized),
      );
    }

    if (_isValidInternalDestination(normalized)) {
      return _SendDestinationAnalysis(
        type: _SendDestinationType.internal,
        normalizedValue: normalized,
        amountBtc: parsed?.amountBtc,
        label: parsed?.label,
        message: parsed?.message,
      );
    }

    return _SendDestinationAnalysis(
      type: _SendDestinationType.invalid,
      normalizedValue: normalized,
    );
  }

  Future<_SendDestinationAnalysis?> _resolveDestinationForKfe(
    _SendDestinationAnalysis analysis,
  ) async {
    if (!analysis.isInternal || _looksLikeUuid(analysis.normalizedValue)) {
      return analysis;
    }

    try {
      final capabilities = await ref
          .read(kfeReceivingCapabilitiesServiceProvider)
          .receivingCapabilities(analysis.normalizedValue);
      if (!mounted) return null;
      final walletId = capabilities.internalWalletId?.trim();
      if (!capabilities.canReceiveInternal ||
          walletId == null ||
          walletId.isEmpty) {
        SnackbarHelper.showError(context.tr.errReceiverNotReady);
        return null;
      }

      final resolved = _SendDestinationAnalysis(
        type: _SendDestinationType.internal,
        normalizedValue: walletId,
        amountBtc: analysis.amountBtc,
        label: capabilities.receiverDisplayName.trim().isNotEmpty
            ? capabilities.receiverDisplayName.trim()
            : analysis.normalizedValue,
        message: analysis.message,
      );

      setState(() {
        _lockedRecipientAddress = walletId;
        _lockedRecipientLabel = resolved.label;
      });
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

  bool _looksLikeUuid(String value) {
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

  String _destinationHelperText(_SendDestinationAnalysis analysis) {
    if (analysis.isEmpty) {
      return 'Informe o destino para continuar.';
    }
    if (analysis.isInvalid) {
      return 'Não reconhecemos este destino. Use usuário Kerosene, endereço Bitcoin, invoice Lightning, link, QR ou NFC.';
    }
    if (analysis.isPaymentLink) {
      return 'Link de pagamento Kerosene detectado.';
    }
    if (analysis.isInternal) {
      return 'Transferência interna Kerosene detectada.';
    }
    if (analysis.isOnChain) {
      final network = bitcoinNetworkDisplayName(
        analysis.detectedOnchainNetwork,
      );
      return 'Endereço Bitcoin on-chain detectado • $network.';
    }
    if (analysis.isLightning) {
      return 'Pagamento Lightning detectado.';
    }
    return '';
  }

  Widget _buildDestinationInputSection(
    BuildContext context, {
    required _SendDestinationAnalysis analysis,
    required bool largeLabel,
  }) {
    final borderColor = analysis.isInvalid
        ? _internalText
        : _destinationResolutionBusy
            ? _internalMutedText
            : _internalBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: largeLabel ? 8 : 0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _receiverController,
                onChanged: (_) {
                  _pendingPaymentLinkId = null;
                  _lockedRecipientAddress = '';
                  _lockedRecipientLabel = null;
                  if (widget.initialAmountBtc == null) {
                    _lockedAmountBtc = 0;
                  }
                },
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                cursorColor: _internalText,
                textAlign: TextAlign.left,
                style: AppTypography.inter(
                  color: _internalText,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  hintText: SendMoneyCopy.destinationHint(context),
                  hintStyle: AppTypography.inter(
                    color: _internalMutedText.withValues(alpha: 0.55),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: KeroseneMotion.short,
              child: _destinationResolutionBusy
                  ? const SizedBox(
                      key: ValueKey('destination-loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _internalMutedText,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('destination-loading-empty'),
                      width: 18,
                      height: 18,
                    ),
            ),
            IconButton(
              onPressed: _scanInternalDestination,
              tooltip: context.tr.scanQR,
              icon: const Icon(KeroseneIcons.scanner, size: 24),
              color: _internalMutedText,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: KeroseneMotion.short,
          margin: const EdgeInsets.only(top: 8),
          height: 1,
          color: borderColor,
        ),
      ],
    );
  }

  Widget _buildInternalFrequentContactsSection(
    List<RecentTransactionDestination> destinations,
  ) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SendMoneyCopy.frequentDestinations(context),
          style: AppTypography.inter(
            color: _internalMutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 126,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildInternalFrequentContact(destinations[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemCount: destinations.length,
          ),
        ),
      ],
    );
  }

  Widget _buildInternalFrequentContact(
    RecentTransactionDestination destination,
  ) {
    final title = _recentInternalDestinationTitle(destination);
    final subtitle = _recentInternalDestinationSubtitle(destination);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _applyRecentInternalDestination(destination),
        child: SizedBox(
          width: 104,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                _InternalRecentAvatar(
                  title: title,
                  size: 64,
                  fontSize: 18,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _internalText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _internalMutedText,
                        fontSize: 11,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInternalAllContactsSection(
    List<RecentTransactionDestination> destinations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SendMoneyCopy.allDestinations(context),
          style: AppTypography.inter(
            color: _internalMutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 24),
        for (final destination in destinations)
          _buildInternalRecentDestination(destination),
      ],
    );
  }

  Widget _buildInternalRecentDestination(
    RecentTransactionDestination destination,
  ) {
    final title = _recentInternalDestinationTitle(destination);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _internalText.withValues(alpha: 0.10)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyRecentInternalDestination(destination),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _InternalRecentAvatar(
                  title: title,
                  size: 48,
                  fontSize: 14,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.newsreader(
                      color: _internalText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountStep(
    BuildContext context, {
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    required double amountBtc,
    required Wallet? wallet,
    required _SendDestinationAnalysis destination,
    required _SendFeeQuote feeQuote,
    required bool isLoading,
  }) {
    return ValueListenableBuilder<String>(
      valueListenable: _amount,
      builder: (context, amountValue, child) {
        final amountBtc = _currentAmountBtc(
          btcUsd: btcUsd,
          btcEur: btcEur,
          btcBrl: btcBrl,
          amountVal: _amount.value,
        );
        final recipient = _currentRecipientLabel();
        final recipientValue = _currentRecipientValue();
        final amountLabel = _lockedAmountBtc > 0
            ? _formatBtcValue(_lockedAmountBtc)
            : MoneyDisplay.formatEditableInput(
                rawValue: amountValue,
                currency: Currency.btc,
                withSymbol: false,
              );
        final fiatLabel = _formatFiatReference(
          btcAmount: amountBtc,
          btcUsd: btcUsd,
          btcEur: btcEur,
          btcBrl: btcBrl,
        );
        final balanceLabel = wallet == null
            ? '--'
            : '${_formatBtcValue(wallet.balance, decimalPlaces: 6)} BTC';
        final amountLocked =
            _pendingPaymentLinkId != null || _lockedAmountBtc > 0;
        final networkFeeLabel = feeQuote.isLoading
            ? 'Calculando'
            : '${_formatBtcValue(feeQuote.networkFeeBtc)} BTC';
        final networkFeeFiatLabel = feeQuote.isLoading
            ? ''
            : _formatFiatReference(
                btcAmount: feeQuote.networkFeeBtc,
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
                includeApproxPrefix: false,
              );
        final canContinue = amountBtc > 0 &&
            !isLoading &&
            (!destination.isOnChain || feeQuote.isReady);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInternalTopBar(context),
            Expanded(
              child: TransactionAmountSurface(
                direction: TransactionAmountDirection.send,
                rail: _railLabelForDestination(destination),
                sourceParty: TransactionPartyData(
                  prefix: 'Enviando de:',
                  title: wallet?.name ?? 'Carteira Principal',
                  subtitle: _compactInternalValue(
                    wallet?.address.trim().isNotEmpty == true
                        ? wallet!.address
                        : wallet?.id ?? '',
                  ),
                  icon: KeroseneIcons.user,
                ),
                destinationParty: TransactionPartyData(
                  prefix: 'para:',
                  title: recipient.isEmpty ? 'Destino' : recipient,
                  subtitle: _compactInternalValue(recipientValue),
                  icon: KeroseneIcons.user,
                ),
                amountLabel: amountLabel,
                unitLabel: MoneyDisplay.symbolFor(_selectedCurrency),
                fiatReference: fiatLabel,
                amountMuted: amountLocked,
                keypadConfig: TransactionKeypadConfig(
                  visible: !amountLocked,
                  onKeyTap: _onKeyTap,
                ),
                details: [
                  TransactionDetailRowData(
                    label: 'Saldo disponível',
                    value: balanceLabel,
                  ),
                  TransactionDetailRowData(
                    label: 'Taxa da rede',
                    value: networkFeeLabel,
                    secondaryValue: networkFeeFiatLabel.isEmpty
                        ? null
                        : networkFeeFiatLabel,
                    loading: feeQuote.isLoading,
                  ),
                  TransactionDetailRowData(
                    label: 'Tempo estimado',
                    value: _estimatedSendTime(destination),
                  ),
                ],
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                fillAvailableHeight: false,
                backgroundColor: _internalBlack,
                textColor: _internalText,
                mutedTextColor: _internalMutedText,
                tertiaryTextColor: _internalOutline,
                surfaceColor: _internalSurface,
                borderColor: _internalBorder,
                primaryButtonColor: _internalText,
                primaryButtonTextColor: _internalBlack,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: _internalBlack,
                border: Border(
                  top: BorderSide(
                    color: _internalBorder.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: _buildInternalPrimaryButton(
                label: context.tr.continueButton,
                enabled: canContinue,
                isLoading: isLoading,
                onTap: _handleContinue,
              ),
            ),
          ],
        );
      },
    );
  }

  String _railLabelForDestination(_SendDestinationAnalysis destination) {
    if (destination.isPaymentLink) return 'Link';
    if (destination.isLightning) return 'Lightning';
    if (destination.isOnChain) return 'On-chain';
    return 'Kerosene';
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

  String _reviewNote(
    _SendDestinationAnalysis destination, {
    required bool isPaymentLink,
  }) {
    if (isPaymentLink) {
      return 'Pagamento por link interno';
    }
    if (destination.isLightning) {
      return 'Pagamento Lightning';
    }
    if (destination.isOnChain) {
      return 'Envio on-chain';
    }
    return 'Transferência interna Kerosene';
  }

  Future<void> _openPaymentConfirmation({
    required Wallet wallet,
    required _SendDestinationAnalysis destination,
    required double amount,
    required double requestedAmount,
    required _SendFeeQuote feeQuote,
    required String toAddress,
  }) async {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final isPaymentLink =
        destination.isPaymentLink || _pendingPaymentLinkId != null;
    final recipientLabel = _currentRecipientLabel();
    final btcAmountLabel = MoneyDisplay.format(
      amount: requestedAmount,
      currency: Currency.btc,
    );
    final fiatAmountLabel = _formatFiatReference(
      btcAmount: requestedAmount,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final note = _reviewNote(destination, isPaymentLink: isPaymentLink);
    final feeLabel = destination.isExternal
        ? '${_formatBtcValue(feeQuote.totalFeesBtc)} BTC'
        : context.tr.free;

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => _InternalTransferReviewScreen<dynamic>(
          title: destination.isExternal
              ? 'Revisar envio'
              : 'Revisar transferência',
          confirmLabel: destination.isLightning
              ? 'Confirmar pagamento'
              : 'Confirmar envio',
          successTitle: destination.isExternal
              ? 'Envio iniciado'
              : 'Transferência concluída',
          successMessage: destination.isExternal
              ? 'A transação foi enviada para processamento.'
              : 'Os fundos foram enviados dentro da Kerosene.',
          recipientLabel: recipientLabel,
          recipientAddress: toAddress,
          amountBtcLabel: btcAmountLabel,
          fiatAmountLabel: fiatAmountLabel,
          feeLabel: feeLabel,
          note: note,
          sourceWallet: wallet.name,
          onConfirm: (confirmationContext) => _confirmPayment(
            confirmationContext: confirmationContext,
            wallet: wallet,
            destination: destination,
            amount: amount,
            feeQuote: feeQuote,
            toAddress: toAddress,
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _showSentTransactionNotification({
    required Wallet wallet,
    required _SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) async {
    final amountLabel = '${_formatBtcValue(amount)} BTC';
    final recipient = _resolveRecentInternalDestinationLabel(toAddress) ??
        _compactInternalValue(toAddress);
    final title = destination.isLightning
        ? 'Pagamento Lightning enviado'
        : destination.isOnChain
            ? 'Envio on-chain iniciado'
            : 'Transferência enviada';
    final body = destination.isExternal
        ? '$amountLabel enviado para $recipient. Acompanhe o status no histórico.'
        : '$amountLabel enviado para $recipient pela Kerosene.';

    await NotificationService().showTransactionNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      summary: wallet.name,
      payload: '/home',
      incoming: false,
    );
  }

  Future<dynamic> _confirmPayment({
    required BuildContext confirmationContext,
    required Wallet wallet,
    required _SendDestinationAnalysis destination,
    required double amount,
    required _SendFeeQuote feeQuote,
    required String toAddress,
  }) async {
    final l10n = context.tr;
    final profile = await _resolveSecurityProfile(wallet);
    if (!mounted || !confirmationContext.mounted) {
      return null;
    }

    final authResult = await TransactionAuthGate.show(
      confirmationContext,
      profile: profile,
      allowDeviceAuthUnavailable: true,
    );

    if (!authResult.isAuthenticated ||
        !mounted ||
        !confirmationContext.mounted) {
      SnackbarHelper.showError(l10n.sendMoneyAuthFailed);
      return null;
    }

    if (_pendingPaymentLinkId != null) {
      final linkId = _pendingPaymentLinkId;
      if (linkId == null) {
        SnackbarHelper.showError(l10n.sendMoneyInvalidPaymentRequest);
        return null;
      }

      final result = await ref.read(paymentLinkNotifierProvider.notifier).pay(
            linkId: linkId,
            payerWalletName: wallet.name,
            totpCode: authResult.totpCode,
            confirmationPassphrase: authResult.confirmationPassphrase,
            passkeyAssertionJson: authResult.passkeyAssertionJson,
          );

      if (result != null) {
        await _showSentTransactionNotification(
          wallet: wallet,
          destination: destination,
          amount: amount,
          toAddress: toAddress,
        );
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        ref.read(paymentLinkNotifierProvider.notifier).reset();
        return result;
      }

      AudioService.instance.playError();
      HapticFeedback.heavyImpact();
      final error = ref.read(paymentLinkNotifierProvider).error;
      if (error != null) {
        if (!mounted || !confirmationContext.mounted) {
          return null;
        }
        SnackbarHelper.showError(
          ErrorTranslator.translate(confirmationContext.l10n, error),
        );
      }
      ref.read(paymentLinkNotifierProvider.notifier).reset();
      return null;
    }

    if (destination.isExternal) {
      final result = await ref.read(withdrawProvider.notifier).withdraw(
            fromWalletName: wallet.id,
            toAddress: destination.isOnChain ? toAddress : null,
            paymentRequest: destination.isLightning ? toAddress : null,
            amount: amount,
            totpCode: authResult.totpCode,
            isLightning: destination.isLightning,
            networkFeeBtc: feeQuote.networkFeeBtc,
            maxRoutingFeeBtc: _defaultLightningRoutingFeeBtc,
            description: destination.isLightning
                ? 'Pagamento Lightning'
                : SendMoneyCopy.onchainSendDescription(context),
            confirmationPassphrase: authResult.confirmationPassphrase,
            passkeyAssertionJson: authResult.passkeyAssertionJson,
          );

      if (result != null) {
        await ref
            .read(recentTransactionDestinationsProvider.notifier)
            .saveDestination(
              address: toAddress,
              kind: destination.isLightning
                  ? RecentTransactionDestinationKind.lightning
                  : RecentTransactionDestinationKind.onChain,
              label: _resolveRecentInternalDestinationLabel(toAddress),
            );
        await _showSentTransactionNotification(
          wallet: wallet,
          destination: destination,
          amount: amount,
          toAddress: toAddress,
        );
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        ref.read(withdrawProvider.notifier).reset();
        return result;
      }

      AudioService.instance.playError();
      HapticFeedback.heavyImpact();
      final error = ref.read(withdrawProvider).error;
      if (error != null) {
        if (!mounted || !confirmationContext.mounted) {
          return null;
        }
        SnackbarHelper.showError(
          ErrorTranslator.translate(confirmationContext.l10n, error),
        );
      }
      ref.read(withdrawProvider.notifier).reset();
      return null;
    }

    final idempotencyKey = const Uuid().v4();
    final result = await ref.read(sendTransactionProvider.notifier).send(
          fromWalletId: wallet.id,
          fromAddress:
              wallet.address.trim().isEmpty ? null : wallet.address.trim(),
          toAddress: toAddress,
          amount: amount,
          feeSatoshis: (feeQuote.networkFeeBtc * 100000000).toInt(),
          context: null,
          passkeyAssertionJson: authResult.passkeyAssertionJson,
          confirmationPassphrase: authResult.confirmationPassphrase,
          totpCode: authResult.totpCode,
          idempotencyKey: idempotencyKey,
          requestTimestamp: DateTime.now().millisecondsSinceEpoch,
        );

    if (result != null) {
      await ref
          .read(recentTransactionDestinationsProvider.notifier)
          .saveDestination(
            address: toAddress,
            kind: RecentTransactionDestinationKind.internal,
            label: _resolveRecentInternalDestinationLabel(toAddress),
          );
      await _showSentTransactionNotification(
        wallet: wallet,
        destination: destination,
        amount: amount,
        toAddress: toAddress,
      );
      AudioService.instance.playTransaction();
      HapticFeedback.vibrate();
      ref.read(sendTransactionProvider.notifier).reset();
      return result;
    }

    AudioService.instance.playError();
    HapticFeedback.heavyImpact();
    final error = ref.read(sendTransactionProvider).error;
    if (error != null) {
      if (!mounted || !confirmationContext.mounted) {
        return null;
      }
      SnackbarHelper.showError(
        ErrorTranslator.translate(confirmationContext.l10n, error),
      );
    }
    ref.read(sendTransactionProvider.notifier).reset();
    return null;
  }

  Future<void> _parsePaymentRequest(String data) async {
    final linkId = QrPaymentParser.extractPaymentLinkId(data);
    if (linkId != null) {
      if (mounted) {
        setState(() {
          _receiverController.text = data.trim();
          _receiverController.selection = TextSelection.fromPosition(
            TextPosition(offset: _receiverController.text.length),
          );
        });
      }
      await _fetchPaymentLinkDetails(linkId);
      return;
    }

    final parsed = QrPaymentParser.decode(data);
    if (parsed != null && parsed.isComplete) {
      final analysis = _analyzeDestination(data);
      final normalized = analysis.normalizedValue.isNotEmpty
          ? analysis.normalizedValue
          : parsed.address;
      setState(() {
        _receiverController.text = normalized;
        _receiverController.selection = TextSelection.fromPosition(
          TextPosition(offset: normalized.length),
        );
        _lockedRecipientAddress = normalized;
        if (parsed.amountBtc != null && parsed.amountBtc! > 0) {
          _lockedAmountBtc = parsed.amountBtc!;
          _amount.value = parsed.amountBtc!
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
        if (parsed.label != null && parsed.label!.isNotEmpty) {
          _lockedRecipientLabel = parsed.label;
        }
      });

      HapticFeedback.lightImpact();
      SnackbarHelper.showSuccess(context.tr.sendMoneyRequestDataLoaded);
    } else {
      final candidate = data.trim();
      if (_isValidInternalDestination(candidate)) {
        setState(() {
          _receiverController.text = candidate;
          _receiverController.selection = TextSelection.fromPosition(
            TextPosition(offset: candidate.length),
          );
        });
        HapticFeedback.lightImpact();
        return;
      }
      SnackbarHelper.showError(context.tr.sendMoneyInvalidQrRequest);
    }
  }

  Future<bool> _fetchPaymentLinkDetails(String linkId) async {
    try {
      final payload =
          await ref.read(transactionRepositoryProvider).getPaymentLink(linkId);
      final amount = payload.amountBtc;
      final status = payload.status.toUpperCase();
      final destinationHash = payload.destinationHash ?? '';

      if (!mounted) {
        return false;
      }

      if (status == 'PAID') {
        SnackbarHelper.showError(context.tr.sendMoneyRequestAlreadyPaid);
        return false;
      }
      if (status == 'CANCELED' || status == 'EXPIRED') {
        SnackbarHelper.showError(context.tr.sendMoneyRequestExpired);
        return false;
      }

      setState(() {
        _pendingPaymentLinkId = linkId;
        _lockedRecipientLabel = destinationHash.isNotEmpty
            ? _shortHash(destinationHash)
            : payload.referenceLabel?.trim().isNotEmpty == true
                ? payload.referenceLabel!.trim()
                : context.tr.sendMoneyLockedDestination;
        _lockedRecipientAddress = destinationHash.isNotEmpty
            ? destinationHash
            : payload.depositAddress;
        if (amount > 0) {
          _lockedAmountBtc = amount;
          _amount.value = amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
      });
      SnackbarHelper.showSuccess(context.tr.sendMoneyPaymentRequestLoaded);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      SnackbarHelper.showError(
        ErrorTranslator.translate(context.tr, error.toString()),
      );
      return false;
    }
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
      _receiverController.text = value;
      _receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });
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

  String _shortHash(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 8)}';
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

  bool _isValidInternalDestination(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('@') ||
        trimmed.toLowerCase().startsWith('bitcoin:')) {
      return false;
    }
    if (RegExp(r'^[A-Za-z0-9_]{3,50}$').hasMatch(trimmed)) {
      return true;
    }
    return _looksLikeUuid(trimmed) ||
        RegExp(r'^[a-fA-F0-9]{32,128}$').hasMatch(trimmed);
  }

  String _compactInternalValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 6)}';
  }

  String _recentInternalDestinationTitle(
    RecentTransactionDestination destination,
  ) {
    final label = destination.label?.trim();
    return label == null || label.isEmpty ? destination.address : label;
  }

  String _recentInternalDestinationSubtitle(
    RecentTransactionDestination destination,
  ) {
    final label = destination.label?.trim();
    if (label == null || label.isEmpty) {
      return _recentInternalDestinationKindLabel(destination.kind);
    }
    return _compactInternalValue(destination.address);
  }

  String _recentInternalDestinationKindLabel(
    RecentTransactionDestinationKind kind,
  ) {
    return switch (kind) {
      RecentTransactionDestinationKind.internal => 'Transferência interna',
      RecentTransactionDestinationKind.onChain => 'Endereço on-chain',
      RecentTransactionDestinationKind.lightning => 'Invoice Lightning',
    };
  }

  String _formatBtcValue(double value, {int decimalPlaces = 8}) {
    return MoneyDisplay.format(
      amount: value,
      currency: Currency.btc,
      withSymbol: false,
      decimalPlaces: decimalPlaces,
    );
  }

  String _walletBalanceLabel(double value) {
    return '${_formatBtcValue(value, decimalPlaces: 6)} BTC';
  }

  String _formatFiatReference({
    required double btcAmount,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    bool includeApproxPrefix = true,
  }) {
    final value = MoneyDisplay.formatAmountFromBtc(
      btcAmount: btcAmount,
      currency: Currency.brl,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    return includeApproxPrefix ? '≈ $value' : value;
  }

  String _estimatedSendTime(_SendDestinationAnalysis destination) {
    if (destination.isOnChain) {
      return '~10 min';
    }
    if (destination.isLightning) {
      return 'Segundos';
    }
    return 'Instantâneo';
  }
}

class _InternalRecentAvatar extends StatelessWidget {
  final String title;
  final double size;
  final double fontSize;

  const _InternalRecentAvatar({
    required this.title,
    this.size = 48,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(title);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _SendMoneyScreenState._internalSurfaceHigh,
        border: Border.all(
          color: _SendMoneyScreenState._internalText.withValues(alpha: 0.10),
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _SendMoneyScreenState._internalText,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
        ),
      ),
    );
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+')).where((part) {
      return part.trim().isNotEmpty;
    }).toList(growable: false);
    if (parts.length > 1) {
      return '${parts.first.characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return trimmed.characters.take(2).join().toUpperCase();
  }
}
