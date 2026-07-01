import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/movement/flow/movement_flow_coordinator.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    show walletProvider;
import 'package:kerosene/features/movement/screens/movement_amount_screen.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/movement/flow/receive_nfc_availability_provider.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'statement_screen.dart';

export 'statement_screen.dart';

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
    transitionDuration: KeroseneMotion.long,
    reverseTransitionDuration: KeroseneMotion.medium,
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
        curve: KeroseneMotion.standard,
        reverseCurve: KeroseneMotion.exit,
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
            curve: KeroseneMotion.standard,
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

const _receiveBackground = AppColors.hexFF0D0D0D;
const _receiveSurfaceHigh = AppColors.hexFF2A2A2A;
const _receiveTextColor = AppColors.hexFFFFFFFF;
const _receiveMutedTextColor = AppColors.hexFFA3A3A3;
const _receiveBodyTextColor = AppColors.hexFFC4C7C8;
const _receiveSubtleTextColor = AppColors.hexFF737373;

class MovementHubScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const MovementHubScreen({
    super.key,
    this.initialWallet,
  });

  @override
  ConsumerState<MovementHubScreen> createState() => _MovementHubScreenState();
}

class _MovementHubScreenState extends ConsumerState<MovementHubScreen> {
  Route<T> _flowRoute<T>(WidgetBuilder builder) {
    return keroseneHorizontalRoute<T>(builder: builder);
  }

  void _openReceive(ReceiveAmountMethod method) {
    final wallet = _resolveWallet(ref.read(walletProvider));
    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final nfcCompatible =
        ref.read(receiveNfcCompatibilityProvider).asData?.value ?? true;
    if (method == ReceiveAmountMethod.nfc && !nfcCompatible) {
      return;
    }

    ref.read(movementFlowCoordinatorProvider.notifier).configureReceive(
          wallet: wallet,
          method: method,
          nfcCompatible: nfcCompatible,
        );
    HapticFeedback.lightImpact();
    Navigator.of(context).push<void>(
      _flowRoute(
        (_) => MovementAmountScreen(
          wallet: wallet,
          method: method,
          onChainWallet: isReceiveOnChainWallet(wallet),
        ),
      ),
    );
  }

