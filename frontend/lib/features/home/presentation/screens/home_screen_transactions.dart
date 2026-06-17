part of 'home_screen.dart';

class HomeTransactionsList extends ConsumerWidget {
  final VoidCallback onCreateWallet;
  final ValueChanged<Wallet> onDepositWallet;

  const HomeTransactionsList({
    super.key,
    required this.onCreateWallet,
    required this.onDepositWallet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(_homeActivityFilterProvider);
    if (selectedFilter == _HomeActivityFilter.notices) {
      return const _HomeNotificationsList();
    }

    final transactionsAsync = ref.watch(transactionHistoryProvider);
    final walletState = ref.watch(walletProvider);
    final activeWallet = walletState is WalletLoaded
        ? walletState.selectedWallet ??
            (walletState.wallets.isNotEmpty ? walletState.wallets.first : null)
        : null;

    return transactionsAsync.when(
      data: (txs) {
        final filteredTxs = _filterHomeTransactions(txs, selectedFilter);
        if (filteredTxs.isEmpty) {
          final hasWallet = activeWallet != null;
          final hasBalance = (activeWallet?.balance ?? 0) > 0;

          return Padding(
            padding: EdgeInsets.zero,
            child: _HomeEmptyTransactionsPanel(
              icon: !hasWallet
                  ? LucideIcons.wallet
                  : !hasBalance
                      ? LucideIcons.landmark
                      : LucideIcons.receipt,
              title: !hasWallet
                  ? context.tr.homeEmptyNoWalletTitle
                  : !hasBalance
                      ? context.tr.homeEmptyNoBalanceTitle
                      : context.tr.homeEmptyNoTransactionsTitle,
              description: !hasWallet
                  ? context.tr.homeEmptyNoWalletDescription
                  : !hasBalance
                      ? context.tr.homeEmptyNoBalanceDescription
                      : context.tr.homeEmptyNoTransactionsDescription,
              actionLabel: !hasWallet
                  ? context.tr.homeCreateWalletAction
                  : !hasBalance
                      ? context.tr.homeDepositAction
                      : context.tr.homeRefreshAction,
              actionIcon: !hasWallet
                  ? LucideIcons.arrowRight
                  : !hasBalance
                      ? LucideIcons.download
                      : LucideIcons.refreshCw,
              onAction: () {
                if (!hasWallet) {
                  onCreateWallet();
                  return;
                }

                if (!hasBalance) {
                  onDepositWallet(activeWallet);
                  return;
                }

                ref.invalidate(transactionHistoryProvider);
              },
            ),
          );
        }
        final visibleTxs = filteredTxs.take(6).toList(growable: false);

        return StatementTransactionScrollStack(
          itemCount: visibleTxs.length,
          itemExtent: _homeSize(174),
          itemGap: _homeSize(12),
          stackGap: _homeSize(114),
          topAnchorOffset: _homeSize(10),
          itemBuilder: (context, index) {
            return _buildTransactionTile(context, visibleTxs[index]);
          },
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: StateFeedbackView(
          state: FeedbackState.loading,
          title: context.tr.homeLoadingTransactionsTitle,
          description: context.tr.homeLoadingTransactionsSubtitle,
        ),
      ),
      error: (e, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: StateFeedbackView.networkError(
          context: context,
          onAction: () => ref.refresh(transactionHistoryProvider),
        ),
      ),
    );
  }

  static List<Transaction> _filterHomeTransactions(
    List<Transaction> txs,
    _HomeActivityFilter filter,
  ) {
    return switch (filter) {
      _HomeActivityFilter.platform => txs
          .where((tx) => tx.isInternal || tx.isLightning)
          .toList(growable: false),
      _HomeActivityFilter.onChain => txs
          .where((tx) => !tx.isInternal && !tx.isLightning)
          .toList(growable: false),
      _HomeActivityFilter.notices => const <Transaction>[],
    };
  }

  static Widget _buildTransactionTile(BuildContext context, Transaction tx) {
    return _HomeStatementTransactionLauncher(transaction: tx);
  }
}

class _HomeStatementTransactionLauncher extends StatefulWidget {
  final Transaction transaction;

  const _HomeStatementTransactionLauncher({required this.transaction});

  @override
  State<_HomeStatementTransactionLauncher> createState() =>
      _HomeStatementTransactionLauncherState();
}

class _HomeStatementTransactionLauncherState
    extends State<_HomeStatementTransactionLauncher> {
  final GlobalKey _originKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _originKey,
      child: StatementTransactionCard(
        transaction: widget.transaction,
        onTap: () {
          HapticFeedback.selectionClick();
          unawaited(
            deposits.loadLibrary().then((_) {
              if (context.mounted) {
                deposits.openTransactionStatement(
                  context,
                  originKey: _originKey,
                  initialTransactionId: widget.transaction.id,
                );
              }
            }),
          );
        },
      ),
    );
  }
}

