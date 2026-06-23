import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/bitcoin_network.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';
import 'package:kerosene/features/send/presentation/send/send_money_copy.dart';
import 'package:kerosene/features/send/presentation/widgets/internal_recent_avatar.dart';

class SendDestinationStep extends StatelessWidget {
  final TextEditingController receiverController;
  final SendDestinationAnalysis analysis;
  final List<RecentTransactionDestination> recentDestinations;
  final bool isLoading;
  final VoidCallback onDestinationChanged;
  final VoidCallback onScan;
  final VoidCallback onContinue;
  final ValueChanged<RecentTransactionDestination> onRecentDestinationSelected;

  const SendDestinationStep({
    super.key,
    required this.receiverController,
    required this.analysis,
    required this.recentDestinations,
    required this.isLoading,
    required this.onDestinationChanged,
    required this.onScan,
    required this.onContinue,
    required this.onRecentDestinationSelected,
  });

  static const internalBlack = KeroseneBrandTokens.background;
  static const internalSurfaceHigh = KeroseneBrandTokens.surfaceHigh;
  static const internalBorder = KeroseneBrandTokens.border;
  static const internalText = KeroseneBrandTokens.textPrimary;
  static const internalMutedText = KeroseneBrandTokens.textMuted;

  @override
  Widget build(BuildContext context) {
    final destination = receiverController.text.trim();
    final isValidDestination = analysis.isValid;
    final hasContacts = recentDestinations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              hasContacts ? 24 : 30,
              24,
              hasContacts ? 28 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DestinationHeader(hasContacts: hasContacts),
                    SizedBox(height: hasContacts ? 32 : 26),
                    _DestinationInputSection(
                      controller: receiverController,
                      analysis: analysis,
                      isLoading: isLoading,
                      largeLabel: !hasContacts,
                      onChanged: onDestinationChanged,
                      onScan: onScan,
                    ),
                    if (destination.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _destinationHelperText(analysis),
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isValidDestination
                                  ? internalMutedText
                                  : internalText,
                              height: 1.35,
                            ),
                      ),
                    ],
                    if (recentDestinations.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _FrequentContactsSection(
                        destinations:
                            recentDestinations.take(3).toList(growable: false),
                        onSelected: onRecentDestinationSelected,
                      ),
                      const SizedBox(height: 36),
                      _AllContactsSection(
                        destinations: recentDestinations,
                        onSelected: onRecentDestinationSelected,
                      ),
                    ] else ...[
                      const SizedBox(height: 42),
                      const _EmptyContactsState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        _DestinationBottomAction(
          hasContacts: hasContacts,
          enabled: isValidDestination,
          isLoading: isLoading,
          onTap: onContinue,
        ),
      ],
    );
  }

  String _destinationHelperText(SendDestinationAnalysis analysis) {
    if (analysis.isEmpty) {
      return 'Informe o destino para continuar.';
    }
    if (analysis.isInvalid) {
      return 'Não reconhecemos este destino. Use usuário Kerosene, endereço Bitcoin, invoice Lightning, link, QR ou NFC.';
    }
    if (analysis.isPaymentLink) {
      return 'Link de pagamento Kerosene detectado.';
    }
    if (analysis.isInternal) {
      return 'Transferência interna Kerosene detectada.';
    }
    if (analysis.isOnChain) {
      final network =
          bitcoinNetworkDisplayName(analysis.detectedOnchainNetwork);
      return 'Endereço Bitcoin on-chain detectado • $network.';
    }
    if (analysis.isLightning) {
      return 'Pagamento Lightning detectado.';
    }
    return '';
  }
}

class _DestinationHeader extends StatelessWidget {
  final bool hasContacts;

