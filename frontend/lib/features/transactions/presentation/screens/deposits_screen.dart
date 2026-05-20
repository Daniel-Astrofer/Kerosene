import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/statement_transaction_card.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/l10n/l10n_extension.dart';

Future<void> openTransactionStatement(
  BuildContext context, {
  required GlobalKey originKey,
  String? initialTransactionId,
}) {
  final navigator = Navigator.of(context);
  final overlayObject = navigator.overlay?.context.findRenderObject();
  final overlayBox = overlayObject is RenderBox ? overlayObject : null;
  final originRect = _originRectForKey(originKey, overlayBox) ??
      _fallbackOriginRect(MediaQuery.sizeOf(context));

  return navigator.push<void>(
    _transactionStatementRoute(
      originRect: originRect,
      initialTransactionId: initialTransactionId,
    ),
  );
}

Rect? _originRectForKey(GlobalKey key, RenderBox? overlayBox) {
  if (overlayBox == null) return null;
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: overlayBox);
  return topLeft & renderObject.size;
}

Rect _fallbackOriginRect(Size size) {
  return Rect.fromLTWH(size.width / 2 - 28, size.height - 120, 56, 56);
}

Route<void> _transactionStatementRoute({
  required Rect originRect,
  String? initialTransactionId,
}) {
  return PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return DepositsScreen(
        initialTransactionId: initialTransactionId,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      if (reduceMotion) {
        return FadeTransition(opacity: curved, child: child);
      }

      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final center = Offset(originRect.center.dx, originRect.bottom);
          final startRadius = math.max(originRect.width, originRect.height) / 2;
          final endRadius = _distanceToFarthestCorner(center, size);
          final radius = startRadius + (endRadius - startRadius) * curved.value;
          final opacity = const Interval(
            0.10,
            0.78,
            curve: Curves.easeOutCubic,
          ).transform(curved.value);

          return ClipPath(
            clipper: _CircularRevealClipper(center: center, radius: radius),
            child: Opacity(opacity: opacity, child: child),
          );
        },
      );
    },
  );
}

