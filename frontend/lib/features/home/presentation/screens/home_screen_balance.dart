// ignore_for_file: unused_element

part of 'home_screen.dart';

class _HomeBalanceSection extends ConsumerStatefulWidget {
  final String userName;
  final WalletState walletState;
  final Wallet? activeWallet;
  final VoidCallback onReceive;
  final VoidCallback onSend;
  final VoidCallback onViewStatement;
  final VoidCallback onOpenWallets;

  const _HomeBalanceSection({
    required this.userName,
    required this.walletState,
    required this.activeWallet,
    required this.onReceive,
    required this.onSend,
    required this.onViewStatement,
    required this.onOpenWallets,
  });

  @override
  ConsumerState<_HomeBalanceSection> createState() =>
      _HomeBalanceSectionState();
}

class _HomeBalanceSectionState extends ConsumerState<_HomeBalanceSection> {
  late final PageController _pageController;
  final GlobalKey _notificationButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(_homeLedgerBalancePageProvider),
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
    final priceFeedActive = ref.watch(_homeRouteActiveProvider);
    final btcUsd = priceFeedActive ? ref.watch(latestBtcPriceProvider) : null;
    final btcEur = priceFeedActive ? ref.watch(btcEurPriceProvider) : null;
    final btcBrl = priceFeedActive ? ref.watch(btcBrlPriceProvider) : null;
    final btcDailyChangePercent =
        priceFeedActive ? ref.watch(btcDailyChangePercentProvider) : null;
    final selectedView = ref.watch(_homeLedgerBalanceViewProvider);
    final selectedPage = ref.watch(_homeLedgerBalancePageProvider);
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

    int pageForView(_HomeLedgerBalanceView view) {
      if (view == _HomeLedgerBalanceView.total) {
        return 0;
      }
      final index = wallets.indexWhere((wallet) =>
          view == _HomeLedgerBalanceView.onChain
              ? wallet.isColdWallet
              : !wallet.isColdWallet);
      return index < 0 ? 0 : index + 1;
    }

