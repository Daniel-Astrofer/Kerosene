import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
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
      'Endereço de depósito copiado.',
      title: widget.providerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CyberBackground(
      useScroll: false,
      resizeToAvoidBottomInset: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.onPrimary.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.providerName.toUpperCase(),
                        style: theme.textTheme.titleMedium!.copyWith(
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Checkout seguro no app',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _reload,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    color: colorScheme.onPrimary,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.onPrimary.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: BorderRadius.circular(AppSpacing.lg),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.amountLabel,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Compra estimada em ${widget.btcAmountLabel}',
                          style: theme.textTheme.bodySmall!.copyWith(
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_pageLoaded || _progress < 100)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: _progress <= 0 ? null : _progress / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassContainer(
                borderRadius: BorderRadius.circular(AppSpacing.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
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
                                  Icon(
                                    LucideIcons.cloudOff,
                                    size: 30,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Nao foi possivel carregar o provedor',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  FilledButton(
                                    onPressed: _reload,
                                    child: const Text('Tentar novamente'),
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
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: BorderRadius.circular(AppSpacing.lg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Endereco BTC vinculado ao checkout',
                          style: theme.textTheme.labelSmall!.copyWith(
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.52),
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.depositAddress.isEmpty
                              ? 'Endereco indisponivel'
                              : widget.depositAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontFamily: 'JetBrainsMono',
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    onPressed:
                        widget.depositAddress.isEmpty ? null : _copyAddress,
                    icon: const Icon(LucideIcons.copy, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
