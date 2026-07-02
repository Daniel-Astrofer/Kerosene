import 'package:kerosene/core/theme/app_colors.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/flow/receive_nfc_availability_provider.dart';

enum ReceiveNfcStage { methodSelection, searching, found, success }

enum ReceiveNfcMethod { direct, lightning, onchain, automatic }

class ReceiveNfcFlowScreen extends StatefulWidget {
  final Wallet wallet;
  final bool onChainWallet;
  final double amountBtc;
  final Future<bool> Function()? supportsNfc;

  const ReceiveNfcFlowScreen({
    super.key,
    required this.wallet,
    required this.onChainWallet,
    required this.amountBtc,
    this.supportsNfc,
  });

  @override
  State<ReceiveNfcFlowScreen> createState() => _ReceiveNfcFlowScreenState();
}

class _ReceiveNfcFlowScreenState extends State<ReceiveNfcFlowScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = AppColors.hexFF050505;
  static const Color _surface = AppColors.hexFF121212;
  static const Color _surfaceHigh = AppColors.hexFF1A1A1A;
  static const Color _border = AppColors.hexFF2A2A2A;
  static const Color _text = AppColors.hexFFFFFFFF;
  static const Color _mutedText = AppColors.hexFFA3A3A3;
  static const Color _success = AppColors.hexFF4ADE80;

  late final AnimationController _pulseController;
  final List<Timer> _timers = [];

  ReceiveNfcStage _stage = ReceiveNfcStage.methodSelection;
  ReceiveNfcMethod _detectedMethod = ReceiveNfcMethod.direct;
  DateTime _completedAt = DateTime.now();
  bool _checkingCompatibility = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.ceremonial,
    )..repeat();
    unawaited(_ensureNfcCompatible());
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _ensureNfcCompatible() async {
    final compatible =
        await (widget.supportsNfc ?? keroseneDeviceSupportsNfc)();
    if (!mounted) return;
    if (!compatible) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _checkingCompatibility = false);
  }

  void _setStage(ReceiveNfcStage stage) {
    if (!mounted) {
      return;
    }
    setState(() => _stage = stage);
  }

  void _selectMethod(ReceiveNfcMethod method) {
    HapticFeedback.selectionClick();
    _clearTimers();
    _detectedMethod = _resolveDetectedMethod(method);
    setState(() => _stage = ReceiveNfcStage.searching);
    _timers
      ..add(Timer(KeroseneMotion.nfcSceneIntro, () {
        _setStage(ReceiveNfcStage.found);
      }))
      ..add(Timer(KeroseneMotion.nfcSceneReady, () {
        _completedAt = DateTime.now();
        HapticFeedback.mediumImpact();
        _setStage(ReceiveNfcStage.success);
      }));
  }

  ReceiveNfcMethod _resolveDetectedMethod(ReceiveNfcMethod method) {
    if (method != ReceiveNfcMethod.automatic) {
      return method;
    }
    return widget.onChainWallet
        ? ReceiveNfcMethod.onchain
        : ReceiveNfcMethod.direct;
  }

  void _clearTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  String get _amountLabel {
    final amount = MoneyDisplay.formatCompact(
      amount: widget.amountBtc,
      currency: Currency.btc,
      withSymbol: false,
      maxDecimalPlaces: 8,
    );
    return '$amount BTC';
  }

  String get _statusLabel {
    return switch (_detectedMethod) {
      ReceiveNfcMethod.direct => 'Confirmado na Kerosene',
      ReceiveNfcMethod.lightning => 'Confirmado via Lightning',
      ReceiveNfcMethod.onchain => 'Aguardando rede Bitcoin',
      ReceiveNfcMethod.automatic => 'Confirmado na Kerosene',
    };
  }

  String get _networkLabel {
    return switch (_detectedMethod) {
      ReceiveNfcMethod.direct => 'Direct',
      ReceiveNfcMethod.lightning => 'Lightning',
      ReceiveNfcMethod.onchain => 'On-chain',
      ReceiveNfcMethod.automatic => 'Direct',
    };
  }

  String get _detectedTitle {
    return switch (_detectedMethod) {
      ReceiveNfcMethod.direct => 'Transação Direct detectada',
      ReceiveNfcMethod.lightning => 'Transação Lightning detectada',
      ReceiveNfcMethod.onchain => 'Transação On-chain detectada',
      ReceiveNfcMethod.automatic => 'Transação Direct detectada',
    };
  }

  String get _detectedDescription {
    return switch (_detectedMethod) {
      ReceiveNfcMethod.direct =>
        'Transferência interna reconhecida. Aguardando autenticação do pagador.',
      ReceiveNfcMethod.lightning =>
        'Invoice Lightning reconhecida. Validando rota e liquidez.',
      ReceiveNfcMethod.onchain =>
        'Pedido on-chain reconhecido. Aguardando propagação da transação.',
      ReceiveNfcMethod.automatic =>
        'Método detectado automaticamente. Aguardando confirmação do pagador.',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingCompatibility) {
      return const Center(child: TorLoadingDots());
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth < 480 ? constraints.maxWidth : 480.0;

            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: AnimatedSwitcher(
                  duration: KeroseneMotion.long,
                  switchInCurve: KeroseneMotion.standard,
                  switchOutCurve: KeroseneMotion.exit,
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: switch (_stage) {
                      ReceiveNfcStage.methodSelection =>
                        _buildMethodSelection(context),
                      ReceiveNfcStage.searching => _buildSearching(context),
                      ReceiveNfcStage.found => _buildFound(context),
                      ReceiveNfcStage.success => _buildSuccess(context),
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearching(BuildContext context) {
    const searchingTitle = 'Aproxime o dispositivo';
    const searchingFooter =
        'Aproxime o dispositivo do pagador ao sensor NFC do seu celular';
    return _buildHeaderLayout(
      context,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNfcOrb(size: 200),
          const SizedBox(height: 32),
          Text(
            searchingTitle,
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _text,
              fontSize: 48,
              fontWeight: FontWeight.w400,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      footer: Text(
        searchingFooter,
        textAlign: TextAlign.center,
        style: AppTypography.inter(
          color: _text.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildMethodSelection(BuildContext context) {
    const selectMethodTitle = 'Selecionar método';
    const selectMethodSubtitle =
        'Selecione quais redes aceitar para recebimento via NFC.';
    const understandMethodsTitle = 'Entenda os métodos';
    const directMethodLabel = 'Direct';
    const lightningMethodLabel = 'Lightning';
    const onChainMethodLabel = 'On-chain';
    const autoDetectLabel = 'Detectar\nautomaticamente';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectMethodTitle,
                    style: AppTypography.newsreader(
                      color: _text,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectMethodSubtitle,
                    style: AppTypography.inter(
                      color: _mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 36),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 32,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.95,
                    children: [
                      _buildMethodOption(
                        icon: KeroseneIcons.internalTransfer,
                        label: directMethodLabel,
                        method: ReceiveNfcMethod.direct,
                      ),
                      _buildMethodOption(
                        icon: KeroseneIcons.lightning,
                        label: lightningMethodLabel,
                        method: ReceiveNfcMethod.lightning,
                      ),
                      _buildMethodOption(
                        icon: KeroseneIcons.onchain,
                        label: onChainMethodLabel,
                        method: ReceiveNfcMethod.onchain,
                      ),
                      _buildMethodOption(
                        icon: KeroseneIcons.nfc,
                        label: autoDetectLabel,
                        method: ReceiveNfcMethod.automatic,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    understandMethodsTitle,
                    style: AppTypography.newsreader(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 156,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        _NfcMethodInfoCard(
                          title: 'Direct',
                          body:
                              'Transferência direta entre usuários da plataforma.',
                        ),
                        _NfcMethodInfoCard(
                          title: 'Lightning',
                          body:
                              'Recebimento instantâneo com taxa de roteamento.',
                        ),
                        _NfcMethodInfoCard(
                          title: 'On-chain',
                          body:
                              'Transação registrada na rede Bitcoin para valores maiores.',
                        ),
                      ],
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

  Widget _buildMethodOption({
    required IconData icon,
    required String label,
    required ReceiveNfcMethod method,
  }) {
    return Semantics(
      button: true,
      label: label.replaceAll('\n', ' '),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _selectMethod(method),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceHigh,
                border: Border.all(color: _border),
              ),
              child: Icon(icon, color: _text, size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: _mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFound(BuildContext context) {
    return _buildHeaderLayout(
      context,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNfcOrb(size: 192, detected: true),
          const SizedBox(height: 40),
          Text(
            _detectedTitle,
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _text,
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _detectedDescription,
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: _mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 48),
          _buildProgressLine(),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    const successTitle = 'Transação reconhecida';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 32),
                    Text(
                      successTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.newsreader(
                        color: _text,
                        fontSize: 48,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _amountLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.newsreader(
                        color: _text,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentStatusChip(),
                    const SizedBox(height: 28),
                    _buildDetailsCard(context),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSuccessActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderLayout(
    BuildContext context, {
    required Widget center,
    Widget? footer,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: center,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: footer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    const receiveLabel = 'Receber';
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(KeroseneIcons.back),
              color: _text,
              style: IconButton.styleFrom(
                foregroundColor: _text,
                shape: const CircleBorder(),
              ),
            ),
          ),
          Text(
            receiveLabel,
            style: AppTypography.inter(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcOrb({required double size, bool detected = false}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final progress = _pulseController.value;
        final scale = 1 + progress * 0.18;
        final opacity = 0.28 * (1 - progress);
        final glowOpacity = detected ? 0.18 : 0.1;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.76,
                height: size * 0.76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _success.withValues(alpha: glowOpacity),
                      blurRadius: detected ? 44 : 34,
                      spreadRadius: detected ? 8 : 2,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _success.withValues(alpha: opacity),
                    ),
                  ),
                ),
              ),
              if (detected)
                Transform.scale(
                  scale: 1 + progress * 0.12,
                  child: Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _success.withValues(alpha: opacity + 0.08),
                      ),
                    ),
                  ),
                ),
              Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_surfaceHigh, _surface],
                  ),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  KeroseneIcons.nfc,
                  color: detected ? _success : _text,
                  size: size * 0.34,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressLine() {
    return SizedBox(
      width: 200,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _border,
          borderRadius: BorderRadius.circular(999),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final widthFactor = _pulseController.value;
              final opacity = 1 - _pulseController.value;

              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthFactor.clamp(0.04, 1),
                  child: Container(
                    color: _success.withValues(alpha: opacity.clamp(0.2, 1)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final progress = _pulseController.value;

        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + progress * 0.22,
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _success.withValues(alpha: 0.24 * (1 - progress)),
                    ),
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceHigh,
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: _success.withValues(alpha: 0.12),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Icon(
                  KeroseneIcons.success,
                  color: _success,
                  size: 48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final time = DateFormat('HH:mm').format(_completedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surfaceHigh, _surface],
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow('Destino', _shortenAddress(widget.wallet.address)),
          const SizedBox(height: 16),
          Divider(color: _border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 16),
          _buildDetailRow('Rede', _networkLabel),
          const SizedBox(height: 16),
          Divider(color: _border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 16),
          _buildDetailRow('Status', _statusLabel),
          const SizedBox(height: 16),
          Divider(color: _border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 16),
          if (_detectedMethod == ReceiveNfcMethod.lightning) ...[
            _buildDetailRow('Taxa Lightning', '0.000001 BTC'),
            const SizedBox(height: 16),
            Divider(color: _border.withValues(alpha: 0.6), height: 1),
            const SizedBox(height: 16),
          ] else if (_detectedMethod == ReceiveNfcMethod.onchain) ...[
            _buildDetailRow('Taxa de rede', 'A confirmar'),
            const SizedBox(height: 16),
            Divider(color: _border.withValues(alpha: 0.6), height: 1),
            const SizedBox(height: 16),
          ],
          _buildDetailRow('Data', 'Hoje, $time'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.inter(
            color: _mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.inter(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _surfaceHigh,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _success.withValues(alpha: 0.60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel,
            style: AppTypography.inter(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: TextButton(
            onPressed: _goHome,
            style: TextButton.styleFrom(
              foregroundColor: _text,
              backgroundColor: _surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _border),
              ),
              textStyle: AppTypography.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
            child: Text(context.tr.goToHome),
          ),
        ),
      ],
    );
  }

  void _goHome() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _NfcMethodInfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _NfcMethodInfoCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ReceiveNfcFlowScreenState._surfaceHigh,
        border: Border.all(color: _ReceiveNfcFlowScreenState._border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.newsreader(
              color: _ReceiveNfcFlowScreenState._text,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.inter(
              color: _ReceiveNfcFlowScreenState._mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _shortenAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 13) return trimmed;
  return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 4)}';
}
