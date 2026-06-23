// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import '../bitcoin_accounts_dependencies.dart';
import '../bitcoin_accounts_screen.dart';

/*
Roadmap-only PSBT submission UI intentionally removed from the active app graph.

class SubmitPsbtSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;
  final PsbtWorkflowView workflow;

  const SubmitPsbtSheet({
    required this.account,
    required this.workflow,
  });

  @override
  ConsumerState<SubmitPsbtSheet> createState() => SubmitPsbtSheetState();
}

class SubmitPsbtSheetState extends ConsumerState<SubmitPsbtSheet> {
  final TextEditingController signedPsbtController = TextEditingController();
  bool broadcast = true;
  bool busy = false;
  PsbtWorkflowView? result;

  String get coldWalletId => coldWalletIdForAccount(widget.account);

  @override
  void dispose() {
    signedPsbtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = result;
    return SheetScaffold(
      title: result == null
          ? context.tr.bitcoinAdvancedSubmitPsbtTitle
          : context.tr.bitcoinAdvancedPsbtValidatedTitle,
      child: result == null ? buildForm(context) : buildResult(context),
    );
  }

  Widget buildForm(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MutedPanel(
          text: context.tr.bitcoinAdvancedSubmitPsbtIntro,
        ),
        const SizedBox(height: AppSpacing.md),
        MiniMetricRow(
          label: context.tr.bitcoinAdvancedDestinationMetric,
          value: shortText(widget.workflow.destinationAddress),
        ),
        const SizedBox(height: AppSpacing.sm),
        MiniMetricRow(
          label: context.tr.bitcoinAdvancedAmountMetric,
          value: formatSats(widget.workflow.amountSats),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: signedPsbtController,
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
          value: broadcast,
          onChanged:
              busy ? null : (value) => setState(() => broadcast = value),
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
          onPressed: busy ? null : submit,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(KeroseneIcons.security, size: 18),
          label: Text(
            busy
                ? context.tr.bitcoinAdvancedValidatingPsbtAction
                : context.tr.bitcoinAdvancedValidatePsbtAction,
          ),
        ),
      ],
    );
  }

  Widget buildResult(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final workflow = result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MutedPanel(text: psbtStatusLabel(context, workflow.status)),
        const SizedBox(height: AppSpacing.md),
        MiniMetricRow(
          label: context.tr.bitcoinAdvancedAmountMetric,
          value: formatSats(workflow.amountSats),
        ),
        const SizedBox(height: AppSpacing.sm),
        MiniMetricRow(
          label: context.tr.bitcoinAdvancedEstimatedFeeMetric,
          value: formatSats(workflow.estimatedFeeSats),
        ),
        if ((workflow.broadcastTxidRef ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MiniMetricRow(
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

  Future<void> submit() async {
    final signedPsbt = signedPsbtController.text.trim();
    if (signedPsbt.isEmpty) {
      AppNotice.showWarning(
        context,
        title: context.tr.bitcoinAdvancedSignatureRequiredTitle,
        message: context.tr.bitcoinAdvancedSignatureRequiredMessage,
      );
      return;
    }

    setState(() => busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final result = await service.submitSignedPsbt(
        workflowId: widget.workflow.id,
        signedPsbt: signedPsbt,
        broadcast: broadcast,
      );
      ref.invalidate(bitcoinColdWalletUtxosProvider(coldWalletId));
      ref.invalidate(bitcoinColdWalletPsbtsProvider(coldWalletId));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => result = result);
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAdvancedPsbtRejectedTitle,
        message: context.tr.bitcoinAdvancedPsbtRejectedMessage,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
*/

class SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const SheetScaffold({required this.title, required this.child});

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

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text);

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

class Pill extends StatelessWidget {
  final String text;

  const Pill({required this.text});

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

class MutedPanel extends StatelessWidget {
  final String text;

