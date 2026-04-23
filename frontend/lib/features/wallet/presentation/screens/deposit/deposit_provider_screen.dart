import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

import 'onramp_webview_screen.dart';

class DepositProviderScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final double inputAmount;
  final Currency inputCurrency;
  final String method;

  const DepositProviderScreen({
    super.key,
    required this.wallet,
    required this.inputAmount,
    required this.inputCurrency,
    required this.method,
  });

  @override
  ConsumerState<DepositProviderScreen> createState() =>
      _DepositProviderScreenState();
}

class _DepositProviderScreenState extends ConsumerState<DepositProviderScreen> {
  Map<String, String> _onrampUrls = const {};
  String? _errorMessage;
  bool _isLoading = true;
  bool _requestTriggered = false;

  static const _providerOptions = [
    _OnrampProviderOption(
      key: 'moonpay',
      name: 'MoonPay',
      description: 'Cartão, Apple Pay e checkout global.',
      iconData: LucideIcons.moon,
      badgeText: 'GLOBAL',
    ),
    _OnrampProviderOption(
      key: 'banxa',
      name: 'Banxa',
      description: 'Compra rápida com cartão e moeda fiat.',
      iconData: LucideIcons.arrowDownUp,
      badgeText: 'FAST',
    ),
    _OnrampProviderOption(
      key: 'bipa',
      name: 'Bipa',
      description: 'Fluxo orientado ao mercado brasileiro.',
      iconData: LucideIcons.landmark,
      badgeText: 'BR',
    ),
  ];

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadOnrampUrls);
  }

  Future<void> _loadOnrampUrls() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;
    await _fetchOnrampUrls();
  }

  Future<void> _fetchOnrampUrls() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result =
        await ref.read(transactionRepositoryProvider).getOnrampUrls();

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (urls) {
        setState(() {
          _isLoading = false;
          _onrampUrls = urls;
        });
      },
    );
  }

  void _retry() {
    _requestTriggered = true;
    _fetchOnrampUrls();
  }

  void _openProvider(
    BuildContext context,
    _OnrampProviderOption provider,
    String checkoutUrl,
    String btcAmountLabel,
  ) {
    final depositAddress = _extractDepositAddress(checkoutUrl);
    if (depositAddress.isEmpty) {
      SnackbarHelper.showError(
        'O link retornado pelo backend não contém endereço de depósito válido.',
        title: provider.name,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnrampWebViewScreen(
          providerName: provider.name,
          checkoutUrl: checkoutUrl,
          depositAddress: depositAddress,
          amountLabel: MoneyDisplay.format(
            amount: widget.inputAmount,
            currency: widget.inputCurrency,
          ),
          btcAmountLabel: btcAmountLabel,
        ),
      ),
    );
  }

  String _extractDepositAddress(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return '';
    }

    return uri.queryParameters['walletAddress'] ??
        uri.queryParameters['address'] ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final btcAmount = MoneyDisplay.convertToBtcAmount(
      amount: widget.inputAmount,
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final btcAmountLabel = MoneyDisplay.format(
      amount: btcAmount,
      currency: Currency.btc,
    );
    final availableProviders = _providerOptions
        .where((provider) => (_onrampUrls[provider.key] ?? '').isNotEmpty)
        .toList(growable: false);

    return ReceiveFlowScaffold(
      title: 'Provedor fiat',
      subtitle: 'Selecione o checkout mantendo o mesmo fluxo visual.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountSummary(context, btcAmountLabel: btcAmountLabel),
          const SizedBox(height: AppSpacing.md),
          _buildSecurityHint(context),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            _buildLoadingState(context)
          else if (_errorMessage != null)
            _buildErrorState(context)
          else if (availableProviders.isEmpty)
            _buildEmptyState(context)
          else
            ...availableProviders.map(
              (provider) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildProviderCard(
                  context,
                  provider: provider,
                  btcAmountLabel: btcAmountLabel,
                  onTap: () => _openProvider(
                    context,
                    provider,
                    _onrampUrls[provider.key]!,
                    btcAmountLabel,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary(
    BuildContext context, {
    required String btcAmountLabel,
  }) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReceiveFlowSectionLabel('Compra solicitada'),
          const SizedBox(height: 4),
          Text(
            MoneyDisplay.format(
              amount: widget.inputAmount,
              currency: widget.inputCurrency,
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Equivale a $btcAmountLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityHint(BuildContext context) {
    return ReceiveFlowPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: receiveFlowTextColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Os provedores abrem em WebView interna com o endereço BTC retornado por `/api/onramp/urls`.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const ReceiveFlowStatePanel(
      icon: LucideIcons.loader2,
      title: 'Carregando provedores',
      message: 'Gerando links de onramp com o endereço seguro da sua wallet.',
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.cloudOff,
      title: 'Falha ao carregar provedores',
      message: _errorMessage ?? 'Erro desconhecido.',
      footer: ReceiveFlowSecondaryButton(
        label: 'Tentar novamente',
        icon: LucideIcons.refreshCw,
        onTap: _retry,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const ReceiveFlowStatePanel(
      icon: LucideIcons.wallet,
      title: 'Nenhum provedor disponível',
      message: 'O backend não retornou links de onramp para esta sessão.',
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required _OnrampProviderOption provider,
    required String btcAmountLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Ink(
          decoration: BoxDecoration(
            color: receiveFlowPanelColor,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: receiveFlowBorderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: receiveFlowPanelRaisedColor,
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: receiveFlowBorderStrongColor),
                      ),
                      child: Icon(
                        provider.iconData,
                        color: receiveFlowTextColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: receiveFlowTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: receiveFlowMutedTextColor,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ReceiveFlowTag(label: provider.badgeText),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.chevronRight,
                      color: receiveFlowFaintTextColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeaturePill(
                        icon: LucideIcons.bitcoin,
                        label: btcAmountLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: _FeaturePill(
                        icon: LucideIcons.link,
                        label: 'Endereço seguro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String label,
  }) {
    return _FeaturePill(icon: icon, label: label);
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: receiveFlowPanelRaisedColor,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: receiveFlowBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: receiveFlowMutedTextColor, size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: receiveFlowTextColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnrampProviderOption {
  final String key;
  final String name;
  final String description;
  final IconData iconData;
  final String badgeText;

  const _OnrampProviderOption({
    required this.key,
    required this.name,
    required this.description,
    required this.iconData,
    required this.badgeText,
  });
}
