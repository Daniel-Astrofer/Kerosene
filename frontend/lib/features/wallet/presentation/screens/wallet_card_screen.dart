import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/l10n/l10n_extension.dart';

const Color _walletCardScreenBackground = Color(0xFF020202);
const Color _walletCardPanelBackground = Color(0xFF0D0D0D);
const Color _walletCardPanelRaised = Color(0xFF141414);
const Color _walletCardPanelBorder = Color(0xFF2A2A2A);
const Color _walletCardPanelBorderStrong = Color(0xFF3A3A3A);
const Color _walletCardText = Color(0xFFF1F1ED);
const Color _walletCardMutedText = Color(0xFFA0A09B);
const Color _walletCardFaintText = Color(0xFF6B6B66);

const List<_CardShowcaseSpec> _cardShowcases = [
  _CardShowcaseSpec(
    id: 'graphite',
    depositRate: 0.009,
    withdrawalRate: 0.009,
    miningRate: 0.003,
    walletCardType: WalletCardType.bronze,
    fillColor: Color(0xFF151515),
    borderColor: Color(0xFF3A3A3A),
    textColor: Color(0xFFF1F1ED),
    mutedTextColor: Color(0xFFA0A09B),
  ),
  _CardShowcaseSpec(
    id: 'silver',
    depositRate: 0.008,
    withdrawalRate: 0.008,
    miningRate: 0.002,
    walletCardType: WalletCardType.white,
    fillColor: Color(0xFFE4E4DF),
    borderColor: Color(0xFFF2F2EC),
    textColor: Color(0xFF090909),
    mutedTextColor: Color(0xFF555550),
  ),
  _CardShowcaseSpec(
    id: 'black',
    depositRate: 0.007,
    withdrawalRate: 0.007,
    miningRate: 0.001,
    walletCardType: WalletCardType.black,
    fillColor: Color(0xFF040404),
    borderColor: Color(0xFF282828),
    textColor: Color(0xFFF1F1ED),
    mutedTextColor: Color(0xFFA0A09B),
  ),
  _CardShowcaseSpec.hidden(),
];

class WalletCardScreen extends ConsumerStatefulWidget {
  const WalletCardScreen({super.key});

  @override
  ConsumerState<WalletCardScreen> createState() => _WalletCardScreenState();
}

class _WalletCardScreenState extends ConsumerState<WalletCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(walletProvider) is WalletInitial) {
        ref.read(walletProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final navigationClearance = AppPrimaryNavigationBar.scaffoldBottomClearance(
      context,
    );
    final responsive = context.responsive;

    final content = switch (walletState) {
      WalletLoading() || WalletInitial() => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8FA0B2)),
        ),
      WalletError(:final message) => _SolidMessage(
          icon: LucideIcons.alertCircle,
          title: context.l10n.walletCardUnavailableTitle,
          message: message,
        ),
      WalletLoaded() => _buildLoadedContent(walletState),
    };

    return Scaffold(
      backgroundColor: _walletCardScreenBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                responsive.isTinyPhone ? 14 : 18,
                responsive.horizontalPadding,
                navigationClearance,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.mobileContentMaxWidth,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.card,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(WalletLoaded loaded) {
    final wallet = loaded.selectedWallet ??
        (loaded.wallets.isNotEmpty ? loaded.wallets.first : null);

    if (wallet == null) {
      return _SolidMessage(
        icon: LucideIcons.creditCard,
        title: context.l10n.walletCardNoActiveTitle,
        message: context.l10n.walletCardNoActiveMessage,
      );
    }

    return _WalletCardCarouselExperience(
      key: ValueKey(
        '${wallet.id}:${wallet.cardType.name}:${wallet.cardSequence}:${wallet.cardRotationStatus}',
      ),
      wallet: wallet,
    );
  }
}

class _WalletCardCarouselExperience extends StatefulWidget {
  final Wallet wallet;

  const _WalletCardCarouselExperience({super.key, required this.wallet});

  @override
  State<_WalletCardCarouselExperience> createState() =>
      _WalletCardCarouselExperienceState();
}

