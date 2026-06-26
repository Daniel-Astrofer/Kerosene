// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'dart:math' as math;

import 'home_screen_dependencies.dart';
import 'home_screen.dart';
import 'home_screen_surface.dart';

class HomeEducationCarousel extends ConsumerStatefulWidget {
  const HomeEducationCarousel();

  @override
  ConsumerState<HomeEducationCarousel> createState() =>
      HomeEducationCarouselState();
}

class HomeEducationCarouselState extends ConsumerState<HomeEducationCarousel> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;
  HomeLedgerBalanceView? _lastView;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = ref.watch(homeLedgerBalanceViewProvider);
    final cards = homeEducationCards(context, view);

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
          height: homeSize(154),
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
                  left: index == 0 ? 0 : homeSize(4),
                  right: index == cards.length - 1 ? 0 : homeSize(4),
                ),
                child: HomeGlassPanel(
                  borderRadius: BorderRadius.circular(homeSize(16)),
                  padding: EdgeInsets.all(homeSize(18)),
                  child: Row(
                    children: [
                      Container(
                        width: homeSize(46),
                        height: homeSize(46),
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
                          size: homeSize(21),
                        ),
                      ),
                      SizedBox(width: homeSize(16)),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.newsreader(
                                textStyle: theme.textTheme.titleMedium,
                                color: Colors.white,
                                fontSize: homeFontSize(20),
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: homeSize(8)),
                            Text(
                              card.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: homeMutedTextColor,
                                fontSize: homeFontSize(12),
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: homeSize(12)),
                            Text(
                              card.tag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: homeFontSize(10),
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
        SizedBox(height: homeSize(12)),
        HomePaginationDots(
          count: cards.length,
          activeIndex: _activeIndex.clamp(0, cards.length - 1),
        ),
      ],
    );
  }
}

class HomeEducationCardData {
  final IconData icon;
  final String title;
  final String body;
  final String tag;

  const HomeEducationCardData({
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
  });
}

List<HomeEducationCardData> homeEducationCards(
  BuildContext context,
  HomeLedgerBalanceView view,
) {
  final tr = context.tr;

  return switch (view) {
    HomeLedgerBalanceView.platform => [
        HomeEducationCardData(
          icon: KeroseneIcons.internalTransfer,
          title: tr.homeEducationInternalTitle,
          body: tr.homeEducationInternalBody,
          tag: tr.homeEducationInternalTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.biometric,
          title: tr.homeEducationWalletHashTitle,
          body: tr.homeEducationWalletHashBody,
          tag: tr.homeEducationWalletHashTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.lightning,
          title: tr.homeEducationLightningTitle,
          body: tr.homeEducationLightningBody,
          tag: tr.homeEducationLightningTag,
        ),
      ],
    HomeLedgerBalanceView.onChain => [
        HomeEducationCardData(
          icon: KeroseneIcons.bitcoin,
          title: tr.homeEducationOnchainTitle,
          body: tr.homeEducationOnchainBody,
          tag: tr.homeEducationOnchainTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.sync,
          title: tr.homeEducationConfirmationsTitle,
          body: tr.homeEducationConfirmationsBody,
          tag: tr.homeEducationConfirmationsTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.gauge,
          title: tr.homeEducationFeesTitle,
          body: tr.homeEducationFeesBody,
          tag: tr.homeEducationFeesTag,
        ),
      ],
    _ => [
        HomeEducationCardData(
          icon: KeroseneIcons.bitcoin,
          title: tr.homeEducationBitcoinTitle,
          body: tr.homeEducationBitcoinBody,
          tag: tr.homeEducationBitcoinTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.lightning,
          title: tr.homeEducationLightningTitle,
          body: tr.homeEducationLightningGeneralBody,
          tag: tr.homeEducationLightningGeneralTag,
        ),
        HomeEducationCardData(
          icon: KeroseneIcons.wallet,
          title: tr.homeEducationInternalTitle,
          body: tr.homeEducationKeroseneGeneralBody,
          tag: tr.homeEducationKeroseneGeneralTag,
        ),
      ],
  };
}