class _HomeNotificationsList extends ConsumerWidget {
  const _HomeNotificationsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final visibleNotifications = notifications.take(6).toList(growable: false);

    if (visibleNotifications.isEmpty) {
      return _HomeEmptyTransactionsPanel(
        icon: LucideIcons.bellOff,
        title: _homeNoticeEmptyTitle(context),
        description: _homeNoticeEmptyDescription(context),
        actionLabel: _homeNoticeEmptyAction(context),
        actionIcon: LucideIcons.bell,
        onAction: () {
          unawaited(openNotificationCenter(context, originKey: GlobalKey()));
        },
      );
    }

    return Column(
      children: [
        for (var index = 0; index < visibleNotifications.length; index++) ...[
          if (index > 0) SizedBox(height: _homeSize(10)),
          _HomeNotificationCard(item: visibleNotifications[index]),
        ],
      ],
    );
  }
}

class _HomeNotificationCard extends ConsumerWidget {
  final SessionNotificationItem item;

  const _HomeNotificationCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = resolveNotificationVisuals(context, item);
    final accent = _homeNotificationAccent(visuals.tone);
    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : visuals.categoryLabel;
    final body = item.body.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          await ref
              .read(sessionNotificationFeedProvider.notifier)
              .markRead(item.id);
          if (context.mounted && item.isActionable) {
            await NotificationNavigation.openFromContext(context, item);
          }
        },
        borderRadius: BorderRadius.circular(_homeSize(18)),
        child: Ink(
          padding: EdgeInsets.all(_homeSize(14)),
          decoration: BoxDecoration(
            color: _homeCardColor,
            borderRadius: BorderRadius.circular(_homeSize(18)),
            border: Border.all(color: _homePanelBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: _homeSize(18),
                offset: Offset(0, _homeSize(8)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: _homeSize(42),
                height: _homeSize(42),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(visuals.icon, color: accent, size: _homeSize(20)),
              ),
              SizedBox(width: _homeSize(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: _homeFontSize(13),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                        SizedBox(width: _homeSize(8)),
                        Text(
                          _homeNotificationTimeLabel(context, item.timestamp),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    fontSize: _homeFontSize(10),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      SizedBox(height: _homeSize(6)),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: _homeFontSize(12),
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.read) ...[
                SizedBox(width: _homeSize(10)),
                Container(
                  width: _homeSize(7),
                  height: _homeSize(7),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color _homeNotificationAccent(AppNotificationTone tone) {
  return switch (tone) {
    AppNotificationTone.success => _homePositiveColor,
    AppNotificationTone.warning => const Color(0xFFF59E0B),
    AppNotificationTone.error => const Color(0xFFFF5A67),
    AppNotificationTone.info => const Color(0xFFA7B0BA),
    AppNotificationTone.neutral => const Color(0xFF9CA3AF),
  };
}

String _homeNotificationTimeLabel(BuildContext context, DateTime timestamp) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(timestamp.toLocal()),
    alwaysUse24HourFormat:
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}

String _homeNoticeEmptyTitle(BuildContext context) {
  return _homeLocalizedCopy(
    context,
    pt: 'Sem avisos',
    en: 'No alerts',
    es: 'Sin avisos',
  );
}

String _homeNoticeEmptyDescription(BuildContext context) {
  return _homeLocalizedCopy(
    context,
    pt: 'Quando houver notificações importantes do aplicativo, elas aparecerão aqui.',
    en: 'Important app notifications will appear here.',
    es: 'Las notificaciones importantes de la app aparecerán aquí.',
  );
}

String _homeNoticeEmptyAction(BuildContext context) {
  return _homeLocalizedCopy(
    context,
    pt: 'Ver central',
    en: 'Open center',
    es: 'Ver central',
  );
}

String _homeLocalizedCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}

class _HomeEmptyTransactionsPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _HomeEmptyTransactionsPanel({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(18)),
      padding: EdgeInsets.all(_homeSize(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _homeSize(40),
            height: _homeSize(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(_homeSize(12)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Icon(icon, color: Colors.white, size: _homeSize(18)),
          ),
          SizedBox(height: _homeSize(AppSpacing.lg)),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: _homeFontSize(16),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _homeSize(6)),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: _homeFontSize(12),
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _homeSize(AppSpacing.lg)),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(_homeSize(50)),
                backgroundColor: Colors.white,
                foregroundColor: _homeBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_homeSize(14)),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: _homeFontSize(14),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
              icon: Icon(actionIcon, size: _homeSize(16)),
              label: Text(actionLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
