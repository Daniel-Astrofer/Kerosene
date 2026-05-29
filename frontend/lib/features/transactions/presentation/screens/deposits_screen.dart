import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/transactions/presentation/widgets/statement_transaction_card.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart'
    show walletProvider;
import 'package:kerosene/features/wallet/presentation/screens/receive_amount_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_method.dart';
import 'package:kerosene/features/wallet/presentation/state/wallet_state.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

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
      return TransactionStatementScreen(
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

const _receiveBackground = Color(0xFF0D0D0D);
const _receiveSurfaceHigh = Color(0xFF2A2A2A);
const _receiveTextColor = Color(0xFFFFFFFF);
const _receiveMutedTextColor = Color(0xFFA3A3A3);
const _receiveBodyTextColor = Color(0xFFC4C7C8);
const _receiveSubtleTextColor = Color(0xFF737373);

enum _ReceivePanel { wallet, methods }

enum _ReceiveRail { kerosene, onChain }

class DepositsScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const DepositsScreen({
    super.key,
    this.initialWallet,
  });

  @override
  ConsumerState<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends ConsumerState<DepositsScreen> {
  _ReceivePanel _panel = _ReceivePanel.wallet;
  _ReceiveRail? _selectedRail;
  Wallet? _selectedWallet;

  bool _isOnChainWallet(Wallet wallet) {
    final mode = wallet.walletMode.trim().toUpperCase();
    return wallet.isSelfCustody ||
        mode.contains('COLD') ||
        mode.contains('ONCHAIN') ||
        mode.contains('ON_CHAIN');
  }

  bool _walletMatchesRail(Wallet wallet, _ReceiveRail rail) {
    return switch (rail) {
      _ReceiveRail.kerosene => !_isOnChainWallet(wallet),
      _ReceiveRail.onChain => _isOnChainWallet(wallet),
    };
  }

  Wallet? _resolveWallet(WalletState walletState, _ReceiveRail rail) {
    if (widget.initialWallet != null &&
        _walletMatchesRail(widget.initialWallet!, rail)) {
      return widget.initialWallet;
    }

    if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
      final selectedWallet = walletState.selectedWallet;
      if (selectedWallet != null && _walletMatchesRail(selectedWallet, rail)) {
        return selectedWallet;
      }
      for (final wallet in walletState.wallets) {
        if (_walletMatchesRail(wallet, rail)) {
          return wallet;
        }
      }
    }

    return null;
  }

  Route<T> _flowRoute<T>(WidgetBuilder builder) {
    return keroseneHorizontalRoute<T>(builder: builder);
  }

  void _handleBack() {
    if (_panel == _ReceivePanel.methods) {
      HapticFeedback.selectionClick();
      setState(() {
        _panel = _ReceivePanel.wallet;
        _selectedRail = null;
        _selectedWallet = null;
      });
      return;
    }
    Navigator.maybePop(context);
  }

  void _selectRail(_ReceiveRail rail) {
    final wallet = _resolveWallet(ref.read(walletProvider), rail);
    if (wallet == null) {
      _showWalletRequiredNotice(rail);
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _selectedRail = rail;
      _selectedWallet = wallet;
      _panel = _ReceivePanel.methods;
    });
  }

  void _openReceive(ReceiveAmountMethod method) {
    final rail = _selectedRail;
    final wallet = _selectedWallet ??
        (rail == null ? null : _resolveWallet(ref.read(walletProvider), rail));
    if (wallet == null) {
      _showWalletRequiredNotice(rail);
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).push<void>(
      _flowRoute(
        (_) => ReceiveAmountScreen(
          wallet: wallet,
          method: method,
          onChainWallet: rail == _ReceiveRail.onChain,
        ),
      ),
    );
  }

  void _openGatewayProviders() {
    final rail = _selectedRail;
    final wallet = _selectedWallet ??
        (rail == null ? null : _resolveWallet(ref.read(walletProvider), rail));
    if (wallet == null) {
      _showWalletRequiredNotice(rail);
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).push<void>(
      _flowRoute((_) => ReceiveGatewayProvidersScreen(wallet: wallet)),
    );
  }

  void _showWalletRequiredNotice([_ReceiveRail? rail]) {
    HapticFeedback.selectionClick();
    final message = switch (rail) {
      _ReceiveRail.kerosene => context.tr.receiveWalletInternalUnavailable,
      _ReceiveRail.onChain => context.tr.receiveWalletOnchainUnavailable,
      null => context.tr.receiveHubNoWalletMessage,
    };
    SnackbarHelper.showInfo(message);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: _receiveBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                _ReceiveTopBar(onBack: _handleBack),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _panel == _ReceivePanel.wallet
                        ? _buildWalletSelection()
                        : _buildMethodSelection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelection() {
    return LayoutBuilder(
      key: const ValueKey('receive-wallet'),
      builder: (context, constraints) {
        final minHeight = math.max(0.0, constraints.maxHeight - 48);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr.receiveWalletSelectionTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSerif(
                      color: _receiveTextColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr.receiveWalletSelectionSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _receiveMutedTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 42),
                  _ReceiveActionList(
                    children: [
                      _ReceiveActionTile(
                        icon: LucideIcons.arrowLeftRight,
                        title: context.tr.receiveWalletKeroseneTitle,
                        subtitle: context.tr.receiveWalletKeroseneSubtitle,
                        onTap: () => _selectRail(_ReceiveRail.kerosene),
                      ),
                      _ReceiveActionTile(
                        icon: LucideIcons.bitcoin,
                        title: context.tr.receiveWalletOnchainTitle,
                        subtitle: context.tr.receiveWalletOnchainSubtitle,
                        onTap: () => _selectRail(_ReceiveRail.onChain),
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodSelection() {
    final rail = _selectedRail ?? _ReceiveRail.kerosene;
    final isOnChain = rail == _ReceiveRail.onChain;
    final title = isOnChain
        ? context.tr.receiveMethodOnchainTitle
        : context.tr.receiveMethodKeroseneTitle;
    final subtitle = isOnChain
        ? context.tr.receiveMethodOnchainSubtitle
        : context.tr.receiveMethodKeroseneSubtitle;

    return SingleChildScrollView(
      key: ValueKey('receive-method-${rail.name}'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSerif(
              color: _receiveTextColor,
              fontSize: 48,
              fontWeight: FontWeight.w400,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: _receiveBodyTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 38),
          _ReceiveActionList(
            children: [
              if (!isOnChain)
                _ReceiveActionTile(
                  icon: LucideIcons.creditCard,
                  title: context.tr.receiveMethodGatewayTitle,
                  subtitle: context.tr.receiveMethodGatewaySubtitle,
                  onTap: _openGatewayProviders,
                  verticalPadding: 24,
                ),
              _ReceiveActionTile(
                icon: LucideIcons.qrCode,
                title: context.tr.receiveMethodQrTitle,
                subtitle: context.tr.receiveMethodQrSubtitle,
                onTap: () => _openReceive(ReceiveAmountMethod.qrCode),
                verticalPadding: 24,
              ),
              _ReceiveActionTile(
                icon: LucideIcons.link2,
                title: context.tr.receiveMethodPaymentLinkTitle,
                subtitle: context.tr.receiveMethodPaymentLinkSubtitle,
                onTap: () => _openReceive(ReceiveAmountMethod.paymentLink),
                verticalPadding: 24,
              ),
              _ReceiveActionTile(
                icon: LucideIcons.nfc,
                title: context.tr.receiveMethodNfcTitle,
                subtitle: context.tr.receiveMethodNfcSubtitle,
                onTap: () => _openReceive(ReceiveAmountMethod.nfc),
                showDivider: false,
                verticalPadding: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiveTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _ReceiveTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _ReceiveRoundButton(
                icon: LucideIcons.chevronLeft,
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            Text(
              context.tr.receive,
              style: GoogleFonts.inter(
                color: _receiveTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiveRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ReceiveRoundButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _receiveSurfaceHigh,
            ),
            child: Icon(icon, color: _receiveTextColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ReceiveActionList extends StatelessWidget {
  final List<_ReceiveActionTile> children;

  const _ReceiveActionList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _ReceiveActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final double verticalPadding;

  const _ReceiveActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.verticalPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _receiveSurfaceHigh,
                ),
                child: Icon(icon, color: _receiveTextColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _receiveTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.24,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _receiveMutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                color: _receiveMutedTextColor.withValues(alpha: 0.76),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiveGatewayProvidersScreen extends ConsumerWidget {
  final Wallet wallet;

  const ReceiveGatewayProvidersScreen({
    super.key,
    required this.wallet,
  });

  List<_GatewayProviderSection> _providerSections(BuildContext context) {
    final tr = context.tr;
    return [
      _GatewayProviderSection(
        title: tr.receiveGatewayRecommendedBrazil,
        providers: [
          _GatewayProvider(
            name: 'MoonPay',
            methods: tr.receiveGatewayMoonPayMethods,
            fees: tr.receiveGatewayMoonPayFees,
            icon: LucideIcons.creditCard,
            aliases: const ['moonpay'],
          ),
          _GatewayProvider(
            name: 'Banxa',
            methods: tr.receiveGatewayBanxaMethods,
            fees: tr.receiveGatewayBanxaFees,
            icon: LucideIcons.circleDollarSign,
            aliases: const ['banxa'],
          ),
          _GatewayProvider(
            name: 'Mercuryo',
            methods: tr.receiveGatewayMercuryoMethods,
            fees: tr.receiveGatewayMercuryoFees,
            icon: LucideIcons.smartphone,
            aliases: const ['mercuryo'],
          ),
          _GatewayProvider(
            name: 'Ramp Network',
            methods: tr.receiveGatewayRampMethods,
            fees: tr.receiveGatewayRampFees,
            icon: LucideIcons.trendingUp,
            aliases: const ['ramp', 'ramp_network', 'rampnetwork'],
          ),
        ],
      ),
      _GatewayProviderSection(
        title: tr.receiveGatewayInstitutional,
        providers: [
          _GatewayProvider(
            name: 'Stripe Crypto Onramp',
            methods: tr.receiveGatewayStripeMethods,
            fees: tr.receiveGatewayStripeFees,
            icon: LucideIcons.building2,
            badge: tr.receiveGatewayInstitutionalBadge,
            aliases: const [
              'stripe',
              'stripe_crypto_onramp',
              'stripe_onramp',
            ],
          ),
          _GatewayProvider(
            name: 'Coinbase Onramp',
            methods: tr.receiveGatewayCoinbaseMethods,
            fees: tr.receiveGatewayCoinbaseFees,
            icon: LucideIcons.database,
            badge: tr.receiveGatewayInstitutionalBadge,
            aliases: const ['coinbase', 'coinbase_onramp'],
          ),
        ],
      ),
      _GatewayProviderSection(
        title: tr.receiveGatewayAggregators,
        providers: [
          _GatewayProvider(
            name: 'Onramper',
            methods: tr.receiveGatewayOnramperMethods,
            fees: tr.receiveGatewayOnramperFees,
            icon: LucideIcons.boxes,
            aliases: const ['onramper'],
          ),
        ],
      ),
      _GatewayProviderSection(
        title: tr.receiveGatewayOther,
        providers: [
          _GatewayProvider(
            name: 'Transak',
            methods: tr.receiveGatewayTransakMethods,
            fees: tr.receiveGatewayTransakFees,
            icon: LucideIcons.arrowLeftRight,
            aliases: const ['transak'],
          ),
          _GatewayProvider(
            name: 'Wert',
            methods: tr.receiveGatewayWertMethods,
            fees: tr.receiveGatewayWertFees,
            icon: LucideIcons.zap,
            aliases: const ['wert'],
          ),
          _GatewayProvider(
            name: 'GateFi / Unlimit',
            methods: tr.receiveGatewayGateFiMethods,
            fees: tr.receiveGatewayGateFiFees,
            icon: LucideIcons.globe2,
            aliases: const ['gatefi', 'unlimit', 'gatefi_unlimit'],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlsAsync = ref.watch(_receiveGatewayProviderUrlsProvider);
    final providers = _providerSections(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(LucideIcons.arrowLeft, size: 24),
                        color: _receiveTextColor,
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr.receiveGatewayProvidersTitle,
                        style: GoogleFonts.ibmPlexSerif(
                          color: _receiveTextColor,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: urlsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: _receiveMutedTextColor,
                      ),
                    ),
                    error: (_, __) => _GatewayProviderList(
                      sections: providers,
                      urls: const {},
                      onSelect: (provider) =>
                          _showProviderUnavailable(context, provider),
                    ),
                    data: (urls) => _GatewayProviderList(
                      sections: providers,
                      urls: urls,
                      onSelect: (provider) =>
                          _selectProvider(context, provider, urls),
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

  void _selectProvider(
    BuildContext context,
    _GatewayProvider provider,
    Map<String, String> urls,
  ) {
    final url = provider.resolveUrl(urls);
    if (url == null || url.isEmpty) {
      _showProviderUnavailable(context, provider);
      return;
    }

    Clipboard.setData(ClipboardData(text: url));
    SnackbarHelper.showSuccess(
      context.tr.receiveGatewayLinkCopied(provider.name, wallet.name),
    );
  }

  void _showProviderUnavailable(
    BuildContext context,
    _GatewayProvider provider,
  ) {
    SnackbarHelper.showInfo(
      context.tr.receiveGatewayProviderUnavailable(provider.name),
    );
  }
}

final _receiveGatewayProviderUrlsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final result = await ref.read(transactionRepositoryProvider).getOnrampUrls();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (urls) => urls,
  );
});

class _GatewayProviderList extends StatelessWidget {
  final List<_GatewayProviderSection> sections;
  final Map<String, String> urls;
  final ValueChanged<_GatewayProvider> onSelect;

  const _GatewayProviderList({
    required this.sections,
    required this.urls,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 30),
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _receiveMutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 1.4,
                  ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < section.providers.length; index++) ...[
              if (index > 0) const SizedBox(height: 24),
              _GatewayProviderTile(
                provider: section.providers[index],
                available: section.providers[index].resolveUrl(urls) != null,
                onTap: () => onSelect(section.providers[index]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GatewayProviderTile extends StatelessWidget {
  final _GatewayProvider provider;
  final bool available;
  final VoidCallback onTap;

  const _GatewayProviderTile({
    required this.provider,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E1E1E),
              ),
              child: Icon(
                provider.icon,
                color: _receiveMutedTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          provider.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _receiveTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                      if (provider.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _receiveMutedTextColor.withValues(
                                alpha: 0.56,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            provider.badge!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: _receiveMutedTextColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    provider.methods,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _receiveMutedTextColor,
                          fontSize: 12,
                          height: 1.25,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    available
                        ? provider.fees
                        : '${provider.fees} • ${context.tr.receiveGatewayComingSoon}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _receiveSubtleTextColor,
                          fontSize: 12,
                          height: 1.25,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFF525252),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _GatewayProviderSection {
  final String title;
  final List<_GatewayProvider> providers;

  const _GatewayProviderSection({
    required this.title,
    required this.providers,
  });
}

class _GatewayProvider {
  final String name;
  final String methods;
  final String fees;
  final IconData icon;
  final String? badge;
  final List<String> aliases;

  const _GatewayProvider({
    required this.name,
    required this.methods,
    required this.fees,
    required this.icon,
    required this.aliases,
    this.badge,
  });

  String? resolveUrl(Map<String, String> urls) {
    for (final entry in urls.entries) {
      final normalizedKey = _normalize(entry.key);
      for (final alias in aliases) {
        if (normalizedKey == _normalize(alias)) {
          final value = entry.value.trim();
          return value.isEmpty ? null : value;
        }
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

enum _StatementFilter { all, incoming, outgoing }

class TransactionStatementScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const TransactionStatementScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<TransactionStatementScreen> createState() =>
      _TransactionStatementScreenState();
}

class _TransactionStatementScreenState
    extends ConsumerState<TransactionStatementScreen> {
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
                            context.tr.financialStatementTitle,
                            style: GoogleFonts.ibmPlexSerif(
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
                            title: context.tr.financialStatementLoadErrorTitle,
                            message: ErrorTranslator.translate(
                              context.tr,
                              error.toString(),
                            ),
                          ),
                        ),
                        data: (transactions) {
                          final rows = _filtered(transactions);
                          if (rows.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _StatementMessage(
                                icon: LucideIcons.receipt,
                                title: context.tr.financialStatementEmptyTitle,
                                message:
                                    context.tr.financialStatementEmptyMessage,
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
  settings('/settings', LucideIcons.settings);

  final String route;
  final IconData icon;

  const _StatementMenuDestination(this.route, this.icon);

  String label(BuildContext context) {
    return switch (this) {
      _StatementMenuDestination.home => context.tr.primaryNavHome,
      _StatementMenuDestination.card => context.tr.primaryNavCard,
      _StatementMenuDestination.history => context.tr.primaryNavHistory,
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
                hintText: context.tr.financialStatementSearchHint,
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
            label: context.tr.financialStatementFilterAll,
            selected: selected == _StatementFilter.all,
            onTap: () => onChanged(_StatementFilter.all),
          ),
          _StatementTab(
            label: context.tr.financialStatementFilterIncoming,
            selected: selected == _StatementFilter.incoming,
            onTap: () => onChanged(_StatementFilter.incoming),
          ),
          _StatementTab(
            label: context.tr.financialStatementFilterOutgoing,
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
