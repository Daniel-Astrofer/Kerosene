part of 'home_screen.dart';

class _HomeEducationCarousel extends ConsumerStatefulWidget {
  const _HomeEducationCarousel();

  @override
  ConsumerState<_HomeEducationCarousel> createState() =>
      _HomeEducationCarouselState();
}

class _HomeEducationCarouselState
    extends ConsumerState<_HomeEducationCarousel> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;
  _HomeLedgerBalanceView? _lastView;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = ref.watch(_homeLedgerBalanceViewProvider);
    final cards = _homeEducationCards(context, view);

    if (_lastView != view) {
      _lastView = view;
      _activeIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }

    return Column(
      children: [
        SizedBox(
          height: _homeSize(154),
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _activeIndex = index);
            },
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : _homeSize(4),
                  right: index == cards.length - 1 ? 0 : _homeSize(4),
                ),
                child: _HomeGlassPanel(
                  borderRadius: BorderRadius.circular(_homeSize(16)),
                  padding: EdgeInsets.all(_homeSize(18)),
                  child: Row(
                    children: [
                      Container(
                        width: _homeSize(46),
                        height: _homeSize(46),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          card.icon,
                          color: Colors.white,
                          size: _homeSize(21),
                        ),
                      ),
                      SizedBox(width: _homeSize(16)),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.ibmPlexSerif(
                                textStyle: theme.textTheme.titleMedium,
                                color: Colors.white,
                                fontSize: _homeFontSize(20),
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: _homeSize(8)),
                            Text(
                              card.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _homeMutedTextColor,
                                fontSize: _homeFontSize(12),
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: _homeSize(12)),
                            Text(
                              card.tag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: _homeFontSize(10),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: _homeSize(12)),
        _HomePaginationDots(
          count: cards.length,
          activeIndex: _activeIndex.clamp(0, cards.length - 1),
        ),
      ],
    );
  }
}

class _HomeEducationCardData {
  final IconData icon;
  final String title;
  final String body;
  final String tag;

  const _HomeEducationCardData({
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
  });
}

List<_HomeEducationCardData> _homeEducationCards(
  BuildContext context,
  _HomeLedgerBalanceView view,
) {
  final tr = context.tr;

  return switch (view) {
    _HomeLedgerBalanceView.platform => [
        _HomeEducationCardData(
          icon: LucideIcons.repeat2,
          title: tr.homeEducationInternalTitle,
          body: tr.homeEducationInternalBody,
          tag: tr.homeEducationInternalTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.fingerprint,
          title: tr.homeEducationWalletHashTitle,
          body: tr.homeEducationWalletHashBody,
          tag: tr.homeEducationWalletHashTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.zap,
          title: tr.homeEducationLightningTitle,
          body: tr.homeEducationLightningBody,
          tag: tr.homeEducationLightningTag,
        ),
      ],
    _HomeLedgerBalanceView.onChain => [
        _HomeEducationCardData(
          icon: LucideIcons.bitcoin,
          title: tr.homeEducationOnchainTitle,
          body: tr.homeEducationOnchainBody,
          tag: tr.homeEducationOnchainTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.activity,
          title: tr.homeEducationConfirmationsTitle,
          body: tr.homeEducationConfirmationsBody,
          tag: tr.homeEducationConfirmationsTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.gauge,
          title: tr.homeEducationFeesTitle,
          body: tr.homeEducationFeesBody,
          tag: tr.homeEducationFeesTag,
        ),
      ],
    _ => [
        _HomeEducationCardData(
          icon: LucideIcons.bitcoin,
          title: tr.homeEducationBitcoinTitle,
          body: tr.homeEducationBitcoinBody,
          tag: tr.homeEducationBitcoinTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.zap,
          title: tr.homeEducationLightningTitle,
          body: tr.homeEducationLightningGeneralBody,
          tag: tr.homeEducationLightningGeneralTag,
        ),
        _HomeEducationCardData(
          icon: LucideIcons.wallet,
          title: tr.homeEducationInternalTitle,
          body: tr.homeEducationKeroseneGeneralBody,
          tag: tr.homeEducationKeroseneGeneralTag,
        ),
      ],
  };
}

class _HomeFundsDistributionSection extends StatelessWidget {
  final WalletState walletState;
  final VoidCallback onViewStatement;

