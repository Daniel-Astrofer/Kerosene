import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/security/domain/entities/security_status.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/external_transfer.dart';
import 'package:teste/features/transactions/domain/entities/lightning_invoice.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

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

  Future<void> _loadInvoice() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;

    try {
      final walletProfile =
          await ref.read(transactionRepositoryProvider).getWalletNetworkProfile(
                walletName: widget.wallet.name,
              );
      if (!walletProfile.lightningEnabled) {
        final message =
            walletProfile.lightningUnavailableReason.trim().isNotEmpty
                ? walletProfile.lightningUnavailableReason.trim()
                : 'Lightning indisponível neste ambiente.';
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingInvoice = false;
          _errorMessage = message;
        });
        SnackbarHelper.showWarning(
          message,
          title: 'Lightning indisponível',
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
      final translated =
          ErrorTranslator.translate(context.l10n, error.toString());
      setState(() {
        _isLoadingInvoice = false;
        _errorMessage = translated;
      });
      SnackbarHelper.showError(
        translated,
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
            previousStatus: previousStatus, latest: latest);
      }

      if (_isTransferFinal(latest.status)) {
        _statusTimer?.cancel();
      }
    } catch (_) {
      // Keep the invoice visible even if polling fails transiently.
    }
  }

  void _showTransferStatusNotice({
    required String previousStatus,
    required ExternalTransfer latest,
  }) {
    final normalized = latest.status.trim().toUpperCase();
    if ((normalized == 'COMPLETED' || normalized == 'SETTLED') &&
        previousStatus != normalized) {
      SnackbarHelper.showSuccess(
        'Invoice Lightning paga e reconciliada.',
        title: 'Pagamento confirmado',
      );
      return;
    }
    if ((normalized == 'EXPIRED' || normalized == 'CANCELLED') &&
        previousStatus != normalized) {
      SnackbarHelper.showInfo(
        normalized == 'CANCELLED'
            ? 'A invoice foi cancelada.'
            : 'A invoice expirou sem pagamento.',
        title: 'Invoice encerrada',
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
      SnackbarHelper.showError('Invoice Lightning indisponível.');
      return;
    }

    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: paymentRequest));
    SnackbarHelper.showSuccess('Invoice copiada com segurança!');
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
    return false;
  }

  String get _statusLabel {
    final normalized =
        (_observedTransfer?.status ?? _invoice?.status ?? 'PENDING')
            .trim()
            .toUpperCase();
    return switch (normalized) {
      'COMPLETED' || 'SETTLED' || 'PAID' => 'Pago',
      'CANCELLED' => 'Cancelado',
      'EXPIRED' => 'Expirado',
      'FAILED' => 'Falhou',
      _ => 'Aguardando pagamento',
    };
  }

  String get _statusDescription {
    final normalized =
        (_observedTransfer?.status ?? _invoice?.status ?? 'PENDING')
            .trim()
            .toUpperCase();
    return switch (normalized) {
      'COMPLETED' ||
      'SETTLED' ||
      'PAID' =>
        'O pagamento Lightning foi confirmado pelo backend e já pode ser reconciliado no histórico.',
      'CANCELLED' => 'Esta invoice foi cancelada e não aceita mais liquidação.',
      'EXPIRED' =>
        'A janela de pagamento expirou. Gere uma nova invoice para continuar.',
      'FAILED' => 'A rota Lightning falhou na liquidação desta invoice.',
      _ =>
        'Invoice BOLT11 emitida. O backend acompanha o estado do pagamento em tempo real.',
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
            title: const Text('Cancelar depósito'),
            content: const Text(
              'A invoice será invalidada. Se o pagamento já tiver sido detectado, o backend recusará o cancelamento.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancelar depósito'),
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
      SnackbarHelper.showSuccess('Depósito cancelado');
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated =
          ErrorTranslator.translate(context.l10n, error.toString());
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
    final sovereigntyAsync = ref.watch(sovereigntyStatusProvider);

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
              _buildStatusCard(invoice),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(
                invoice,
                receiveBtc,
                sats,
                quoteLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildOperationalRouteCard(sovereigntyAsync, invoice),
              const SizedBox(height: AppSpacing.md),
              _buildInvoiceField(invoice),
              const SizedBox(height: AppSpacing.md),
              ReceiveFlowPrimaryButton(
                label: 'Copiar invoice',
                icon: LucideIcons.copy,
                onTap: _copyInvoice,
              ),
              if (_canCancelInvoice) ...[
                const SizedBox(height: AppSpacing.sm),
                ReceiveFlowSecondaryButton(
                  label: _isCancelling ? 'Cancelando...' : 'Cancelar depósito',
                  icon: LucideIcons.xCircle,
                  onTap: _isCancelling ? null : _cancelInvoice,
                ),
              ],
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
            const ReceiveFlowSectionLabel('Estado atual'),
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
            value: invoice.lightningAddress.isNotEmpty
                ? invoice.lightningAddress
                : 'Invoice BOLT11',
            mono: true,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Payment hash',
            value: invoice.paymentHash,
            mono: true,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Nó Lightning', value: providerLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Crédito esperado',
            value: MoneyDisplay.format(
              amount: receiveBtc,
              currency: Currency.btc,
            ),
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Satoshis', value: '$sats SATS'),
        ],
      ),
    );
  }

  Widget _buildStatusCard(LightningInvoice invoice) {
    final transfer = _observedTransfer;
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReceiveFlowSectionLabel('Evento observado'),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowMetricRow(label: 'Status', value: _statusLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Transfer ID',
            value: invoice.transferId,
            mono: true,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Payment hash',
            value: transfer?.paymentHash.trim().isNotEmpty == true
                ? transfer!.paymentHash
                : invoice.paymentHash,
            mono: true,
          ),
          if (transfer?.detectedAt != null) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: 'Detectado em',
              value: _formatTimestamp(transfer!.detectedAt!),
            ),
          ],
          if (transfer?.settledAt != null) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: 'Liquidado em',
              value: _formatTimestamp(transfer!.settledAt!),
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Resumo',
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

  Widget _buildOperationalRouteCard(
    AsyncValue<SecurityStatus> sovereigntyAsync,
    LightningInvoice invoice,
  ) {
    final providerLabel =
        invoice.provider.isNotEmpty ? invoice.provider : widget.providerName;

    return ReceiveFlowPanel(
      child: sovereigntyAsync.when(
        loading: () => _LightningOperationalRouteBody(
          title: 'Rota operacional',
          subtitle:
              'Consultando o estado do quórum para validar a rota Lightning.',
          rows: [
            _LightningOperationalRouteRow(
              label: 'Liquidação',
              value: 'Lightning via nó $providerLabel',
            ),
          ],
        ),
        error: (_, __) => _LightningOperationalRouteBody(
          title: 'Rota operacional',
          subtitle:
              'A invoice permanece válida, mas a leitura do quórum não respondeu nesta tentativa.',
          rows: [
            _LightningOperationalRouteRow(
              label: 'Liquidação',
              value: 'Lightning via nó $providerLabel',
            ),
          ],
        ),
        data: (status) {
          final consensus = status.networkConsensus;
          final activeNodes = (consensus['activeNodes'] as num?)?.toInt() ?? 0;
          final totalNodes = (consensus['totalNodes'] as num?)?.toInt() ?? 0;
          final requiredNodes =
              (consensus['requiredNodes'] as num?)?.toInt() ?? 0;
          final failStop = consensus['failStopMode'] == true;

          return _LightningOperationalRouteBody(
            title: 'Rota operacional',
            subtitle: failStop
                ? 'A malha entrou em fail-stop. Entradas Lightning seguem observáveis, mas a liquidação operacional deve ser tratada com cautela.'
                : 'Invoice emitida pelo backend e acompanhada pela mesma malha de quórum que protege a liquidação operacional.',
            rows: [
              _LightningOperationalRouteRow(
                label: 'Liquidação',
                value: 'Lightning via nó $providerLabel',
              ),
              _LightningOperationalRouteRow(
                label: 'Quórum',
                value:
                    '$activeNodes/$totalNodes ativos • mínimo $requiredNodes',
              ),
              _LightningOperationalRouteRow(
                label: 'Fail-stop',
                value: failStop ? 'Ativo' : 'Inativo',
              ),
            ],
          );
        },
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

class _LightningOperationalRouteBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_LightningOperationalRouteRow> rows;

  const _LightningOperationalRouteBody({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiveFlowSectionLabel(title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: receiveFlowMutedTextColor,
                height: 1.35,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (int index = 0; index < rows.length; index++) ...[
          ReceiveFlowMetricRow(
            label: rows[index].label,
            value: rows[index].value,
          ),
          if (index != rows.length - 1) const ReceiveFlowDivider(),
        ],
      ],
    );
  }
}

class _LightningOperationalRouteRow {
  final String label;
  final String value;

  const _LightningOperationalRouteRow({
    required this.label,
    required this.value,
  });
}
