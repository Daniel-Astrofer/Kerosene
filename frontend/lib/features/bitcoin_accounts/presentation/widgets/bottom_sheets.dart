// ignore_for_file: unused_element

part of '../bitcoin_accounts_screen.dart';

/*
Roadmap-only PSBT submission UI intentionally removed from the active app graph.

class _SubmitPsbtSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;
  final PsbtWorkflowView workflow;

  const _SubmitPsbtSheet({
    required this.account,
    required this.workflow,
  });

  @override
  ConsumerState<_SubmitPsbtSheet> createState() => _SubmitPsbtSheetState();
}

class _SubmitPsbtSheetState extends ConsumerState<_SubmitPsbtSheet> {
  final TextEditingController _signedPsbtController = TextEditingController();
  bool _broadcast = true;
  bool _busy = false;
  PsbtWorkflowView? _result;

  String get _coldWalletId => _coldWalletIdForAccount(widget.account);

  @override
  void dispose() {
    _signedPsbtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return _SheetScaffold(
      title: result == null
          ? context.tr.bitcoinAdvancedSubmitPsbtTitle
          : context.tr.bitcoinAdvancedPsbtValidatedTitle,
      child: result == null ? _buildForm(context) : _buildResult(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(
          text: context.tr.bitcoinAdvancedSubmitPsbtIntro,
        ),
        const SizedBox(height: AppSpacing.md),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedDestinationMetric,
          value: _shortText(widget.workflow.destinationAddress),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedAmountMetric,
          value: _formatSats(widget.workflow.amountSats),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _signedPsbtController,
          minLines: 4,
          maxLines: 8,
          style: AppTypography.technicalMono(
            textStyle: TextStyle(
              color: colors.text,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
          decoration: colors.inputDecoration(
            label: context.tr.bitcoinAdvancedSignedPsbtLabel,
            hintText: context.tr.bitcoinAdvancedSignedPsbtHint,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile.adaptive(
          value: _broadcast,
          onChanged:
              _busy ? null : (value) => setState(() => _broadcast = value),
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr.bitcoinAdvancedBroadcastAfterValidationTitle,
            style: TextStyle(color: colors.text),
          ),
          subtitle: Text(
            context.tr.bitcoinAdvancedBroadcastAfterValidationSubtitle,
            style: TextStyle(color: colors.mutedText),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          style: colors.filledButtonStyle(),
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(KeroseneIcons.security, size: 18),
          label: Text(
            _busy
                ? context.tr.bitcoinAdvancedValidatingPsbtAction
                : context.tr.bitcoinAdvancedValidatePsbtAction,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final workflow = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: _psbtStatusLabel(context, workflow.status)),
        const SizedBox(height: AppSpacing.md),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedAmountMetric,
          value: _formatSats(workflow.amountSats),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedEstimatedFeeMetric,
          value: _formatSats(workflow.estimatedFeeSats),
        ),
        if ((workflow.broadcastTxidRef ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _MiniMetricRow(
            label: 'Broadcast',
            value: workflow.broadcastTxidRef!,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          style: colors.filledButtonStyle(),
          onPressed: () => Navigator.maybePop(context),
          child: Text(context.tr.bitcoinAdvancedDoneAction),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final signedPsbt = _signedPsbtController.text.trim();
    if (signedPsbt.isEmpty) {
      AppNotice.showWarning(
        context,
        title: context.tr.bitcoinAdvancedSignatureRequiredTitle,
        message: context.tr.bitcoinAdvancedSignatureRequiredMessage,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final result = await service.submitSignedPsbt(
        workflowId: widget.workflow.id,
        signedPsbt: signedPsbt,
        broadcast: _broadcast,
      );
      ref.invalidate(bitcoinColdWalletUtxosProvider(_coldWalletId));
      ref.invalidate(bitcoinColdWalletPsbtsProvider(_coldWalletId));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAdvancedPsbtRejectedTitle,
        message: context.tr.bitcoinAdvancedPsbtRejectedMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
*/

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colors = BitcoinAccountsColors.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          18,
          responsive.horizontalPadding,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.sheetMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontSize: responsive.compactFontSize(
                          tiny: 18,
                          compact: 19,
                          regular: 20,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: colors.pillRadius,
        border: Border.all(color: colors.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  final String text;

  const _MutedPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: colors.panelDecoration(
        color: colors.surfaceAlt,
        showShadow: false,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.mutedText, height: 1.4),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: colors.panelDecoration(),
      child: Column(
        children: [
          _IconFrame(icon: icon),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: colors.filledButtonStyle(),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  final IconData icon;

  const _IconFrame({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: colors.iconRadius,
        border: Border.all(color: colors.borderStrong),
      ),
      child: Icon(icon, color: colors.text, size: 19),
    );
  }
}

class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: colors.panelDecoration(),
          ),
      ],
    );
  }
}

