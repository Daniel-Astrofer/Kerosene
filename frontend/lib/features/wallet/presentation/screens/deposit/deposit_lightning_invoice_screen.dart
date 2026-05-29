import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/api_display_text.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/transactions/domain/entities/external_transfer.dart';
import 'package:kerosene/features/transactions/domain/entities/lightning_invoice.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:uuid/uuid.dart';

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
  ConsumerState<DepositLightningInvoiceScreen> createState() =>
      _DepositLightningInvoiceScreenState();
}

class _DepositLightningInvoiceScreenState
    extends ConsumerState<DepositLightningInvoiceScreen> {
  Timer? _timer;
  Timer? _statusTimer;
  LightningInvoice? _invoice;
  ExternalTransfer? _observedTransfer;
  String? _errorMessage;
  bool _isLoadingInvoice = true;
  bool _isCancelling = false;
  bool _requestTriggered = false;
  final String _invoiceIdempotencyKey = const Uuid().v4();
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadInvoice);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String _copy({required String pt, required String en, required String es}) {
    return switch (context.tr.localeName) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
  }

  Future<void> _loadInvoice() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;

    try {
      final walletProfile = await ref
          .read(transactionRepositoryProvider)
          .getWalletNetworkProfile(walletName: widget.wallet.name);
      if (!mounted) {
        return;
      }
      if (!walletProfile.lightningEnabled) {
        final message = walletProfile.lightningUnavailableReason.trim().isEmpty
            ? _copy(
                pt: 'Lightning não está disponível para esta carteira no momento.',
                en: 'Lightning is not available for this wallet right now.',
                es: 'Lightning no está disponible para esta billetera en este momento.',
              )
            : ApiDisplayText.message(
                context,
                walletProfile.lightningUnavailableReason,
              );
        setState(() {
          _isLoadingInvoice = false;
          _errorMessage = message;
        });
        SnackbarHelper.showWarning(
          message,
          title: _copy(
            pt: 'Lightning indisponível',
            en: 'Lightning unavailable',
            es: 'Lightning no disponible',
          ),
        );
        return;
      }

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
                idempotencyKey: _invoiceIdempotencyKey,
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
      await _refreshObservedTransfer(showNotice: false);
      _startObservedTransferPolling();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated = ErrorTranslator.translate(
        context.tr,
        error.toString(),
      );
      setState(() {
        _isLoadingInvoice = false;
        _errorMessage = translated;
      });
      SnackbarHelper.showError(
        translated,
        title: _copy(
          pt: 'Depósito Lightning',
          en: 'Lightning deposit',
          es: 'Depósito Lightning',
        ),
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

  void _startObservedTransferPolling() {
    final transferId = _invoice?.transferId.trim() ?? '';
    if (transferId.isEmpty) {
      return;
    }
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshObservedTransfer();
    });
  }

  Future<void> _refreshObservedTransfer({bool showNotice = true}) async {
    final transferId = _invoice?.transferId.trim() ?? '';
    if (transferId.isEmpty) {
      return;
    }

    try {
      final latest = await ref
          .read(transactionRepositoryProvider)
          .getExternalTransfer(transferId);
      if (!mounted) {
        return;
      }

      final previousStatus =
          (_observedTransfer?.status ?? _invoice?.status ?? 'PENDING')
              .trim()
              .toUpperCase();
      setState(() {
        _observedTransfer = latest;
      });

      if (previousStatus != latest.status.trim().toUpperCase()) {
        ref.invalidate(externalTransfersProvider);
        ref.invalidate(transactionHistoryProvider);
      }

      if (showNotice) {
        _showTransferStatusNotice(
          previousStatus: previousStatus,
          latest: latest,
        );
      }

      if (_isTransferFinal(latest.status)) {
        _statusTimer?.cancel();
      }
    } catch (_) {
      // Keep the payment code visible even if a refresh fails briefly.
    }
  }

  void _showTransferStatusNotice({
    required String previousStatus,
    required ExternalTransfer latest,
  }) {
    final normalized = latest.status.trim().toUpperCase();
    if ((normalized == 'COMPLETED' ||
            normalized == 'SETTLED' ||
            normalized == 'PAID') &&
        previousStatus != normalized) {
      SnackbarHelper.showSuccess(
        _copy(
          pt: 'Pagamento Lightning confirmado.',
          en: 'Lightning payment confirmed.',
          es: 'Pago Lightning confirmado.',
        ),
        title: _copy(
          pt: 'Pagamento confirmado',
          en: 'Payment confirmed',
          es: 'Pago confirmado',
        ),
      );
      return;
    }
    if ((normalized == 'EXPIRED' || normalized == 'CANCELLED') &&
        previousStatus != normalized) {
      SnackbarHelper.showInfo(
        normalized == 'CANCELLED'
            ? _copy(
                pt: 'O pedido Lightning foi cancelado.',
                en: 'The Lightning request was cancelled.',
                es: 'El pedido Lightning fue cancelado.',
              )
            : _copy(
                pt: 'O pedido Lightning expirou sem pagamento.',
                en: 'The Lightning request expired without payment.',
                es: 'El pedido Lightning expiró sin pago.',
              ),
        title: _copy(
          pt: 'Pedido encerrado',
          en: 'Request closed',
          es: 'Pedido cerrado',
        ),
      );
    }
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
      SnackbarHelper.showError(
        _copy(
          pt: 'Código Lightning indisponível.',
          en: 'Lightning code unavailable.',
          es: 'Código Lightning no disponible.',
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: paymentRequest));
    SnackbarHelper.showSuccess(
      _copy(
        pt: 'Código Lightning copiado.',
        en: 'Lightning code copied.',
        es: 'Código Lightning copiado.',
      ),
    );
  }

  bool _isTransferFinal(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'COMPLETED' ||
        normalized == 'SETTLED' ||
        normalized == 'PAID' ||
        normalized == 'FAILED' ||
        normalized == 'CANCELLED' ||
        normalized == 'EXPIRED';
  }

  bool get _canCancelInvoice {
    if (_isCancelling) {
      return false;
    }
    final transferId = _invoice?.transferId.trim() ?? '';
    if (transferId.isEmpty || _observedTransfer == null) {
      return false;
    }
    return _observedTransfer!.status.trim().toUpperCase() == 'PENDING';
  }

  String get _statusLabel {
    final normalized =
        (_observedTransfer?.status ?? _invoice?.status ?? 'PENDING')
            .trim()
            .toUpperCase();
    return ApiDisplayText.status(context, normalized);
  }

  String get _statusDescription {
    final normalized =
        (_observedTransfer?.status ?? _invoice?.status ?? 'PENDING')
            .trim()
            .toUpperCase();
    return switch (normalized) {
      'COMPLETED' || 'SETTLED' || 'PAID' => _copy(
          pt: 'O pagamento Lightning foi confirmado.',
          en: 'The Lightning payment was confirmed.',
          es: 'El pago Lightning fue confirmado.',
        ),
      'CANCELLED' => _copy(
          pt: 'Este pedido foi cancelado e não aceita mais pagamento.',
          en: 'This request was cancelled and no longer accepts payment.',
          es: 'Este pedido fue cancelado y ya no acepta pago.',
        ),
      'EXPIRED' => _copy(
          pt: 'A janela de pagamento expirou. Gere um novo pedido para continuar.',
          en: 'The payment window expired. Create a new request to continue.',
          es: 'La ventana de pago expiró. Crea un nuevo pedido para continuar.',
        ),
      'FAILED' => _copy(
          pt: 'Não foi possível concluir este pagamento Lightning. Gere um novo pedido para tentar novamente.',
          en: 'We could not complete this Lightning payment. Create a new request and try again.',
          es: 'No pudimos completar este pago Lightning. Crea un nuevo pedido e inténtalo otra vez.',
        ),
      _ => _copy(
          pt: 'Aguardando pagamento Lightning. Esta tela será atualizada automaticamente.',
          en: 'Waiting for the Lightning payment. This screen updates automatically.',
          es: 'Esperando el pago Lightning. Esta pantalla se actualiza automáticamente.',
        ),
    };
  }

  Future<void> _cancelInvoice() async {
    final transferId = _invoice?.transferId.trim() ?? '';
    if (transferId.isEmpty || !_canCancelInvoice) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              _copy(
                pt: 'Cancelar depósito',
                en: 'Cancel deposit',
                es: 'Cancelar depósito',
              ),
            ),
            content: Text(
              _copy(
                pt: 'Este recebimento será ocultado/cancelado na Kerosene. Se alguém já enviou BTC para o endereço, a rede Bitcoin ainda pode confirmar a transação.',
                en: 'This receive request will be hidden/cancelled in Kerosene. If someone already sent BTC to the address, the Bitcoin network can still confirm the transaction.',
                es: 'Este recibimiento se ocultará/cancelará en Kerosene. Si alguien ya envió BTC a la dirección, la red Bitcoin aún puede confirmar la transacción.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr.depositLedgerBackAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  _copy(
                    pt: 'Cancelar depósito',
                    en: 'Cancel deposit',
                    es: 'Cancelar depósito',
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isCancelling = true);
    try {
      final cancelled = await ref
          .read(transactionRepositoryProvider)
          .cancelInboundTransfer(transferId);
      if (!mounted) {
        return;
      }
      _statusTimer?.cancel();
      setState(() {
        _observedTransfer = cancelled;
      });
      ref.invalidate(externalTransfersProvider);
      ref.invalidate(transactionHistoryProvider);
      SnackbarHelper.showSuccess(
        _copy(
          pt: 'Depósito cancelado.',
          en: 'Deposit cancelled.',
          es: 'Depósito cancelado.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated = ErrorTranslator.translate(
        context.tr,
        error.toString(),
      );
      SnackbarHelper.showError(translated);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    if (btcUsd == null && btcBrl == null) {
      return ReceiveFlowScaffold(
        title: _copy(
          pt: 'Depósito Lightning',
          en: 'Lightning deposit',
          es: 'Depósito Lightning',
        ),
        subtitle: _copy(
          pt: 'Preparando seu pedido de recebimento.',
          en: 'Preparing your payment request.',
          es: 'Preparando tu pedido de recepción.',
        ),
        child: ReceiveFlowStatePanel(
          icon: LucideIcons.loader2,
          title: context.tr.depositLightningLoading,
          message: _copy(
            pt: 'Buscando a cotação atual antes de criar o pedido.',
            en: 'Checking the current quote before creating the request.',
            es: 'Consultando la cotización actual antes de crear el pedido.',
          ),
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
      title: _copy(
        pt: 'Depósito Lightning',
        en: 'Lightning deposit',
        es: 'Depósito Lightning',
      ),
      subtitle: _copy(
        pt: 'Copie o código Lightning e acompanhe a confirmação.',
        en: 'Copy the Lightning code and follow confirmation.',
        es: 'Copia el código Lightning y sigue la confirmación.',
      ),
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
              _buildStatusCard(),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(invoice, receiveBtc, sats, quoteLabel),
              const SizedBox(height: AppSpacing.md),
              _buildInvoiceField(invoice),
              const SizedBox(height: AppSpacing.md),
              ReceiveFlowPrimaryButton(
                label: _copy(
                  pt: 'Copiar código',
                  en: 'Copy code',
                  es: 'Copiar código',
                ),
                icon: LucideIcons.copy,
                onTap: _copyInvoice,
              ),
              if (_canCancelInvoice) ...[
                const SizedBox(height: AppSpacing.sm),
                ReceiveFlowSecondaryButton(
                  label: _isCancelling
                      ? _copy(
                          pt: 'Cancelando...',
                          en: 'Cancelling...',
                          es: 'Cancelando...',
                        )
                      : _copy(
                          pt: 'Cancelar depósito',
                          en: 'Cancel deposit',
                          es: 'Cancelar depósito',
                        ),
                  icon: LucideIcons.xCircle,
                  onTap: _isCancelling ? null : _cancelInvoice,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                _copy(
                  pt: 'O pedido expira automaticamente. Se vencer, gere um novo.',
                  en: 'The request expires automatically. If it expires, create a new one.',
                  es: 'El pedido expira automáticamente. Si vence, crea uno nuevo.',
                ),
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
    return ReceiveFlowStatePanel(
      icon: LucideIcons.zap,
      title: _copy(
        pt: 'Criando pedido Lightning',
        en: 'Creating Lightning request',
        es: 'Creando pedido Lightning',
      ),
      message: _copy(
        pt: 'Estamos preparando um código exclusivo para este depósito.',
        en: 'We are preparing a unique code for this deposit.',
        es: 'Estamos preparando un código único para este depósito.',
      ),
    );
  }

  Widget _buildErrorState() {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.alertTriangle,
      title: _copy(
        pt: 'Não foi possível criar o pedido',
        en: 'Could not create the request',
        es: 'No se pudo crear el pedido',
      ),
      message: _errorMessage ?? context.tr.errUnexpected,
      footer: ReceiveFlowSecondaryButton(
        label: context.tr.tryAgain,
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
          ReceiveFlowSectionLabel(
            _copy(
              pt: 'Total a receber',
              en: 'Total to receive',
              es: 'Total a recibir',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(
              amount: requestedAmount,
              currency: widget.inputCurrency,
            ),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: receiveFlowTextColor,
                  fontSize: 36,
                  fontFamily: AppTypography.numericFontFamily,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(amount: receiveBtc, currency: Currency.btc),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontFamily: AppTypography.numericFontFamily,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    if (_isTransferFinal(_observedTransfer?.status ?? _invoice?.status ?? '')) {
      return ReceiveFlowPanel(
        child: Column(
          children: [
            ReceiveFlowSectionLabel(
              _copy(
                pt: 'Estado atual',
                en: 'Current status',
                es: 'Estado actual',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _statusLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: receiveFlowTextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }
    return ReceiveFlowPanel(
      child: Column(
        children: [
          ReceiveFlowSectionLabel(
            _copy(pt: 'Expira em', en: 'Expires in', es: 'Expira en'),
          ),
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
              fontFamily: AppTypography.numericFontFamily,
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
    return ReceiveFlowPanel(
      child: Column(
        children: [
          if (quoteLabel != null) ...[
            ReceiveFlowMetricRow(
              label: _copy(
                pt: 'Cotação BTC',
                en: 'BTC quote',
                es: 'Cotización BTC',
              ),
              value: quoteLabel,
            ),
            const ReceiveFlowDivider(),
          ],
          ReceiveFlowMetricRow(
            label: context.tr.depositLightningGoesTo,
            value: invoice.walletName,
          ),
          if (invoice.lightningAddress.isNotEmpty) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: _copy(
                pt: 'Endereço Lightning',
                en: 'Lightning address',
                es: 'Dirección Lightning',
              ),
              value: invoice.lightningAddress,
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: _copy(
              pt: 'Valor esperado',
              en: 'Expected amount',
              es: 'Valor esperado',
            ),
            value: MoneyDisplay.format(
              amount: receiveBtc,
              currency: Currency.btc,
            ),
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Sats', value: '$sats'),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final transfer = _observedTransfer;
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(
            _copy(
              pt: 'Acompanhamento do pagamento',
              en: 'Payment tracking',
              es: 'Seguimiento del pago',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowMetricRow(label: context.tr.status, value: _statusLabel),
          if (transfer?.detectedAt != null) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: _copy(
                pt: 'Detectado em',
                en: 'Detected at',
                es: 'Detectado en',
              ),
              value: _formatTimestamp(transfer!.detectedAt!),
            ),
          ],
          if (transfer?.settledAt != null) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: _copy(
                pt: 'Confirmado em',
                en: 'Confirmed at',
                es: 'Confirmado en',
              ),
              value: _formatTimestamp(transfer!.settledAt!),
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.tr.depositLightningSummary,
            value: _statusDescription,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInvoiceField(LightningInvoice invoice) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(
            _copy(
              pt: 'Código Lightning',
              en: 'Lightning code',
              es: 'Código Lightning',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            invoice.paymentRequest,
            style: AppTypography.technicalMono(
              textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
