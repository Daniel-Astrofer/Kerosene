import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:kerosene/features/auth/presentation/screens/login_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/emergency_recovery_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/server_unavailable_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/welcome_screen.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/home/presentation/screens/home_loading_screen.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_page.dart';
import 'package:kerosene/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:kerosene/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:kerosene/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:kerosene/features/security/presentation/screens/sovereignty_status_screen.dart';
import 'package:kerosene/features/settings/presentation/screens/settings_screen.dart';
import 'package:kerosene/features/transactions/presentation/screens/deposits_screen.dart';
import 'package:kerosene/features/transactions/presentation/screens/withdraw_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_amount_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_method.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_payment_link_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_request_flow_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:kerosene/features/web_admin/navigation/admin_content_router.dart';
import 'package:kerosene/features/web_admin/navigation/admin_routes.dart';
import 'package:kerosene/features/web_admin/screens/login/admin_login_screen.dart';
import 'package:kerosene/features/web_admin/shell/admin_shell.dart';
import 'package:kerosene/features/web_admin/theme/admin_theme.dart';

import '../storybook_mocks.dart';
import 'payment_stories.dart';
import 'receive_stories.dart';

Story appFlowStory() {
  return Story(
    name: 'Kerosene/App Flow',
    builder: (_) => const KeroseneAppFlowNavigator(),
  );
}

class KeroseneAppFlowNavigator extends StatefulWidget {
  const KeroseneAppFlowNavigator({super.key});

  @override
  State<KeroseneAppFlowNavigator> createState() =>
      _KeroseneAppFlowNavigatorState();
}

class _KeroseneAppFlowNavigatorState extends State<KeroseneAppFlowNavigator> {
  late String _selectedId = _flowItems.first.id;
  String _query = '';

  _FlowItem get _selectedItem => _flowItems.firstWhere(
        (item) => item.id == _selectedId,
        orElse: () => _flowItems.first,
      );

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems(_query);
    final selectedItem = _selectedItem;
    final selectedIndex =
        _flowItems.indexWhere((item) => item.id == _selectedId);