enum _ColdWalletStep { purpose, prepare, backup, verify }

enum _ColdWalletLevel {
  essential,
  recommended,
  maximum;

  int get wordCount => this == essential ? 12 : 24;
  bool get usesExtraWord => this == maximum;

  String title(BuildContext context) {
    return switch (this) {
      essential => context.tr.coldWalletLevelEssentialTitle,
      recommended => context.tr.coldWalletLevelRecommendedTitle,
      maximum => context.tr.coldWalletLevelMaximumTitle,
    };
  }

  String body(BuildContext context) {
    return switch (this) {
      essential => context.tr.coldWalletLevelEssentialBody,
      recommended => context.tr.coldWalletLevelRecommendedBody,
      maximum => context.tr.coldWalletLevelMaximumBody,
    };
  }
}

String _expiryLabel(BuildContext context, String value) {
  return switch (value) {
    '15M' => context.tr.receive15Min,
    '1H' => context.tr.receive1Hour,
    '24H' => context.tr.receive24Hours,
    'PERMANENT' => context.tr.receiveNoExpiration,
    _ => value,
  };
}

String _receiveStatusLabel(BuildContext context, String status) {
  return switch (status) {
    'ACTIVE' => context.tr.bitcoinReceiveStatusActive,
    'MEMPOOL_SEEN' => context.tr.bitcoinReceiveStatusDetected,
    'CONFIRMING' => context.tr.bitcoinReceiveStatusConfirming,
    'PAID' => context.tr.bitcoinReceiveStatusPaid,
    'EXPIRED' => context.tr.bitcoinReceiveStatusExpired,
    'EXPIRED_RECEIVED' => context.tr.bitcoinReceiveStatusLate,
    'AUTO_RESOLUTION_PENDING' => context.tr.bitcoinReceiveStatusReview,
    'USER_ACTION_REQUIRED' => context.tr.bitcoinReceiveStatusAction,
    'FAILED_SAFE' => context.tr.bitcoinReceiveStatusProtected,
    _ => context.tr.bitcoinReceiveStatusWaiting,
  };
}

String _receiveStatusMessage(
  BuildContext context,
  ReceivingRequestView request,
) {
  return switch (request.status) {
    'ACTIVE' => context.tr.bitcoinReceiveMessageActive,
    'MEMPOOL_SEEN' => context.tr.bitcoinReceiveMessageDetected,
    'CONFIRMING' => context.tr.bitcoinReceiveMessageConfirming,
    'PAID' => context.tr.bitcoinReceiveMessagePaid,
    'EXPIRED' => context.tr.bitcoinReceiveMessageExpired,
    'EXPIRED_RECEIVED' => context.tr.bitcoinReceiveMessageLate,
    'AUTO_RESOLUTION_PENDING' => context.tr.bitcoinReceiveMessageReview,
    'USER_ACTION_REQUIRED' => context.tr.bitcoinReceiveMessageAction,
    'FAILED_SAFE' => context.tr.bitcoinReceiveMessageProtected,
    _ => context.tr.bitcoinReceiveMessageWaiting,
  };
}

