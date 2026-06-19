part of '../bitcoin_accounts_screen.dart';

class _CreatePsbtSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;

  const _CreatePsbtSheet({required this.account});

  @override
  ConsumerState<_CreatePsbtSheet> createState() => _CreatePsbtSheetState();
}

class _CreatePsbtSheetState extends ConsumerState<_CreatePsbtSheet> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _feeRateController = TextEditingController();
  final Set<String> _selectedUtxoIds = {};

  bool _busy = false;
  PsbtWorkflowView? _created;

  String get _coldWalletId => _coldWalletIdForAccount(widget.account);

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    _feeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return _SheetScaffold(
      title: created == null
          ? context.tr.bitcoinAdvancedCreatePsbtTitle
          : context.tr.bitcoinAdvancedPsbtCreatedTitle,
      child: created == null ? _buildForm(context) : _buildCreated(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final utxosAsync = ref.watch(bitcoinColdWalletUtxosProvider(_coldWalletId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(
          text: context.tr.bitcoinAdvancedCreatePsbtIntro,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _destinationController,
          style: TextStyle(color: colors.text),
          decoration: colors.inputDecoration(
            label: context.tr.bitcoinAdvancedDestinationLabel,
            hintText: 'bc1...',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: colors.text),
          decoration: colors.inputDecoration(
            label: context.tr.bitcoinAdvancedAmountSatsLabel,
            hintText: '250000',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _feeRateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: colors.text),
          decoration: colors.inputDecoration(
            label: context.tr.bitcoinAdvancedFeeRateOptionalLabel,
            hintText: 'sat/vB',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AdvancedSubsection(
          title: context.tr.bitcoinAdvancedOptionalUtxosTitle,
          icon: LucideIcons.coins,
          child: utxosAsync.when(
            loading: () => const _MiniLoadingRows(),
            error: (_, __) => _MiniActionState(
              icon: LucideIcons.alertTriangle,
              title: context.tr.bitcoinAdvancedUtxosUnavailableTitle,
              message: context.tr.bitcoinAdvancedAutoUtxosFallback,
              onRetry: () =>
                  ref.invalidate(bitcoinColdWalletUtxosProvider(_coldWalletId)),
            ),
            data: _buildSelectableUtxos,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          style: colors.filledButtonStyle(),
          onPressed: _busy ? null : _create,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.fileText, size: 18),
          label: Text(
            _busy
                ? context.tr.bitcoinAdvancedCreatingPsbtAction
                : context.tr.bitcoinAdvancedCreatePsbtAction,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableUtxos(List<ColdWalletUtxoView> utxos) {
    final colors = _BitcoinAccountsColors.of(context);
    final spendable = utxos.where((utxo) => utxo.isSpendable).toList();
    if (spendable.isEmpty) {
      return _MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoSpendableUtxos,
      );
    }

    return Column(
      children: [
        _MiniHint(
          text: context.tr.bitcoinAdvancedAutoUtxosMessage,
        ),
        for (final utxo in spendable.take(8))
          CheckboxListTile(
            value: _selectedUtxoIds.contains(utxo.id),
            onChanged: _busy
                ? null
                : (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedUtxoIds.add(utxo.id);
                      } else {
                        _selectedUtxoIds.remove(utxo.id);
                      }
                    });
                  },
            activeColor: colors.text,
            checkColor: colors.filledButtonForeground,
            side: BorderSide(color: colors.borderStrong),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _formatSats(utxo.amountSats),
              style: TextStyle(color: colors.text),
            ),
            subtitle: Text(
              '${utxo.txidRef}:${utxo.vout} | ${utxo.confirmations} conf.',
              style: TextStyle(color: colors.mutedText),
            ),
          ),
      ],
    );
  }

  Widget _buildCreated(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final workflow = _created!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(
          text: context.tr.bitcoinAdvancedCreatedReviewMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedDestinationMetric,
          value: _shortText(workflow.destinationAddress),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedAmountMetric,
          value: _formatSats(workflow.amountSats),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedEstimatedFeeMetric,
          value: _formatSats(workflow.estimatedFeeSats),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: colors.panelDecoration(
            color: colors.surfaceAlt,
            showShadow: false,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              workflow.unsignedPsbt,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.text,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          style: colors.outlinedButtonStyle(),
          onPressed: () => _copyText(
            context,
            workflow.unsignedPsbt,
            title: context.tr.bitcoinAdvancedPsbtCopiedTitle,
            message: context.tr.bitcoinAdvancedSignExternallyMessage,
          ),
          icon: const Icon(LucideIcons.copy, size: 18),
          label: Text(context.tr.bitcoinAdvancedCopyUnsignedPsbtAction),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final destination = _destinationController.text.trim();
    final amountSats = int.tryParse(_amountController.text.trim()) ?? 0;
    final feeRate = int.tryParse(_feeRateController.text.trim());

    if (destination.isEmpty || amountSats <= 0) {
      AppNotice.showWarning(
        context,
        title: context.tr.bitcoinAdvancedIncompleteDataTitle,
        message: context.tr.bitcoinAdvancedIncompleteDataMessage,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final created = await service.createColdWalletPsbt(
        coldWalletId: _coldWalletId,
        destinationAddress: destination,
        amountSats: amountSats,
        feeRate: feeRate,
        selectedUtxoIds: _selectedUtxoIds.toList(growable: false),
      );
      ref.invalidate(bitcoinColdWalletUtxosProvider(_coldWalletId));
      ref.invalidate(bitcoinColdWalletPsbtsProvider(_coldWalletId));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _created = created);
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAdvancedCreateFailedTitle,
        message: context.tr.bitcoinAdvancedCreateFailedMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
