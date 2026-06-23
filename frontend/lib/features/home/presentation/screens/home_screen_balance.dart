// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'home_screen_dependencies.dart';
import 'home_screen.dart';
import 'home_screen_surface.dart';

class HomeBalanceSection extends ConsumerStatefulWidget {
  final String userName;
  final WalletState walletState;
  final Wallet? activeWallet;
  final VoidCallback onReceive;
  final VoidCallback onSend;
  final VoidCallback onViewStatement;
  final VoidCallback onOpenWallets;

  const HomeBalanceSection({
    required this.userName,
    required this.walletState,
    required this.activeWallet,
    required this.onReceive,
    required this.onSend,
    required this.onViewStatement,
    required this.onOpenWallets,
  });

  @override
  ConsumerState<HomeBalanceSection> createState() => HomeBalanceSectionState();
}

class HomeBalanceSectionState extends ConsumerState<HomeBalanceSection> {
  late final PageController _pageController;
  final GlobalKey _notificationButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(homeLedgerBalancePageProvider),
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
    final selectedCurrency = ref.watch(currencyProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final notificationCount = ref.watch(sessionNotificationUnreadCountProvider);
    final priceFeedActive = ref.watch(homeRouteActiveProvider);
    final btcUsd = priceFeedActive ? ref.watch(latestBtcPriceProvider) : null;
    final btcEur = priceFeedActive ? ref.watch(btcEurPriceProvider) : null;
    final btcBrl = priceFeedActive ? ref.watch(btcBrlPriceProvider) : null;
    final btcDailyChangePercent =
        priceFeedActive ? ref.watch(btcDailyChangePercentProvider) : null;
    final selectedView = ref.watch(homeLedgerBalanceViewProvider);
    final selectedPage = ref.watch(homeLedgerBalancePageProvider);
    final wallets = widget.walletState is WalletLoaded
        ? (widget.walletState as WalletLoaded).wallets
        : const <Wallet>[];
    final quoteCurrency =
        selectedCurrency == Currency.btc ? Currency.brl : selectedCurrency;
    final hasSelectedQuote = switch (quoteCurrency) {
      Currency.btc => true,
      Currency.usd => btcUsd != null && btcUsd > 0,
      Currency.eur => btcEur != null && btcEur > 0,
      Currency.brl => btcBrl != null && btcBrl > 0,
    };

    int pageForView(HomeLedgerBalanceView view) {
      if (view == HomeLedgerBalanceView.total) {
        return 0;
      }
      final index = wallets.indexWhere((wallet) =>
          view == HomeLedgerBalanceView.onChain
              ? wallet.isColdWallet
              : !wallet.isColdWallet);
      return index < 0 ? 0 : index + 1;
    }

    ref.listen<HomeLedgerBalanceView>(homeLedgerBalanceViewProvider, (
      previous,
      next,
    ) {
      if (wallets.isEmpty) {
        return;
      }
      final page = pageForView(next);
      if (!_pageController.hasClients) {
        return;
      }

      final currentPage =
          _pageController.page ?? _pageController.initialPage.toDouble();
      if ((currentPage - page).abs() < 0.05) {
        return;
      }

      unawaited(
        _pageController.animateToPage(
          page,
          duration: KeroseneMotion.medium,
          curve: KeroseneMotion.standard,
        ),
      );
    });

    final walletCardData = [
      for (final wallet in wallets)
        HomeBalanceCardData.forWallet(
          wallet: wallet,
          convertedBalanceLabel: _convertedWalletBalanceLabel(
            wallet: wallet,
            balanceSettings: balanceSettings,
            quoteCurrency: quoteCurrency,
            hasSelectedQuote: hasSelectedQuote,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          ),
          dailyChangeLabel: _walletDailyChangeLabel(
            wallet: wallet,
            quoteCurrency: quoteCurrency,
            hasSelectedQuote: hasSelectedQuote,
            btcDailyChangePercent: btcDailyChangePercent,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          ),
          dailyChangeColor: _walletDailyChangeColor(
            wallet: wallet,
            quoteCurrency: quoteCurrency,
            hasSelectedQuote: hasSelectedQuote,
            btcDailyChangePercent: btcDailyChangePercent,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          ),
          decimalPlaces: balanceSettings.decimalPlaces,
          balanceHidden: balanceSettings.isHidden,
        ),
    ];

    HomeBalanceCardData cardDataFor(HomeLedgerBalanceView view) {
      final scopedWallets = _walletsForView(wallets, view);
      final primaryWallet = _primaryWalletForView(
        activeWallet: widget.activeWallet,
        scopedWallets: scopedWallets,
        view: view,
      );
      final balanceBtc = _sumWallets(scopedWallets);
      final convertedBalanceValue = MoneyDisplay.convertFromBtcAmount(
        btcAmount: balanceBtc,
        currency: quoteCurrency,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      );
      final convertedBalanceLabel = balanceSettings.isHidden
          ? '${MoneyDisplay.tickerSymbolFor(quoteCurrency)} ••••••••'
          : hasSelectedQuote
              ? MoneyDisplay.format(
                  amount: convertedBalanceValue,
                  currency: quoteCurrency,
                )
              : '${quoteCurrency.code} indisponivel';
      final dailyChangeValue = hasSelectedQuote && btcDailyChangePercent != null
          ? convertedBalanceValue * (btcDailyChangePercent / 100)
          : null;
      final isDailyChangePositive = (dailyChangeValue ?? 0) >= 0;
      final dailyChangeColor =
          isDailyChangePositive ? homePositiveColor : AppColors.hexFFFF5A67;
      final dailyChangeSign = isDailyChangePositive ? '+' : '-';
      final percentSeparator =
          MoneyDisplay.localeFor(quoteCurrency).startsWith('en') ? '.' : ',';
      final dailyChangePercentLabel = btcDailyChangePercent
          ?.abs()
          .toStringAsFixed(2)
          .replaceAll('.', percentSeparator);
      final dailyChangeLabel = dailyChangePercentLabel != null
          ? '$dailyChangeSign$dailyChangePercentLabel% (24h)'
          : '${quoteCurrency.code} indisponivel';

      return HomeBalanceCardData(
        view: view,
        wallet: view == HomeLedgerBalanceView.total ? null : primaryWallet,
        balanceBtc: balanceBtc,
        convertedBalanceLabel: convertedBalanceLabel,
        dailyChangeLabel: dailyChangeLabel,
        dailyChangeColor: dailyChangeColor,
        decimalPlaces: balanceSettings.decimalPlaces,
        balanceHidden: balanceSettings.isHidden,
      );
    }

    void toggleVisibility() {
      HapticFeedback.lightImpact();
      ref.read(balanceSettingsProvider.notifier).toggleVisibility();
    }

    void selectPage(int page) {
      ref.read(homeLedgerBalancePageProvider.notifier).state = page;
      final walletIndex = page - 1;
      final wallet = walletIndex >= 0 && walletIndex < walletCardData.length
          ? walletCardData[walletIndex].wallet
          : null;
      final view = page == 0
          ? HomeLedgerBalanceView.total
          : wallet?.isColdWallet == true
              ? HomeLedgerBalanceView.onChain
              : HomeLedgerBalanceView.platform;
      ref.read(homeLedgerBalanceViewProvider.notifier).state = view;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _localizedGreeting(context, widget.userName),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: AppTypography.newsreader(
                    textStyle: theme.textTheme.titleLarge,
                    color: Colors.white,
                    fontSize: _greetingFontSize(
                      userName: widget.userName,
                      baseFontSize: responsive.compactFontSize(
                        tiny: homeFontSize(22),
                        compact: homeFontSize(24),
                        regular: homeFontSize(25),
                      ),
                    ),
                    fontWeight: FontWeight.w300,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            SizedBox(width: homeSize(12)),
            HomeHeaderIconButton(
              icon: balanceSettings.isHidden
                  ? KeroseneIcons.eyeOff
                  : KeroseneIcons.eye,
              onTap: toggleVisibility,
            ),
            SizedBox(width: homeSize(8)),
            HomeHeaderIconButton(
              key: _notificationButtonKey,
              icon: KeroseneIcons.notifications,
              hasBadge: notificationCount > 0,
              onTap: () async {
                HapticFeedback.selectionClick();
                if (!mounted) {
                  return;
                }
                await openNotificationCenter(
                  context,
                  originKey: _notificationButtonKey,
                );
              },
            ),
          ],
        ),
        SizedBox(height: homeSize(18)),
        SizedBox(
          height: responsive.isTinyPhone ? homeSize(276) : homeSize(286),
          child: walletCardData.isEmpty
              ? HomeBalanceCard(
                  data: walletCardData.isNotEmpty
                      ? walletCardData.first
                      : cardDataFor(HomeLedgerBalanceView.total),
                  onViewStatement: widget.onViewStatement,
                  onOpenWallets: widget.onOpenWallets,
                )
              : PageView(
                  key: const ValueKey('home-balance-carousel'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: selectPage,
                  children: [
                    HomeBalanceCard(
                      data: cardDataFor(HomeLedgerBalanceView.total),
                      onViewStatement: widget.onViewStatement,
                      onOpenWallets: widget.onOpenWallets,
                    ),
                    for (final data in walletCardData)
                      HomeBalanceCard(
                        data: data,
                        onViewStatement: widget.onViewStatement,
                        onOpenWallets: widget.onOpenWallets,
                      ),
                  ],
                ),
        ),
        SizedBox(height: homeSize(16)),
        Row(
          children: [
            Expanded(
              child: HomeBalanceActionButton(
                icon: KeroseneIcons.down,
                label: context.tr.homeReceiveActionShort,
                onTap: widget.onReceive,
                primary: true,
              ),
            ),
            SizedBox(width: homeSize(12)),
            Expanded(
              child: HomeBalanceActionButton(
                icon: KeroseneIcons.up,
                label: context.tr.homeSendTitle,
                onTap: widget.onSend,
                primary: false,
              ),
            ),
          ],
        ),
        SizedBox(height: homeSize(14)),
        if (walletCardData.isNotEmpty)
          HomePaginationDots(
            count: walletCardData.length + 1,
            activeIndex: selectedPage.clamp(
              selectedView == HomeLedgerBalanceView.total ? 0 : 0,
              walletCardData.length,
            ),
          ),
      ],
    );
  }

  static String _convertedWalletBalanceLabel({
    required Wallet wallet,
    required BalanceSettings balanceSettings,
    required Currency quoteCurrency,
    required bool hasSelectedQuote,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (balanceSettings.isHidden) {
      return '${MoneyDisplay.tickerSymbolFor(quoteCurrency)} ••••••••';
    }
    if (!hasSelectedQuote) {
      return '${quoteCurrency.code} indisponivel';
    }
    final converted = MoneyDisplay.convertFromBtcAmount(
      btcAmount: wallet.balance,
      currency: quoteCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    return MoneyDisplay.format(amount: converted, currency: quoteCurrency);
  }

  static String _walletDailyChangeLabel({
    required Wallet wallet,
    required Currency quoteCurrency,
    required bool hasSelectedQuote,
    required double? btcDailyChangePercent,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (!hasSelectedQuote || btcDailyChangePercent == null) {
      return '${quoteCurrency.code} indisponivel';
    }
    final separator =
        MoneyDisplay.localeFor(quoteCurrency).startsWith('en') ? '.' : ',';
    final percent = btcDailyChangePercent
        .abs()
        .toStringAsFixed(2)
        .replaceAll('.', separator);
    final sign = btcDailyChangePercent >= 0 ? '+' : '-';
    return '$sign$percent% (24h)';
  }

  static Color _walletDailyChangeColor({
    required Wallet wallet,
    required Currency quoteCurrency,
    required bool hasSelectedQuote,
    required double? btcDailyChangePercent,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return (btcDailyChangePercent ?? 0) >= 0
        ? homePositiveColor
        : AppColors.hexFFFF5A67;
  }

  static int _pageIndexFor(HomeLedgerBalanceView view) {
    return switch (view) {
      HomeLedgerBalanceView.total => 0,
      HomeLedgerBalanceView.platform => 1,
      HomeLedgerBalanceView.onChain => 2,
    };
  }

  static List<Wallet> _walletsForView(
    List<Wallet> wallets,
    HomeLedgerBalanceView view,
  ) {
    if (view == HomeLedgerBalanceView.total) {
      return wallets;
    }

    final filtered = wallets
        .where(
          (wallet) => view == HomeLedgerBalanceView.onChain
              ? wallet.isSelfCustody
              : wallet.isKeroseneCustody,
        )
        .toList(growable: false);
    return filtered;
  }

  static Wallet? _primaryWalletForView({
    required Wallet? activeWallet,
    required List<Wallet> scopedWallets,
    required HomeLedgerBalanceView view,
  }) {
    if (view == HomeLedgerBalanceView.total) {
      return activeWallet ??
          (scopedWallets.isNotEmpty ? scopedWallets.first : null);
    }

    final activeMatches = activeWallet != null &&
        (view == HomeLedgerBalanceView.onChain
            ? activeWallet.isSelfCustody
            : activeWallet.isKeroseneCustody);
    if (activeMatches) {
      return activeWallet;
    }
    return scopedWallets.isNotEmpty ? scopedWallets.first : null;
  }

  static double _sumWallets(List<Wallet> wallets) {
    return wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
  }

  static String _localizedGreeting(BuildContext context, String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.tr.homeGreetingMorning(userName);
    }
    if (hour < 18) {
      return context.tr.homeGreetingAfternoon(userName);
    }
    return context.tr.homeGreetingEvening(userName);
  }

  static double _greetingFontSize({
    required String userName,
    required double baseFontSize,
  }) {
    const maxNameCharsAtBaseSize = 9;
    final nameLength = userName.runes.length;
    if (nameLength <= maxNameCharsAtBaseSize) {
      return baseFontSize;
    }

    return (baseFontSize * maxNameCharsAtBaseSize / nameLength)
        .clamp(homeFontSize(14), baseFontSize);
  }
}

class HomeBalanceCardData {
  final HomeLedgerBalanceView view;
  final Wallet? wallet;
  final double balanceBtc;
  final String convertedBalanceLabel;
  final String dailyChangeLabel;
  final Color dailyChangeColor;
  final int decimalPlaces;
  final bool balanceHidden;

  const HomeBalanceCardData({
    required this.view,
    required this.wallet,
    required this.balanceBtc,
    required this.convertedBalanceLabel,
    required this.dailyChangeLabel,
    required this.dailyChangeColor,
    required this.decimalPlaces,
    required this.balanceHidden,
  });

  factory HomeBalanceCardData.forWallet({
    required Wallet wallet,
    required String convertedBalanceLabel,
    required String dailyChangeLabel,
    required Color dailyChangeColor,
    required int decimalPlaces,
    required bool balanceHidden,
  }) {
    return HomeBalanceCardData(
      view: wallet.isColdWallet
          ? HomeLedgerBalanceView.onChain
          : HomeLedgerBalanceView.platform,
      wallet: wallet,
      balanceBtc: wallet.balance,
      convertedBalanceLabel: convertedBalanceLabel,
      dailyChangeLabel: dailyChangeLabel,
      dailyChangeColor: dailyChangeColor,
      decimalPlaces: decimalPlaces,
      balanceHidden: balanceHidden,
    );
  }
}

class HomeBalanceCard extends ConsumerWidget {
  final HomeBalanceCardData data;
  final VoidCallback onViewStatement;
  final VoidCallback onOpenWallets;

  const HomeBalanceCard({
    required this.data,
    required this.onViewStatement,
    required this.onOpenWallets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final isTotal = data.view == HomeLedgerBalanceView.total;
    final title = isTotal
        ? homeTotalBalanceTitle(context)
        : data.wallet?.custodyDisplayLabel ??
            switch (data.view) {
              HomeLedgerBalanceView.platform =>
                homeInternalBalanceTitle(context),
              HomeLedgerBalanceView.onChain => homeOnchainBalanceTitle(context),
              HomeLedgerBalanceView.total => homeTotalBalanceTitle(context),
            };
    final walletName =
        _nonEmpty(data.wallet?.name, homeGlobalWalletTitle(context));
    final btcUnitLabel = 'BTC';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: homeMutedTextColor,
                        fontSize: homeFontSize(12),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isTotal)
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenWallets();
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: homeSize(32),
                  height: homeSize(32),
                ),
                icon: Icon(
                  KeroseneIcons.send,
                  size: homeSize(20),
                  color: homeMutedTextColor,
                ),
              ),
          ],
        ),
        SizedBox(height: homeSize(10)),
        if (data.wallet != null) ...[
          Text(
            walletName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: homeFontSize(14),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(15)),
        ] else
          SizedBox(height: homeSize(24)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBalanceDisplay(
                balance: data.balanceBtc,
                decimalPlaces: data.decimalPlaces,
                locale: MoneyDisplay.localeFor(Currency.btc),
                enableFlash: false,
                isHidden: data.balanceHidden,
                digitWidthFactor: 0.72,
                characterSpacing: 0.1,
                decimalScaleFactor: 0.78,
                separatorScaleFactor: 0.78,
                onDecimalTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(balanceSettingsProvider.notifier).cycleDecimals();
                },
                style: AppTypography.homeBalance(color: Colors.white).copyWith(
                  fontSize: responsive.compactFontSize(
                    tiny: homeFontSize(isTotal ? 36 : 32),
                    compact: homeFontSize(isTotal ? 42 : 38),
                    regular: homeFontSize(isTotal ? 46 : 42),
                  ),
                  letterSpacing: 0,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: homeSize(6),
                  bottom: homeSize(4),
                ),
                child: Text(
                  btcUnitLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: homeMutedTextColor,
                    fontSize: homeFontSize(16),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: homeSize(5)),
        Text(
          data.convertedBalanceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: homeMutedTextColor,
            fontSize: homeFontSize(14),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: homeSize(5)),
        Row(
          children: [
            Icon(
              data.dailyChangeColor == homePositiveColor
                  ? KeroseneIcons.up
                  : KeroseneIcons.down,
              color: data.dailyChangeColor,
              size: homeSize(12),
            ),
            SizedBox(width: homeSize(5)),
            Flexible(
              child: Text(
                data.dailyChangeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: data.dailyChangeColor,
                  fontSize: homeFontSize(13),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );

    if (isTotal && data.wallet == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          homeSize(6),
          homeSize(20),
          homeSize(6),
          homeSize(20),
        ),
        child: content,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenWallets();
      },
      child: HomeGlassPanel(
        borderRadius: BorderRadius.circular(homeSize(18)),
        padding: EdgeInsets.all(homeSize(20)),
        child: content,
      ),
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

class HomeAvatar extends StatelessWidget {
  final String name;

  const HomeAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(name);

    return Container(
      width: homeSize(40),
      height: homeSize(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: homeCardColor,
        border: Border.all(color: homePanelBorderColor),
        image: const DecorationImage(
          image: AssetImage(KeroseneLogo.assetPath),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }

  static String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '...') {
      return 'K';
    }
    return trimmed.characters.first.toUpperCase();
  }
}

String homeInternalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Internal balance',
    'es' => 'Saldo interno',
    _ => 'Saldo Interno',
  };
}

String homeOnchainBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain balance',
    'es' => 'Saldo On-chain',
    _ => 'Saldo Onchain',
  };
}

String homeTotalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total balance',
    'es' => 'Saldo total',
    _ => 'Saldo Total',
  };
}

String homeGlobalWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Global wallet',
    'es' => 'Cartera global',
    _ => 'Carteira Global',
  };
}

String homeConsolidatedWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total Balance',
    'es' => 'Saldo Total',
    _ => 'Saldo Total',
  };
}

String homeOnchainWalletCardTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain wallet',
    'es' => 'Cartera On-chain',
    _ => 'Carteira On-chain',
  };
}

String homeStatementActionLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Go to statement',
    'es' => 'Ir al extracto',
    _ => 'Ir para extrato',
  };
}