double _distanceToFarthestCorner(Offset center, Size size) {
  return [
    Offset.zero,
    Offset(size.width, 0),
    Offset(0, size.height),
    Offset(size.width, size.height),
  ].map((corner) => (corner - center).distance).reduce(math.max);
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _CircularRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

enum _StatementFilter { all, incoming, outgoing }

class DepositsScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const DepositsScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends ConsumerState<DepositsScreen> {
  final ScrollController _scrollController = ScrollController();
  _StatementFilter _filter = _StatementFilter.all;
  String _query = '';
  String? _expandedTransactionId;

  @override
  void initState() {
    super.initState();
    _expandedTransactionId = widget.initialTransactionId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    ref.invalidate(transactionHistoryProvider);
    await ref.read(transactionHistoryProvider.future);
  }

  void _updateFilter(_StatementFilter value) {
    if (value == _filter) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filter = value;
      _expandedTransactionId = null;
    });
    _scrollToTop();
  }

  void _updateQuery(String value) {
    if (value == _query) return;
    setState(() {
      _query = value;
      _expandedTransactionId = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 132.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF1C1C1E),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                          child: _StatementTopBar(
                            onBack: () => Navigator.maybePop(context),
                            onSearchChanged: _updateQuery,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                          child: Text(
                            'Transações',
                            style: GoogleFonts.ebGaramond(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: _StatementTabs(
                            selected: _filter,
                            onChanged: _updateFilter,
                          ),
                        ),
                      ),
                      historyAsync.when(
                        loading: () => const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        error: (error, _) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: _StatementMessage(
                            icon: LucideIcons.alertCircle,
                            title: 'Não foi possível carregar',
                            message: ErrorTranslator.translate(
                              context.tr,
                              error.toString(),
                            ),
                          ),
                        ),
                        data: (transactions) {
                          final rows = _filtered(transactions);
                          if (rows.isEmpty) {
                            return const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _StatementMessage(
                                icon: LucideIcons.receipt,
                                title: 'Sem transações',
                                message:
                                    'As movimentações da conta aparecerão aqui.',
                              ),
                            );
                          }

                          final expandedTransactionId = _expandedTransactionId;
                          final expandedIndex = expandedTransactionId == null
                              ? -1
                              : rows.indexWhere(
                                  (tx) => tx.id == expandedTransactionId,
                                );
                          final hasExpanded = expandedIndex >= 0;
                          if (hasExpanded) {
                            final selected = rows[expandedIndex];
                            final otherRows = rows
                                .where((tx) => tx.id != selected.id)
                                .toList(growable: false);
                            return SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                bottomPadding,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    _buildTransactionCard(
                                      selected,
                                      0,
                                      forceExpanded: true,
                                      hasAnyExpanded: true,
                                    ),
                                    const SizedBox(height: 14),
                                    StatementTransactionScrollStack(
                                      key: ValueKey(
                                        'statement-stack-expanded-${selected.id}-${rows.length}',
                                      ),
                                      itemCount: otherRows.length,
                                      itemExtent: 174,
                                      itemGap: 12,
                                      stackGap: 114,
                                      topAnchorOffset: 390,
                                      collapseStartFraction: 0.75,
                                      itemBuilder: (context, index) =>
                                          _buildTransactionCard(
                                        otherRows[index],
                                        index + 1,
                                        hasAnyExpanded: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              24,
                              24,
                              bottomPadding,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: StatementTransactionScrollStack(
                                key: ValueKey(
                                  'statement-stack-${_filter.name}-${_query.trim()}-${rows.length}',
                                ),
                                itemCount: rows.length,
                                itemExtent: 174,
                                itemGap: 12,
                                stackGap: 114,
                                topAnchorOffset: 12,
                                collapseStartFraction: 0.75,
                                itemBuilder: (context, index) =>
                                    _buildTransactionCard(
                                  rows[index],
                                  index,
                                  hasAnyExpanded: false,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const _StatementFloatingMenuOverlay(),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction tx,
    int index, {
    bool forceExpanded = false,
    required bool hasAnyExpanded,
  }) {
    final expanded = forceExpanded || tx.id == _expandedTransactionId;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final card = Padding(
      padding:
          EdgeInsets.only(bottom: hasAnyExpanded && !forceExpanded ? 14 : 0),
      child: StatementTransactionCard(
        transaction: tx,
        expanded: expanded,
        mode: hasAnyExpanded
            ? StatementTransactionCardMode.separated
            : StatementTransactionCardMode.stacked,
        onTap: () {
          HapticFeedback.selectionClick();
          if (forceExpanded) return;
          setState(() {
            _expandedTransactionId = expanded ? null : tx.id;
          });
        },
      ),
    );

    if (reduceMotion || hasAnyExpanded) return card;
    return card
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: (80 + index * 45).ms,
          curve: Curves.easeOutCubic,
          begin: 0.16,
        )
        .slideY(
          begin: 0.035,
          end: 0,
          duration: 340.ms,
          delay: (80 + index * 45).ms,
          curve: Curves.easeOutCubic,
        );
  }

  List<Transaction> _filtered(List<Transaction> source) {
    final query = _query.trim().toLowerCase();
    final rows = source.where((tx) {
      final directionMatches = switch (_filter) {
        _StatementFilter.all => true,
        _StatementFilter.incoming => tx.type == TransactionType.receive ||
            tx.type == TransactionType.deposit,
        _StatementFilter.outgoing => tx.type == TransactionType.send ||
            tx.type == TransactionType.withdrawal ||
            tx.type == TransactionType.fee,
      };
      if (!directionMatches) return false;
      if (query.isEmpty) return true;
      final haystack = [
        tx.id,
        tx.fromAddress,
        tx.toAddress,
        tx.description,
        tx.blockchainTxid,
        tx.externalReference,
        tx.invoiceId,
        tx.paymentHash,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
    rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return rows;
  }
}

enum _StatementMenuDestination {
  home('/home', LucideIcons.home),
  card('/card', LucideIcons.walletCards),
  history('/history', LucideIcons.receipt),
  mining('/mining', LucideIcons.zap),
  settings('/settings', LucideIcons.settings);

  final String route;
  final IconData icon;

  const _StatementMenuDestination(this.route, this.icon);

  String label(BuildContext context) {
    return switch (this) {
      _StatementMenuDestination.home => context.tr.primaryNavHome,
      _StatementMenuDestination.card => context.tr.primaryNavCard,
      _StatementMenuDestination.history => context.tr.primaryNavHistory,
      _StatementMenuDestination.mining => context.tr.primaryNavMining,
      _StatementMenuDestination.settings => context.tr.primaryNavSettings,
    };
  }
}

class _StatementFloatingMenuOverlay extends StatelessWidget {
  const _StatementFloatingMenuOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(0, 0, 24, 32),
              child: Align(
                alignment: Alignment.bottomRight,
                child: _StatementFloatingMenuButton(
                  currentDestination: _StatementMenuDestination.history,
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 128,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementFloatingMenuButton extends StatelessWidget {
  final _StatementMenuDestination currentDestination;

  const _StatementFloatingMenuButton({required this.currentDestination});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MaterialLocalizations.of(context).showMenuTooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            _showMenu(context);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF101010),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.menu, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF101010).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final destination in _StatementMenuDestination.values)
                    _StatementMenuDestinationTile(
                      destination: destination,
                      selected: destination == currentDestination,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatementMenuDestinationTile extends StatelessWidget {
  final _StatementMenuDestination destination;
  final bool selected;

  const _StatementMenuDestinationTile({
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFCE353) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  destination.route,
                  (route) => false,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(destination.icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  destination.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.check,
                  color: Color(0xFFFCE353),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementTopBar extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;

  const _StatementTopBar({
    required this.onBack,
    required this.onSearchChanged,
  });

  @override
  State<_StatementTopBar> createState() => _StatementTopBarState();
}

class _StatementTopBarState extends State<_StatementTopBar> {
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return Row(
        children: [
          _RoundIconButton(
            icon: LucideIcons.chevronLeft,
            onPressed: () {
              widget.onSearchChanged('');
              setState(() => _searching = false);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: widget.onSearchChanged,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF8A8A8E),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(
            icon: LucideIcons.chevronLeft, onPressed: widget.onBack),
        _RoundIconButton(
          icon: LucideIcons.search,
          onPressed: () => setState(() => _searching = true),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _StatementTabs extends StatelessWidget {
  final _StatementFilter selected;
  final ValueChanged<_StatementFilter> onChanged;

  const _StatementTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _StatementTab(
            label: 'Todas',
            selected: selected == _StatementFilter.all,
            onTap: () => onChanged(_StatementFilter.all),
          ),
          _StatementTab(
            label: 'Recebidas',
            selected: selected == _StatementFilter.incoming,
            onTap: () => onChanged(_StatementFilter.incoming),
          ),
          _StatementTab(
            label: 'Enviadas',
            selected: selected == _StatementFilter.outgoing,
            onTap: () => onChanged(_StatementFilter.outgoing),
          ),
        ],
      ),
    );
  }
}

class _StatementTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatementTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2C2C2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : const Color(0xFF8A8A8E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatementMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.64), size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF8A8A8E),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