  void _openGatewayProviders() {
    final wallet = _resolveWallet(ref.read(walletProvider));
    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).push<void>(
      _flowRoute((_) => ReceiveGatewayProvidersScreen(wallet: wallet)),
    );
  }

  void _showWalletRequiredNotice() {
    HapticFeedback.selectionClick();
    SnackbarHelper.showInfo(context.tr.receiveHubNoWalletMessage);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final selectedWallet = _resolveWallet(walletState);
    final nfcCompatibility = ref.watch(receiveNfcCompatibilityProvider);
    final canShowNfc = nfcCompatibility.asData?.value ?? true;

    if (widget.initialWallet == null &&
        (walletState is WalletInitial || walletState is WalletLoading)) {
      return const KeroseneLogoLoadingView();
    }

    return Scaffold(
      backgroundColor: _receiveBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                _ReceiveTopBar(onBack: () => Navigator.maybePop(context)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: KeroseneMotion.medium,
                    switchInCurve: KeroseneMotion.standard,
                    switchOutCurve: KeroseneMotion.exit,
                    child: _buildMethodSelection(
                      selectedWallet,
                      canShowNfc: canShowNfc,
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

  Widget _buildMethodSelection(
    Wallet? wallet, {
    required bool canShowNfc,
  }) {
    final kind = wallet == null
        ? MovementReceiveWalletKind.internal
        : classifyReceiveWallet(wallet);
    final actions = availableReceiveActions(
      wallet: wallet,
      nfcCompatible: canShowNfc,
    );
    final showNfcOption = actions.any(
      (action) => action.kind == MovementReceiveActionKind.nfc,
    );
    const receiveMethodLabel = 'Como deseja receber';
    final subtitle = switch (kind) {
      MovementReceiveWalletKind.internal => showNfcOption
          ? 'Escolha NFC, P2P, link, QR Code ou gateway para receber na plataforma.'
          : 'Escolha P2P, link, QR Code ou gateway para receber na plataforma.',
      MovementReceiveWalletKind.custodialOnchain =>
        'Escolha QR Code ou link de pagamento para receber on-chain.',
      MovementReceiveWalletKind.coldWallet =>
        'Escolha QR Code ou link de pagamento para receber na cold wallet.',
    };

    return SingleChildScrollView(
      key: ValueKey('receive-method-${wallet?.id ?? kind.name}'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receiveMethodLabel,
            style: AppTypography.newsreader(
              color: _receiveTextColor,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.inter(
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
              for (var index = 0; index < actions.length; index++)
                _actionTileFor(
                  context,
                  actions[index],
                  showDivider: index < actions.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  _ReceiveActionTile _actionTileFor(
    BuildContext context,
    MovementReceiveAction action, {
    required bool showDivider,
  }) {
    return switch (action.kind) {
      MovementReceiveActionKind.gateway => _ReceiveActionTile(
          icon: KeroseneIcons.creditCard,
          title: context.tr.receiveMethodGatewayTitle,
          subtitle: context.tr.receiveMethodGatewaySubtitle,
          onTap: _openGatewayProviders,
          showDivider: showDivider,
          verticalPadding: 24,
        ),
      MovementReceiveActionKind.p2p => _ReceiveActionTile(
          icon: KeroseneIcons.internalTransfer,
          title: 'P2P',
          subtitle: 'Receber por transferencia de usuario interno',
          onTap: () => _openReceive(ReceiveAmountMethod.p2p),
          showDivider: showDivider,
          verticalPadding: 24,
        ),
      MovementReceiveActionKind.qrCode => _ReceiveActionTile(
          icon: KeroseneIcons.qr,
          title: context.tr.receiveMethodQrTitle,
          subtitle: context.tr.receiveMethodQrSubtitle,
          onTap: () => _openReceive(ReceiveAmountMethod.qrCode),
          showDivider: showDivider,
          verticalPadding: 24,
        ),
      MovementReceiveActionKind.paymentLink => _ReceiveActionTile(
          icon: KeroseneIcons.onchain,
          title: context.tr.receiveMethodPaymentLinkTitle,
          subtitle: context.tr.receiveMethodPaymentLinkSubtitle,
          onTap: () => _openReceive(ReceiveAmountMethod.paymentLink),
          showDivider: showDivider,
          verticalPadding: 24,
        ),
      MovementReceiveActionKind.nfc => _ReceiveActionTile(
          icon: KeroseneIcons.nfc,
          title: context.tr.receiveMethodNfcTitle,
          subtitle: context.tr.receiveMethodNfcSubtitle,
          onTap: () => _openReceive(ReceiveAmountMethod.nfc),
          showDivider: showDivider,
          verticalPadding: 24,
        ),
    };
  }

  Wallet? _resolveWallet(WalletState walletState) {
    if (widget.initialWallet != null) {
      return widget.initialWallet!;
    }
    if (walletState is! WalletLoaded) {
      return null;
    }
    for (final wallet in walletState.wallets) {
      if (wallet.isActive) {
        return wallet;
      }
    }
    return walletState.wallets.isNotEmpty ? walletState.wallets.first : null;
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
                icon: KeroseneIcons.back,
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                      style: AppTypography.inter(
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
                      style: AppTypography.inter(
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
                KeroseneIcons.chevronRight,
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
            icon: KeroseneIcons.creditCard,
            aliases: const ['moonpay'],
          ),
          _GatewayProvider(
            name: 'Banxa',
            methods: tr.receiveGatewayBanxaMethods,
            fees: tr.receiveGatewayBanxaFees,
            icon: KeroseneIcons.fiat,
            aliases: const ['banxa'],
          ),
          _GatewayProvider(
            name: 'Mercuryo',
            methods: tr.receiveGatewayMercuryoMethods,
            fees: tr.receiveGatewayMercuryoFees,
            icon: KeroseneIcons.device,
            aliases: const ['mercuryo'],
          ),
          _GatewayProvider(
            name: 'Ramp Network',
            methods: tr.receiveGatewayRampMethods,
            fees: tr.receiveGatewayRampFees,
            icon: KeroseneIcons.trendUp,
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
            icon: KeroseneIcons.business,
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
            icon: KeroseneIcons.database,
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
            icon: KeroseneIcons.stack,
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
            icon: KeroseneIcons.internalTransfer,
            aliases: const ['transak'],
          ),
          _GatewayProvider(
            name: 'Wert',
            methods: tr.receiveGatewayWertMethods,
            fees: tr.receiveGatewayWertFees,
            icon: KeroseneIcons.lightning,
            aliases: const ['wert'],
          ),
          _GatewayProvider(
            name: 'GateFi / Unlimit',
            methods: tr.receiveGatewayGateFiMethods,
            fees: tr.receiveGatewayGateFiFees,
            icon: KeroseneIcons.globe,
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

    if (urlsAsync.isLoading && !urlsAsync.hasValue) {
      return const KeroseneLogoLoadingView();
    }

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
                        icon: const Icon(KeroseneIcons.back, size: 24),
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
                        style: AppTypography.newsreader(
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
                    loading: () => const SizedBox.shrink(),
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
                color: AppColors.hexFF1E1E1E,
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
              KeroseneIcons.chevronRight,
              color: AppColors.hexFF525252,
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