  const _HomeFundsDistributionSection({
    required this.walletState,
    required this.onViewStatement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallets = walletState is WalletLoaded
        ? (walletState as WalletLoaded).wallets
        : const <Wallet>[];
    final onchainBalance = _sumWallets(
      wallets.where((wallet) => wallet.isSelfCustody),
    );
    final keroseneBalance = _sumWallets(
      wallets.where((wallet) => wallet.isKeroseneCustody),
    );
    final totalBalance = onchainBalance + keroseneBalance;
    final onchainShare = totalBalance > 0 ? onchainBalance / totalBalance : 0.0;
    final keroseneShare =
        totalBalance > 0 ? keroseneBalance / totalBalance : 0.0;
    final totalLabel = totalBalance > 0 ? '100%' : '0%';

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(16)),
      padding: EdgeInsets.all(_homeSize(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _homeFundsDistributionTitle(context),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: _homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewStatement,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.72),
                  padding: EdgeInsets.symmetric(horizontal: _homeSize(8)),
                  minimumSize: Size(0, _homeSize(32)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelSmall?.copyWith(
                    fontSize: _homeFontSize(12),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(_homeViewStatementShortLabel(context)),
              ),
            ],
          ),
          SizedBox(height: _homeSize(14)),
          Row(
            children: [
              SizedBox(
                width: _homeSize(96),
                height: _homeSize(96),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(_homeSize(96)),
                      painter: _HomeDistributionChartPainter(
                        onchainShare: onchainShare,
                        keroseneShare: keroseneShare,
                      ),
                    ),
                    Text(
                      totalLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: _homeFontSize(12),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _homeSize(24)),
              Expanded(
                child: Column(
                  children: [
                    _HomeDistributionLegendRow(
                      color: _homeAmberColor,
                      label: context.tr.homeOnchainWalletLabel,
                      percent: onchainShare,
                    ),
                    SizedBox(height: _homeSize(14)),
                    _HomeDistributionLegendRow(
                      color: _homePositiveColor,
                      label: context.tr.homeKeroseneWalletLabel,
                      percent: keroseneShare,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _sumWallets(Iterable<Wallet> wallets) {
    return wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
  }
}

class _HomeDistributionLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;

  const _HomeDistributionLegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentLabel = '${(percent * 100).toStringAsFixed(1)}%';

    return Row(
      children: [
        Container(
          width: _homeSize(10),
          height: _homeSize(10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: _homeSize(8)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _homeMutedTextColor,
              fontSize: _homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(width: _homeSize(8)),
        Text(
          percentLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: _homeFontSize(12),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _HomeDistributionChartPainter extends CustomPainter {
  final double onchainShare;
  final double keroseneShare;

  const _HomeDistributionChartPainter({
    required this.onchainShare,
    required this.keroseneShare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _homeSize(5);
    final strokeWidth = _homeSize(4);
    final basePaint = Paint()
      ..color = _homePanelBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _homeSize(3);
    canvas.drawCircle(center, radius, basePaint);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final onchainSweep = (math.pi * 2) * onchainShare.clamp(0.0, 1.0);
    final keroseneSweep = (math.pi * 2) * keroseneShare.clamp(0.0, 1.0);

    if (onchainSweep > 0) {
      segmentPaint.color = _homeAmberColor;
      canvas.drawArc(rect, start, onchainSweep, false, segmentPaint);
    }
    if (keroseneSweep > 0) {
      segmentPaint.color = _homePositiveColor;
      canvas.drawArc(
        rect,
        start + onchainSweep,
        keroseneSweep,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeDistributionChartPainter oldDelegate) {
    return oldDelegate.onchainShare != onchainShare ||
        oldDelegate.keroseneShare != keroseneShare;
  }
}

class _HomeActivityFilterChips extends ConsumerWidget {
  const _HomeActivityFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(_homeActivityFilterProvider);
    const filters = [
      _HomeActivityFilter.onChain,
      _HomeActivityFilter.platform,
      _HomeActivityFilter.notices,
    ];

    void selectFilter(_HomeActivityFilter filter) {
      HapticFeedback.selectionClick();
      ref.read(_homeActivityFilterProvider.notifier).state = filter;
      if (filter == _HomeActivityFilter.platform) {
        ref.read(_homeLedgerBalanceViewProvider.notifier).state =
            _HomeLedgerBalanceView.platform;
      } else if (filter == _HomeActivityFilter.onChain) {
        ref.read(_homeLedgerBalanceViewProvider.notifier).state =
            _HomeLedgerBalanceView.onChain;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) SizedBox(width: _homeSize(8)),
            _HomeActivityFilterChip(
              label: _homeFilterLabel(context, filters[index]),
              selected: selectedFilter == filters[index],
              onTap: () => selectFilter(filters[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeActivityFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HomeActivityFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeSize(999)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: _homeSize(16),
            vertical: _homeSize(7),
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : _homeCardColor,
            borderRadius: BorderRadius.circular(_homeSize(999)),
            border: Border.all(
              color: selected ? Colors.white : _homePanelBorderColor,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? Colors.black : _homeMutedTextColor,
              fontSize: _homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

String _homeFundsDistributionTitle(BuildContext context) {
  return context.tr.homeFundsDistributionTitle;
}

String _homeRecentActivitiesTitle(BuildContext context) {
  return context.tr.homeRecentActivitiesTitle;
}

String _homeViewAllLabel(BuildContext context) {
  return context.tr.viewAll;
}

String _homeViewStatementShortLabel(BuildContext context) {
  return context.tr.homeViewStatementShortLabel;
}

String _homeOnchainFilterLabel(BuildContext context) {
  return context.tr.homeOnchainFilterLabel;
}

String _homePlatformFilterLabel(BuildContext context) {
  return context.tr.homePlatformFilterLabel;
}

String _homeNoticesFilterLabel(BuildContext context) {
  return context.tr.homeNoticesFilterLabel;
}

String _homeFilterLabel(BuildContext context, _HomeActivityFilter filter) {
  return switch (filter) {
    _HomeActivityFilter.platform => _homePlatformFilterLabel(context),
    _HomeActivityFilter.onChain => _homeOnchainFilterLabel(context),
    _HomeActivityFilter.notices => _homeNoticesFilterLabel(context),
  };
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _HomeSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _homeAmberColor,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
