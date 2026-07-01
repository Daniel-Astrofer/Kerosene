import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:kerosene/features/auth/presentation/screens/login_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/emergency_recovery_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/server_unavailable_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/welcome_screen.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/home/presentation/screens/home_loading_screen.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_page.dart';
import 'package:kerosene/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:kerosene/features/security/presentation/screens/notification_settings_screen.dart';
import 'package:kerosene/features/security/presentation/screens/sovereignty_status_screen.dart';
import 'package:kerosene/features/security/presentation/screens/settings_screen.dart';
import 'package:kerosene/features/movement/screens/movement_hub_screen.dart';
import 'package:kerosene/features/movement/screens/movement_amount_screen.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'package:kerosene/features/movement/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/features/movement/screens/receive_request_flow_screen.dart';
import 'package:kerosene/features/movement/screens/send_money_screen.dart';
import 'package:kerosene/features/web/navigation/admin_content_router.dart';
import 'package:kerosene/features/web/navigation/admin_routes.dart';
import 'package:kerosene/features/web/screens/login/admin_login_screen.dart';
import 'package:kerosene/features/web/shell/admin_shell.dart';
import 'package:kerosene/features/web/theme/admin_theme.dart';

import '../storybook_mocks.dart';
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
  late String _selectedId = storybookFlowItems.first.id;
  String _query = '';

  FlowItem get _selectedItem => storybookFlowItems.firstWhere(
        (item) => item.id == _selectedId,
        orElse: () => storybookFlowItems.first,
      );

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems(_query);
    final selectedItem = _selectedItem;
    final selectedIndex =
        storybookFlowItems.indexWhere((item) => item.id == _selectedId);

    return Material(
      color: KeroseneBrandTokens.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 960;
          if (compact) {
            return Column(
              children: [
                _FlowHeader(
                  item: selectedItem,
                  selectedIndex: selectedIndex,
                  total: storybookFlowItems.length,
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
                      total: storybookFlowItems.length,
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

  List<FlowItem> _filteredItems(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return storybookFlowItems;
    }
    return storybookFlowItems.where((item) {
      return item.title.toLowerCase().contains(normalized) ||
          item.section.toLowerCase().contains(normalized) ||
          item.routeName.toLowerCase().contains(normalized);
    }).toList();
  }

  void _select(String id) {
    setState(() => _selectedId = id);
  }

  void _selectPrevious() {
    final current =
        storybookFlowItems.indexWhere((item) => item.id == _selectedId);
    final previous =
        (current - 1) < 0 ? storybookFlowItems.length - 1 : current - 1;
    setState(() => _selectedId = storybookFlowItems[previous].id);
  }

  void _selectNext() {
    final current =
        storybookFlowItems.indexWhere((item) => item.id == _selectedId);
    final next = (current + 1) % storybookFlowItems.length;
    setState(() => _selectedId = storybookFlowItems[next].id);
  }
}

class _FlowNavigation extends StatelessWidget {
  final List<FlowItem> items;
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
    final grouped = <String, List<FlowItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    return Container(
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.backgroundSoft,
        border: Border(
          right: compact
              ? BorderSide.none
              : const BorderSide(color: KeroseneBrandTokens.border),
          bottom: compact
              ? const BorderSide(color: KeroseneBrandTokens.border)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: TextField(
              onChanged: onQueryChanged,
              style: const TextStyle(
                  color: KeroseneBrandTokens.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  KeroseneIcons.search,
                  color: KeroseneBrandTokens.textMuted,
                  size: 18,
                ),
                hintText: 'Buscar tela',
                hintStyle:
                    const TextStyle(color: KeroseneBrandTokens.textMuted),
                filled: true,
                fillColor: KeroseneBrandTokens.surfaceHigh,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: KeroseneBrandTokens.borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: KeroseneBrandTokens.borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: KeroseneBrandTokens.textPrimary),
                ),
              ),
            ),
          ),
          Expanded(
            child: query.trim().isNotEmpty && items.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma tela encontrada',
                      style: TextStyle(color: KeroseneBrandTokens.textMuted),
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
          color: KeroseneBrandTokens.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FlowNavigationTile extends StatelessWidget {
  final FlowItem item;
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
    final foreground =
        selected ? Colors.white : KeroseneBrandTokens.textSecondary;
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
          color: selected
              ? KeroseneBrandTokens.surfaceElevated
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? KeroseneBrandTokens.borderStrong
                : Colors.transparent,
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
                      color: KeroseneBrandTokens.textMuted,
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
  final FlowItem item;
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
        color: KeroseneBrandTokens.backgroundSoft,
        border: Border(bottom: BorderSide(color: KeroseneBrandTokens.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KeroseneBrandTokens.surfaceHigh,
              border: Border.all(color: KeroseneBrandTokens.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon,
                color: KeroseneBrandTokens.textPrimary, size: 19),
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
                    color: KeroseneBrandTokens.textPrimary,
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
                    color: KeroseneBrandTokens.textMuted,
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
              icon: const Icon(KeroseneIcons.chevronLeft),
              color: KeroseneBrandTokens.textPrimary,
            ),
          ),
          Tooltip(
            message: 'Próxima tela',
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(KeroseneIcons.chevronRight),
              color: KeroseneBrandTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPreview extends StatelessWidget {
  final FlowItem item;

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
          color: KeroseneBrandTokens.background,
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
  final FlowItem item;

  const _DeviceFrame({required this.item});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      item.surface == FlowSurface.mobile ? 28 : 12,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.background,
        borderRadius: borderRadius,
        border: Border.all(color: KeroseneBrandTokens.borderStrong),
        boxShadow: [
          BoxShadow(
            color: KeroseneBrandTokens.background.withValues(alpha: 0.45),
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
    '/accounts': (_) => const BitcoinAccountsScreen(),
    '/accounts': (_) => const BitcoinAccountsScreen(),
    '/activity': (_) => const TransactionStatementScreen(),
    '/notifications': (_) => const NotificationCenterScreen(),
    '/account/security': (_) => const SettingsScreen(),
    '/account/notifications': (_) => const NotificationSettingsScreen(),
    '/security/sovereignty': (_) => const SovereigntyStatusScreen(),
    '/send-money': (_) => SendMoneyScreen(
          walletId: primaryWallet.id,
          initialAddress: 'bc1qstorybookrecipient00000000000000000',
          initialAmountBtc: 0.0015,
        ),
    '/receive': (_) => MovementHubScreen(initialWallet: primaryWallet),
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
    '/receive/amount/qr': (_) => MovementAmountScreen(
          wallet: primaryWallet,
          method: ReceiveAmountMethod.qrCode,
          onChainWallet: false,
        ),
    '/receive/amount/link': (_) => MovementAmountScreen(
          wallet: primaryWallet,
          method: ReceiveAmountMethod.paymentLink,
          onChainWallet: false,
        ),
    '/receive/amount/nfc': (_) => MovementAmountScreen(
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
      backgroundColor: KeroseneBrandTokens.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(KeroseneIcons.error,
                  color: KeroseneBrandTokens.textSecondary),
              const SizedBox(height: 12),
              Text(
                routeName.isEmpty ? 'Rota sem nome' : routeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KeroseneBrandTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rota ainda não registrada no fluxo Storybook.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: KeroseneBrandTokens.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
