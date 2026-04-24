import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_status_badge.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

class ReceivePaymentLinkScreen extends ConsumerStatefulWidget {
  final PaymentLink initialLink;
  final String requestedAmountLabel;
  final String btcAmountLabel;
  final String? walletLabel;
  final String? cardTypeLabel;
  final String? depositFeeLabel;
  final String? netAmountLabel;

  const ReceivePaymentLinkScreen({
    super.key,
    required this.initialLink,
    required this.requestedAmountLabel,
    required this.btcAmountLabel,
    this.walletLabel,
    this.cardTypeLabel,
    this.depositFeeLabel,
    this.netAmountLabel,
  });

  @override
  ConsumerState<ReceivePaymentLinkScreen> createState() =>
      _ReceivePaymentLinkScreenState();
}

class _ReceivePaymentLinkScreenState
    extends ConsumerState<ReceivePaymentLinkScreen> {
  Timer? _ticker;
  late PaymentLink _link;
  bool _isRefreshing = false;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _link = widget.initialLink;
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isLockedPaymentRequest => _link.isInternalPaymentRequest;

  String get _paymentUri {
    final explicitUri = _link.paymentUri?.trim();
    if (explicitUri != null && explicitUri.isNotEmpty) {
      return explicitUri;
    }

    if (_isLockedPaymentRequest) {
      return QrPaymentParser.encodePaymentLink(_link.id);
    }

    return QrPaymentParser.encode(
      address: _link.depositAddress,
      amountBtc: _link.amountBtc,
      label: widget.walletLabel,
      message: _link.description,
    );
  }

  String get _destinationHash {
    final value = _link.destinationHash?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return _link.depositAddress;
  }

  Duration get _remainingTime {
    final expiresAt = _link.expiresAt;
    if (expiresAt == null) {
      return Duration.zero;
    }

    final remaining = expiresAt.toLocal().difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  bool get _shouldKeepPolling => _link.isPending || _link.isVerifyingOnboarding;
  bool get _canCancelLink =>
      !_isLockedPaymentRequest &&
      (_link.isPending || _link.isVerifyingOnboarding);

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) {
        return;
      }

      setState(() {
        _elapsedSeconds += 1;
      });

      final shouldRefresh = _elapsedSeconds % 12 == 0;
      if (shouldRefresh && _shouldKeepPolling && !_isRefreshing) {
        await _refreshLink(silent: true);
      }
    });
  }

  Future<void> _refreshLink({bool silent = false}) async {
    if (_isRefreshing) {
      return;
    }

    final previousStatus = _link.status;

    setState(() => _isRefreshing = true);
    try {
      final latest = await ref
          .read(transactionRepositoryProvider)
          .getPaymentLink(_link.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _link = latest;
      });

      if (previousStatus != latest.status) {
        ref.invalidate(paymentLinksProvider);
        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(pagedTransactionHistoryProvider);
      }
    } catch (error) {
      if (!silent && mounted) {
        SnackbarHelper.showError('Nao foi possivel atualizar o link: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _copyValue(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    await HapticFeedback.selectionClick();
    SnackbarHelper.showSuccess(message);
  }

  Future<void> _cancelLink() async {
    final reason = await _showCancelReasonSheet();
    if (reason == null) {
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final cancelled =
          await ref.read(transactionRepositoryProvider).cancelPaymentLink(
                linkId: _link.id,
                reason: reason.trim().isEmpty ? null : reason.trim(),
              );

      if (!mounted) {
        return;
      }

      setState(() {
        _link = cancelled;
      });
      ref.invalidate(paymentLinksProvider);
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(pagedTransactionHistoryProvider);
      SnackbarHelper.showSuccess('Link de pagamento cancelado.');
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError('Nao foi possivel cancelar o link: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<String?> _showCancelReasonSheet() {
    final controller = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: receiveFlowPanelColor,
              border: Border.all(color: receiveFlowBorderStrongColor),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cancelar link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opcionalmente registre o motivo para manter o histórico operacional coerente.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo do cancelamento',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  icon: const Icon(LucideIcons.xCircle, size: 16),
                  label: const Text('Confirmar cancelamento'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Nao informado';
    }
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String get _statusHeadline {
    if (_link.isVerifyingOnboarding) {
      return 'Pagamento em verificacao';
    }
    if (_link.isPaid || _link.isCompleted) {
      return 'Pagamento recebido';
    }
    if (_link.isCancelled) {
      return 'Link cancelado';
    }
    if (_link.isExpired) {
      return 'Link expirado';
    }
    return 'Aguardando pagamento';
  }

  String get _statusMessage {
    if (_link.isVerifyingOnboarding) {
      return 'A rede ja identificou o pagamento e o backend ainda esta validando a etapa final.';
    }
    if (_link.isPaid || _link.isCompleted) {
      return 'O valor deste link ja foi recebido. O historico do criador reflete esse estado automaticamente.';
    }
    if (_link.isCancelled) {
      return _link.cancelReason?.trim().isNotEmpty == true
          ? 'Este link foi cancelado: ${_link.cancelReason}.'
          : 'Este link foi cancelado e nao aceita mais pagamentos.';
    }
    if (_link.isExpired) {
      return 'Este link nao aceita mais pagamentos. Gere um novo QR para continuar a receber.';
    }
    if (_isLockedPaymentRequest) {
      return 'Quem abrir este QR ou link verá apenas a confirmação. Valor e destino ficam travados pelo servidor.';
    }
    return 'Use o QR code ou copie o link de pagamento abaixo. O status sera atualizado automaticamente.';
  }

  String _shortHash(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusMeta = FinancialStatusBadge.paymentLink(_link.status);

    return ReceiveFlowScaffold(
      title: 'Recebimento',
      subtitle: 'QR, link e acompanhamento no mesmo padrão visual.',
      actions: [
        if (_isRefreshing)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: receiveFlowTextColor,
              strokeWidth: 2,
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(statusMeta),
          const SizedBox(height: 16),
          _buildQrCard(context),
          const SizedBox(height: 16),
          _buildLinkDetails(context),
          const SizedBox(height: 16),
          _buildConfigurationCard(context),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHero(FinancialStatusMeta statusMeta) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ReceiveFlowTag(
                label: statusMeta.label.resolve(context),
                icon: LucideIcons.activity,
              ),
              _MetricChip(
                icon: Icons.timer_outlined,
                label: _link.isExpired
                    ? 'Expirado'
                    : 'Expira em ${_formatDuration(_remainingTime)}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.requestedAmountLabel,
            style: const TextStyle(
              color: receiveFlowTextColor,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.8,
            ),
          ),
          if (widget.requestedAmountLabel != widget.btcAmountLabel) ...[
            const SizedBox(height: 6),
            Text(
              widget.btcAmountLabel,
              style: TextStyle(
                color: receiveFlowMutedTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (widget.depositFeeLabel != null ||
              widget.netAmountLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (widget.cardTypeLabel != null) widget.cardTypeLabel,
                if (widget.depositFeeLabel != null)
                  'depósito ${widget.depositFeeLabel}',
                if (widget.netAmountLabel != null)
                  'líquido ${widget.netAmountLabel}',
              ].join(' • '),
              style: TextStyle(
                color: receiveFlowMutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _statusHeadline,
            style: const TextStyle(
              color: receiveFlowTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            style: TextStyle(
              color: receiveFlowMutedTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailTag(
                title: 'ID',
                value: _link.id,
              ),
              if (_isLockedPaymentRequest && _destinationHash.isNotEmpty)
                _DetailTag(
                  title: 'Destino',
                  value: _shortHash(_destinationHash),
                ),
              _DetailTag(
                title: 'Expira',
                value: _formatDateTime(_link.expiresAt),
              ),
              if (_link.txid != null && _link.txid!.isNotEmpty)
                _DetailTag(
                  title: 'TXID',
                  value: _link.txid!,
                ),
              if (_link.isCancelled)
                _DetailTag(
                  title: 'Estado',
                  value: 'Cancelado',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: QrImageView(
              data: _paymentUri,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
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
          const SizedBox(height: 16),
          Text(
            context.l10n.receiveScanToPay,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkDetails(BuildContext context) {
    if (_isLockedPaymentRequest) {
      return Column(
        children: [
          _CopyFieldCard(
            title: 'Link de pagamento',
            value: _paymentUri,
            helper:
                'Este link abre a confirmação com valor e destino travados.',
            onCopy: () => _copyValue(
              _paymentUri,
              'Link de pagamento copiado para a area de transferencia.',
            ),
          ),
          const SizedBox(height: 12),
          _CopyFieldCard(
            title: 'Hash do destino',
            value: _destinationHash,
            helper:
                'Somente o hash publico da carteira de destino fica visivel para quem paga.',
            onCopy: () => _copyValue(
              _destinationHash,
              'Hash do destino copiado para a area de transferencia.',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _CopyFieldCard(
          title: 'Link de pagamento',
          value: _paymentUri,
          helper:
              'Este e o payload completo do QR com endereco e valor definidos.',
          onCopy: () => _copyValue(
            _paymentUri,
            'Link de pagamento copiado para a area de transferencia.',
          ),
        ),
        const SizedBox(height: 12),
        _CopyFieldCard(
          title: context.l10n.depositAddress,
          value: _link.depositAddress,
          helper:
              'Endereco retornado pela API para receber exatamente este pagamento.',
          onCopy: () => _copyValue(
            _link.depositAddress,
            'Endereco de deposito copiado para a area de transferencia.',
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = <Widget>[
          _ActionButton(
            onTap: () => _refreshLink(),
            icon: LucideIcons.refreshCw,
            label: 'Atualizar',
          ),
          _ActionButton(
            onTap: () => Navigator.pushNamed(context, '/history'),
            icon: LucideIcons.history,
            label: 'Histórico',
          ),
          if (_canCancelLink)
            _ActionButton(
              onTap: _cancelLink,
              icon: LucideIcons.xCircle,
              label: 'Cancelar',
            ),
        ];

        if (constraints.maxWidth < 540) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                actions[index],
                if (index != actions.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              Expanded(child: actions[index]),
              if (index != actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildConfigurationCard(BuildContext context) {
    final metadataEntries = _link.metadata.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuracao do link',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailTag(
                title: 'Visibilidade',
                value: _humanizeFlag(_link.visibility),
              ),
              _DetailTag(
                title: 'Fechamento',
                value: _humanizeFlag(_link.confirmationMode),
              ),
              _DetailTag(
                title: 'Valor',
                value: _link.amountLocked ? 'Travado' : 'Flexivel',
              ),
              if (_link.referenceLabel != null &&
                  _link.referenceLabel!.trim().isNotEmpty)
                _DetailTag(
                  title: 'Referencia',
                  value: _link.referenceLabel!,
                ),
              if (_link.createdAt != null)
                _DetailTag(
                  title: 'Criado em',
                  value: _formatDateTime(_link.createdAt),
                ),
              if (_link.paidAt != null)
                _DetailTag(
                  title: 'Pago em',
                  value: _formatDateTime(_link.paidAt),
                ),
              if (_link.completedAt != null)
                _DetailTag(
                  title: 'Liquidado em',
                  value: _formatDateTime(_link.completedAt),
                ),
              if (_link.cancelledAt != null)
                _DetailTag(
                  title: 'Cancelado em',
                  value: _formatDateTime(_link.cancelledAt),
                ),
            ],
          ),
          if (metadataEntries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Metadados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metadataEntries
                  .map(
                    (entry) => _DetailTag(
                      title: entry.key,
                      value: entry.value,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _humanizeFlag(String value) {
    return value
        .split('_')
        .where((segment) => segment.trim().isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _CopyFieldCard extends StatelessWidget {
  final String title;
  final String value;
  final String helper;
  final VoidCallback onCopy;

  const _CopyFieldCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar'),
                style: TextButton.styleFrom(
                  foregroundColor: receiveFlowMutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: AppTypography.technicalMono(
              textStyle: const TextStyle(
                color: receiveFlowTextColor,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowSecondaryButton(
      onTap: onTap,
      icon: icon,
      label: label,
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: receiveFlowPanelRaisedColor,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: receiveFlowBorderStrongColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: receiveFlowMutedTextColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final String title;
  final String value;

  const _DetailTag({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = title.trim().toUpperCase();
    final isTechnicalValue = normalizedTitle == 'ID' ||
        normalizedTitle == 'TXID' ||
        normalizedTitle == 'DESTINO';

    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: receiveFlowPanelColor,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: receiveFlowBorderStrongColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowFaintTextColor,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: isTechnicalValue
                ? AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: receiveFlowTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                  )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: receiveFlowTextColor,
                      fontWeight: FontWeight.w500,
                    ),
          ),
        ],
      ),
    );
  }
}
