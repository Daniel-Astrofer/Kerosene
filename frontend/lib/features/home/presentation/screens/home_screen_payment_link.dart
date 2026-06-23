// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'home_screen_dependencies.dart';
import 'home_screen.dart';

class HomeRealtimeBootstrap extends ConsumerWidget {
  const HomeRealtimeBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(balanceWebSocketServiceProvider);
    return const SizedBox.shrink();
  }
}

final homePaymentLinkPreviewProvider =
    FutureProvider.family<PaymentLink, String>((ref, linkId) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPaymentLink(linkId);
});

enum PaymentPayloadKind {
  empty,
  paymentLink,
  onChain,
  lightning,
  internal,
  invalid,
}

class PaymentPayloadDraft {
  final PaymentPayloadKind kind;
  final String normalizedPayload;
  final String title;
  final String destinationLabel;
  final String? supportingLabel;
  final String actionLabel;
  final double? amountBtc;
  final IconData icon;

  const PaymentPayloadDraft({
    required this.kind,
    required this.normalizedPayload,
    required this.title,
    required this.destinationLabel,
    required this.actionLabel,
    required this.icon,
    this.supportingLabel,
    this.amountBtc,
  });

  bool get canContinue =>
      kind != PaymentPayloadKind.empty && kind != PaymentPayloadKind.invalid;

  bool get isPaymentLink => kind == PaymentPayloadKind.paymentLink;

  String? get paymentLinkId => isPaymentLink
      ? QrPaymentParser.extractPaymentLinkId(normalizedPayload)
      : null;

  static PaymentPayloadDraft analyze(BuildContext context, String raw) {
    final l10n = context.tr;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.empty,
        normalizedPayload: '',
        title: l10n.homePendingLinkTitle,
        destinationLabel: l10n.homePendingLinkMessage,
        actionLabel: l10n.homePayloadActionContinue,
        icon: KeroseneIcons.onchain,
      );
    }

    final explicitLinkId = QrPaymentParser.extractPaymentLinkId(trimmed);
    if (explicitLinkId != null) {
      return paymentLink(context, explicitLinkId, normalizedPayload: trimmed);
    }

    final parsed = QrPaymentParser.decode(trimmed);
    final candidate = parsed?.preferredDestination ?? trimmed;
    if (isLightningPaymentPayload(candidate)) {
      final normalized = candidate.toLowerCase().startsWith('lightning:')
          ? candidate.substring(10).trim()
          : candidate;
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.lightning,
        normalizedPayload: normalized,
        title: l10n.homeLightningPaymentTitle,
        destinationLabel: _shortPaymentValue(normalized),
        supportingLabel:
            parsed?.message ?? parsed?.label ?? l10n.homeInvoiceOrLnurl,
        actionLabel: l10n.homePayloadActionContinueLightning,
        amountBtc: parsed?.amountBtc ?? extractLightningAmountBtc(normalized),
        icon: KeroseneIcons.lightning,
      );
    }

    if (isOnChainPaymentPayload(trimmed, candidate)) {
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.onChain,
        normalizedPayload: trimmed,
        title: l10n.homeOnchainPaymentTitle,
        destinationLabel: _shortPaymentValue(candidate),
        supportingLabel:
            parsed?.message ?? parsed?.label ?? l10n.homeBitcoinAddress,
        actionLabel: l10n.homePayloadActionContinueOnchain,
        amountBtc: parsed?.amountBtc,
        icon: KeroseneIcons.onchain,
      );
    }

    if (trimmed.toLowerCase().startsWith('kerosene:pay') &&
        parsed != null &&
        parsed.address.trim().isNotEmpty) {
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.internal,
        normalizedPayload: trimmed,
        title: l10n.homeInternalTransferTitle,
        destinationLabel: parsed.label?.trim().isNotEmpty == true
            ? parsed.label!.trim()
            : parsed.address.trim(),
        supportingLabel: parsed.address.trim(),
        actionLabel: l10n.homePayloadActionContinueInternal,
        amountBtc: parsed.amountBtc,
        icon: KeroseneIcons.internalTransfer,
      );
    }

    if (trimmed.startsWith('@') &&
        RegExp(r'^@[a-zA-Z0-9_]{3,30}$').hasMatch(trimmed)) {
      final username = trimmed.substring(1);
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.internal,
        normalizedPayload: username,
        title: l10n.homeInternalTransferTitle,
        destinationLabel: '@$username',
        supportingLabel: l10n.homeKeroseneUser,
        actionLabel: l10n.homePayloadActionContinueInternal,
        icon: KeroseneIcons.internalTransfer,
      );
    }

    if (RegExp(r'\s').hasMatch(trimmed)) {
      return PaymentPayloadDraft(
        kind: PaymentPayloadKind.invalid,
        normalizedPayload: '',
        title: l10n.homeInvalidLinkTitle,
        destinationLabel: l10n.homeInvalidLinkMessage,
        actionLabel: l10n.homePayloadActionContinue,
        icon: KeroseneIcons.warning,
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.isNotEmpty && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return paymentLink(context, last);
      }
    }

    return paymentLink(context, trimmed);
  }

  static PaymentPayloadDraft paymentLink(
    BuildContext context,
    String id, {
    String? normalizedPayload,
  }) {
    final l10n = context.tr;
    final normalizedId = id.trim();
    return PaymentPayloadDraft(
      kind: PaymentPayloadKind.paymentLink,
      normalizedPayload: normalizedPayload ?? 'kerosene:link:$normalizedId',
      title: l10n.homeInternalLinkTitle,
      destinationLabel: _shortPaymentValue(normalizedId),
      supportingLabel: l10n.homePaymentId,
      actionLabel: l10n.homePayloadActionLoadLink,
      icon: KeroseneIcons.onchain,
    );
  }
}

