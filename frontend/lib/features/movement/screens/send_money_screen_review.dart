import 'package:kerosene/features/movement/domain/entities/tx_status.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/features/movement/screens/send_money_formatters.dart';
import 'package:kerosene/features/movement/widgets/movement_confirmation_surface.dart';

import 'send_money_screen_dependencies.dart';

class SendPaymentReviewRowData {
  final String label;
  final String value;
  final bool numeric;
  final bool technical;

  const SendPaymentReviewRowData({
    required this.label,
    required this.value,
    this.numeric = false,
    this.technical = false,
  });
}

class SendPaymentReceiptRowData {
  final String label;
  final String value;
  final bool numeric;
  final bool technical;

  const SendPaymentReceiptRowData({
    required this.label,
    required this.value,
    this.numeric = false,
    this.technical = false,
  });
}

class SendPaymentReceiptData {
  final String title;
  final String amountLabel;
  final DateTime occurredAt;
  final List<SendPaymentReceiptRowData> rows;
  final String shareText;

  const SendPaymentReceiptData({
    required this.title,
    required this.amountLabel,
    required this.occurredAt,
    required this.rows,
    required this.shareText,
  });
}

class InternalTransferReviewScreen<T> extends StatefulWidget {
  final String title;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final String confirmLabel;
  final List<SendPaymentReviewRowData> rows;
  final Future<T?> Function(BuildContext context) onConfirm;
  final SendPaymentReceiptData? Function(T result)? receiptBuilder;

  const InternalTransferReviewScreen({
    super.key,
    this.title = 'Confere essa transação?',
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    this.confirmLabel = 'Autorizar',
    required this.rows,
    required this.onConfirm,
    this.receiptBuilder,
  });

  @override
  State<InternalTransferReviewScreen<T>> createState() =>
      InternalTransferReviewScreenState<T>();
}

