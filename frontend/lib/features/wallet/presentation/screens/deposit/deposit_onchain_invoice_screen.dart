import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

class DepositOnchainInvoiceScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final double inputAmount;
  final Currency inputCurrency;
  final String providerName;

  const DepositOnchainInvoiceScreen({
    super.key,
    required this.wallet,
    required this.inputAmount,
    required this.inputCurrency,
    required this.providerName,
  });

  @override
  ConsumerState<DepositOnchainInvoiceScreen> createState() =>
      _DepositOnchainInvoiceScreenState();
}

class _DepositOnchainInvoiceScreenState
    extends ConsumerState<DepositOnchainInvoiceScreen> {
  String _depositAddress = '';
  String? _errorMessage;
  bool _isLoadingAddress = true;
  bool _requestTriggered = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadOnchainDepositAddress);
  }

  Future<void> _loadOnchainDepositAddress() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;

    setState(() {
      _isLoadingAddress = true;
      _errorMessage = null;
    });

    try {
      final result =
          await ref.read(transactionRepositoryProvider).getDepositAddress();

      if (!mounted) {
        return;
      }

      result.fold(
        (failure) {
          setState(() {
            _isLoadingAddress = false;
            _errorMessage = failure.message;
            _depositAddress = '';
          });
          SnackbarHelper.showError(
            failure.message,
            title: 'Depósito on-chain',
          );
        },
        (address) {
          final normalized = address.trim();
          if (normalized.isEmpty) {
            const message = 'Endereço de depósito não retornado pelo backend.';
            setState(() {
              _isLoadingAddress = false;
              _errorMessage = message;
              _depositAddress = '';
            });
            SnackbarHelper.showError(
              message,
              title: 'Depósito on-chain',
            );
            return;
          }

          setState(() {
            _depositAddress = normalized;
            _isLoadingAddress = false;
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingAddress = false;
        _errorMessage = error.toString();
      });
      SnackbarHelper.showError(
        error.toString(),
        title: 'Depósito on-chain',
      );
    }
  }

  void _copyAddress(String address) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: address));
    SnackbarHelper.showSuccess('Endereço copiado!');
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    if (btcUsd == null && btcBrl == null) {
      return const ReceiveFlowScaffold(
        title: 'Depósito on-chain',
        subtitle: 'Preparando dados do endereço.',
        child: ReceiveFlowStatePanel(
          icon: LucideIcons.loader2,
          title: 'Carregando',
          message: 'Buscando cotação para preparar o depósito on-chain.',
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
    final quoteLabel = MoneyDisplay.formatQuoteValue(
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowScaffold(
      title: 'Depósito on-chain',
      subtitle: 'Mesmo design do fluxo, com QR e endereço Bitcoin.',
      child: Builder(
        builder: (context) {
          if (_isLoadingAddress) {
            return _buildAddressLoading();
          }

          if (_errorMessage != null) {
            return _buildAddressError();
          }

          final address = _depositAddress;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainCard(widget.inputAmount),
              const SizedBox(height: AppSpacing.sm),
              _buildAwaitConfirmationBanner(),
              const SizedBox(height: AppSpacing.md),
              _buildQrCodeSection(address),
              const SizedBox(height: AppSpacing.sm),
              _buildAddressPill(address),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(
                receiveBtc,
                quoteLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSecurityFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressLoading() {
    return const ReceiveFlowStatePanel(
      icon: LucideIcons.network,
      title: 'Obtendo endereço',
      message:
          'Após o pagamento na rede Bitcoin, o saldo será refletido quando as confirmações chegarem.',
    );
  }

  Widget _buildAddressError() {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.alertTriangle,
      title: 'Não foi possível preparar o depósito',
      message: _errorMessage ?? 'Erro desconhecido',
      footer: ReceiveFlowSecondaryButton(
        label: 'Tentar novamente',
        icon: LucideIcons.refreshCw,
        onTap: () {
          _requestTriggered = false;
          _loadOnchainDepositAddress();
        },
      ),
    );
  }

  Widget _buildMainCard(double totalRequested) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        children: [
          const ReceiveFlowSectionLabel('Total a depositar'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(
              amount: totalRequested,
              currency: widget.inputCurrency,
            ),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: receiveFlowTextColor,
                  fontSize: 32,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowTag(label: 'Via ${widget.providerName}'),
        ],
      ),
    );
  }

  Widget _buildAwaitConfirmationBanner() {
    return ReceiveFlowPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: const Icon(
              LucideIcons.clock3,
              color: receiveFlowTextColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Envie BTC para o endereço abaixo. O histórico e o saldo serão atualizados após 3 confirmações na rede.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String address) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          const ReceiveFlowSectionLabel('Endereço BTC'),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
            ),
            child: QrImageView(
              data: 'bitcoin:$address',
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPill(String address) {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              address,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontFamily: 'JetBrainsMono',
                  ),
            ),
          ),
          const SizedBox(width: 8),
          ReceiveFlowSecondaryButton(
            label: 'Copiar',
            icon: LucideIcons.copy,
            fullWidth: false,
            onTap: () => _copyAddress(address),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBlock(
    double receiveBtc,
    String? quoteLabel,
  ) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          if (quoteLabel != null) ...[
            ReceiveFlowMetricRow(label: 'Cotação BTC', value: quoteLabel),
            const ReceiveFlowDivider(),
          ],
          ReceiveFlowMetricRow(
              label: 'Carteira de destino', value: widget.wallet.name),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Provider', value: widget.providerName),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Crédito esperado',
            value:
                MoneyDisplay.format(amount: receiveBtc, currency: Currency.btc),
            mono: true,
          ),
          const ReceiveFlowDivider(),
          const ReceiveFlowMetricRow(
              label: 'Confirmações mínimas', value: '3 blocos'),
          const ReceiveFlowDivider(),
          const ReceiveFlowMetricRow(
            label: 'Origem do endereço',
            value: 'Sistema mestre',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return ReceiveFlowPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: receiveFlowTextColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'O endereço foi carregado do backend autenticado. O saldo aparece no histórico quando a rede confirmar o depósito.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
