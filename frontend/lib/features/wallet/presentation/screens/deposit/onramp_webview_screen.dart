import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnrampWebViewScreen extends StatefulWidget {
  final String providerName;
  final String checkoutUrl;
  final String depositAddress;
  final String amountLabel;
  final String btcAmountLabel;

  const OnrampWebViewScreen({
    super.key,
    required this.providerName,
    required this.checkoutUrl,
    required this.depositAddress,
    required this.amountLabel,
    required this.btcAmountLabel,
  });

  @override
  State<OnrampWebViewScreen> createState() => _OnrampWebViewScreenState();
}

class _OnrampWebViewScreenState extends State<OnrampWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _pageLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) {
              return;
            }
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageLoaded = false;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pageLoaded = true;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) == false || !mounted) {
              return;
            }
            setState(() {
              _pageLoaded = false;
              _errorMessage = error.description.isEmpty
                  ? 'Falha ao carregar a página.'
                  : error.description;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }

            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }

            SnackbarHelper.showWarning(
              'O provedor tentou abrir um link externo não suportado dentro do app.',
              title: widget.providerName,
            );
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _reload() async {
    setState(() {
      _errorMessage = null;
      _pageLoaded = false;
      _progress = 0;
    });
    await _controller.reload();
  }

  void _copyAddress() {
    if (widget.depositAddress.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.depositAddress));
    SnackbarHelper.showSuccess(
      context.tr.depositFlowDepositAddressCopied,
      title: widget.providerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: widget.providerName,
      subtitle: context.tr.depositFlowCheckoutSubtitle,
      scrollable: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      actions: [
        ReceiveFlowIconButton(
          icon: LucideIcons.refreshCw,
          onTap: _reload,
        ),
      ],
      child: Column(
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.amountLabel,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: receiveFlowTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr.depositFlowEstimatedPurchase(
                          widget.btcAmountLabel,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receiveFlowMutedTextColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_pageLoaded || _progress < 100)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: LinearProgressIndicator(
                minHeight: 3,
                value: _progress <= 0 ? null : _progress / 100,
                backgroundColor: const Color(0x14FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ReceiveFlowPanel(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_errorMessage != null)
                      ColoredBox(
                        color: const Color(0xEE050505),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.cloudOff,
                                  size: 28,
                                  color: receiveFlowTextColor,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  context.tr.depositFlowProviderLoadError,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: receiveFlowTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ErrorTranslator.translate(
                                    context.tr,
                                    _errorMessage!,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: receiveFlowMutedTextColor,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ReceiveFlowSecondaryButton(
                                  onTap: _reload,
                                  label: context.tr.depositFlowRetry,
                                  icon: LucideIcons.refreshCw,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPanel(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReceiveFlowSectionLabel(
                        context.tr.depositFlowCheckoutAddressTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.depositAddress.isEmpty
                            ? context.tr.depositFlowAddressUnavailable
                            : widget.depositAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receiveFlowTextColor,
                              fontFamily: 'JetBrainsMono',
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ReceiveFlowSecondaryButton(
                  onTap: widget.depositAddress.isEmpty ? null : _copyAddress,
                  icon: LucideIcons.copy,
                  label: context.tr.depositFlowCopy,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