    return Material(
      color: const Color(0xFF050505),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 960;
          if (compact) {
            return Column(
              children: [
                _FlowHeader(
                  item: selectedItem,
                  selectedIndex: selectedIndex,
                  total: _flowItems.length,
                  onPrevious: _selectPrevious,
                  onNext: _selectNext,
                ),
                SizedBox(
                  height: 182,
                  child: _FlowNavigation(
                    items: filteredItems,
                    selectedId: _selectedId,
                    query: _query,
                    compact: true,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onSelected: _select,
                  ),
                ),
                Expanded(child: _FlowPreview(item: selectedItem)),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 316,
                child: _FlowNavigation(
                  items: filteredItems,
                  selectedId: _selectedId,
                  query: _query,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onSelected: _select,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _FlowHeader(
                      item: selectedItem,
                      selectedIndex: selectedIndex,
                      total: _flowItems.length,
                      onPrevious: _selectPrevious,
                      onNext: _selectNext,
                    ),
                    Expanded(child: _FlowPreview(item: selectedItem)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_FlowItem> _filteredItems(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _flowItems;
    }
    return _flowItems.where((item) {
      return item.title.toLowerCase().contains(normalized) ||
          item.section.toLowerCase().contains(normalized) ||
          item.routeName.toLowerCase().contains(normalized);
    }).toList();
  }

  void _select(String id) {
    setState(() => _selectedId = id);
  }

  void _selectPrevious() {
    final current = _flowItems.indexWhere((item) => item.id == _selectedId);
    final previous = (current - 1) < 0 ? _flowItems.length - 1 : current - 1;
    setState(() => _selectedId = _flowItems[previous].id);
  }

  void _selectNext() {
    final current = _flowItems.indexWhere((item) => item.id == _selectedId);
    final next = (current + 1) % _flowItems.length;
    setState(() => _selectedId = _flowItems[next].id);
  }
}

class _FlowNavigation extends StatelessWidget {
  final List<_FlowItem> items;
  final String selectedId;
  final String query;
  final bool compact;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSelected;

  const _FlowNavigation({
    required this.items,
    required this.selectedId,
    required this.query,
    required this.onQueryChanged,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_FlowItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0C),
        border: Border(
          right: compact
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF222224)),
          bottom: compact
              ? const BorderSide(color: Color(0xFF222224))
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: TextField(
              onChanged: onQueryChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: Color(0xFF8E8E93),
                  size: 18,
                ),
                hintText: 'Buscar tela',
                hintStyle: const TextStyle(color: Color(0xFF6F6F74)),
                filled: true,
                fillColor: const Color(0xFF151517),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
              ),
            ),
          ),
          Expanded(
            child: query.trim().isNotEmpty && items.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma tela encontrada',
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      10,
                      compact ? 0 : 4,
                      10,
                      14,
                    ),
                    scrollDirection: compact ? Axis.horizontal : Axis.vertical,
                    children: grouped.entries.expand((entry) {
                      return [
                        if (!compact) _SectionLabel(entry.key),
                        ...entry.value.map(
                          (item) => _FlowNavigationTile(
                            item: item,
                            selected: item.id == selectedId,
                            compact: compact,
                            onTap: () => onSelected(item.id),
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        label.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF77777C),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FlowNavigationTile extends StatelessWidget {
  final _FlowItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _FlowNavigationTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFFB8B8BE);
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 178 : null,
        margin: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 0,
          vertical: compact ? 6 : 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF222226) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF3E3E44) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.routeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6F6F74),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Tooltip(message: '${item.section} · ${item.title}', child: child);
  }
}

class _FlowHeader extends StatelessWidget {
  final _FlowItem item;
  final int selectedIndex;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _FlowHeader({
    required this.item,
    required this.selectedIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF080809),
        border: Border(bottom: BorderSide(color: Color(0xFF222224))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border.all(color: const Color(0xFF2A2A2D)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.section} · ${item.routeName} · ${selectedIndex + 1}/$total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Tela anterior',
            child: IconButton(
              onPressed: onPrevious,
              icon: const Icon(LucideIcons.chevronLeft),
              color: Colors.white,
            ),
          ),
          Tooltip(
            message: 'Próxima tela',
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(LucideIcons.chevronRight),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPreview extends StatelessWidget {
  final _FlowItem item;

  const _FlowPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetSize = item.surface.targetSize;
        final availableWidth = math.max(constraints.maxWidth - 48, 320);
        final availableHeight = math.max(constraints.maxHeight - 48, 420);
        final scale = math.min(
          1.0,
          math.min(
            availableWidth / targetSize.width,
            availableHeight / targetSize.height,
          ),
        );

        return ColoredBox(
          color: const Color(0xFF050505),
          child: Center(
            child: SizedBox(
              width: targetSize.width * scale,
              height: targetSize.height * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: targetSize.width,
                  height: targetSize.height,
                  child: _DeviceFrame(item: item),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeviceFrame extends StatelessWidget {
  final _FlowItem item;

  const _DeviceFrame({required this.item});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      item.surface == _FlowSurface.mobile ? 28 : 12,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFF2D2D31)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Navigator(
          key: ValueKey(item.routeName),
          initialRoute: item.routeName,
          onGenerateRoute: (settings) {
            final routes = _routeBuilders();
            final builder = routes[settings.name] ??
                (_) => _UnknownRoutePane(routeName: settings.name ?? '');
            return PageRouteBuilder<void>(
              settings: settings,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) {
                return builder(context);
              },
            );
          },
        ),
      ),
    );
  }
}

Map<String, WidgetBuilder> _routeBuilders() {
  final primaryWallet = mockWallets.first;
  final coldWallet = mockWallets.length > 1 ? mockWallets[1] : primaryWallet;
  final pendingPaymentLink = mockPaymentLink();
  final paidPaymentLink = mockPaymentLink(
    id: 'storybook-payment-link-paid',
    status: 'paid',
    amountBtc: 0.018,
  );

  return {
    '/welcome': (_) => const WelcomeScreen(),
    '/login': (_) => const LoginScreen(username: 'satoshi_storybook'),
    '/recovery/emergency': (_) => const EmergencyRecoveryScreen(),
    '/passkey': (_) => const PasskeyVerificationScreen(
          username: 'satoshi_storybook',
          fallbackPassphrase: 'correct horse battery staple',
        ),
    '/signup': (_) => const SignupFlowScreen(),
    '/server-unavailable': (_) => const ServerUnavailableScreen(
          message: 'Ambiente Storybook indisponível para demonstração',
        ),
    '/home_loading': (_) => const HomeLoadingScreen(),
    '/home': (_) => const HomeScreen(),
    '/settings': (_) => const SettingsScreen(showPrimaryNavigation: true),
    '/card': (_) => const BitcoinAccountsScreen(),
    '/bitcoin/advanced': (_) => const BitcoinAccountsScreen(),
    '/history': (_) => const TransactionStatementScreen(),
    '/notifications': (_) => const NotificationCenterScreen(),
    '/account/security': (_) => const SecuritySettingsScreen(),
    '/account/notifications': (_) => const NotificationSettingsScreen(),
    '/security/sovereignty': (_) => const SovereigntyStatusScreen(),
    '/send-money': (_) => SendMoneyScreen(
          walletId: primaryWallet.id,
          initialAddress: 'bc1qstorybookrecipient00000000000000000',
          initialAmountBtc: 0.0015,
        ),
    '/payments/intent': (_) => const PaymentIntentScenarioPreview(
          scenario: PaymentIntentStoryScenario.quote,
        ),
    '/payments/intent-settled': (_) => const PaymentIntentScenarioPreview(
          scenario: PaymentIntentStoryScenario.settled,
        ),
    '/payments/intent-failed': (_) => const PaymentIntentScenarioPreview(
          scenario: PaymentIntentStoryScenario.failed,
        ),
    '/withdraw/onchain': (_) => WithdrawScreen(
          wallet: primaryWallet,
          entryMode: WithdrawEntryMode.onChain,
          initialDestination: 'bc1qstorybookrecipient00000000000000000',
          initialAmountBtc: 0.0015,
        ),
    '/withdraw/lightning': (_) => WithdrawScreen(
          wallet: primaryWallet,
          entryMode: WithdrawEntryMode.lightning,
          initialDestination: 'lnbc150000n1storybook',
          initialAmountBtc: 0.0015,
        ),
    '/receive': (_) => DepositsScreen(initialWallet: primaryWallet),
    '/receive/providers': (_) => ReceiveGatewayProvidersScreen(
          wallet: primaryWallet,
        ),
    '/receive/requests/loading': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.loading,
        ),
    '/receive/requests/empty': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.empty,
        ),
    '/receive/requests/pending': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.pending,
        ),
    '/receive/requests/paid': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.paid,
        ),
    '/receive/requests/expired': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.expired,
        ),
    '/receive/requests/error': (_) => const ReceiveRequestsScenarioPreview(
          scenario: ReceiveRequestStoryScenario.error,
        ),
    '/receive/amount/qr': (_) => ReceiveAmountScreen(
          wallet: primaryWallet,
          method: ReceiveAmountMethod.qrCode,
          onChainWallet: false,
        ),
    '/receive/amount/link': (_) => ReceiveAmountScreen(
          wallet: primaryWallet,
          method: ReceiveAmountMethod.paymentLink,
          onChainWallet: false,
        ),
    '/receive/amount/nfc': (_) => ReceiveAmountScreen(
          wallet: primaryWallet,
          method: ReceiveAmountMethod.nfc,
          onChainWallet: false,
        ),
    '/receive/qr': (_) => ReceiveRequestFlowScreen(
          wallet: primaryWallet,
          onChainWallet: false,
          amountBtc: 0.025,
          method: ReceiveAmountMethod.qrCode,
          initialStage: ReceiveRequestStage.qr,
          enableStatusPolling: false,
          initialAddress: primaryWallet.address,
          initialPaymentUri:
              'kerosene:pay?address=${primaryWallet.address}&amount=0.02500000',
        ),
    '/receive/payment-link': (_) => ReceivePaymentLinkScreen(
          initialLink: pendingPaymentLink,
          requestedAmountLabel: '0.00420000 BTC',
          btcAmountLabel: '0.00420000 BTC',
          walletLabel: primaryWallet.name,
          cardTypeLabel: 'Kerosene',
          depositFeeLabel: '0.00000000 BTC',
          netAmountLabel: '0.00420000 BTC',
        ),
    '/receive/payment-link-paid': (_) => ReceivePaymentLinkScreen(
          initialLink: paidPaymentLink,
          requestedAmountLabel: '0.01800000 BTC',
          btcAmountLabel: '0.01800000 BTC',
          walletLabel: primaryWallet.name,
          cardTypeLabel: 'Kerosene',
          depositFeeLabel: '0.00000000 BTC',
          netAmountLabel: '0.01800000 BTC',
        ),
    '/receive/onchain-confirming': (_) => ReceiveRequestFlowScreen(
          wallet: coldWallet,
          onChainWallet: true,
          amountBtc: 0.045,
          method: ReceiveAmountMethod.qrCode,
          initialStage: ReceiveRequestStage.confirmations,
          enableStatusPolling: false,
          initialAddress: coldWallet.address,
          initialPaymentUri: 'bitcoin:${coldWallet.address}?amount=0.04500000',
          initialTxid: 'storybook-onchain-txid',
          initialConfirmations: 1,
          requiredConfirmations: 3,
        ),
    '/receive/onchain-identified': (_) => ReceiveRequestFlowScreen(
          wallet: coldWallet,
          onChainWallet: true,
          amountBtc: 0.045,
          method: ReceiveAmountMethod.qrCode,
          initialStage: ReceiveRequestStage.identified,
          enableStatusPolling: false,
          initialAddress: coldWallet.address,
          initialPaymentUri: 'bitcoin:${coldWallet.address}?amount=0.04500000',
          initialTxid: 'storybook-onchain-txid',
          initialConfirmations: 3,
          requiredConfirmations: 3,
          identifiedAt: DateTime(2026, 5, 28, 12, 20),
        ),
    '/receive/nfc': (_) => ReceiveNfcFlowScreen(
          wallet: primaryWallet,
          onChainWallet: false,
          amountBtc: 0.00125,
        ),
    '/receive/onchain-nfc': (_) => ReceiveNfcFlowScreen(
          wallet: coldWallet,
          onChainWallet: true,
          amountBtc: 0.00125,
        ),
    '/public/landing': (_) => const KeroseneLandingPage(),
    '/public/download': (_) => const KeroseneLandingPage(focusDownload: true),
    '/public/status': (_) => const KerosenePublicStatusPage(),
    '/admin/login': (_) => const AdminLoginScreen(),
    '/admin/dashboard': (_) =>
        const _AdminShellPreview(route: AdminRoute.dashboard),
    '/admin/monitoring': (_) =>
        const _AdminShellPreview(route: AdminRoute.monitoring),
    '/admin/transactions': (_) =>
        const _AdminShellPreview(route: AdminRoute.transactions),
    '/admin/lightning': (_) =>
        const _AdminShellPreview(route: AdminRoute.lightning),
    '/admin/onchain': (_) =>
        const _AdminShellPreview(route: AdminRoute.onchain),
    '/admin/checks': (_) => const _AdminShellPreview(route: AdminRoute.checks),
    '/admin/payment-links': (_) =>
        const _AdminShellPreview(route: AdminRoute.paymentLinks),
    '/admin/analytics': (_) =>
        const _AdminShellPreview(route: AdminRoute.analytics),
    '/admin/volatility': (_) =>
        const _AdminShellPreview(route: AdminRoute.volatility),
    '/admin/companies': (_) =>
        const _AdminShellPreview(route: AdminRoute.companies),
    '/admin/audit': (_) => const _AdminShellPreview(route: AdminRoute.audit),
    '/admin/authenticated-devices': (_) =>
        const _AdminShellPreview(route: AdminRoute.authenticatedDevices),
    '/admin/notifications': (_) =>
        const _AdminShellPreview(route: AdminRoute.notifications),
    '/admin/settings': (_) =>
        const _AdminShellPreview(route: AdminRoute.settings),
  };
}

