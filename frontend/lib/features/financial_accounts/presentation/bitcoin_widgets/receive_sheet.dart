// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'package:kerosene/core/errors/exceptions.dart';

import '../bitcoin_accounts_dependencies.dart';
import '../bitcoin_accounts_screen.dart';
import 'bottom_sheets.dart';

class ReceiveSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;

  const ReceiveSheet({required this.account});

  @override
  ConsumerState<ReceiveSheet> createState() => ReceiveSheetState();
}

class ReceiveSheetState extends ConsumerState<ReceiveSheet> {
  final TextEditingController amount = TextEditingController();
  String expiry = '1H';
  bool oneTime = true;
  bool busy = false;
  ReceivingRequestView? result;
  Timer? poller;

  @override
  void dispose() {
    poller?.cancel();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: context.tr.bitcoinReceiveTitle,
      child: result == null ? buildForm(context) : buildLiveRequest(context),
    );
  }

  Widget buildForm(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        TextField(
          controller: amount,
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
                label: Text(expiryLabel(context, option)),
                selected: expiry == option,
                onSelected: (_) => setState(() => expiry = option),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          value: oneTime,
          onChanged: (value) => setState(() => oneTime = value),
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
            onPressed: busy ? null : createReceiveRequest,
            icon: const Icon(KeroseneIcons.qr, size: 18),
            label: Text(
              busy
                  ? context.tr.bitcoinReceiveGenerating
                  : context.tr.bitcoinReceiveGenerateAddress,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLiveRequest(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final currentResult = result!;
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
              data: currentResult.bip21.trim().isNotEmpty
                  ? currentResult.bip21
                  : 'bitcoin:${currentResult.address}',
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BitcoinAddressBlocks(
          address: currentResult.address,
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
            Pill(text: receiveStatusLabel(context, currentResult.status)),
            if (currentResult.amountSats != null)
              Pill(text: formatSats(currentResult.amountSats!)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MutedPanel(text: receiveStatusMessage(context, currentResult)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = constraints.maxWidth < 360;
            final buttons = [
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(),
                onPressed: busy ? null : copyAddress,
                icon: const Icon(KeroseneIcons.copy, size: 18),
                label: Text(context.tr.copyAddress),
              ),
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(),
                onPressed: busy ? null : () => refreshStatus(silent: false),
                icon: const Icon(KeroseneIcons.refresh, size: 18),
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

  Future<void> createReceiveRequest() async {
    setState(() => busy = true);
    try {
      final parsed = int.tryParse(amount.text.trim());
      final service = ref.read(bitcoinAccountsServiceProvider);
      final created = await service.createReceiveRequest(
        accountId: widget.account.id,
        amountSats: parsed != null && parsed > 0 ? parsed : null,
        expiry: expiry,
        oneTime: oneTime,
      );
      if (!mounted) return;
      ref.invalidate(bitcoinAccountReceiveRequestsProvider(widget.account.id));
      setState(() => result = created);
      startPolling();
    } catch (error) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinReceiveCreateErrorTitle,
        message: receiveCreateErrorMessage(context, error),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String receiveCreateErrorMessage(BuildContext context, Object error) {
    if (error is AppException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return context.tr.bitcoinReceiveCreateErrorMessage;
  }

  Future<void> refreshStatus({required bool silent}) async {
    final current = result;
    if (current == null || busy) return;
    if (!silent) setState(() => busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final updated = await service.getReceiveStatus(current.id);
      if (!mounted) return;
      setState(() => result = updated);
      if (isTerminal(updated.status)) {
        poller?.cancel();
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
      if (!silent && mounted) setState(() => busy = false);
    }
  }

  Future<void> copyAddress() async {
    final currentResult = result;
    if (currentResult == null) return;
    await Clipboard.setData(ClipboardData(text: currentResult.address));
    if (!mounted) return;
    AppNotice.showSuccess(
      context,
      title: context.tr.bitcoinReceiveCopiedTitle,
      message: context.tr.bitcoinReceiveCopiedMessage,
    );
  }

  void startPolling() {
    poller?.cancel();
    poller = Timer.periodic(
      KeroseneMotion.notificationHold,
      (_) => refreshStatus(silent: true),
    );
  }

  bool isTerminal(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'PAID' ||
        normalized == 'EXPIRED' ||
        normalized == 'HIDDEN' ||
        normalized == 'CANCELLED';
  }
}