class HomeFundsDistributionSection extends ConsumerWidget {
  final WalletState walletState;
  final VoidCallback onViewStatement;

  const HomeFundsDistributionSection({
    required this.walletState,
    required this.onViewStatement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallets = walletState is WalletLoaded
        ? (walletState as WalletLoaded).wallets
        : const <Wallet>[];
    final displayWallets = _sortedWallets(wallets);
    final totalBalance = displayWallets.fold<double>(
      0,
      (sum, wallet) => sum + math.max(0, wallet.balance),
    );
    final entries = <HomeWalletDistributionEntry>[
      for (var index = 0; index < displayWallets.length; index++)
        HomeWalletDistributionEntry(
          wallet: displayWallets[index],
          color: displayWallets.length == 1
              ? _singleWalletDistributionColor
              : _walletDistributionColor(index),
          share: totalBalance > 0
              ? math.max(0, displayWallets[index].balance) / totalBalance
              : 0,
        ),
    ];
    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(16)),
      padding: EdgeInsets.all(homeSize(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  homeFundsDistributionTitle(context),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewStatement,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.72),
                  padding: EdgeInsets.symmetric(horizontal: homeSize(8)),
                  minimumSize: Size(0, homeSize(32)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelSmall?.copyWith(
                    fontSize: homeFontSize(12),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(homeViewStatementShortLabel(context)),
              ),
            ],
          ),
          SizedBox(height: homeSize(14)),
          Center(
            child: SizedBox(
              width: homeSize(126),
              height: homeSize(126),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(homeSize(126)),
                    painter: HomeDistributionChartPainter(entries: entries),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalBalance > 0 ? '100%' : '0%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: homeFontSize(13),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Wallet> _sortedWallets(List<Wallet> wallets) {
    final active = wallets.where((wallet) => wallet.isActive).toList();
    final source = active.isNotEmpty ? active : List<Wallet>.from(wallets);
    source.sort((a, b) {
      final byBalance = b.balance.compareTo(a.balance);
      if (byBalance != 0) return byBalance;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return source;
  }
}

class HomeWalletDistributionEntry {
  final Wallet wallet;
  final Color color;
  final double share;

  const HomeWalletDistributionEntry({
    required this.wallet,
    required this.color,
    required this.share,
  });
}

class HomeDistributionEmptyState extends StatelessWidget {
  const HomeDistributionEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(homeSize(16)),
      decoration: BoxDecoration(
        color: homeCardColor,
        borderRadius: BorderRadius.circular(homeSize(14)),
        border: Border.all(color: homePanelBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: homeSize(36),
            height: homeSize(36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              shape: BoxShape.circle,
            ),
            child: Icon(
              KeroseneIcons.wallet,
              color: Colors.white.withValues(alpha: 0.84),
              size: homeSize(18),
            ),
          ),
          SizedBox(width: homeSize(12)),
          Expanded(
            child: Text(
              _distributionCopy(
                context,
                pt: 'Nenhuma carteira disponível para distribuir fundos.',
                en: 'No wallet available for fund distribution.',
                es: 'No hay billeteras disponibles para distribuir fondos.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: homeMutedTextColor,
                fontSize: homeFontSize(12),
                height: 1.35,
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeDistributionChartPainter extends CustomPainter {
  final List<HomeWalletDistributionEntry> entries;

  const HomeDistributionChartPainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - homeSize(5);
    final strokeWidth = homeSize(5);
    final basePaint = Paint()
      ..color = homePanelBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = homeSize(3);
    canvas.drawCircle(center, radius, basePaint);

    final totalShare =
        entries.fold<double>(0, (sum, entry) => sum + entry.share);
    if (totalShare <= 0) return;

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    const gap = 0.018;

    for (final entry in entries) {
      final normalizedShare = entry.share / totalShare;
      final sweep = (math.pi * 2) * normalizedShare;
      if (sweep <= 0) continue;
      segmentPaint.color = entry.color;
      canvas.drawArc(
        rect,
        start + gap,
        math.max(0, sweep - gap * 2),
        false,
        segmentPaint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant HomeDistributionChartPainter oldDelegate) {
    if (oldDelegate.entries.length != entries.length) return true;
    for (var index = 0; index < entries.length; index++) {
      final old = oldDelegate.entries[index];
      final current = entries[index];
      if (old.wallet.id != current.wallet.id ||
          old.wallet.balance != current.wallet.balance ||
          old.share != current.share ||
          old.color != current.color) {
        return true;
      }
    }
    return false;
  }
}

Color _walletDistributionColor(int index) {
  return switch (index % 6) {
    0 => Colors.white,
    1 => Colors.white.withValues(alpha: 0.78),
    2 => Colors.white.withValues(alpha: 0.62),
    3 => Colors.white.withValues(alpha: 0.48),
    4 => Colors.white.withValues(alpha: 0.34),
    _ => Colors.white.withValues(alpha: 0.24),
  };
}

const Color _singleWalletDistributionColor = AppColors.hexFF444748;

String _distributionCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}

class HomeActivityFilterChips extends ConsumerWidget {
  const HomeActivityFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(homeActivityFilterProvider);
    const filters = [
      HomeActivityFilter.all,
      HomeActivityFilter.incoming,
      HomeActivityFilter.outgoing,
      HomeActivityFilter.pending,
      HomeActivityFilter.failed,
    ];

    void selectFilter(HomeActivityFilter filter) {
      HapticFeedback.selectionClick();
      ref.read(homeActivityFilterProvider.notifier).state = filter;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) SizedBox(width: homeSize(8)),
            HomeActivityFilterChip(
              label: homeFilterLabel(context, filters[index]),
              selected: selectedFilter == filters[index],
              onTap: () => selectFilter(filters[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeActivityFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const HomeActivityFilterChip({
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
        borderRadius: BorderRadius.circular(homeSize(999)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: homeSize(16),
            vertical: homeSize(7),
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : homeCardColor,
            borderRadius: BorderRadius.circular(homeSize(999)),
            border: Border.all(
              color: selected ? Colors.white : homePanelBorderColor,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? Colors.black : homeMutedTextColor,
              fontSize: homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

String homeFundsDistributionTitle(BuildContext context) {
  return context.tr.homeFundsDistributionTitle;
}

String homeRecentActivitiesTitle(BuildContext context) {
  return context.tr.homeRecentActivitiesTitle;
}

String homeViewAllLabel(BuildContext context) {
  return context.tr.viewAll;
}

String homeViewStatementShortLabel(BuildContext context) {
  return context.tr.homeViewStatementShortLabel;
}

String homeOnchainFilterLabel(BuildContext context) {
  return context.tr.homeOnchainFilterLabel;
}

String homePlatformFilterLabel(BuildContext context) {
  return context.tr.homePlatformFilterLabel;
}

String homeNoticesFilterLabel(BuildContext context) {
  return context.tr.homeNoticesFilterLabel;
}

String homeFilterLabel(BuildContext context, HomeActivityFilter filter) {
  return switch (filter) {
    HomeActivityFilter.all => context.tr.financialStatementFilterAll,
    HomeActivityFilter.incoming => context.tr.financialStatementFilterIncoming,
    HomeActivityFilter.outgoing => context.tr.financialStatementFilterOutgoing,
    HomeActivityFilter.pending => context.tr.financialStatementFilterPending,
    HomeActivityFilter.failed => context.tr.financialStatementFilterFailed,
  };
}

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const HomeSectionHeader({
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
            foregroundColor: homeAmberColor,
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