class InternalTransferReviewScreenState<T>
    extends State<InternalTransferReviewScreen<T>> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    final result = await widget.onConfirm(context);
    if (!mounted) return;

    if (result != null) {
      final receipt = widget.receiptBuilder?.call(result);
      if (receipt != null) {
        final receiptResult = await Navigator.of(context).push<T>(
          MaterialPageRoute<T>(
            builder: (_) => SendPaymentReceiptScreen<T>(
              data: receipt,
              result: result,
            ),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(receiptResult ?? result);
        return;
      }

      Navigator.of(context).pop(result);
      return;
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: _SendFlowColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SendFlowHeader(
                    onClose: _isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      child: _ReviewBody(
                        title: widget.title,
                        amountBtcLabel: widget.amountBtcLabel,
                        fiatAmountLabel: widget.fiatAmountLabel,
                        rows: widget.rows,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: _AuthorizeButton(
                      label: widget.confirmLabel,
                      isSubmitting: _isSubmitting,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SendPaymentReceiptScreen<T> extends StatefulWidget {
  final SendPaymentReceiptData data;
  final T result;

  const SendPaymentReceiptScreen({
    super.key,
    required this.data,
    required this.result,
  });

  @override
  State<SendPaymentReceiptScreen<T>> createState() =>
      _SendPaymentReceiptScreenState<T>();
}

class _SendPaymentReceiptScreenState<T>
    extends State<SendPaymentReceiptScreen<T>> {
  void _close() {
    Navigator.of(context).pop<T>(widget.result);
  }

  Future<void> _shareReceipt() async {
    await Clipboard.setData(ClipboardData(text: widget.data.shareText));
    HapticFeedback.selectionClick();
    SnackbarHelper.showSuccess('Comprovante copiado');
  }

  @override
  Widget build(BuildContext context) {
    final rows = <SendPaymentReceiptRowData>[
      SendPaymentReceiptRowData(
        label: 'Data',
        value: _formatReceiptDate(widget.data.occurredAt),
        numeric: true,
      ),
      ...widget.data.rows,
    ];

    return Scaffold(
      backgroundColor: _SendFlowColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SendFlowHeader(onClose: _close),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: _ReceiptBody(
                      title: widget.data.title,
                      amountLabel: widget.data.amountLabel,
                      rows: rows,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _ReceiptShareButton(onPressed: _shareReceipt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  final String title;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final List<SendPaymentReviewRowData> rows;

  const _ReviewBody({
    required this.title,
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return MovementConfirmationSurface(
      title: title,
      amountLabel: amountBtcLabel,
      supportingLabel: fiatAmountLabel,
      compactRows: true,
      rows: [
        for (final row in rows)
          MovementConfirmationRow(
            label: row.label,
            value: row.value,
            numeric: row.numeric,
            technical: row.technical,
          ),
      ],
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  final String title;
  final String amountLabel;
  final List<SendPaymentReceiptRowData> rows;

  const _ReceiptBody({
    required this.title,
    required this.amountLabel,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return MovementConfirmationSurface(
      title: title,
      amountLabel: amountLabel,
      leading: const _ReceiptSuccessMark(),
      rows: [
        for (final row in rows)
          MovementConfirmationRow(
            label: row.label,
            value: row.value,
            numeric: row.numeric,
            technical: row.technical,
          ),
      ],
    );
  }
}

class _SendFlowHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _SendFlowHeader({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(KeroseneIcons.close, size: 22),
          style: IconButton.styleFrom(
            foregroundColor: _SendFlowColors.muted,
            disabledForegroundColor: _SendFlowColors.muted.withValues(
              alpha: 0.38,
            ),
            minimumSize: const Size.square(44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

class _AuthorizeButton extends StatelessWidget {
  final String label;
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _AuthorizeButton({
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSubmitting ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: _SendFlowColors.button,
              border: Border.all(color: _SendFlowColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: isSubmitting ? 1 : 0),
                    duration: const Duration(milliseconds: 920),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: child,
                      );
                    },
                    child: const ColoredBox(color: _SendFlowColors.success),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Row(
                        key: ValueKey<bool>(isSubmitting),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSubmitting ? 'Autorizando' : label,
                            style: AppTypography.inter(
                              color: _SendFlowColors.buttonText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSubmitting
                                ? KeroseneIcons.security
                                : KeroseneIcons.lock,
                            color: _SendFlowColors.buttonText,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptSuccessMark extends StatelessWidget {
  const _ReceiptSuccessMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _SendFlowColors.success.withValues(alpha: 0.20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          KeroseneIcons.check,
          color: _SendFlowColors.success,
          size: 34,
        ),
      ),
    );
  }
}

class _ReceiptShareButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReceiptShareButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _SendFlowColors.shareButton,
          foregroundColor: _SendFlowColors.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        icon: const Icon(KeroseneIcons.share, size: 17),
        label: const Text('COMPARTILHAR'),
      ),
    );
  }
}

String receiptAmountLabelFromStatus({
  required TxStatus status,
  required double fallbackAmountBtc,
}) {
  final amount =
      status.amountReceived > 0 ? status.amountReceived : fallbackAmountBtc;
  return formatBtcValue(amount);
}

String compactSendReceiptValue(String value, {int head = 12, int tail = 8}) {
  final trimmed = value.trim();
  if (trimmed.length <= head + tail + 3) return trimmed;
  return '${trimmed.substring(0, head)}...${trimmed.substring(trimmed.length - tail)}';
}

String _formatReceiptDate(DateTime value) {
  const months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];
  final day = value.day.toString().padLeft(2, '0');
  final month = months[value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day $month ${value.year} - $hour:$minute';
}

class _SendFlowColors {
  const _SendFlowColors._();

  static const background = Colors.black;
  static const button = AppColors.hexFF131313;
  static const shareButton = AppColors.hexFF1A1A1A;
  static const border = AppColors.hexFF222222;
  static const text = Colors.white;
  static const muted = AppColors.hexFF71717A;
  static const buttonText = AppColors.hexFFE4E4E7;
  static const success = AppColors.hexFF22C55E;
}
