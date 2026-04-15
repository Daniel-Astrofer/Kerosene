import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/widgets/transaction_auth_gate.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/fee_estimate.dart';
import 'package:teste/features/transactions/presentation/screens/payment_confirmation_screen.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
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
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    if (d.isInvalid) {
      return Theme.of(context).colorScheme.error;
    }
    if (!_destinationMatchesFlow(d)) {
      return AppColors.warning;
    }
    return AppColors.success;
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
      if (!mounted ||
          (!_feeEstimatePending && _debouncedAmountBtc == 0)) {
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
      if (!mounted ||
          (!_feeEstimatePending && _debouncedAmountBtc == 0)) {
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
      return const CyberBackground.authenticated(
        child: Center(child: CircularProgressIndicator()),
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
    final canContinue = _destinationMatchesFlow(destination) &&
        (widget.entryMode == WithdrawEntryMode.lightning
            ? feeQuote.hasAmount
            : feeQuote.isReady);

    return CyberBackground.authenticated(
      useScroll: false,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
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
                  _buildDestinationCard(context, destination),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescriptionCard(context),
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
                  BouncingButton(
                    text: context.l10n.withdrawConfirmButton,
                    isLoading: isSubmittingWithdraw,
                    icon: LucideIcons.arrowUpRight,
                    onPressed: canContinue
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.04),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(
            _screenTitle(context),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.amountToSend,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.60),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                MoneyDisplay.tickerSymbolFor(_selectedCurrency),
                style: AppTypography.h1.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _displayAmount,
                style: AppTypography.amountInput(
                  isBtc: _selectedCurrency == Currency.btc,
                  color: Theme.of(context).colorScheme.onPrimary,
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
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }

  Widget _buildFiatReferenceLine({required double amountBtc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'Equivale a ${MoneyDisplay.format(amount: amountBtc, currency: Currency.btc)}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    _WithdrawDestinationAnalysis destination,
  ) {
    final accent = _destinationValidationColor(context, destination);
    final isEmpty = destination.type == _WithdrawDestinationType.empty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppCopy.withdrawDestinationLabel.resolve(context),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pasteDestination,
                icon: const Icon(LucideIcons.clipboard, size: 15),
                label: Text(
                  AppCopy.withdrawDestinationPaste.resolve(context),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          GlassContainer(
            enableBlur: false,
            blur: 18,
            opacity: 0.02,
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent),
            child: TextField(
              controller: _addressController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              minLines: 1,
              maxLines: 1,
              cursorColor: accent,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
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
                  color:
                      isEmpty ? Colors.white.withValues(alpha: 0.34) : accent,
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
                      color: Colors.white.withValues(alpha: 0.28),
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
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppCopy.withdrawDescriptionLabel.resolve(context),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.60),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
            decoration: InputDecoration(
              hintText: context.l10n.withdrawDescHint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.34),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    final quoteColor = Colors.white.withValues(alpha: 0.72);

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.withdrawFeeSection,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.60),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (feeQuote.isLoading) const LinearProgressIndicator(minHeight: 4),
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
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: AppSpacing.md),
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
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                'Nao foi possivel estimar a taxa de rede no momento. Revise novamente em instantes antes de confirmar o envio.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      height: 1.45,
                    ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                !hasAmount
                    ? 'Digite um valor para calcular o custo total antes de confirmar.'
                    : feeQuote.usesMaximumRoutingFee
                        ? 'A taxa da plataforma usa o cartão ${wallet.cardType.label}. O roteamento acima é o teto reservado para o pagamento Lightning.'
                        : 'A taxa da plataforma usa o cartão ${wallet.cardType.label}. A taxa de rede usa a estimativa padrão atual da mempool.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final isBackspace = key == '←';
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(isBackspace ? key : key),
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: isBackspace
                ? Icon(
                    LucideIcons.delete,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 18,
                  )
                : Text(
                    key,
                    style: AppTypography.number.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
          ),
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
    final textColor = emphasize
        ? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.72);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w600,
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
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              fontFamily: monospace ? 'JetBrainsMono' : null,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