List<Transaction> _transactionsForAccount({
  required BitcoinAccount account,
  required List<Transaction> transactions,
  required List<ReceivingRequestView> requests,
}) {
  final keys = <String>{
    account.id,
    account.cardId ?? '',
    account.coldWalletId ?? '',
    account.label,
    account.xpubFingerprint ?? '',
    for (final request in requests) request.address,
    for (final request in requests) request.bip21,
  }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();

  if (keys.isEmpty) return const [];

  bool matches(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return keys.any((key) => normalized == key || normalized.contains(key));
  }

  final rows = transactions.where((tx) {
    return matches(tx.fromAddress) ||
        matches(tx.toAddress) ||
        matches(tx.description ?? '') ||
        matches(tx.externalReference ?? '') ||
        matches(tx.invoiceId ?? '') ||
        matches(tx.paymentHash ?? '');
  }).toList();
  rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return rows;
}

String _cardExpiryLabel(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.codeUnits.fold<int>(0, (value, unit) => value + unit);
  final month = (hash % 12) + 1;
  final year = 29 + (hash % 5);
  return '${month.toString().padLeft(2, '0')}/$year';
}

String _shortText(String value) {
  final text = value.trim();
  if (text.length <= 18) return text;
  return '${text.substring(0, 8)}...${text.substring(text.length - 8)}';
}

String _cardCode(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.hashCode.abs() % 1000;
  return hash.toString().padLeft(3, '0');
}

String _shortCardIdentifier(BitcoinAccount account) {
  final source = (account.cardId ?? account.id).replaceAll('-', '');
  if (source.length <= 20) return source;
  return source.substring(0, 20);
}

String _transactionTitle(Transaction transaction) {
  if (transaction.isLightning) return 'Lightning';
  if (transaction.isInternal) return 'Kerosene';
  return switch (transaction.type) {
    TransactionType.receive || TransactionType.deposit => 'Recebimento',
    TransactionType.send || TransactionType.withdrawal => 'Envio',
    TransactionType.fee => 'Taxa',
    TransactionType.swap => 'Swap',
  };
}

String _relativeTransactionDate(DateTime timestamp) {
  final now = DateTime.now();
  final local = timestamp.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';
  if (difference < 7) {
    return switch (local.weekday) {
      DateTime.monday => 'Segunda',
      DateTime.tuesday => 'Terça',
      DateTime.wednesday => 'Quarta',
      DateTime.thursday => 'Quinta',
      DateTime.friday => 'Sexta',
      DateTime.saturday => 'Sábado',
      _ => 'Domingo',
    };
  }
  final year = local.year.toString().substring(2);
  final month = local.month.toString().padLeft(2, '0');
  return '${local.day}/$month/$year';
}

String _signedSats(Transaction transaction) {
  final isIncoming = transaction.type == TransactionType.receive ||
      transaction.type == TransactionType.deposit;
  final sign = isIncoming ? '+' : '-';
  return '$sign${_formatSats(transaction.amountSatoshis)}';
}

String _coldWalletIdForAccount(BitcoinAccount account) {
  final coldWalletId = account.coldWalletId?.trim();
  return coldWalletId == null || coldWalletId.isEmpty
      ? account.id
      : coldWalletId;
}

Future<void> _copyText(
  BuildContext context,
  String value, {
  required String title,
  required String message,
}) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  AppNotice.showSuccess(context, title: title, message: message);
}

String _utxoStatusLabel(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'UNSPENT' => context.tr.bitcoinAdvancedUtxoStatusUnspent,
    'LOCKED' => context.tr.bitcoinAdvancedUtxoStatusLocked,
    'SPENT' => context.tr.bitcoinAdvancedUtxoStatusSpent,
    _ => status,
  };
}

String _psbtStatusLabel(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'DRAFT' => context.tr.bitcoinAdvancedPsbtStatusDraft,
    'UNSIGNED_CREATED' => context.tr.bitcoinAdvancedPsbtStatusUnsignedCreated,
    'WAITING_EXTERNAL_SIGNATURE' =>
      context.tr.bitcoinAdvancedPsbtStatusWaitingSignature,
    'VALIDATED' => context.tr.bitcoinAdvancedPsbtStatusValidated,
    'BROADCASTED' => context.tr.bitcoinAdvancedPsbtStatusBroadcasted,
    'REJECTED_TAMPERED' => context.tr.bitcoinAdvancedPsbtStatusRejectedTampered,
    'REJECTED_POLICY' => context.tr.bitcoinAdvancedPsbtStatusRejectedPolicy,
    'FAILED_SAFE' => context.tr.bitcoinAdvancedPsbtStatusFailedSafe,
    _ => status,
  };
}