String _shortPaymentValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 34) {
    return trimmed;
  }
  return '${trimmed.substring(0, 18)}...${trimmed.substring(trimmed.length - 10)}';
}

class PaymentLinkEntryScreen extends ConsumerStatefulWidget {
  const PaymentLinkEntryScreen();

  @override
  ConsumerState<PaymentLinkEntryScreen> createState() =>
      PaymentLinkEntryScreenState();
}

class PaymentLinkEntryScreenState
    extends ConsumerState<PaymentLinkEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = PaymentPayloadDraft.analyze(context, _controller.text);
    final linkId = draft.paymentLinkId;
    final linkAsync = linkId == null
        ? null
        : ref.watch(homePaymentLinkPreviewProvider(linkId));
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    return ReceiveFlowScaffold(
      title: context.tr.homePaymentLinkTitle,
      subtitle: context.tr.homePaymentLinkSubtitle,
      bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                  child: ReceiveFlowSectionLabel(
                    context.tr.homePayloadLabel.toUpperCase(),
                  ),
                ),
                const Divider(height: 1, color: receiveFlowDividerColor),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  onChanged: (_) => setState(() {}),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: receiveFlowTextColor,
                        fontFamily: AppTypography.financialFontFamily,
                        height: 1.35,
                      ),
                  decoration: InputDecoration(
                    hintText: context.tr.homePayloadHint,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowFaintTextColor,
                          height: 1.35,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowSecondaryButton(
            label: context.tr.homePasteAction.toUpperCase(),
            icon: KeroseneIcons.paste,
            onTap: _pasteFromClipboard,
          ),
          const SizedBox(height: AppSpacing.xl),
          PaymentPayloadPreview(
            draft: draft,
            linkAsync: linkAsync,
            selectedCurrency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          ),
          const SizedBox(height: AppSpacing.xl),
          ReceiveFlowPrimaryButton(
            label: draft.actionLabel,
            icon: KeroseneIcons.next,
            onTap: draft.canContinue
                ? () => Navigator.of(context).pop(draft.normalizedPayload)
                : null,
          ),
        ],
      ),
    );
  }
}

class PaymentPayloadPreview extends StatelessWidget {
  final PaymentPayloadDraft draft;
  final AsyncValue<PaymentLink>? linkAsync;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const PaymentPayloadPreview({
    required this.draft,
    required this.linkAsync,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    final link = linkAsync?.asData?.value;
    final amountBtc = link?.amountBtc ?? draft.amountBtc;
    final amountLabel = amountBtc != null && amountBtc > 0
        ? MoneyDisplay.formatAmountFromBtc(
            btcAmount: amountBtc,
            currency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          )
        : draft.isPaymentLink
            ? context.tr.homeAmountFromLink
            : context.tr.homeAmountNotProvided;
    final destination = link?.isInternalPaymentRequest == true
        ? (link!.destinationHash?.trim().isNotEmpty == true
            ? _shortPaymentValue(link.destinationHash!)
            : context.tr.homeDestinationLocked)
        : draft.destinationLabel;
    final support = linkAsync?.isLoading == true
        ? context.tr.homeLoadingLinkData
        : linkAsync?.hasError == true
            ? context.tr.homeLinkValidationLater
            : link?.description.trim().isNotEmpty == true
                ? link!.description.trim()
                : draft.supportingLabel;

    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: receiveFlowPanelRaisedColor,
                  border: Border.all(color: receiveFlowBorderStrongColor),
                ),
                child: Icon(draft.icon, color: receiveFlowTextColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: receiveFlowTextColor,
                            fontWeight: FontWeight.w300,
                            height: 1.1,
                          ),
                    ),
                    if (support != null && support.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        support,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receiveFlowMutedTextColor,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PaymentPreviewRow(
            label: context.tr.homeNetworkLabel,
            value: _networkLabel(context, draft.kind),
          ),
          const ReceiveFlowDivider(),
          PaymentPreviewRow(
            label: context.tr.homeDestinationLabel,
            value: destination,
          ),
          const ReceiveFlowDivider(),
          PaymentPreviewRow(
            label: context.tr.homeAmountLabel,
            value: amountLabel,
          ),
        ],
      ),
    );
  }

  String _networkLabel(BuildContext context, PaymentPayloadKind kind) {
    return switch (kind) {
      PaymentPayloadKind.paymentLink => context.tr.homeNetworkInternal,
      PaymentPayloadKind.onChain => context.tr.homeNetworkOnchain,
      PaymentPayloadKind.lightning => context.tr.homeNetworkLightning,
      PaymentPayloadKind.internal => context.tr.homeNetworkInternal,
      PaymentPayloadKind.invalid => context.tr.homeNetworkInvalid,
      PaymentPayloadKind.empty => context.tr.homeNetworkWaiting,
    };
  }
}

class PaymentPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const PaymentPreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: receiveFlowFaintTextColor,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontFamily: value.length > 18
                        ? AppTypography.financialFontFamily
                        : AppTypography.bodyFontFamily,
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