class _WalletCardCarouselExperienceState
    extends State<_WalletCardCarouselExperience> {
  late final PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForWalletCardType(widget.wallet.cardType);
    _pageController = PageController(
      viewportFraction: 0.94,
      initialPage: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final currentCard = _cardShowcases[_selectedIndex];
    final activeCard = _showcaseForWalletCardType(widget.wallet.cardType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.walletCardAccountCardsTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _walletCardText,
            fontSize: responsive.compactFontSize(
              tiny: 22,
              compact: 24,
              regular: 28,
            ),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.walletCardAccountCardsSubtitle(widget.wallet.name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _walletCardMutedText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoChip(
              label: context.l10n.walletCardCurrentLabel,
              value: activeCard.title(context),
            ),
            _InfoChip(
              label: context.l10n.walletCardUpgradeLabel,
              value: context.l10n.walletCardAutomatic,
            ),
            _InfoChip(
              label: context.l10n.walletCardValidityLabel,
              value: _expiryLabel(context, widget.wallet.cardExpiresAt),
            ),
            _InfoChip(
              label: context.l10n.walletCardRotationLabel,
              value: _rotationLabel(context, widget.wallet),
            ),
            if (widget.wallet.hasPreviousCard)
              _InfoChip(
                label: context.l10n.walletCardPreviousLabel,
                value: '****${widget.wallet.previousCardNumberSuffix}',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.94;
            final cardHeight = (cardWidth / 1.72)
                .clamp(
                  responsive.isTinyPhone ? 164.0 : 184.0,
                  responsive.isCompact ? 218.0 : 236.0,
                )
                .toDouble();

            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _cardShowcases.length,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                itemBuilder: (context, index) {
                  final spec = _cardShowcases[index];
                  final isSelected = index == _selectedIndex;
                  final isCurrent =
                      spec.walletCardType == widget.wallet.cardType;

                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.96,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _ShowcaseCard(
                        spec: spec,
                        wallet: widget.wallet,
                        isCurrent: isCurrent,
                        isSelected: isSelected,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _CarouselIndicator(
          itemCount: _cardShowcases.length,
          currentIndex: _selectedIndex,
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: currentCard.isHidden
              ? const SizedBox(key: ValueKey('hidden-card'), height: 8)
              : _CardDescriptionPanel(
                  key: ValueKey(currentCard.id),
                  spec: currentCard,
                  isCurrent:
                      currentCard.walletCardType == widget.wallet.cardType,
                ),
        ),
        if (widget.wallet.cardLastRotatedAt != null ||
            widget.wallet.hasPreviousCard) ...[
          const SizedBox(height: AppSpacing.lg),
          _RotationTimelinePanel(wallet: widget.wallet),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _UpgradeRulesPanel(),
      ],
    );
  }

  int _indexForWalletCardType(WalletCardType cardType) {
    return switch (cardType) {
      WalletCardType.bronze => 0,
      WalletCardType.white => 1,
      WalletCardType.black => 2,
    };
  }

  _CardShowcaseSpec _showcaseForWalletCardType(WalletCardType cardType) {
    return _cardShowcases.firstWhere(
      (spec) => spec.walletCardType == cardType,
      orElse: () => _cardShowcases.first,
    );
  }

  String _rotationLabel(BuildContext context, Wallet wallet) {
    if (wallet.isCardRotating) {
      return context.l10n.walletCardRotating;
    }
    if (wallet.isCardExpiring) {
      return context.l10n.walletCardExpiring;
    }
    return context.l10n.walletCardActive;
  }

  String _expiryLabel(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) {
      return context.l10n.walletCardNotInformed;
    }
    return '${dateTime.month.toString().padLeft(2, '0')}/${(dateTime.year % 100).toString().padLeft(2, '0')}';
  }
}

class _ShowcaseCard extends StatelessWidget {
  final _CardShowcaseSpec spec;
  final Wallet wallet;
  final bool isCurrent;
  final bool isSelected;

  const _ShowcaseCard({
    required this.spec,
    required this.wallet,
    required this.isCurrent,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: spec.fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: spec.borderColor,
          width: isSelected ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.24 : 0.14),
            blurRadius: isSelected ? 22 : 14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(
                        alpha: spec.id == 'silver' ? 0.20 : 0.05,
                      ),
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: spec.id == 'silver' ? 0.08 : 0.20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: spec.isHidden
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.lock,
                            size: 34,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'BLOQUEADO',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'KEROSENE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: spec.textColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const Spacer(),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: spec.textColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: spec.textColor.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'ATUAL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: spec.textColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ShowcaseChip(
                              fillColor: spec.id == 'silver'
                                  ? const Color(0xFFF0F0EA)
                                  : const Color(0xFFC9C9C1),
                              lineColor: Colors.black.withValues(alpha: 0.22),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.contactless,
                              color: spec.textColor.withValues(alpha: 0.70),
                              size: 24,
                            ),
                            const Spacer(),
                            Text(
                              spec.title(context).toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: spec.mutedTextColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _displayNumber(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: spec.textColor,
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _ShowcaseCardField(
                                label: 'CARD HOLDER',
                                value: (isCurrent
                                        ? wallet.effectiveCardHolderName
                                        : wallet.name)
                                    .toUpperCase(),
                                textColor: spec.textColor,
                                mutedTextColor: spec.mutedTextColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            _ShowcaseCardField(
                              label: 'VALID THRU',
                              value: _validThru(),
                              textColor: spec.textColor,
                              mutedTextColor: spec.mutedTextColor,
                              alignEnd: true,
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

  String _displayNumber() {
    if (isCurrent) {
      return wallet.effectiveMaskedCardNumber;
    }
    final suffix = switch (spec.walletCardType) {
      WalletCardType.bronze => '1001',
      WalletCardType.white => '2002',
      WalletCardType.black => '3003',
      null => '0000',
    };
    return '****  ****  ****  $suffix';
  }

  String _validThru() {
    if (isCurrent && wallet.cardExpiresAt != null) {
      final expiry = wallet.cardExpiresAt!;
      return '${expiry.month.toString().padLeft(2, '0')}/${(expiry.year % 100).toString().padLeft(2, '0')}';
    }
    final year = DateTime.now().year + 4;
    return '12/${(year % 100).toString().padLeft(2, '0')}';
  }
}

class _RotationTimelinePanel extends StatelessWidget {
  final Wallet wallet;

  const _RotationTimelinePanel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.walletCardRotationTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.walletCardRotationSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _walletCardMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineRow(
            label: context.l10n.walletCardCurrentLabel,
            value: context.l10n.walletCardCurrentExpires(
              wallet.effectiveMaskedCardNumber,
              _formatDate(context, wallet.cardExpiresAt),
            ),
          ),
          if (wallet.cardLastRotatedAt != null)
            _TimelineRow(
              label: context.l10n.walletCardLastRotationLabel,
              value: _formatDateTime(context, wallet.cardLastRotatedAt),
            ),
          if (wallet.hasPreviousCard)
            _TimelineRow(
              label: context.l10n.walletCardPreviousLabel,
              value: context.l10n.walletCardPreviousExpired(
                '****${wallet.previousCardNumberSuffix}',
                _formatDate(context, wallet.previousCardExpiresAt),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.l10n.walletCardNotInformed;
    }
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatDateTime(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.l10n.walletCardNotInformed;
    }
    return '${_formatDate(context, value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimelineRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final labelWidth = responsive.isTinyPhone ? 82.0 : 104.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardFaintText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: responsive.isTinyPhone ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _walletCardText,
                    fontFamily: 'IBM Plex Mono',
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCardField extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color mutedTextColor;
  final bool alignEnd;

  const _ShowcaseCardField({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedTextColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mutedTextColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: alignEnd ? 58 : double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseChip extends StatelessWidget {
  final Color fillColor;
  final Color lineColor;

  const _ShowcaseChip({required this.fillColor, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: CustomPaint(painter: _ShowcaseChipPainter(lineColor: lineColor)),
    );
  }
}

class _ShowcaseChipPainter extends CustomPainter {
  final Color lineColor;

  const _ShowcaseChipPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawLine(
      Offset(size.width * 0.34, 3),
      Offset(size.width * 0.34, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, 3),
      Offset(size.width * 0.66, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(3, size.height * 0.32),
      Offset(size.width * 0.26, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(3, size.height * 0.68),
      Offset(size.width * 0.26, size.height * 0.68),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.32),
      Offset(size.width - 3, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.68),
      Offset(size.width - 3, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShowcaseChipPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _CardDescriptionPanel extends StatelessWidget {
  final _CardShowcaseSpec spec;
  final bool isCurrent;

  const _CardDescriptionPanel({
    super.key,
    required this.spec,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.title(context),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _walletCardPanelBorderStrong),
                  ),
                  child: Text(
                    context.l10n.walletCardYourCard,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _walletCardText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.description(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _walletCardMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FeeInfoRow(
            label: context.l10n.walletCardDepositLabel,
            value: WalletCardType.formatRate(spec.depositRate ?? 0),
          ),
          _FeeInfoRow(
            label: context.l10n.walletCardWithdrawLabel,
            value: WalletCardType.formatRate(spec.withdrawalRate ?? 0),
          ),
          _FeeInfoRow(
            label: context.l10n.walletCardMiningLabel,
            value: WalletCardType.formatRate(spec.miningRate ?? 0),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.walletCardHowToGet,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.qualification(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _walletCardMutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRulesPanel extends StatelessWidget {
  const _UpgradeRulesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.walletCardRulesTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.walletCardRulesSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _walletCardMutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _EligibilityRow(
            color: Color(0xFF343434),
            title: context.l10n.walletCardGraphiteTitle,
            description: context.l10n.walletCardGraphiteEligibility,
          ),
          _EligibilityRow(
            color: Color(0xFFE4E4DF),
            title: context.l10n.walletCardSilverTitle,
            description: context.l10n.walletCardSilverEligibility,
          ),
          _EligibilityRow(
            color: Color(0xFF050505),
            title: context.l10n.walletCardBlackTitle,
            description: context.l10n.walletCardBlackEligibility,
          ),
        ],
      ),
    );
  }
}

class _FeeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _FeeInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _walletCardMutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _walletCardText,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityRow extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _EligibilityRow({
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _walletCardText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _walletCardMutedText,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _walletCardPanelRaised,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _walletCardPanelBorderStrong),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardFaintText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _CarouselIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentIndex ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SolidMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SolidMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8FA0B2), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _walletCardMutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShowcaseSpec {
  final String id;
  final double? depositRate;
  final double? withdrawalRate;
  final double? miningRate;
  final WalletCardType? walletCardType;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final bool isHidden;

  const _CardShowcaseSpec({
    required this.id,
    required this.depositRate,
    required this.withdrawalRate,
    required this.miningRate,
    required this.walletCardType,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
  }) : isHidden = false;

  const _CardShowcaseSpec.hidden()
      : id = 'hidden',
        depositRate = null,
        withdrawalRate = null,
        miningRate = null,
        walletCardType = null,
        fillColor = const Color(0x0AFFFFFF),
        borderColor = const Color(0x26FFFFFF),
        textColor = const Color(0xFFF4F6F8),
        mutedTextColor = const Color(0xB3F4F6F8),
        isHidden = true;

  String title(BuildContext context) {
    return switch (id) {
      'graphite' => context.l10n.walletCardGraphiteTitle,
      'silver' => context.l10n.walletCardSilverTitle,
      'black' => context.l10n.walletCardBlackTitle,
      _ => context.l10n.walletCardHiddenTitle,
    };
  }

  String tierLabel(BuildContext context) {
    return switch (id) {
      'graphite' => context.l10n.walletCardGraphiteTier,
      'silver' => context.l10n.walletCardSilverTier,
      'black' => context.l10n.walletCardBlackTier,
      _ => '',
    };
  }

  String description(BuildContext context) {
    return switch (id) {
      'graphite' => context.l10n.walletCardGraphiteDescription,
      'silver' => context.l10n.walletCardSilverDescription,
      'black' => context.l10n.walletCardBlackDescription,
      _ => '',
    };
  }

  String qualification(BuildContext context) {
    return switch (id) {
      'graphite' => context.l10n.walletCardGraphiteQualification,
      'silver' => context.l10n.walletCardSilverQualification,
      'black' => context.l10n.walletCardBlackQualification,
      _ => '',
    };
  }
}
