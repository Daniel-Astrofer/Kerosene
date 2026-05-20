part of 'send_money_screen.dart';

class _InternalTransferReviewScreen<T> extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String successTitle;
  final String successMessage;
  final String recipientLabel;
  final String recipientAddress;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final String feeLabel;
  final String note;
  final String sourceWallet;
  final Future<T?> Function(BuildContext context) onConfirm;

  const _InternalTransferReviewScreen({
    this.title = 'Revisar transferência',
    this.confirmLabel = 'Confirmar transferência',
    this.successTitle = 'Transferência concluída',
    this.successMessage = 'Os fundos foram enviados dentro da Kerosene.',
    required this.recipientLabel,
    required this.recipientAddress,
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    required this.feeLabel,
    required this.note,
    required this.sourceWallet,
    required this.onConfirm,
  });

  @override
  State<_InternalTransferReviewScreen<T>> createState() =>
      _InternalTransferReviewScreenState<T>();
}

class _InternalTransferReviewScreenState<T>
    extends State<_InternalTransferReviewScreen<T>> {
  bool _isSubmitting = false;
  T? _result;

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await widget.onConfirm(context);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return _InternalTransferSuccessView<T>(
        result: result,
        recipientLabel: widget.recipientLabel,
        amountBtcLabel: widget.amountBtcLabel,
        fiatAmountLabel: widget.fiatAmountLabel,
        feeLabel: widget.feeLabel,
        title: widget.successTitle,
        message: widget.successMessage,
      );
    }

    return Scaffold(
      backgroundColor: _SendMoneyScreenState._internalBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: _SendMoneyScreenState._internalText,
                    backgroundColor: _SendMoneyScreenState._internalSurface,
                    side: const BorderSide(
                      color: _SendMoneyScreenState._internalBorder,
                    ),
                    minimumSize: const Size.square(40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            color: _SendMoneyScreenState._internalText,
                            fontSize: 38,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _InternalReviewRow(
                          label: 'Para',
                          value: widget.recipientLabel,
                          trailingIcon: LucideIcons.chevronRight,
                        ),
                        if (widget.recipientAddress.trim().isNotEmpty &&
                            widget.recipientAddress.trim() !=
                                widget.recipientLabel.trim())
                          _InternalReviewRow(
                            label: 'ID',
                            value: widget.recipientAddress.trim(),
                          ),
                        _InternalReviewRow(
                          label: 'Valor',
                          value: widget.amountBtcLabel,
                          helper: widget.fiatAmountLabel,
                          valueLarge: true,
                        ),
                        _InternalReviewRow(
                          label: 'Taxa',
                          value: widget.feeLabel,
                        ),
                        _InternalReviewRow(
                          label: 'Origem',
                          value: widget.sourceWallet,
                        ),
                        _InternalReviewRow(
                          label: 'Nota',
                          value: widget.note,
                          alignTop: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: _SendMoneyScreenState._internalText,
                        foregroundColor: _SendMoneyScreenState._internalBlack,
                        disabledBackgroundColor: _SendMoneyScreenState
                            ._internalText
                            .withValues(alpha: 0.32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _SendMoneyScreenState._internalBlack,
                              ),
                            )
                          : const Icon(LucideIcons.arrowRight, size: 20),
                      label: Text(
                        widget.confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        color: _SendMoneyScreenState._internalMutedText,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'TRANSAÇÃO PROTEGIDA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _SendMoneyScreenState._internalMutedText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternalReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData? trailingIcon;
  final bool valueLarge;
  final bool alignTop;

  const _InternalReviewRow({
    required this.label,
    required this.value,
    this.helper,
    this.trailingIcon,
    this.valueLarge = false,
    this.alignTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _SendMoneyScreenState._internalMutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: alignTop ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _SendMoneyScreenState._internalText,
                              fontSize: valueLarge ? 20 : 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        trailingIcon,
                        color: _SendMoneyScreenState._internalMutedText,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (helper != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    helper!,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _SendMoneyScreenState._internalMutedText,
                          fontSize: 11,
                          height: 1.25,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalTransferSuccessView<T> extends StatelessWidget {
  final T result;
  final String recipientLabel;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final String feeLabel;
  final String title;
  final String message;

  const _InternalTransferSuccessView({
    required this.result,
    required this.recipientLabel,
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    required this.feeLabel,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SendMoneyScreenState._internalBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _SendMoneyScreenState._internalSuccessGreen
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: _SendMoneyScreenState._internalSuccessGreen,
                  ),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: _SendMoneyScreenState._internalSuccessGreen,
                  size: 42,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.72, 0.72),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                    duration: 420.ms,
                  )
                  .fadeIn(duration: 240.ms),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  color: _SendMoneyScreenState._internalText,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  height: 1.08,
                  letterSpacing: 0,
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 280.ms),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _SendMoneyScreenState._internalMutedText,
                      fontSize: 14,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 44),
              _InternalReviewRow(label: 'Para', value: recipientLabel),
              _InternalReviewRow(
                label: 'Valor',
                value: amountBtcLabel,
                helper: fiatAmountLabel,
                valueLarge: true,
              ),
              _InternalReviewRow(label: 'Taxa', value: feeLabel),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(result),
                  style: FilledButton.styleFrom(
                    backgroundColor: _SendMoneyScreenState._internalText,
                    foregroundColor: _SendMoneyScreenState._internalBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Concluir',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