class _AdminShellPreview extends ConsumerStatefulWidget {
  final AdminRoute route;

  const _AdminShellPreview({required this.route});

  @override
  ConsumerState<_AdminShellPreview> createState() => _AdminShellPreviewState();
}

class _AdminShellPreviewState extends ConsumerState<_AdminShellPreview> {
  @override
  void initState() {
    super.initState();
    _syncRoute();
  }

  @override
  void didUpdateWidget(covariant _AdminShellPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      _syncRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.themeData,
      child: const AdminShell(child: AdminContentRouter()),
    );
  }

  void _syncRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(adminRouteProvider.notifier).navigate(widget.route);
    });
  }
}

class _UnknownRoutePane extends StatelessWidget {
  final String routeName;

  const _UnknownRoutePane({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                routeName.isEmpty ? 'Rota sem nome' : routeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rota ainda não registrada no fluxo Storybook.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FlowSurface {
  mobile(Size(390, 844)),
  desktop(Size(1180, 760)),
  public(Size(1240, 780));

  final Size targetSize;

  const _FlowSurface(this.targetSize);
}

class _FlowItem {
  final String id;
  final String section;
  final String title;
  final String routeName;
  final IconData icon;
  final _FlowSurface surface;

  const _FlowItem({
    required this.id,
    required this.section,
    required this.title,
    required this.routeName,
    required this.icon,
    required this.surface,
  });
}

const _flowItems = [
  _FlowItem(
    id: 'auth-welcome',
    section: 'Entrada',
    title: 'Boas-vindas',
    routeName: '/welcome',
    icon: LucideIcons.home,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'auth-login',
    section: 'Entrada',
    title: 'Login',
    routeName: '/login',
    icon: LucideIcons.user,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'auth-recovery',
    section: 'Entrada',
    title: 'Recovery emergencial',
    routeName: '/recovery/emergency',
    icon: LucideIcons.keyRound,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'auth-passkey',
    section: 'Entrada',
    title: 'Passkey',
    routeName: '/passkey',
    icon: LucideIcons.fingerprint,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'auth-signup',
    section: 'Entrada',
    title: 'Cadastro',
    routeName: '/signup',
    icon: LucideIcons.userCheck,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'auth-server',
    section: 'Entrada',
    title: 'Servidor indisponível',
    routeName: '/server-unavailable',
    icon: LucideIcons.serverOff,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-loading',
    section: 'App Mobile',
    title: 'Carregamento',
    routeName: '/home_loading',
    icon: LucideIcons.loader2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-home',
    section: 'App Mobile',
    title: 'Home',
    routeName: '/home',
    icon: LucideIcons.wallet,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-card',
    section: 'App Mobile',
    title: 'Contas Bitcoin',
    routeName: '/card',
    icon: LucideIcons.walletCards,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'bitcoin-advanced',
    section: 'App Mobile',
    title: 'Bitcoin Advanced',
    routeName: '/bitcoin/advanced',
    icon: LucideIcons.fileText,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-history',
    section: 'App Mobile',
    title: 'Extrato',
    routeName: '/history',
    icon: LucideIcons.receipt,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-send',
    section: 'App Mobile',
    title: 'Enviar',
    routeName: '/send-money',
    icon: LucideIcons.arrowUpRight,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'payments-intent',
    section: 'Payments',
    title: 'Payment Intent quote',
    routeName: '/payments/intent',
    icon: LucideIcons.router,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'payments-intent-settled',
    section: 'Payments',
    title: 'Payment settled',
    routeName: '/payments/intent-settled',
    icon: LucideIcons.checkCircle2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'payments-intent-failed',
    section: 'Payments',
    title: 'Payment failed',
    routeName: '/payments/intent-failed',
    icon: LucideIcons.alertTriangle,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-withdraw-onchain',
    section: 'App Mobile',
    title: 'Saque on-chain',
    routeName: '/withdraw/onchain',
    icon: LucideIcons.link,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-withdraw-lightning',
    section: 'App Mobile',
    title: 'Saque Lightning',
    routeName: '/withdraw/lightning',
    icon: LucideIcons.zap,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-settings',
    section: 'App Mobile',
    title: 'Configurações',
    routeName: '/settings',
    icon: LucideIcons.settings,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'mobile-notifications',
    section: 'App Mobile',
    title: 'Notificações',
    routeName: '/notifications',
    icon: LucideIcons.bell,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'account-security',
    section: 'Conta',
    title: 'Segurança',
    routeName: '/account/security',
    icon: LucideIcons.shieldCheck,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'account-notifications',
    section: 'Conta',
    title: 'Preferências de notificação',
    routeName: '/account/notifications',
    icon: LucideIcons.bell,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'account-sovereignty',
    section: 'Conta',
    title: 'Status soberano',
    routeName: '/security/sovereignty',
    icon: LucideIcons.shield,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-selection',
    section: 'Receber',
    title: 'Seleção',
    routeName: '/receive',
    icon: LucideIcons.arrowDown,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-providers',
    section: 'Receber',
    title: 'Provedores',
    routeName: '/receive/providers',
    icon: LucideIcons.creditCard,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-loading',
    section: 'Receber',
    title: 'Requests carregando',
    routeName: '/receive/requests/loading',
    icon: LucideIcons.loader2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-empty',
    section: 'Receber',
    title: 'Requests vazio',
    routeName: '/receive/requests/empty',
    icon: LucideIcons.inbox,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-pending',
    section: 'Receber',
    title: 'Request pendente',
    routeName: '/receive/requests/pending',
    icon: LucideIcons.clock3,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-paid',
    section: 'Receber',
    title: 'Request pago',
    routeName: '/receive/requests/paid',
    icon: LucideIcons.checkCircle2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-expired',
    section: 'Receber',
    title: 'Request expirado',
    routeName: '/receive/requests/expired',
    icon: LucideIcons.timerOff,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-requests-error',
    section: 'Receber',
    title: 'Requests erro',
    routeName: '/receive/requests/error',
    icon: LucideIcons.alertTriangle,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-amount-qr',
    section: 'Receber',
    title: 'Valor para QR',
    routeName: '/receive/amount/qr',
    icon: LucideIcons.qrCode,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-amount-link',
    section: 'Receber',
    title: 'Valor para link',
    routeName: '/receive/amount/link',
    icon: LucideIcons.link2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-amount-nfc',
    section: 'Receber',
    title: 'Valor para NFC',
    routeName: '/receive/amount/nfc',
    icon: LucideIcons.nfc,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-qr',
    section: 'Receber',
    title: 'QR e dados',
    routeName: '/receive/qr',
    icon: LucideIcons.qrCode,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-link',
    section: 'Receber',
    title: 'Link pendente',
    routeName: '/receive/payment-link',
    icon: LucideIcons.link2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-link-paid',
    section: 'Receber',
    title: 'Link pago',
    routeName: '/receive/payment-link-paid',
    icon: LucideIcons.checkCircle2,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-onchain-confirming',
    section: 'Receber',
    title: 'Confirmações',
    routeName: '/receive/onchain-confirming',
    icon: LucideIcons.clock3,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-onchain-identified',
    section: 'Receber',
    title: 'Pagamento identificado',
    routeName: '/receive/onchain-identified',
    icon: LucideIcons.checkCircle,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-nfc',
    section: 'Receber',
    title: 'NFC Kerosene',
    routeName: '/receive/nfc',
    icon: LucideIcons.nfc,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'receive-onchain-nfc',
    section: 'Receber',
    title: 'NFC on-chain',
    routeName: '/receive/onchain-nfc',
    icon: LucideIcons.nfc,
    surface: _FlowSurface.mobile,
  ),
  _FlowItem(
    id: 'public-landing',
    section: 'Web Público',
    title: 'Landing',
    routeName: '/public/landing',
    icon: LucideIcons.globe2,
    surface: _FlowSurface.public,
  ),
  _FlowItem(
    id: 'public-download',
    section: 'Web Público',
    title: 'Download',
    routeName: '/public/download',
    icon: LucideIcons.download,
    surface: _FlowSurface.public,
  ),
  _FlowItem(
    id: 'public-status',
    section: 'Web Público',
    title: 'Status',
    routeName: '/public/status',
    icon: LucideIcons.activity,
    surface: _FlowSurface.public,
  ),
  _FlowItem(
    id: 'admin-login',
    section: 'Admin Web',
    title: 'Login admin',
    routeName: '/admin/login',
    icon: LucideIcons.keyRound,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-dashboard',
    section: 'Admin Web',
    title: 'Dashboard',
    routeName: '/admin/dashboard',
    icon: LucideIcons.layoutGrid,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-monitoring',
    section: 'Admin Web',
    title: 'Monitoring',
    routeName: '/admin/monitoring',
    icon: LucideIcons.activity,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-transactions',
    section: 'Admin Web',
    title: 'Integrity Proofs',
    routeName: '/admin/transactions',
    icon: LucideIcons.fingerprint,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-lightning',
    section: 'Admin Web',
    title: 'Lightning',
    routeName: '/admin/lightning',
    icon: LucideIcons.zap,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-onchain',
    section: 'Admin Web',
    title: 'On-chain',
    routeName: '/admin/onchain',
    icon: LucideIcons.link,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-checks',
    section: 'Admin Web',
    title: 'Hash Chain',
    routeName: '/admin/checks',
    icon: LucideIcons.network,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-payment-links',
    section: 'Admin Web',
    title: 'Payment Metrics',
    routeName: '/admin/payment-links',
    icon: LucideIcons.qrCode,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-analytics',
    section: 'Admin Web',
    title: 'Analytics',
    routeName: '/admin/analytics',
    icon: LucideIcons.gauge,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-volatility',
    section: 'Admin Web',
    title: 'Volatility',
    routeName: '/admin/volatility',
    icon: LucideIcons.trendingUp,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-companies',
    section: 'Admin Web',
    title: 'Infrastructure',
    routeName: '/admin/companies',
    icon: LucideIcons.building2,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-audit',
    section: 'Admin Web',
    title: 'Audit & Security',
    routeName: '/admin/audit',
    icon: LucideIcons.shieldCheck,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-devices',
    section: 'Admin Web',
    title: 'Authenticated Devices',
    routeName: '/admin/authenticated-devices',
    icon: LucideIcons.smartphone,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-notifications',
    section: 'Admin Web',
    title: 'Notifications',
    routeName: '/admin/notifications',
    icon: LucideIcons.bell,
    surface: _FlowSurface.desktop,
  ),
  _FlowItem(
    id: 'admin-settings',
    section: 'Admin Web',
    title: 'Settings',
    routeName: '/admin/settings',
    icon: LucideIcons.settings,
    surface: _FlowSurface.desktop,
  ),
];
