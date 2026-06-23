// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'home_screen_dependencies.dart';
import 'home_screen.dart';
import 'home_screen_surface.dart';

class HomeTransactionsList extends ConsumerStatefulWidget {
  final VoidCallback onCreateWallet;
  final ValueChanged<Wallet> onDepositWallet;

  const HomeTransactionsList({
    super.key,
    required this.onCreateWallet,
    required this.onDepositWallet,
  });

  @override
  ConsumerState<HomeTransactionsList> createState() =>
      _HomeTransactionsListState();
}

class _HomeTransactionsListState extends ConsumerState<HomeTransactionsList> {
  String? _expandedTransactionId;

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(homeActivityFilterProvider);
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
            child: HomeEmptyTransactionsPanel(
              icon: !hasWallet
                  ? KeroseneIcons.wallet
                  : !hasBalance
                      ? KeroseneIcons.institution
                      : KeroseneIcons.history,
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
                  ? KeroseneIcons.next
                  : !hasBalance
                      ? KeroseneIcons.download
                      : KeroseneIcons.refresh,
              onAction: () {
                if (!hasWallet) {
                  widget.onCreateWallet();
                  return;
                }

                if (!hasBalance) {
                  widget.onDepositWallet(activeWallet);
                  return;
                }

                ref.invalidate(transactionHistoryProvider);
              },
            ),
          );
        }

        final visibleTxs = filteredTxs.take(6).toList(growable: false);
        final expandedIndex = _expandedTransactionId == null
            ? -1
            : visibleTxs.indexWhere(
                (tx) => tx.id == _expandedTransactionId,
              );

        return StatementTransactionScrollStack(
          itemCount: visibleTxs.length,
          itemExtent: homeSize(174),
          expandedItemExtent: homeSize(376),
          expandedIndex: expandedIndex >= 0 ? expandedIndex : null,
          itemGap: homeSize(12),
          stackGap: homeSize(114),
          topAnchorOffset: homeSize(10),
          itemBuilder: (context, index) {
            return _buildTransactionTile(
              visibleTxs[index],
              expanded: visibleTxs[index].id == _expandedTransactionId,
            );
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

  List<Transaction> _filterHomeTransactions(
    List<Transaction> txs,
    HomeActivityFilter filter,
  ) {
    return switch (filter) {
      HomeActivityFilter.all => txs,
      HomeActivityFilter.incoming =>
        txs.where((tx) => tx.isCredit).toList(growable: false),
      HomeActivityFilter.outgoing =>
        txs.where((tx) => tx.isDebit).toList(growable: false),
      HomeActivityFilter.pending => txs
          .where(
            (tx) =>
                tx.status == TransactionStatus.pending ||
                tx.status == TransactionStatus.confirming,
          )
          .toList(growable: false),
      HomeActivityFilter.failed => txs
          .where((tx) => tx.status == TransactionStatus.failed)
          .toList(growable: false),
    };
  }

  Widget _buildTransactionTile(
    Transaction tx, {
    required bool expanded,
  }) {
    return StatementTransactionCard(
      transaction: tx,
      expanded: expanded,
      mode: StatementTransactionCardMode.stacked,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _expandedTransactionId = expanded ? null : tx.id;
        });
      },
    );
  }
}

class HomeNotificationsList extends ConsumerWidget {
  const HomeNotificationsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final visibleNotifications = notifications.take(6).toList(growable: false);

    if (visibleNotifications.isEmpty) {
      return HomeEmptyTransactionsPanel(
        icon: KeroseneIcons.notificationsOff,
        title: homeNoticeEmptyTitle(context),
        description: homeNoticeEmptyDescription(context),
        actionLabel: homeNoticeEmptyAction(context),
        actionIcon: KeroseneIcons.notifications,
        onAction: () {
          unawaited(openNotificationCenter(context, originKey: GlobalKey()));
        },
      );
    }

    return Column(
      children: [
        for (var index = 0; index < visibleNotifications.length; index++) ...[
          if (index > 0) SizedBox(height: homeSize(10)),
          HomeNotificationCard(item: visibleNotifications[index]),
        ],
      ],
    );
  }
}

class HomeNotificationCard extends ConsumerWidget {
  final SessionNotificationItem item;

  const HomeNotificationCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = resolveNotificationVisuals(context, item);
    final accent = homeNotificationAccent(visuals.tone);
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
        borderRadius: BorderRadius.circular(homeSize(18)),
        child: Ink(
          padding: EdgeInsets.all(homeSize(14)),
          decoration: BoxDecoration(
            color: homeCardColor,
            borderRadius: BorderRadius.circular(homeSize(18)),
            border: Border.all(color: homePanelBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: homeSize(18),
                offset: Offset(0, homeSize(8)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: homeSize(42),
                height: homeSize(42),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(visuals.icon, color: accent, size: homeSize(20)),
              ),
              SizedBox(width: homeSize(12)),
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
                                  fontSize: homeFontSize(13),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                        SizedBox(width: homeSize(8)),
                        Text(
                          homeNotificationTimeLabel(context, item.timestamp),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    fontSize: homeFontSize(10),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      SizedBox(height: homeSize(6)),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: homeFontSize(12),
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.read) ...[
                SizedBox(width: homeSize(10)),
                Container(
                  width: homeSize(7),
                  height: homeSize(7),
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

Color homeNotificationAccent(AppNotificationTone tone) {
  return switch (tone) {
    AppNotificationTone.success => homePositiveColor,
    AppNotificationTone.warning => AppColors.hexFFF59E0B,
    AppNotificationTone.error => AppColors.hexFFFF5A67,
    AppNotificationTone.info => AppColors.hexFFA7B0BA,
    AppNotificationTone.neutral => AppColors.hexFF9CA3AF,
  };
}

String homeNotificationTimeLabel(BuildContext context, DateTime timestamp) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(timestamp.toLocal()),
    alwaysUse24HourFormat:
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}

String homeNoticeEmptyTitle(BuildContext context) {
  return homeLocalizedCopy(
    context,
    pt: 'Sem avisos',
    en: 'No alerts',
    es: 'Sin avisos',
  );
}

String homeNoticeEmptyDescription(BuildContext context) {
  return homeLocalizedCopy(
    context,
    pt: 'Quando houver notificações importantes do aplicativo, elas aparecerão aqui.',
    en: 'Important app notifications will appear here.',
    es: 'Las notificaciones importantes de la app aparecerán aquí.',
  );
}

String homeNoticeEmptyAction(BuildContext context) {
  return homeLocalizedCopy(
    context,
    pt: 'Ver central',
    en: 'Open center',
    es: 'Ver central',
  );
}

String homeLocalizedCopy(
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

class HomeEmptyTransactionsPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const HomeEmptyTransactionsPanel({
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

    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(18)),
      padding: EdgeInsets.all(homeSize(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: homeSize(40),
            height: homeSize(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(homeSize(12)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Icon(icon, color: Colors.white, size: homeSize(18)),
          ),
          SizedBox(height: homeSize(AppSpacing.lg)),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: homeFontSize(16),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(6)),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: homeFontSize(12),
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(AppSpacing.lg)),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(homeSize(50)),
                backgroundColor: Colors.white,
                foregroundColor: homeBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(homeSize(14)),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: homeFontSize(14),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
              icon: Icon(actionIcon, size: homeSize(16)),
              label: Text(actionLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
