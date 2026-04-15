import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_status_badge.dart';
import 'package:teste/l10n/l10n_extension.dart';

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
    if (_isLockedPaymentRequest) {
      final explicitUri = _link.paymentUri?.trim();
      if (explicitUri != null && explicitUri.isNotEmpty) {
        return explicitUri;
      }
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

    return CyberBackground.authenticated(
      useScroll: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            _buildHero(statusMeta).animate().fade().slideY(begin: 0.08),
            const SizedBox(height: 18),
            _buildQrCard(context).animate(delay: 80.ms).fade(),
            const SizedBox(height: 18),
            _buildLinkDetails(context).animate(delay: 120.ms).fade(),
            const SizedBox(height: 18),
            _buildActions(context).animate(delay: 160.ms).fade(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            LucideIcons.chevronLeft,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(AppSpacing.sm),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECEBER POR QR',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Link de pagamento rastreado',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.56),
                    ),
              ),
            ],
          ),
        ),
        if (_isRefreshing)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildHero(FinancialStatusMeta statusMeta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1A26), Color(0xFF09111A)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FinancialStatusBadge(meta: statusMeta, compact: true),
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
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.8,
            ),
          ),
          if (widget.requestedAmountLabel != widget.btcAmountLabel) ...[
            const SizedBox(height: 6),
            Text(
              widget.btcAmountLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _statusHeadline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.45,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                color: Color(0xFF071018),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF071018),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.receiveScanToPay.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.42),
                  letterSpacing: 2.6,
                  fontWeight: FontWeight.w900,
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
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onTap: () => _refreshLink(),
            icon: LucideIcons.refreshCw,
            label: 'ATUALIZAR',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            onTap: () => Navigator.pushNamed(context, '/history'),
            icon: LucideIcons.history,
            label: 'HISTORICO',
          ),
        ),
      ],
    );
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.54),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
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
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
