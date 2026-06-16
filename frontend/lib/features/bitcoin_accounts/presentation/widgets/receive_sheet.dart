part of '../bitcoin_accounts_screen.dart';

class _ReceiveSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;

  const _ReceiveSheet({required this.account});

  @override
  ConsumerState<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends ConsumerState<_ReceiveSheet> {
  final TextEditingController _amount = TextEditingController();
  String _expiry = '1H';
  bool _oneTime = true;
  bool _busy = false;
  ReceivingRequestView? _result;
  Timer? _poller;

  @override
  void dispose() {
    _poller?.cancel();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: context.tr.bitcoinReceiveTitle,
      child: _result == null ? _buildForm(context) : _buildLiveRequest(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Column(
      children: [
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.text),
          decoration: colors.inputDecoration(
            label: context.tr.bitcoinReceiveAmountOptional,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in const ['15M', '1H', '24H', 'PERMANENT'])
              ChoiceChip(
                label: Text(_expiryLabel(context, option)),
                selected: _expiry == option,
                onSelected: (_) => setState(() => _expiry = option),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          value: _oneTime,
          onChanged: (value) => setState(() => _oneTime = value),
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr.bitcoinReceiveOneTime,
            style: TextStyle(color: colors.text),
          ),
          subtitle: Text(
            context.tr.bitcoinReceiveOneTimeSubtitle,
            style: TextStyle(color: colors.mutedText),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: colors.filledButtonStyle(),
            onPressed: _busy ? null : _createReceiveRequest,
            icon: const Icon(LucideIcons.qrCode, size: 18),
            label: Text(
              _busy
                  ? context.tr.bitcoinReceiveGenerating
                  : context.tr.bitcoinReceiveGenerateAddress,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRequest(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final result = _result!;
    final qrSize =
        context.responsive.clampWidth(210).clamp(168.0, 210.0).toDouble();

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderStrong),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: QrImageView(
              data: result.bip21.trim().isNotEmpty
                  ? result.bip21
                  : 'bitcoin:${result.address}',
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BitcoinAddressBlocks(
          address: result.address,
          style: AppTypography.technicalMono(
            textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: _receiveStatusLabel(context, result.status)),
            if (result.amountSats != null)
              _Pill(text: _formatSats(result.amountSats!)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MutedPanel(text: _receiveStatusMessage(context, result)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = constraints.maxWidth < 360;
            final buttons = [
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(),
                onPressed: _busy ? null : _copyAddress,
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(context.tr.copyAddress),
              ),
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(),
                onPressed: _busy ? null : () => _refreshStatus(silent: false),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(context.tr.bitcoinReceiveRefresh),
              ),
            ];

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: AppSpacing.sm),
                  buttons[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createReceiveRequest() async {
    setState(() => _busy = true);
    try {
      final parsed = int.tryParse(_amount.text.trim());
      final service = ref.read(bitcoinAccountsServiceProvider);
      final created = await service.createReceiveRequest(
        accountId: widget.account.id,
        amountSats: parsed != null && parsed > 0 ? parsed : null,
        expiry: _expiry,
        oneTime: _oneTime,
      );
      if (!mounted) return;
      ref.invalidate(bitcoinAccountReceiveRequestsProvider(widget.account.id));
      setState(() => _result = created);
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinReceiveCreateErrorTitle,
        message: context.tr.bitcoinReceiveCreateErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus({required bool silent}) async {
    final current = _result;
    if (current == null || _busy) return;
    if (!silent) setState(() => _busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final updated = await service.getReceiveStatus(current.id);
      if (!mounted) return;
      setState(() => _result = updated);
      if (_isTerminal(updated.status)) {
        _poller?.cancel();
      }
    } catch (_) {
      if (!silent && mounted) {
        AppNotice.showError(
          context,
          title: context.tr.bitcoinReceiveStatusErrorTitle,
          message: context.tr.bitcoinReceiveStatusErrorMessage,
        );
      }
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyAddress() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.address));
    if (!mounted) return;
    AppNotice.showSuccess(
      context,
      title: context.tr.bitcoinReceiveCopiedTitle,
      message: context.tr.bitcoinReceiveCopiedMessage,
    );
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshStatus(silent: true),
    );
  }

  bool _isTerminal(String status) =>
      status == 'PAID' || status == 'HIDDEN' || status == 'FAILED_SAFE';
}