String _taxEventTypeLabel(BuildContext context, String eventType) {
  return switch (eventType.trim().toUpperCase()) {
    'DEPOSIT_INTERNAL' => context.tr.bitcoinTaxEventDepositInternal,
    'DEPOSIT_EXTERNAL' => context.tr.bitcoinTaxEventDepositExternal,
    'WITHDRAWAL' => context.tr.bitcoinTaxEventWithdrawal,
    'SPEND' => context.tr.bitcoinTaxEventSpend,
    'FEE' => context.tr.bitcoinTaxEventFee,
    _ => eventType,
  };
}

String _taxClassificationLabel(BuildContext context, String classification) {
  return switch (classification.trim().toUpperCase()) {
    'SELF_TRANSFER' => context.tr.bitcoinTaxClassSelfTransfer,
    'THIRD_PARTY_DEPOSIT' => context.tr.bitcoinTaxClassThirdPartyDeposit,
    'SPEND' => context.tr.bitcoinTaxClassSpend,
    'FEE' => context.tr.bitcoinTaxClassFee,
    'UNKNOWN' => context.tr.bitcoinTaxClassUnknown,
    _ => context.tr.bitcoinTaxClassPending,
  };
}

String _formatSats(int sats) {
  final btc = sats / 100000000;
  return '${btc.toStringAsFixed(8)} BTC';
}

String _accountCardIdentifier(BitcoinAccount account) {
  final candidates = [
    if (account.isWatchOnly) account.xpubFingerprint,
    if (account.isWatchOnly) account.coldWalletId,
    account.cardId,
    account.xpubFingerprint,
    account.coldWalletId,
    account.id,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _accountCustodyLabel(BuildContext context, BitcoinAccount account) {
  if (account.isWatchOnly) return context.tr.bitcoinAccountsColdWalletBadge;
  if (account.isCustodialOnchain) {
    return context.tr.bitcoinAccountsCustodyOnchainTitle;
  }
  return context.tr.bitcoinAccountsKeroseneCardBadge;
}

String _accountTypeLabel(BuildContext context, BitcoinAccount account) {
  final description = account.walletTypeDescription.trim();
  if (description.isNotEmpty) return description;
  if (account.isWatchOnly) {
    return context.tr.bitcoinAccountsCustodyWatchOnlyTitle;
  }
  if (account.isCustodialOnchain) {
    return context.tr.bitcoinAccountsCustodyOnchainTitle;
  }
  return context.tr.bitcoinAccountsCustodyInternalTitle;
}

int _accountVisibleBalance(BitcoinAccount account) {
  if (account.isWatchOnly) return account.observedBalanceSats;
  return account.totalSats;
}

bool _hasPublicMaterial(BitcoinAccount account) {
  return account.isWatchOnly ||
      account.isCustodialOnchain ||
      (account.xpubFingerprint ?? '').trim().isNotEmpty ||
      (account.derivationPath ?? '').trim().isNotEmpty ||
      (account.scriptPolicy ?? '').trim().isNotEmpty;
}

String _displayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Não informado' : trimmed;
}

String _historyDetail(Transaction transaction) {
  final candidates = [
    transaction.blockchainTxid,
    transaction.externalReference,
    transaction.isDebit ? transaction.toAddress : transaction.fromAddress,
    transaction.invoiceId,
    transaction.paymentHash,
    transaction.id,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return _shortText(value);
  }
  return 'Movimento Bitcoin';
}

String _historyTimestampLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year}\n$hour:$minute';
}

String _transactionStatusLabel(
  BuildContext context,
  TransactionStatus status,
) {
  return switch (status) {
    TransactionStatus.pending => context.tr.bitcoinReceiveStatusWaiting,
    TransactionStatus.confirming => context.tr.bitcoinReceiveStatusConfirming,
    TransactionStatus.confirmed => context.tr.bitcoinReceiveStatusPaid,
    TransactionStatus.failed => context.tr.bitcoinReceiveStatusProtected,
  };
}