  const MutedPanel({required this.text});

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

class StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const StatePanel({
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
          IconFrame(icon: icon),
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

class IconFrame extends StatelessWidget {
  final IconData icon;

  const IconFrame({required this.icon});

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

class AccountsSkeleton extends StatelessWidget {
  const AccountsSkeleton();

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

enum ColdWalletStep { purpose, prepare, backup, verify }

enum ColdWalletLevel {
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

String expiryLabel(BuildContext context, String value) {
  return switch (value) {
    '15M' => context.tr.receive15Min,
    '1H' => context.tr.receive1Hour,
    '24H' => context.tr.receive24Hours,
    'PERMANENT' => context.tr.receiveNoExpiration,
    _ => value,
  };
}

String receiveStatusLabel(BuildContext context, String status) {
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

String receiveStatusMessage(
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

List<Transaction> transactionsForAccount({
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

String cardExpiryLabel(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.codeUnits.fold<int>(0, (value, unit) => value + unit);
  final month = (hash % 12) + 1;
  final year = 29 + (hash % 5);
  return '${month.toString().padLeft(2, '0')}/$year';
}

String shortText(String value) {
  final text = value.trim();
  if (text.length <= 18) return text;
  return '${text.substring(0, 8)}...${text.substring(text.length - 8)}';
}

String cardCode(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.hashCode.abs() % 1000;
  return hash.toString().padLeft(3, '0');
}

String shortCardIdentifier(BitcoinAccount account) {
  final source = (account.cardId ?? account.id).replaceAll('-', '');
  if (source.length <= 20) return source;
  return source.substring(0, 20);
}

String transactionTitle(Transaction transaction) {
  if (transaction.isLightning) return 'Lightning';
  if (transaction.isInternal) return 'Kerosene';
  return switch (transaction.type) {
    TransactionType.receive || TransactionType.deposit => 'Recebimento',
    TransactionType.send || TransactionType.withdrawal => 'Envio',
    TransactionType.fee => 'Taxa',
    TransactionType.swap => 'Swap',
  };
}

String relativeTransactionDate(DateTime timestamp) {
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

String signedSats(Transaction transaction) {
  final isIncoming = transaction.type == TransactionType.receive ||
      transaction.type == TransactionType.deposit;
  final sign = isIncoming ? '+' : '-';
  return '$sign${formatSats(transaction.amountSatoshis)}';
}

String coldWalletIdForAccount(BitcoinAccount account) {
  final coldWalletId = account.coldWalletId?.trim();
  return coldWalletId == null || coldWalletId.isEmpty
      ? account.id
      : coldWalletId;
}

Future<void> copyText(
  BuildContext context,
  String value, {
  required String title,
  required String message,
}) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  AppNotice.showSuccess(context, title: title, message: message);
}

String utxoStatusLabel(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'UNSPENT' => context.tr.bitcoinAdvancedUtxoStatusUnspent,
    'LOCKED' => context.tr.bitcoinAdvancedUtxoStatusLocked,
    'SPENT' => context.tr.bitcoinAdvancedUtxoStatusSpent,
    _ => status,
  };
}

String psbtStatusLabel(BuildContext context, String status) {
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

String taxEventTypeLabel(BuildContext context, String eventType) {
  return switch (eventType.trim().toUpperCase()) {
    'DEPOSIT_INTERNAL' => context.tr.bitcoinTaxEventDepositInternal,
    'DEPOSIT_EXTERNAL' => context.tr.bitcoinTaxEventDepositExternal,
    'WITHDRAWAL' => context.tr.bitcoinTaxEventWithdrawal,
    'SPEND' => context.tr.bitcoinTaxEventSpend,
    'FEE' => context.tr.bitcoinTaxEventFee,
    _ => eventType,
  };
}

String taxClassificationLabel(BuildContext context, String classification) {
  return switch (classification.trim().toUpperCase()) {
    'SELF_TRANSFER' => context.tr.bitcoinTaxClassSelfTransfer,
    'THIRD_PARTY_DEPOSIT' => context.tr.bitcoinTaxClassThirdPartyDeposit,
    'SPEND' => context.tr.bitcoinTaxClassSpend,
    'FEE' => context.tr.bitcoinTaxClassFee,
    'UNKNOWN' => context.tr.bitcoinTaxClassUnknown,
    _ => context.tr.bitcoinTaxClassPending,
  };
}

String formatSats(int sats) {
  final btc = sats / 100000000;
  return '${btc.toStringAsFixed(8)} BTC';
}

String accountCardIdentifier(BitcoinAccount account) {
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

String accountCustodyLabel(BuildContext context, BitcoinAccount account) {
  if (account.isWatchOnly) return context.tr.bitcoinAccountsColdWalletBadge;
  if (account.isCustodialOnchain) {
    return context.tr.bitcoinAccountsCustodyOnchainTitle;
  }
  return context.tr.bitcoinAccountsKeroseneCardBadge;
}

String accountTypeLabel(BuildContext context, BitcoinAccount account) {
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

int accountVisibleBalance(BitcoinAccount account) {
  if (account.isWatchOnly) return account.observedBalanceSats;
  return account.totalSats;
}

bool hasPublicMaterial(BitcoinAccount account) {
  return account.isWatchOnly ||
      account.isCustodialOnchain ||
      (account.xpubFingerprint ?? '').trim().isNotEmpty ||
      (account.derivationPath ?? '').trim().isNotEmpty ||
      (account.scriptPolicy ?? '').trim().isNotEmpty;
}

String displayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Não informado' : trimmed;
}

String historyDetail(Transaction transaction) {
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
    if (value.isNotEmpty) return shortText(value);
  }
  return 'Movimento Bitcoin';
}

String historyTimestampLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year}\n$hour:$minute';
}

String transactionStatusLabel(
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
