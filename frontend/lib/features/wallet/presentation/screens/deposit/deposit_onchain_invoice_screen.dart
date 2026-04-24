import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/security/domain/entities/security_status.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/domain/entities/external_transfer.dart';
import 'package:teste/features/transactions/domain/entities/onchain_address_allocation.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

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
  Timer? _statusTimer;
  OnchainAddressAllocation? _allocation;
  ExternalTransfer? _observedTransfer;
  String _depositAddress = '';
  String? _errorMessage;
  bool _isLoadingAddress = true;
  bool _isCancelling = false;
  bool _requestTriggered = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadOnchainDepositAddress);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnchainDepositAddress() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;
    _statusTimer?.cancel();

    setState(() {
      _isLoadingAddress = true;
      _errorMessage = null;
      _allocation = null;
      _observedTransfer = null;
    });

    try {
      final allocation =
          await ref.read(transactionRepositoryProvider).issueOnchainAddress(
                walletName: widget.wallet.name,
                regenerate: true,
              );
      final normalized = allocation.onchainAddress.trim();

      if (!mounted) {
        return;
      }

      if (normalized.isEmpty) {
        const message = 'Endereço on-chain não retornado pelo backend.';
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

      if (!allocation.hasTransferId) {
        const message =
            'O backend não retornou o evento de observação deste depósito on-chain.';
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
        _allocation = allocation;
        _observedTransfer = null;
        _depositAddress = normalized;
        _isLoadingAddress = false;
      });
      await _refreshObservedTransfer(showNotice: false);
      _startObservedTransferPolling();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated =
          ErrorTranslator.translate(context.l10n, error.toString());
      setState(() {
        _isLoadingAddress = false;
        _errorMessage = translated;
      });
      SnackbarHelper.showError(
        translated,
        title: 'Depósito on-chain',
      );
    }
  }

  void _startObservedTransferPolling() {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty) {
      return;
    }
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshObservedTransfer();
    });
  }

  Future<void> _refreshObservedTransfer({bool showNotice = true}) async {
    final transferId = _allocation?.transferId.trim() ?? '';
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
          (_observedTransfer?.status ?? _allocation?.transferStatus ?? '')
              .trim()
              .toUpperCase();
      final previousConfirmations =
          _observedTransfer?.confirmations ?? _allocation?.confirmations ?? 0;

      setState(() {
        _observedTransfer = latest;
      });

      if (previousStatus != latest.status.trim().toUpperCase() ||
          previousConfirmations != latest.confirmations) {
        ref.invalidate(externalTransfersProvider);
        ref.invalidate(transactionHistoryProvider);
      }

      if (showNotice) {
        _showObservedTransferNotice(
          previousStatus: previousStatus,
          previousConfirmations: previousConfirmations,
          latest: latest,
        );
      }

      if (_isTransferFinal(latest.status)) {
        _statusTimer?.cancel();
      }
    } catch (_) {
      // Keep the issued address usable even if the refresh fails transiently.
    }
  }

  void _showObservedTransferNotice({
    required String previousStatus,
    required int previousConfirmations,
    required ExternalTransfer latest,
  }) {
    final normalizedStatus = latest.status.trim().toUpperCase();
    if ((normalizedStatus == 'DETECTED' ||
            normalizedStatus == 'MEMPOOL' ||
            normalizedStatus == 'CONFIRMED' ||
            normalizedStatus == 'COMPLETED') &&
        previousStatus != normalizedStatus &&
        latest.blockchainTxid.trim().isNotEmpty) {
      SnackbarHelper.showInfo(
        'Depósito detectado na rede Bitcoin. Acompanhando ${latest.confirmations}/$_requiredConfirmations confirmações.',
        title: 'Depósito detectado',
      );
    }

    if (latest.confirmations >= _requiredConfirmations &&
        previousConfirmations < _requiredConfirmations &&
        _isTransferFinal(normalizedStatus)) {
      SnackbarHelper.showSuccess(
        'Depósito confirmado e pronto para crédito nesta carteira.',
        title: 'Depósito confirmado',
      );
    }
  }

  bool _isTransferFinal(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'COMPLETED' ||
        normalized == 'CONFIRMED' ||
        normalized == 'FAILED' ||
        normalized == 'CANCELLED' ||
        normalized == 'EXPIRED';
  }

  void _copyAddress(String address) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: address));
    SnackbarHelper.showSuccess('Endereço copiado!');
  }

  int get _requiredConfirmations => _allocation?.requiredConfirmations ?? 3;

  int get _currentConfirmations =>
      _observedTransfer?.confirmations ?? _allocation?.confirmations ?? 0;

  bool get _canCancelDeposit {
    if (_allocation == null || _isCancelling) {
      return false;
    }
    final status =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    final hasDetectedTx =
        (_observedTransfer?.blockchainTxid.trim().isNotEmpty ?? false) ||
            (_allocation?.blockchainTxid.trim().isNotEmpty ?? false);
    return status == 'PENDING' && !hasDetectedTx;
  }

  String get _providerLabel {
    final allocationProvider = _allocation?.provider.trim() ?? '';
    return allocationProvider.isNotEmpty
        ? allocationProvider
        : widget.providerName;
  }

  bool get _isSelfCustody =>
      _allocation?.isSelfCustody ?? widget.wallet.isSelfCustody;

  String get _sourceLabel =>
      _isSelfCustody ? 'XPUB do usuário' : 'Tesouraria Kerosene';

  String get _sourceDescription => _isSelfCustody
      ? 'Endereço derivado do XPUB enviado pelo usuário. O backend apenas monitora este endereço.'
      : 'Endereço novo derivado na custódia da plataforma e observado até a confirmação final.';

  String get _networkLabel {
    final network = (_allocation?.network ?? 'mainnet').trim().toLowerCase();
    return switch (network) {
      'mainnet' => 'Mainnet',
      'testnet' => 'Testnet',
      'regtest' => 'Regtest',
      _ => network.isEmpty ? 'Bitcoin' : network,
    };
  }

  String get _statusLabel {
    final status =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    return switch (status) {
      'COMPLETED' => 'Crédito concluído',
      'CONFIRMED' => 'Confirmado',
      'DETECTED' || 'MEMPOOL' => 'Detectado',
      'PENDING' => 'Aguardando rede',
      'FAILED' => 'Falhou',
      'CANCELLED' => 'Cancelado',
      'EXPIRED' => 'Expirado',
      _ => status,
    };
  }

  String get _statusDescription {
    final normalizedStatus =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    if (normalizedStatus == 'CANCELLED') {
      return 'Este depósito foi cancelado. O endereço deixou de ser observado pela plataforma.';
    }
    if (_observedTransfer == null ||
        (_observedTransfer!.blockchainTxid.trim().isEmpty &&
            _currentConfirmations == 0)) {
      return 'Endereço exclusivo deste depósito. O backend está observando este endereço na $_networkLabel.';
    }
    if (_currentConfirmations >= _requiredConfirmations &&
        _isTransferFinal(_observedTransfer!.status)) {
      return 'A rede confirmou o depósito. O crédito desta carteira já pode ser reconciliado no histórico.';
    }
    return 'Depósito detectado. Aguardando $_currentConfirmations/$_requiredConfirmations confirmações para fechar este evento.';
  }

  Future<void> _cancelDeposit() async {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty || !_canCancelDeposit) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancelar depósito'),
            content: const Text(
              'Este endereço será invalidado e o monitoramento será encerrado. Se a transação já tiver sido detectada, o cancelamento será recusado.',
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
              _buildTrackingCard(),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(
                receiveBtc,
                quoteLabel,
              ),
              if (_canCancelDeposit) ...[
                const SizedBox(height: AppSpacing.md),
                ReceiveFlowSecondaryButton(
                  label: _isCancelling ? 'Cancelando...' : 'Cancelar depósito',
                  icon: LucideIcons.xCircle,
                  onTap: _isCancelling ? null : _cancelDeposit,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _buildOperationalRouteCard(sovereigntyAsync),
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
                  fontFamily: AppTypography.numericFontFamily,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowTag(label: 'Nó $_providerLabel'),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
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
              _statusDescription,
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

  Widget _buildTrackingCard() {
    final transfer = _observedTransfer;
    final txid = transfer?.blockchainTxid.trim().isNotEmpty == true
        ? transfer!.blockchainTxid.trim()
        : _allocation?.blockchainTxid.trim() ?? '';
    final observedAmountBtc = transfer?.amountBtc ?? 0;

    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReceiveFlowSectionLabel('Evento observado'),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowMetricRow(label: 'Status', value: _statusLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Confirmações',
            value: '$_currentConfirmations/$_requiredConfirmations',
          ),
          if (txid.isNotEmpty) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: 'TXID',
              value: txid,
              mono: true,
            ),
          ],
          if (observedAmountBtc > 0) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: 'Valor visto na rede',
              value: MoneyDisplay.format(
                amount: observedAmountBtc,
                currency: Currency.btc,
              ),
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Transfer ID',
            value: _allocation?.transferId ?? '',
            mono: true,
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
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: receiveFlowTextColor,
                    ),
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
    final transfer = _observedTransfer;
    final observedAmountBtc = transfer?.amountBtc ?? 0;

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
          ReceiveFlowMetricRow(label: 'Rede', value: _networkLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(label: 'Nó monitor', value: _providerLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Valor esperado',
            value:
                MoneyDisplay.format(amount: receiveBtc, currency: Currency.btc),
          ),
          if (observedAmountBtc > 0) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: 'Valor recebido',
              value: MoneyDisplay.format(
                amount: observedAmountBtc,
                currency: Currency.btc,
              ),
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Confirmações mínimas',
            value: '$_requiredConfirmations blocos',
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: 'Origem do endereço',
            value: _sourceLabel,
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
              _sourceDescription,
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

  Widget _buildOperationalRouteCard(
    AsyncValue<SecurityStatus> sovereigntyAsync,
  ) {
    return ReceiveFlowPanel(
      child: sovereigntyAsync.when(
        loading: () => _OperationalRouteBody(
          title: 'Rota operacional',
          subtitle:
              'Consultando o estado do quórum para confirmar a derivação do endereço.',
          rows: [
            _OperationalRouteRow(
              label: 'Custódia',
              value: _isSelfCustody
                  ? 'XPUB self-custody monitorado'
                  : 'On-chain autenticado',
            ),
          ],
        ),
        error: (_, __) => _OperationalRouteBody(
          title: 'Rota operacional',
          subtitle:
              'O endereço continua utilizável, mas o painel de quórum não respondeu nesta leitura.',
          rows: [
            _OperationalRouteRow(
              label: 'Custódia',
              value: _isSelfCustody
                  ? 'XPUB self-custody monitorado'
                  : 'On-chain via nó $_providerLabel',
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

          return _OperationalRouteBody(
            title: 'Rota operacional',
            subtitle: failStop
                ? 'A custódia mantém fail-stop ativo; monitore apenas entradas até a malha voltar ao mínimo operacional.'
                : _isSelfCustody
                    ? 'Endereço derivado do XPUB desta carteira. O backend só acompanha a rede e não assina gastos.'
                    : 'Endereço derivado na custódia autenticada e confirmado pelo quórum antes de ser exposto ao app.',
            rows: [
              _OperationalRouteRow(
                label: 'Custódia',
                value: _isSelfCustody
                    ? 'XPUB self-custody monitorado'
                    : 'On-chain via nó $_providerLabel',
              ),
              _OperationalRouteRow(
                label: 'Quórum',
                value:
                    '$activeNodes/$totalNodes ativos • mínimo $requiredNodes',
              ),
              _OperationalRouteRow(
                label: 'Fail-stop',
                value: failStop ? 'Ativo' : 'Inativo',
              ),
              _OperationalRouteRow(
                label: 'Rede',
                value: _networkLabel,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OperationalRouteBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_OperationalRouteRow> rows;

  const _OperationalRouteBody({
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

class _OperationalRouteRow {
  final String label;
  final String value;

  const _OperationalRouteRow({
    required this.label,
    required this.value,
  });
}
