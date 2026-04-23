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
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/core/widgets/transaction_auth_gate.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/fee_estimate.dart';
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

  const _WithdrawDestinationAnalysis({
    required this.type,
    required this.normalizedValue,
  });

  bool get isOnChain => type == _WithdrawDestinationType.onChain;
  bool get isLightning => type == _WithdrawDestinationType.lightning;
  bool get isInvalid => type == _WithdrawDestinationType.invalid;
}

class _WithdrawFeeQuote {
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

  bool get hasAmount => amountBtc > 0;
  bool get isReady =>
      hasAmount && !isLoading && error == null && networkFeeBtc > 0;
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
    required double amountBtc,
    required double platformFeeRate,
    required AsyncValue<FeeEstimate>? feeEstimateAsync,
  }) {
    if (amountBtc <= 0) {
      return _WithdrawFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: 0,
        usesMaximumRoutingFee: widget.entryMode == WithdrawEntryMode.lightning,
        isEstimated: widget.entryMode == WithdrawEntryMode.onChain,
      );
    }

    final platformFeeBtc = amountBtc * platformFeeRate;

    if (widget.entryMode == WithdrawEntryMode.lightning) {
      final networkFeeBtc = _defaultLightningRoutingFeeBtc;
      return _WithdrawFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: platformFeeBtc,
        networkFeeBtc: networkFeeBtc,
        totalDebitedBtc: amountBtc + platformFeeBtc + networkFeeBtc,
        usesMaximumRoutingFee: true,
      );
    }

    if (feeEstimateAsync == null) {
      return _WithdrawFeeQuote(
        amountBtc: amountBtc,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: platformFeeBtc,
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

    return _WithdrawFeeQuote(
      amountBtc: amountBtc,
      platformFeeRate: platformFeeRate,
      platformFeeBtc: platformFeeBtc,
      networkFeeBtc: networkFeeBtc,
      totalDebitedBtc: amountBtc + platformFeeBtc + networkFeeBtc,
      feeRateSatPerByte: feeRateSatPerByte,
      isLoading: isLoading,
      error: error,
      isEstimated: true,
    );
  }

  _WithdrawDestinationAnalysis _analyzeDestination(String raw) {
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
      return _WithdrawDestinationAnalysis(
        type: _WithdrawDestinationType.onChain,
        normalizedValue: normalized,
      );
    }

    return _WithdrawDestinationAnalysis(
      type: _WithdrawDestinationType.invalid,
      normalizedValue: normalized,
    );
  }

  bool _looksLikeBitcoinAddress(String value) {
    return RegExp(r'^(1|3|bc1|m|n|2|tb1)[a-zA-HJ-NP-Z0-9]{20,90}$')
        .hasMatch(value.trim());
  }

  String _destinationLabel(
      BuildContext context, _WithdrawDestinationAnalysis d) {
    switch (d.type) {
      case _WithdrawDestinationType.onChain:
        return AppCopy.withdrawNetworkOnChainChip.resolve(context);
      case _WithdrawDestinationType.lightning:
        return context.l10n.lightning;
      case _WithdrawDestinationType.invalid:
        return AppCopy.withdrawNetworkReviewChip.resolve(context);
      case _WithdrawDestinationType.empty:
        return widget.entryMode == WithdrawEntryMode.lightning
            ? context.l10n.lightning
            : AppCopy.withdrawNetworkOnChainChip.resolve(context);
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
    if (d.isInvalid) {
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
    if (d.isInvalid || !_destinationMatchesFlow(d)) {
      return LucideIcons.alertCircle;
    }
    return LucideIcons.checkCircle2;
  }

  String _destinationValidationText(
    BuildContext context,
    _WithdrawDestinationAnalysis d,
  ) {
    if (d.type == _WithdrawDestinationType.empty) {
      return widget.entryMode == WithdrawEntryMode.lightning
          ? 'Informe uma invoice Lightning ou LNURL para continuar.'
          : 'Informe um endereco Bitcoin on-chain ou URI bitcoin: para continuar.';
    }
    if (d.isInvalid) {
      return AppCopy.withdrawDestinationInvalid.resolve(context);
    }
    if (!_destinationMatchesFlow(d)) {
      return widget.entryMode == WithdrawEntryMode.lightning
          ? 'Este campo recebeu um endereco on-chain. Use uma invoice Lightning ou LNURL.'
          : 'Este campo recebeu uma invoice Lightning. Use o fluxo Lightning para enviar.';
    }
    return d.isLightning
        ? 'Invoice Lightning ou LNURL valida para este envio.'
        : 'Endereco on-chain valido para este envio.';
  }

  String _screenTitle(BuildContext context) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        return 'ENVIAR ON-CHAIN';
      case WithdrawEntryMode.lightning:
        return 'ENVIAR LIGHTNING';
    }
  }

  String _selectedNetworkLabel(BuildContext context) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        return AppCopy.withdrawNetworkOnChainChip.resolve(context);
      case WithdrawEntryMode.lightning:
        return context.l10n.lightning;
    }
  }

  String _destinationHint(BuildContext context) {
    switch (widget.entryMode) {
      case WithdrawEntryMode.onChain:
        return 'Cole o endereco Bitcoin';
      case WithdrawEntryMode.lightning:
        return 'Cole a invoice Lightning ou LNURL';
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
  }) async {
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
        message: 'Informe uma invoice Lightning ou LNURL para este fluxo.',
      );
      return;
    }

    if (widget.entryMode == WithdrawEntryMode.onChain &&
        destination.isLightning) {
      AppNotice.showWarning(
        context,
        title: context.l10n.lightning,
        message:
            'O destino informado é Lightning. Abra o fluxo Lightning para continuar.',
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

    if (widget.entryMode == WithdrawEntryMode.onChain && !feeQuote.isReady) {
      AppNotice.showWarning(
        context,
        title: context.l10n.withdrawFeeSection,
        message: feeQuote.isLoading
            ? 'Aguarde a estimativa da taxa de rede para revisar o valor total do envio.'
            : 'Nao foi possivel estimar a taxa de rede agora. Tente novamente em instantes.',
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
    );
  }

  Future<void> _openWithdrawConfirmation({
    required Wallet wallet,
    required _WithdrawDestinationAnalysis destination,
    required _WithdrawFeeQuote feeQuote,
  }) async {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final networkLabel = _destinationLabel(context, destination);
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
    final platformFeeAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: feeQuote.platformFeeBtc,
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
        ? 'A transação exige TOTP e os fatores de segurança configurados na sua conta antes de chegar ao servidor.'
        : 'A transação exige confirmação por passkey antes de chegar ao servidor.';

    final details = <PaymentConfirmationDetail>[
      PaymentConfirmationDetail(
        label: 'Rede',
        value: networkLabel,
        icon: destination.isLightning ? LucideIcons.zap : LucideIcons.link,
      ),
      PaymentConfirmationDetail(
        label: 'Carteira de origem',
        value: wallet.name,
        icon: LucideIcons.wallet,
      ),
      PaymentConfirmationDetail(
        label: 'Cartão',
        value:
            '${wallet.cardType.label} • ${WalletCardType.formatRate(wallet.withdrawalFeeRate)}',
        icon: LucideIcons.percent,
      ),
      PaymentConfirmationDetail(
        label: 'Tipo',
        value:
            destination.isLightning ? 'Pagamento Lightning' : 'Saque on-chain',
        icon: destination.isLightning ? LucideIcons.zap : LucideIcons.link,
      ),
      PaymentConfirmationDetail(
        label:
            destination.isLightning ? 'Valor da invoice' : 'Valor no destino',
        value: primaryAmount,
        icon: LucideIcons.bitcoin,
        emphasized: true,
      ),
      PaymentConfirmationDetail(
        label: 'Valor em BTC',
        value: secondaryAmount,
        icon: LucideIcons.coins,
        monospace: true,
      ),
      PaymentConfirmationDetail(
        label:
            'Taxa de plataforma (${WalletCardType.formatRate(feeQuote.platformFeeRate)})',
        value: platformFeeAmount,
        icon: LucideIcons.percent,
      ),
      PaymentConfirmationDetail(
        label: destination.isLightning
            ? 'Teto de roteamento'
            : 'Taxa estimada de rede',
        value: networkFeeAmount,
        icon: destination.isLightning
            ? LucideIcons.arrowLeftRight
            : LucideIcons.gauge,
      ),
      if (!destination.isLightning && feeQuote.feeRateSatPerByte != null)
        PaymentConfirmationDetail(
          label: 'Taxa mempool',
          value: '${feeQuote.feeRateSatPerByte!.toStringAsFixed(0)} sat/vB',
          icon: LucideIcons.activity,
        ),
      PaymentConfirmationDetail(
        label: 'Total debitado',
        value: totalDebitedAmount,
        icon: LucideIcons.receipt,
        emphasized: true,
      ),
      PaymentConfirmationDetail(
        label: 'Saldo antes',
        value: balanceBeforeAmount,
        icon: LucideIcons.wallet,
      ),
      PaymentConfirmationDetail(
        label: 'Saldo estimado depois',
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
          eyebrow: 'Revisão final',
          amountPrimary: primaryAmount,
          amountSecondary: secondaryAmount,
          sourceLabel: 'De',
          sourceValue: wallet.name,
          destinationLabel: AppCopy.withdrawDestinationLabel.resolve(context),
          destinationValue: destination.normalizedValue,
          networkLabel: networkLabel,
          notice: destination.isLightning
              ? 'Confira a invoice e o teto de roteamento. O backend envia o pagamento e ajusta a liquidação conforme a rota disponível.'
              : 'Confira o endereço on-chain com atenção. Depois de transmitida, a transação Bitcoin não pode ser desfeita.',
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

    if (!authResult.isAuthenticated || !mounted) {
      AppNotice.showWarning(
        confirmationContext,
        title: confirmationContext.l10n.withdrawConfirmButton,
        message: 'Autenticação cancelada ou incompleta.',
      );
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

    if (!mounted) return;

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
        subtitle: 'Carregando carteira para iniciar o envio.',
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
    final amountBtc = _parsedAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final destination = _analyzeDestination(_addressController.text);
    final feeEstimateAsync = amountBtc > 0 &&
            widget.entryMode == WithdrawEntryMode.onChain &&
            !_feeEstimatePending &&
            _debouncedAmountBtc > 0
        ? ref.watch(feeEstimateProvider(_debouncedAmountBtc))
        : null;

    final feeQuote = _resolveFeeQuote(
      amountBtc: amountBtc,
      platformFeeRate: wallet.withdrawalFeeRate,
      feeEstimateAsync: feeEstimateAsync,
    );
    final canContinueAmount = _destinationMatchesFlow(destination) &&
        (widget.entryMode == WithdrawEntryMode.lightning
            ? feeQuote.hasAmount
            : feeQuote.isReady);
    final canGoToAmountStep = _destinationMatchesFlow(destination) &&
        !destination.isInvalid &&
        destination.type != _WithdrawDestinationType.empty;
    final recentDestinations = _recentDestinationsForCurrentFlow();

    return ReceiveFlowScaffold(
      title: _screenTitle(context),
      subtitle: widget.entryMode == WithdrawEntryMode.lightning
          ? 'Informe a invoice Lightning, revise o valor e confirme o pagamento.'
          : 'Informe o endereço Bitcoin, revise taxas e confirme o saque.',
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
                _buildDestinationCard(context, destination),
                if (recentDestinations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  RecentTransactionDestinationsSection(
                    title: widget.entryMode == WithdrawEntryMode.lightning
                        ? 'Ultimas invoices'
                        : 'Ultimos enderecos',
                    destinations: recentDestinations,
                    onSelect: _applyRecentDestination,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildDescriptionCard(context),
                const SizedBox(height: AppSpacing.xl),
                ReceiveFlowPrimaryButton(
                  label: 'CONTINUAR',
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
                _buildFeeCard(
                  context,
                  wallet: wallet,
                  destination: destination,
                  feeQuote: feeQuote,
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

  Widget _buildFiatReferenceLine({required double amountBtc}) {
    return Text(
      'Equivale a ${MoneyDisplay.format(amount: amountBtc, currency: Currency.btc)}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: receiveFlowMutedTextColor,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    _WithdrawDestinationAnalysis destination,
  ) {
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
                _destinationValidationText(context, destination),
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
    final platformFeeValue = _formatTransactionBtcAmount(
      btcAmount: feeQuote.platformFeeBtc,
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
            ? 'Estimando...'
            : feeQuote.error != null
                ? 'Indisponivel'
                : _formatTransactionBtcAmount(
                    btcAmount: feeQuote.networkFeeBtc,
                    btcUsd: btcUsd,
                    btcEur: btcEur,
                    btcBrl: btcBrl,
                  );
    final totalValue = !hasAmount
        ? '--'
        : feeQuote.isLoading
            ? 'Aguardando taxa'
            : feeQuote.error != null
                ? 'Indisponivel'
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
          _FeeRow(label: 'Carteira de origem', value: wallet.name),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: 'Cartão',
            value:
                '${wallet.cardType.label} • ${WalletCardType.formatRate(wallet.withdrawalFeeRate)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: 'Rede selecionada',
            value: _selectedNetworkLabel(context),
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
          _FeeRow(label: context.l10n.withdrawAmountLabel, value: amountValue),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label:
                'Taxa de plataforma (${WalletCardType.formatRate(feeQuote.platformFeeRate)})',
            value: platformFeeValue,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: widget.entryMode == WithdrawEntryMode.lightning
                ? 'Taxa maxima de roteamento'
                : 'Taxa estimada de rede',
            value: networkValue,
          ),
          if (feeRateValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _FeeRow(
              label: 'Taxa mempool',
              value: feeRateValue,
              valueColor: quoteColor,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: 'Total debitado',
            value: totalValue,
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: widget.entryMode == WithdrawEntryMode.lightning
                ? 'Valor da invoice'
                : 'Valor no destino',
            value: amountValue,
            valueColor: quoteColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: AppCopy.withdrawWalletBalanceLabel.resolve(context),
            value: balanceBeforeValue,
            valueColor: quoteColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(
            label: 'Saldo estimado depois',
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
                'Nao foi possivel estimar a taxa de rede no momento. Revise novamente em instantes antes de confirmar o envio.',
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
                    ? 'Digite um valor para calcular o custo total antes de confirmar.'
                    : feeQuote.usesMaximumRoutingFee
                        ? 'A taxa da plataforma usa o cartão ${wallet.cardType.label}. O roteamento acima é o teto reservado para o pagamento Lightning.'
                        : 'A taxa da plataforma usa o cartão ${wallet.cardType.label}. A taxa de rede usa a estimativa padrão atual da mempool.',
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