    ref.listen<_HomeLedgerBalanceView>(_homeLedgerBalanceViewProvider, (
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
        _HomeBalanceCardData.forWallet(
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

    _HomeBalanceCardData cardDataFor(_HomeLedgerBalanceView view) {
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
          isDailyChangePositive ? _homePositiveColor : AppColors.hexFFFF5A67;
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

      return _HomeBalanceCardData(
        view: view,
        wallet: view == _HomeLedgerBalanceView.total ? null : primaryWallet,
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
      ref.read(_homeLedgerBalancePageProvider.notifier).state = page;
      final walletIndex = page - 1;
      final wallet = walletIndex >= 0 && walletIndex < walletCardData.length
          ? walletCardData[walletIndex].wallet
          : null;
      final view = page == 0
          ? _HomeLedgerBalanceView.total
          : wallet?.isColdWallet == true
              ? _HomeLedgerBalanceView.onChain
              : _HomeLedgerBalanceView.platform;
      ref.read(_homeLedgerBalanceViewProvider.notifier).state = view;
      if (view == _HomeLedgerBalanceView.platform) {
        ref.read(_homeActivityFilterProvider.notifier).state =
            _HomeActivityFilter.platform;
      } else if (view == _HomeLedgerBalanceView.onChain) {
        ref.read(_homeActivityFilterProvider.notifier).state =
            _HomeActivityFilter.onChain;
      }
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
                        tiny: _homeFontSize(22),
                        compact: _homeFontSize(24),
                        regular: _homeFontSize(25),
                      ),
                    ),
                    fontWeight: FontWeight.w300,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            SizedBox(width: _homeSize(12)),
            _HomeHeaderIconButton(
              icon: balanceSettings.isHidden
                  ? KeroseneIcons.eyeOff
                  : KeroseneIcons.eye,
              onTap: toggleVisibility,
            ),
            SizedBox(width: _homeSize(8)),
            _HomeHeaderIconButton(
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
        SizedBox(height: _homeSize(18)),
        SizedBox(
          height: responsive.isTinyPhone ? _homeSize(276) : _homeSize(286),
          child: walletCardData.isEmpty
              ? _HomeBalanceCard(
                  data: walletCardData.isNotEmpty
                      ? walletCardData.first
                      : cardDataFor(_HomeLedgerBalanceView.total),
                  onViewStatement: widget.onViewStatement,
                  onOpenWallets: widget.onOpenWallets,
                )
              : PageView(
                  key: const ValueKey('home-balance-carousel'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: selectPage,
                  children: [
                    _HomeBalanceCard(
                      data: cardDataFor(_HomeLedgerBalanceView.total),
                      onViewStatement: widget.onViewStatement,
                      onOpenWallets: widget.onOpenWallets,
                    ),
                    for (final data in walletCardData)
                      _HomeBalanceCard(
                        data: data,
                        onViewStatement: widget.onViewStatement,
                        onOpenWallets: widget.onOpenWallets,
                      ),
                  ],
                ),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            Expanded(
              child: _HomeBalanceActionButton(
                icon: KeroseneIcons.down,
                label: context.tr.homeReceiveActionShort,
                onTap: widget.onReceive,
                primary: true,
              ),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeBalanceActionButton(
                icon: KeroseneIcons.up,
                label: context.tr.homeSendTitle,
                onTap: widget.onSend,
                primary: false,
              ),
            ),
          ],
        ),
        SizedBox(height: _homeSize(14)),
        if (walletCardData.isNotEmpty)
          _HomePaginationDots(
            count: walletCardData.length + 1,
            activeIndex: selectedPage.clamp(
              selectedView == _HomeLedgerBalanceView.total ? 0 : 0,
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
        ? _homePositiveColor
        : AppColors.hexFFFF5A67;
  }

  static int _pageIndexFor(_HomeLedgerBalanceView view) {
    return switch (view) {
      _HomeLedgerBalanceView.total => 0,
      _HomeLedgerBalanceView.platform => 1,
      _HomeLedgerBalanceView.onChain => 2,
    };
  }

  static List<Wallet> _walletsForView(
    List<Wallet> wallets,
    _HomeLedgerBalanceView view,
  ) {
    if (view == _HomeLedgerBalanceView.total) {
      return wallets;
    }

    final filtered = wallets
        .where(
          (wallet) => view == _HomeLedgerBalanceView.onChain
              ? wallet.isSelfCustody
              : wallet.isKeroseneCustody,
        )
        .toList(growable: false);
    return filtered;
  }

  static Wallet? _primaryWalletForView({
    required Wallet? activeWallet,
    required List<Wallet> scopedWallets,
    required _HomeLedgerBalanceView view,
  }) {
    if (view == _HomeLedgerBalanceView.total) {
      return activeWallet ??
          (scopedWallets.isNotEmpty ? scopedWallets.first : null);
    }

    final activeMatches = activeWallet != null &&
        (view == _HomeLedgerBalanceView.onChain
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
        .clamp(_homeFontSize(14), baseFontSize);
  }
}

class _HomeBalanceCardData {
  final _HomeLedgerBalanceView view;
  final Wallet? wallet;
  final double balanceBtc;
  final String convertedBalanceLabel;
  final String dailyChangeLabel;
  final Color dailyChangeColor;
  final int decimalPlaces;
  final bool balanceHidden;

  const _HomeBalanceCardData({
    required this.view,
    required this.wallet,
    required this.balanceBtc,
    required this.convertedBalanceLabel,
    required this.dailyChangeLabel,
    required this.dailyChangeColor,
    required this.decimalPlaces,
    required this.balanceHidden,
  });

  factory _HomeBalanceCardData.forWallet({
    required Wallet wallet,
    required String convertedBalanceLabel,
    required String dailyChangeLabel,
    required Color dailyChangeColor,
    required int decimalPlaces,
    required bool balanceHidden,
  }) {
    return _HomeBalanceCardData(
      view: wallet.isColdWallet
          ? _HomeLedgerBalanceView.onChain
          : _HomeLedgerBalanceView.platform,
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

class _HomeBalanceCard extends ConsumerWidget {
  final _HomeBalanceCardData data;
  final VoidCallback onViewStatement;
  final VoidCallback onOpenWallets;

  const _HomeBalanceCard({
    required this.data,
    required this.onViewStatement,
    required this.onOpenWallets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final isTotal = data.view == _HomeLedgerBalanceView.total;
    final title = isTotal
        ? _homeTotalBalanceTitle(context)
        : data.wallet?.custodyDisplayLabel ??
            switch (data.view) {
              _HomeLedgerBalanceView.platform =>
                _homeInternalBalanceTitle(context),
              _HomeLedgerBalanceView.onChain =>
                _homeOnchainBalanceTitle(context),
              _HomeLedgerBalanceView.total => _homeTotalBalanceTitle(context),
            };
    final walletName =
        _nonEmpty(data.wallet?.name, _homeGlobalWalletTitle(context));
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
                        color: _homeMutedTextColor,
                        fontSize: _homeFontSize(12),
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
                  width: _homeSize(32),
                  height: _homeSize(32),
                ),
                icon: Icon(
                  KeroseneIcons.send,
                  size: _homeSize(20),
                  color: _homeMutedTextColor,
                ),
              ),
          ],
        ),
        SizedBox(height: _homeSize(10)),
        if (data.wallet != null) ...[
          Text(
            walletName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: _homeFontSize(14),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _homeSize(15)),
        ] else
          SizedBox(height: _homeSize(24)),
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
                style: AppTypography.amountInput(isBtc: true).copyWith(
                  color: Colors.white,
                  fontSize: responsive.compactFontSize(
                    tiny: _homeFontSize(isTotal ? 36 : 32),
                    compact: _homeFontSize(isTotal ? 42 : 38),
                    regular: _homeFontSize(isTotal ? 46 : 42),
                  ),
                  letterSpacing: 0,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: _homeSize(6),
                  bottom: _homeSize(4),
                ),
                child: Text(
                  btcUnitLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _homeMutedTextColor,
                    fontSize: _homeFontSize(16),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(5)),
        Text(
          data.convertedBalanceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _homeMutedTextColor,
            fontSize: _homeFontSize(14),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: _homeSize(5)),
        Row(
          children: [
            Icon(
              data.dailyChangeColor == _homePositiveColor
                  ? KeroseneIcons.up
                  : KeroseneIcons.down,
              color: data.dailyChangeColor,
              size: _homeSize(12),
            ),
            SizedBox(width: _homeSize(5)),
            Flexible(
              child: Text(
                data.dailyChangeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: data.dailyChangeColor,
                  fontSize: _homeFontSize(13),
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
          _homeSize(6),
          _homeSize(20),
          _homeSize(6),
          _homeSize(20),
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
      child: _HomeGlassPanel(
        borderRadius: BorderRadius.circular(_homeSize(18)),
        padding: EdgeInsets.all(_homeSize(20)),
        child: content,
      ),
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

class _HomeAvatar extends StatelessWidget {
  final String name;

  const _HomeAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(name);

    return Container(
      width: _homeSize(40),
      height: _homeSize(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _homeCardColor,
        border: Border.all(color: _homePanelBorderColor),
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

String _homeInternalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Internal balance',
    'es' => 'Saldo interno',
    _ => 'Saldo Interno',
  };
}

String _homeOnchainBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain balance',
    'es' => 'Saldo On-chain',
    _ => 'Saldo Onchain',
  };
}

String _homeTotalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total balance',
    'es' => 'Saldo total',
    _ => 'Saldo Total',
  };
}

String _homeGlobalWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Global wallet',
    'es' => 'Cartera global',
    _ => 'Carteira Global',
  };
}

String _homeConsolidatedWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total Balance',
    'es' => 'Saldo Total',
    _ => 'Saldo Total',
  };
}

String _homeOnchainWalletCardTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain wallet',
    'es' => 'Cartera On-chain',
    _ => 'Carteira On-chain',
  };
}

String _homeStatementActionLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Go to statement',
    'es' => 'Ir al extracto',
    _ => 'Ir para extrato',
  };
}
