import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/bitcoin_network.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/services/audio_service.dart';
import 'package:teste/core/widgets/nfc_scan_dialog.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:teste/core/l10n/l10n_extension.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/fee_estimate.dart';
import 'package:teste/features/transactions/domain/entities/withdraw_fee_quote_calculation.dart';

import '../../../../core/utils/qr_payment_parser.dart';
import '../../../../core/widgets/transaction_auth_gate.dart';

import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';

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
  static const Color _internalBlack = Color(0xFF000000);
  static const Color _internalSurface = Color(0xFF111111);
  static const Color _internalSurfaceHigh = Color(0xFF1F1F1F);
  static const Color _internalBorder = Color(0xFF2C2C2E);
  static const Color _internalText = Color(0xFFFFFFFF);
  static const Color _internalMutedText = Color(0xFFA3A3A3);
  static const Color _internalOutline = Color(0xFF666666);
  static const Color _internalSuccessGreen = Color(0xFF4ADE80);
  static const double _defaultLightningRoutingFeeBtc = 0.000001;

  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  double _lockedAmountBtc = 0.0;
  String? _lockedRecipientLabel;
  Wallet? _selectedWallet;

  final _receiverController = TextEditingController();

  String _amount = '0';
  late Currency _selectedCurrency;

  int _currentStep = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = Currency.btc;
    if (widget.initialAmountBtc != null) {
      _lockedAmountBtc = widget.initialAmountBtc!;
      _amount = widget.initialAmountBtc!
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
    setState(() {
      _amount = MoneyDisplay.applyKeypadInput(
        currentValue: _amount,
        key: key,
        currency: _selectedCurrency,
        maxLength: _selectedCurrency == Currency.btc ? 16 : 12,
      );
    });
  }

  double _amountAsDouble() => MoneyDisplay.parseEditableInput(_amount);

  double _currentAmountBtc({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (_lockedAmountBtc > 0) {
      return _lockedAmountBtc;
    }
    return MoneyDisplay.convertToBtcAmount(
      amount: _amountAsDouble(),
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSending = ref.watch(
      sendTransactionProvider.select((state) => state.isLoading),
    );
    final isPayingLink = ref.watch(
      paymentLinkNotifierProvider.select((state) => state.isLoading),
    );
    final isLoading = isSending || isPayingLink;
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
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
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep -= 1);
      return;
    }

    Navigator.pop(context);
  }

  Widget _buildInternalTopBar(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _handleBack();
              },
              icon: const Icon(LucideIcons.arrowLeft, size: 22),
              tooltip: context.tr.authBackAction,
              style: IconButton.styleFrom(
                foregroundColor: _internalText,
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Text(
                'Enviar',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: _internalText,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
        Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
        Row(children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
        Row(children: [_buildKey('.'), _buildKey('0'), _buildKey('←')]),
      ],
    );
  }

  Widget _buildInternalPrimaryButton({
    required String label,
    IconData? icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: _internalText,
          foregroundColor: _internalBlack,
          disabledBackgroundColor: _internalText.withValues(alpha: 0.22),
          disabledForegroundColor: _internalText.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _internalBlack,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase()),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    final display = key == '.' ? ',' : key;

    return Expanded(
      child: SizedBox(
        height: 56,
        child: TextButton(
          onPressed: () => _onKeyTap(key),
          style: TextButton.styleFrom(
            foregroundColor: isBackspace ? _internalOutline : _internalText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          child: isBackspace
              ? const Icon(LucideIcons.delete, size: 24)
              : Text(display),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final walletState = ref.read(walletProvider);
    final currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) {
      SnackbarHelper.showError('Carteira não carregada.');
      return;
    }
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    var amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    var destination = _currentDestinationAnalysis();

    HapticFeedback.mediumImpact();

    if (!destination.isValid) {
      SnackbarHelper.showError(
        destination.isEmpty
            ? context.tr.sendMoneyMissingDestination
            : 'Destino inválido.',
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
      );
      destination = _currentDestinationAnalysis();
    }

    if (amountBtc <= 0) {
      SnackbarHelper.showError(context.tr.errorAmountRequired);
      return;
    }

    final feeQuote = await _resolveSubmitFeeQuote(
      wallet: currentWallet,
      destination: destination,
      amountBtc: amountBtc,
    );
    if (feeQuote == null) return;

    final totalDebited =
        destination.isExternal ? feeQuote.totalDebitedBtc : amountBtc;

    if (currentWallet.balance > 0 && totalDebited > currentWallet.balance) {
      SnackbarHelper.showError('Saldo insuficiente para esta transferência.');
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
      SnackbarHelper.showError(
        'Não conseguimos calcular a taxa de rede agora. Tente novamente.',
      );
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
            label: 'Continuar',
            icon: LucideIcons.arrowRight,
            enabled: selectedWallet != null,
            onTap: () {
              if (selectedWallet == null) {
                SnackbarHelper.showError('Selecione uma carteira.');
                return;
              }
              HapticFeedback.selectionClick();
              ref.read(walletProvider.notifier).selectWallet(selectedWallet);
              setState(() {
                _selectedWallet = selectedWallet;
                _currentStep = 1;
              });
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
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
            LucideIcons.alertCircle,
            color: _internalMutedText,
            size: 34,
          ),
          const SizedBox(height: 16),
          Text(
            'Não foi possível carregar suas carteiras.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ebGaramond(
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
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Tentar novamente'),
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
            'Nenhuma carteira encontrada para envio.',
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
                'Enviar',
                style: GoogleFonts.ebGaramond(
                  color: _internalText,
                  fontSize: 42,
                  fontWeight: FontWeight.w400,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha de qual carteira deseja retirar seus bitcoins.',
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
    final walletMode = wallet.walletMode.trim().isEmpty
        ? 'KEROSENE'
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
            duration: const Duration(milliseconds: 180),
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
                        LucideIcons.wallet,
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
                      duration: const Duration(milliseconds: 180),
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
                              LucideIcons.check,
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
                      'SALDO DISPONÍVEL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _internalMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_formatBtcValue(wallet.balance, decimalPlaces: 6)} BTC',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _internalText,
                            fontFamily: 'JetBrainsMono',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInternalTopBar(context),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Insira um usuário Kerosene, endereço Bitcoin, invoice Lightning, link de pagamento, QR ou NFC.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _internalMutedText,
                            fontSize: 14,
                            height: 1.55,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 46),
                    _buildInternalDestinationInput(
                      context,
                      analysis: analysis,
                    ),
                    if (destination.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _destinationHelperText(analysis),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isValidDestination
                                  ? _internalMutedText
                                  : _internalText,
                              height: 1.35,
                            ),
                      ),
                    ],
                    const SizedBox(height: 52),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInternalQuickAction(
                          context,
                          icon: LucideIcons.scanLine,
                          label: 'QR Code',
                          tooltip: 'Ler QR Code',
                          onTap: _scanInternalDestination,
                        ),
                        const SizedBox(width: 48),
                        _buildInternalQuickAction(
                          context,
                          iconWidget: const Icon(Icons.nfc, size: 25),
                          label: 'NFC',
                          tooltip: 'Usar NFC',
                          onTap: _scanNfcDestination,
                        ),
                      ],
                    ),
                    if (recentDestinations.isNotEmpty) ...[
                      const SizedBox(height: 56),
                      Text(
                        'CONTATOS RECENTES',
                        style: GoogleFonts.ebGaramond(
                          color: _internalMutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final destination in recentDestinations.take(6))
                        _buildInternalRecentDestination(destination),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 34),
          child: _buildInternalPrimaryButton(
            label: 'Continuar',
            icon: LucideIcons.arrowRight,
            enabled: isValidDestination,
            onTap: () {
              if (!isValidDestination) {
                SnackbarHelper.showError(
                  destination.isEmpty
                      ? context.tr.sendMoneyMissingDestination
                      : 'Destino inválido.',
                );
                return;
              }
              unawaited(_continueFromDestinationStep(analysis));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _continueFromDestinationStep(
    _SendDestinationAnalysis analysis,
  ) async {
    FocusScope.of(context).unfocus();

    if (analysis.isPaymentLink) {
      final linkId = analysis.paymentLinkId;
      if (linkId == null || linkId.isEmpty) {
        SnackbarHelper.showError(context.tr.sendMoneyInvalidPaymentRequest);
        return;
      }
      final loaded = await _fetchPaymentLinkDetails(linkId);
      if (!loaded || !mounted) return;
    } else if (analysis.hasLockedAmount) {
      setState(() {
        _lockedAmountBtc = analysis.amountBtc!;
        _amount = analysis.amountBtc!
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
        _lockedRecipientLabel = analysis.label;
        _lockedRecipientAddress = analysis.normalizedValue;
      });
    } else if (analysis.label != null && analysis.label!.trim().isNotEmpty) {
      setState(() {
        _lockedRecipientLabel = analysis.label;
      });
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
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
    if (locked.isNotEmpty && _receiverController.text.trim().isEmpty) {
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
    final normalized = parsed?.address.trim().isNotEmpty == true
        ? parsed!.address.trim()
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

  Widget _buildInternalDestinationInput(
    BuildContext context, {
    required _SendDestinationAnalysis analysis,
  }) {
    final hasValue = _receiverController.text.trim().isNotEmpty;
    final isValidDestination = analysis.isValid;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: hasValue && isValidDestination
                ? _internalText
                : _internalText.withValues(alpha: 0.88),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _receiverController,
        onChanged: (_) => setState(() {
          _pendingPaymentLinkId = null;
          _lockedRecipientAddress = '';
          _lockedRecipientLabel = null;
          if (widget.initialAmountBtc == null) {
            _lockedAmountBtc = 0;
          }
        }),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        cursorColor: _internalText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _internalText,
              fontSize: 18,
              height: 1.4,
              letterSpacing: 0,
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(8, 11, 8, 13),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildInternalQuickAction(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _internalText),
              ),
              child: Tooltip(
                message: tooltip,
                child: Center(
                  child: iconWidget ??
                      Icon(
                        icon,
                        size: 24,
                        color: _internalText,
                      ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _internalMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  Widget _buildInternalRecentDestination(
    RecentTransactionDestination destination,
  ) {
    final label = destination.label?.trim();
    final title = label == null || label.isEmpty ? destination.address : label;
    final subtitle = label == null || label.isEmpty
        ? _compactInternalValue(destination.address)
        : _compactInternalValue(destination.address);

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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _InternalRecentAvatar(title: title),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _internalText,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.05,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _internalMutedText,
                              fontSize: 12,
                              height: 1.25,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  LucideIcons.chevronRight,
                  color: _internalOutline,
                  size: 20,
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
    final recipient = _currentRecipientLabel();
    final recipientValue = _currentRecipientValue();
    final amountLabel = _lockedAmountBtc > 0
        ? _formatBtcValue(_lockedAmountBtc)
        : MoneyDisplay.formatEditableInput(
            rawValue: _amount,
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
    final locked = _pendingPaymentLinkId != null ||
        _lockedRecipientAddress.isNotEmpty ||
        _lockedAmountBtc > 0;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInternalTopBar(context),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InternalSendPartyRow(
                          prefix: 'Enviando de:',
                          title: wallet?.name ?? 'Carteira Principal',
                          subtitle: _compactInternalValue(
                            wallet?.address.trim().isNotEmpty == true
                                ? wallet!.address
                                : wallet?.id ?? '',
                          ),
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 22),
                        _InternalSendPartyRow(
                          prefix: 'para:',
                          title: recipient.isEmpty ? 'Destino' : recipient,
                          subtitle: _compactInternalValue(recipientValue),
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 38),
                        const Spacer(),
                        _InternalSendAmountField(
                          amountLabel: amountLabel,
                          fiatLabel: fiatLabel,
                          muted: locked,
                        ),
                        const SizedBox(height: 28),
                        _InternalSendFinancialDetails(
                          balanceLabel: balanceLabel,
                          networkFeeLabel: networkFeeLabel,
                          networkFeeFiatLabel: networkFeeFiatLabel,
                          estimatedTimeLabel: _estimatedSendTime(destination),
                        ),
                        const SizedBox(height: 24),
                        if (!locked) ...[
                          RepaintBoundary(child: _buildKeypad()),
                          const SizedBox(height: 18),
                        ],
                        _buildInternalPrimaryButton(
                          label: 'Continuar',
                          enabled: amountBtc > 0 &&
                              !isLoading &&
                              (!destination.isOnChain || feeQuote.isReady),
                          isLoading: isLoading,
                          onTap: _handleContinue,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _currentRecipientValue() {
    return _lockedRecipientAddress.isNotEmpty
        ? _lockedRecipientAddress
        : _receiverController.text.trim();
  }

  String _currentRecipientLabel() {
    final label = _lockedRecipientLabel?.trim();
    if (label == null || label.isEmpty || label == 'Destino bloqueado') {
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
            fromWalletName: wallet.name,
            toAddress: destination.isOnChain ? toAddress : null,
            paymentRequest: destination.isLightning ? toAddress : null,
            amount: amount,
            totpCode: authResult.totpCode,
            isLightning: destination.isLightning,
            maxRoutingFeeBtc: _defaultLightningRoutingFeeBtc,
            description: destination.isLightning
                ? 'Pagamento Lightning'
                : 'Saque on-chain',
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
          _amount = parsed.amountBtc!
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
    final result =
        await ref.read(ledgerRepositoryProvider).getPaymentRequest(linkId);

    return result.fold(
      (failure) {
        SnackbarHelper.showError(
          ErrorTranslator.translate(
            context.tr,
            failure.errorCode ?? failure.message,
          ),
        );
        return false;
      },
      (data) {
        final payload = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        final rawAmount = payload['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
        final status =
            (payload['status']?.toString() ?? 'PENDING').toUpperCase();
        final destinationHash = _readPaymentRequestDestinationHash(payload);

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
              : context.tr.sendMoneyLockedDestination;
          _lockedRecipientAddress = destinationHash.isNotEmpty
              ? destinationHash
              : context.tr.sendMoneyLockedDestination;
          if (amount > 0) {
            _lockedAmountBtc = amount;
            _amount = amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          }
        });
        SnackbarHelper.showSuccess(context.tr.sendMoneyPaymentRequestLoaded);
        return true;
      },
    );
  }

  String _readPaymentRequestDestinationHash(Map<String, dynamic> data) {
    const keys = [
      'destinationHash',
      'destination_hash',
      'addressHash',
      'address_hash',
      'walletHash',
      'wallet_hash',
    ];

    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
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
        label == 'Destino bloqueado') {
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

  Future<void> _scanNfcDestination() async {
    HapticFeedback.selectionClick();
    final payload = await showDialog<String>(
      context: context,
      builder: (_) => const NfcScanDialog(),
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
    return RegExp(r'^[a-fA-F0-9]{32,128}$').hasMatch(trimmed);
  }

  String _compactInternalValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 6)}';
  }

  String _formatBtcValue(double value, {int decimalPlaces = 8}) {
    return MoneyDisplay.format(
      amount: value,
      currency: Currency.btc,
      withSymbol: false,
      decimalPlaces: decimalPlaces,
    );
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

class _InternalSendPartyRow extends StatelessWidget {
  final String prefix;
  final String title;
  final String subtitle;
  final IconData icon;

  const _InternalSendPartyRow({
    required this.prefix,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _SendMoneyScreenState._internalSurfaceHigh,
            border: Border.all(
              color:
                  _SendMoneyScreenState._internalText.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            icon,
            color: _SendMoneyScreenState._internalMutedText,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$prefix ',
                      style: const TextStyle(
                        color: _SendMoneyScreenState._internalMutedText,
                      ),
                    ),
                    TextSpan(text: title),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _SendMoneyScreenState._internalText,
                      fontSize: 15,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle.isEmpty ? '--' : subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _SendMoneyScreenState._internalOutline,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InternalSendAmountField extends StatelessWidget {
  final String amountLabel;
  final String fiatLabel;
  final bool muted;

  const _InternalSendAmountField({
    required this.amountLabel,
    required this.fiatLabel,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = muted
        ? _SendMoneyScreenState._internalBorder
        : _SendMoneyScreenState._internalText.withValues(alpha: 0.20);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: _SendMoneyScreenState._internalText,
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BTC',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _SendMoneyScreenState._internalMutedText,
                          fontSize: 18,
                          height: 1,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  fiatLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _SendMoneyScreenState._internalMutedText,
                        fontSize: 17,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: lineColor),
      ],
    );
  }
}

class _InternalSendFinancialDetails extends StatelessWidget {
  final String balanceLabel;
  final String networkFeeLabel;
  final String networkFeeFiatLabel;
  final String estimatedTimeLabel;

  const _InternalSendFinancialDetails({
    required this.balanceLabel,
    required this.networkFeeLabel,
    required this.networkFeeFiatLabel,
    required this.estimatedTimeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InternalSendDetailRow(label: 'Saldo atual', value: balanceLabel),
        const SizedBox(height: 16),
        _InternalSendDetailRow(
          label: 'Taxa de rede',
          value: networkFeeLabel,
          secondaryValue:
              networkFeeFiatLabel.isEmpty ? null : '(~ $networkFeeFiatLabel)',
        ),
        const SizedBox(height: 16),
        _InternalSendDetailRow(
          label: 'Tempo estimado',
          value: estimatedTimeLabel,
        ),
      ],
    );
  }
}

class _InternalSendDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? secondaryValue;

  const _InternalSendDetailRow({
    required this.label,
    required this.value,
    this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _SendMoneyScreenState._internalText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: 0,
        );

    return Row(
      crossAxisAlignment: secondaryValue == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _SendMoneyScreenState._internalMutedText,
                  fontSize: 15,
                  height: 1.3,
                  letterSpacing: 0,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 3),
                Text(
                  secondaryValue!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SendMoneyScreenState._internalOutline,
                        fontSize: 13,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InternalRecentAvatar extends StatelessWidget {
  final String title;

  const _InternalRecentAvatar({required this.title});

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(title);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _SendMoneyScreenState._internalSurfaceHigh,
        border: Border.all(
          color: _SendMoneyScreenState._internalText.withValues(alpha: 0.10),
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _SendMoneyScreenState._internalText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
        ),
      ),
    );
  }

  String _initialFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
