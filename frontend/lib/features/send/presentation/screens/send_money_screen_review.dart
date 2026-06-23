// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'send_money_screen_dependencies.dart';
import 'send_money_screen.dart';

class InternalTransferReviewScreen<T> extends StatefulWidget {
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

  const InternalTransferReviewScreen({
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
  State<InternalTransferReviewScreen<T>> createState() =>
      InternalTransferReviewScreenState<T>();
}

class InternalTransferReviewScreenState<T>
    extends State<InternalTransferReviewScreen<T>> {
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
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: SendMoneyScreenState.internalBlack,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(KeroseneIcons.back, size: 22),
                    style: IconButton.styleFrom(
                      foregroundColor: SendMoneyScreenState.internalText,
                      backgroundColor: SendMoneyScreenState.internalSurface,
                      side: const BorderSide(
                        color: SendMoneyScreenState.internalBorder,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.left,
                            style: AppTypography.newsreader(
                              color: SendMoneyScreenState.internalText,
                              fontSize: 38,
                              fontWeight: FontWeight.w500,
                              height: 1.05,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _ReviewAmountPanel(
                            amountBtcLabel: widget.amountBtcLabel,
                            fiatAmountLabel: widget.fiatAmountLabel,
                          ),
                          const SizedBox(height: 18),
                          _ReviewEntryAnimation(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SendMoneyScreenState.internalSurface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: SendMoneyScreenState.internalBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  InternalReviewRow(
                                    label: 'Para',
                                    value: widget.recipientLabel,
                                    trailingIcon: KeroseneIcons.chevronRight,
                                  ),
                                  if (widget.recipientAddress
                                          .trim()
                                          .isNotEmpty &&
                                      widget.recipientAddress.trim() !=
                                          widget.recipientLabel.trim())
                                    InternalReviewRow(
                                      label: 'ID',
                                      value: widget.recipientAddress.trim(),
                                    ),
                                  InternalReviewRow(
                                    label: 'Valor',
                                    value: widget.amountBtcLabel,
                                    helper: widget.fiatAmountLabel,
                                    valueLarge: true,
                                  ),
                                  InternalReviewRow(
                                    label: 'Taxa',
                                    value: widget.feeLabel,
                                  ),
                                  InternalReviewRow(
                                    label: 'Origem',
                                    value: widget.sourceWallet,
                                  ),
                                  InternalReviewRow(
                                    label: 'Nota',
                                    value: widget.note,
                                    alignTop: true,
                                    showDivider: false,
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
                          backgroundColor: SendMoneyScreenState.internalText,
                          foregroundColor: SendMoneyScreenState.internalBlack,
                          disabledBackgroundColor: SendMoneyScreenState
                              .internalText
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
                                  color: SendMoneyScreenState.internalBlack,
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
                          color: SendMoneyScreenState.internalMutedText,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          protectedLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: SendMoneyScreenState.internalMutedText,
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
      ),
    );
  }
}

class _ReviewAmountPanel extends StatelessWidget {
  final String amountBtcLabel;
  final String fiatAmountLabel;

  const _ReviewAmountPanel({
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: SendMoneyScreenState.internalSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SendMoneyScreenState.internalBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  KeroseneIcons.security,
                  color: SendMoneyScreenState.internalMutedText,
                  size: 14,
                ),
                const SizedBox(width: 7),
                Text(
                  'REVISÃO FINAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SendMoneyScreenState.internalMutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              amountBtcLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.financial(
                color: SendMoneyScreenState.internalText,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fiatAmountLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SendMoneyScreenState.internalMutedText,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewEntryAnimation extends StatelessWidget {
  final Widget child;

  const _ReviewEntryAnimation({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 310),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class InternalReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData? trailingIcon;
  final bool valueLarge;
  final bool alignTop;
  final bool showDivider;

  const InternalReviewRow({
    required this.label,
    required this.value,
    this.helper,
    this.trailingIcon,
    this.valueLarge = false,
    this.alignTop = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: KeroseneBrandTokens.borderSubtle),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment:
            alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SendMoneyScreenState.internalMutedText,
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
                              color: SendMoneyScreenState.internalText,
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
                        color: SendMoneyScreenState.internalMutedText,
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
                          color: SendMoneyScreenState.internalMutedText,
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
