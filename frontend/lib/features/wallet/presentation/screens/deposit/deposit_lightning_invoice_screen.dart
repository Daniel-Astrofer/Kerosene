import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/domain/entities/lightning_invoice.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

class DepositLightningInvoiceScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final double inputAmount;
  final Currency inputCurrency;
  final String providerName;

  const DepositLightningInvoiceScreen({
    super.key,
    required this.wallet,
    required this.inputAmount,
    required this.inputCurrency,
    required this.providerName,
  });

  @override
  ConsumerState<DepositLightningInvoiceScreen> createState() => _DepositLightningInvoiceScreenState();
}

class _DepositLightningInvoiceScreenState extends ConsumerState<DepositLightningInvoiceScreen> {
  Timer? _timer;
  LightningInvoice? _invoice;
  String? _errorMessage;
  bool _isLoadingInvoice = true;
  bool _requestTriggered = false;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadInvoice);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvoice() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;

    try {
      final btcUsd = ref.read(latestBtcPriceProvider);
      final btcEur = ref.read(btcEurPriceProvider);
      final btcBrl = ref.read(btcBrlPriceProvider);
      final amountBtc = MoneyDisplay.convertToBtcAmount(
        amount: widget.inputAmount,
        currency: widget.inputCurrency,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      );

      final invoice =
          await ref.read(transactionRepositoryProvider).createLightningInvoice(
                walletName: widget.wallet.name,
                amount: amountBtc,
                memo: 'Deposito Lightning ${widget.wallet.name}',
                expiresInSeconds: 900,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        _invoice = invoice;
        _isLoadingInvoice = false;
      });
      _syncRemaining();
      _startTimer();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingInvoice = false;
        _errorMessage = error.toString();
      });
      SnackbarHelper.showError(
        error.toString(),
        title: 'Invoice Lightning',
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      _syncRemaining();
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
      }
    });
  }

  void _syncRemaining() {
    final invoice = _invoice;
    if (invoice == null) {
      return;
    }
    setState(() {
      _secondsRemaining = invoice.remaining.inSeconds;
    });
  }

  String get _formattedMinutes =>
      (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
  String get _formattedSeconds =>
      (_secondsRemaining % 60).toString().padLeft(2, '0');

  void _copyInvoice() {
    final paymentRequest = _invoice?.paymentRequest.trim() ?? '';
    if (paymentRequest.isEmpty) {
      SnackbarHelper.showError('Invoice Lightning indisponível.');
      return;
    }

    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: paymentRequest));
    SnackbarHelper.showSuccess('Invoice copiada com segurança!');
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    if (btcUsd == null && btcBrl == null) {
      return const ReceiveFlowScaffold(
        title: 'Depósito Lightning',
        subtitle: 'Preparando cotação e invoice.',
        child: ReceiveFlowStatePanel(
          icon: LucideIcons.loader2,
          title: 'Carregando',
          message: 'Buscando cotação para preparar a invoice.',
        ),
      );
    }

    final receiveBtc = MoneyDisplay.convertToBtcAmount(
      amount: widget.inputAmount,
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final sats = (receiveBtc * 100000000).round();
    final quoteLabel = MoneyDisplay.formatQuoteValue(
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowScaffold(
      title: 'Depósito Lightning',
      subtitle: 'Mesmo visual compacto, com campos específicos de invoice.',
      child: Builder(
        builder: (context) {
          if (_isLoadingInvoice) {
            return _buildLoadingState();
          }

          if (_errorMessage != null) {
            return _buildErrorState();
          }

          final invoice = _invoice;
          if (invoice == null) {
            return _buildErrorState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainCard(widget.inputAmount, receiveBtc),
              const SizedBox(height: AppSpacing.md),
              _buildTimerWidget(),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(
                invoice,
                receiveBtc,
                sats,
                quoteLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInvoiceField(invoice),
              const SizedBox(height: AppSpacing.md),
              ReceiveFlowPrimaryButton(
                label: 'Copiar invoice',
                icon: LucideIcons.copy,
                onTap: _copyInvoice,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A invoice expira automaticamente. Se ela vencer, gere uma nova.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: receiveFlowFaintTextColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ReceiveFlowStatePanel(
      icon: LucideIcons.zap,
      title: 'Emitindo invoice',
      message: 'O backend está gerando um BOLT11 vinculado a esta carteira.',
    );
  }

  Widget _buildErrorState() {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.alertTriangle,
      title: 'Não foi possível gerar a invoice',
      message: _errorMessage ?? 'Erro desconhecido',
      footer: ReceiveFlowSecondaryButton(
        label: 'Tentar novamente',
        icon: LucideIcons.refreshCw,
        onTap: () {
          _requestTriggered = false;
          setState(() {
            _isLoadingInvoice = true;
            _errorMessage = null;
          });
          _loadInvoice();
        },
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildMainCard(double requestedAmount, double receiveBtc) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        children: [
          const ReceiveFlowSectionLabel('Total da invoice'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(
              amount: requestedAmount,
              currency: widget.inputCurrency,
            ),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: receiveFlowTextColor,
                  fontSize: 36,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(amount: receiveBtc, currency: Currency.btc),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontFamily: 'JetBrainsMono',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          const ReceiveFlowSectionLabel('Expira em'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerBlock(_formattedMinutes),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  ':',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: receiveFlowMutedTextColor,
                      ),
                ),
              ),
              _buildTimerBlock(_formattedSeconds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBlock(String value) {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: receiveFlowTextColor,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildDetailsBlock(
    LightningInvoice invoice,
    double receiveBtc,
    int sats,
    String? quoteLabel,
  ) {
    final providerLabel =
        invoice.provider.isNotEmpty ? invoice.provider : widget.providerName;

    return ReceiveFlowPanel(
      child: Column(
        children: [
          if (quoteLabel != null) ...[
            ReceiveFlowMetricRow(label: 'Cotação ao vivo', value: quoteLabel),
            const ReceiveFlowDivider(),
          ],
          ReceiveFlowMetricRow(
              label: 'Carteira destino', value: invoice.walletName),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Lightning Address',
            value: invoice.lightningAddress,
            mono: true,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Provider', value: providerLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Crédito esperado',
            value: MoneyDisplay.format(
              amount: receiveBtc,
              currency: Currency.btc,
            ),
            mono: true,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
              label: 'Satoshis', value: '$sats SATS', mono: true),
        ],
      ),
    );
  }

  Widget _buildInvoiceField(LightningInvoice invoice) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReceiveFlowSectionLabel('Invoice BOLT11'),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            invoice.paymentRequest,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowTextColor,
                  fontFamily: 'JetBrainsMono',
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
