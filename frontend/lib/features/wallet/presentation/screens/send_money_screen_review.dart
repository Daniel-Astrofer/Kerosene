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
  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await widget.onConfirm(context);
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
      return;
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    const protectedLabel = 'TRANSAÇÃO PROTEGIDA';
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
                  icon: const Icon(KeroseneIcons.back, size: 22),
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
                          style: AppTypography.newsreader(
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
                          trailingIcon: KeroseneIcons.chevronRight,
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
                          : const Icon(KeroseneIcons.next, size: 20),
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
                        KeroseneIcons.security,
                        color: _SendMoneyScreenState._internalMutedText,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        protectedLabel,
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
          top: BorderSide(color: KeroseneBrandTokens.borderSubtle),
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
