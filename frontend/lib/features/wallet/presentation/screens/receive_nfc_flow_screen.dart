import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';

enum ReceiveNfcStage { searching, found, success }

class ReceiveNfcFlowScreen extends StatefulWidget {
  final Wallet wallet;
  final bool onChainWallet;
  final double amountBtc;

  const ReceiveNfcFlowScreen({
    super.key,
    required this.wallet,
    required this.onChainWallet,
    required this.amountBtc,
  });

  @override
  State<ReceiveNfcFlowScreen> createState() => _ReceiveNfcFlowScreenState();
}

class _ReceiveNfcFlowScreenState extends State<ReceiveNfcFlowScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFF050505);
  static const Color _surface = Color(0xFF121212);
  static const Color _surfaceHigh = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF2A2A2A);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _mutedText = Color(0xFFA3A3A3);
  static const Color _success = Color(0xFF4ADE80);

  late final AnimationController _pulseController;
  final List<Timer> _timers = [];

  ReceiveNfcStage _stage = ReceiveNfcStage.searching;
  DateTime _completedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _timers
      ..add(Timer(const Duration(milliseconds: 1600), () {
        _setStage(ReceiveNfcStage.found);
      }))
      ..add(Timer(const Duration(milliseconds: 3900), () {
        _completedAt = DateTime.now();
        HapticFeedback.mediumImpact();
        _setStage(ReceiveNfcStage.success);
      }));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _setStage(ReceiveNfcStage stage) {
    if (!mounted) {
      return;
    }
    setState(() => _stage = stage);
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
    return widget.onChainWallet
        ? 'Confirmado na rede'
        : 'Confirmado na Kerosene';
  }

  String get _networkLabel {
    return widget.onChainWallet ? 'Bitcoin (BTC)' : 'Kerosene';
  }

  @override
  Widget build(BuildContext context) {
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
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: switch (_stage) {
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
    return _buildHeaderLayout(
      context,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNfcOrb(size: 200),
          const SizedBox(height: 32),
          Text(
            'Aproxime o dispositivo',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
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
        'Aproxime o dispositivo do pagador ao sensor NFC do seu celular',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: _text.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          letterSpacing: 0,
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
            'Dispositivo detectado!',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
              color: _text,
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando confirmação e autenticação no dispositivo do pagador...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
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
                      'Pagamento\nIdentificado!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSerif(
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
                      style: GoogleFonts.ibmPlexSerif(
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
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(LucideIcons.chevronLeft),
              color: _text,
              style: IconButton.styleFrom(
                foregroundColor: _text,
                shape: const CircleBorder(),
              ),
            ),
          ),
          Text(
            'Receber',
            style: GoogleFonts.inter(
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
                  LucideIcons.nfc,
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
                  LucideIcons.checkCircle2,
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
          style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Ir para o início'),
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

String _shortenAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 13) return trimmed;
  return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 4)}';
}