  const _DestinationHeader({required this.hasContacts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: context.tr.close,
            icon: const Icon(KeroseneIcons.close, size: 24),
            color: SendDestinationStep.internalText,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        SizedBox(height: hasContacts ? 18 : 20),
        Text(
          SendMoneyCopy.destinationTitle(context),
          textAlign: TextAlign.left,
          style: AppTypography.newsreader(
            color: SendDestinationStep.internalText,
            fontSize: hasContacts ? 30 : 28,
            fontWeight: hasContacts ? FontWeight.w700 : FontWeight.w500,
            height: hasContacts ? 1.12 : 1.2,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DestinationBottomAction extends StatelessWidget {
  final bool hasContacts;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLoading;

  const _DestinationBottomAction({
    required this.hasContacts,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final actionEnabled = enabled && !isLoading;
    final backgroundColor = !actionEnabled
        ? SendDestinationStep.internalSurfaceHigh.withValues(alpha: 0.64)
        : hasContacts
            ? SendDestinationStep.internalSurfaceHigh
            : SendDestinationStep.internalText;
    final foregroundColor = !actionEnabled
        ? SendDestinationStep.internalMutedText
        : hasContacts
            ? SendDestinationStep.internalText
            : SendDestinationStep.internalBlack;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        color: SendDestinationStep.internalBlack,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: actionEnabled ? onTap : null,
            style: FilledButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(hasContacts ? 8 : 28),
              ),
              textStyle: AppTypography.inter(
                fontSize: hasContacts ? 14 : 11,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: hasContacts ? 1.4 : 1.1,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr.continueButton),
          ),
        ),
      ),
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  const _EmptyContactsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SendDestinationStep.internalSurfaceHigh,
            ),
            child: const Center(
              child: Icon(
                KeroseneIcons.userAdd,
                color: SendDestinationStep.internalMutedText,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            SendMoneyCopy.noRecentDestinations(context),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: SendDestinationStep.internalText,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SendMoneyCopy.noRecentDestinationsBody(context),
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: SendDestinationStep.internalMutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationInputSection extends StatefulWidget {
  final TextEditingController controller;
  final SendDestinationAnalysis analysis;
  final bool isLoading;
  final bool largeLabel;
  final VoidCallback onChanged;
  final VoidCallback onScan;

  const _DestinationInputSection({
    required this.controller,
    required this.analysis,
    required this.isLoading,
    required this.largeLabel,
    required this.onChanged,
    required this.onScan,
  });

  @override
  State<_DestinationInputSection> createState() =>
      _DestinationInputSectionState();
}

class _DestinationInputSectionState extends State<_DestinationInputSection> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final activeElementColor = _hasFocus
        ? SendDestinationStep.internalText
        : SendDestinationStep.internalMutedText;
    final borderColor = widget.analysis.isInvalid
        ? SendDestinationStep.internalText
        : widget.isLoading || _hasFocus
            ? activeElementColor
            : SendDestinationStep.internalBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.largeLabel ? 8 : 0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: (_) => widget.onChanged(),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                cursorColor: SendDestinationStep.internalText,
                textAlign: TextAlign.left,
                style: AppTypography.inter(
                  color: SendDestinationStep.internalText,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  hintText:
                      _hasFocus ? null : SendMoneyCopy.destinationHint(context),
                  hintStyle: AppTypography.inter(
                    color: activeElementColor.withValues(alpha: 0.55),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: KeroseneMotion.short,
              child: widget.isLoading
                  ? SizedBox(
                      key: const ValueKey('destination-loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: activeElementColor,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('destination-loading-empty'),
                      width: 18,
                      height: 18,
                    ),
            ),
            IconButton(
              onPressed: widget.onScan,
              tooltip: context.tr.scanQR,
              icon: const Icon(KeroseneIcons.scanner, size: 24),
              color: activeElementColor,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: KeroseneMotion.short,
          margin: const EdgeInsets.only(top: 8),
          height: 1,
          color: borderColor,
        ),
      ],
    );
  }
}

class _FrequentContactsSection extends StatelessWidget {
  final List<RecentTransactionDestination> destinations;
  final ValueChanged<RecentTransactionDestination> onSelected;

  const _FrequentContactsSection({
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SendMoneyCopy.frequentDestinations(context),
          style: AppTypography.inter(
            color: SendDestinationStep.internalMutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 126,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _FrequentContact(
                destination: destinations[index],
                onSelected: onSelected,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemCount: destinations.length,
          ),
        ),
      ],
    );
  }
}

class _FrequentContact extends StatelessWidget {
  final RecentTransactionDestination destination;
  final ValueChanged<RecentTransactionDestination> onSelected;

  const _FrequentContact({required this.destination, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final title = recentInternalDestinationTitle(destination);
    final subtitle = recentInternalDestinationSubtitle(destination);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelected(destination),
        child: SizedBox(
          width: 104,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                InternalRecentAvatar(title: title, size: 64, fontSize: 18),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SendDestinationStep.internalText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SendDestinationStep.internalMutedText,
                        fontSize: 11,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllContactsSection extends StatelessWidget {
  final List<RecentTransactionDestination> destinations;
  final ValueChanged<RecentTransactionDestination> onSelected;

  const _AllContactsSection(
      {required this.destinations, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SendMoneyCopy.allDestinations(context),
          style: AppTypography.inter(
            color: SendDestinationStep.internalMutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 24),
        for (final destination in destinations)
          _RecentDestinationRow(
            destination: destination,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _RecentDestinationRow extends StatelessWidget {
  final RecentTransactionDestination destination;
  final ValueChanged<RecentTransactionDestination> onSelected;

  const _RecentDestinationRow(
      {required this.destination, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final title = recentInternalDestinationTitle(destination);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SendDestinationStep.internalText.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(destination),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                InternalRecentAvatar(title: title, size: 48, fontSize: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.newsreader(
                      color: SendDestinationStep.internalText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
