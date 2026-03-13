import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/shared/widgets/cyber_icons.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/features/wallet/domain/entities/payment_request.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../widgets/liquid_action_painter.dart';

enum TransactionMode { normal, nfc, qr, manual }

class UnifiedTransactionScreen extends ConsumerStatefulWidget {
  final bool isInitialSend;
  const UnifiedTransactionScreen({super.key, this.isInitialSend = true});

  @override
  ConsumerState<UnifiedTransactionScreen> createState() =>
      _UnifiedTransactionScreenState();
}

class _UnifiedTransactionScreenState
    extends ConsumerState<UnifiedTransactionScreen>
    with TickerProviderStateMixin {
  int _activePage = 0; // 0: Send, 1: Receive
  final TextEditingController _amountController = TextEditingController(
    text: "0",
  );
  final FocusNode _amountFocusNode = FocusNode();

  // Gesture State
  Offset _dragOffset = Offset.zero;
  final double _threshold = 120.0;
  final double _dampening = 0.85;

  // Transaction Mode
  TransactionMode _currentMode = TransactionMode.normal;
  bool _isNfcSupported = false;

  // Error shake state
  bool _isError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _activePage = widget.isInitialSend ? 0 : 1;
    _checkNfcSupport();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        setState(() => _isError = false);
      }
    });
  }

  Future<void> _checkNfcSupport() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (mounted) {
      setState(() {
        _isNfcSupported = availability == NfcAvailability.enabled;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_amountFocusNode.hasFocus) _amountFocusNode.unfocus();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final oldOffset = _dragOffset;
      _dragOffset += details.delta * _dampening;

      final bool wasXOver = oldOffset.dx.abs() >= _threshold;
      final bool isXOver = _dragOffset.dx.abs() >= _threshold;
      final bool wasYOver = oldOffset.dy >= _threshold;
      final bool isYOver = _dragOffset.dy >= _threshold;

      if ((!wasXOver && isXOver) || (!wasYOver && isYOver)) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    if (dx.abs() > dy.abs()) {
      if (dx < -(_threshold * 0.8) && _isNfcSupported) {
        _setMode(TransactionMode.nfc);
      } else if (dx > (_threshold * 0.8)) {
        _setMode(TransactionMode.qr);
      }
    } else {
      if (dy > (_threshold * 0.8)) {
        _setMode(TransactionMode.manual);
      }
    }

    setState(() => _dragOffset = Offset.zero);
  }

  void _triggerErrorShake() {
    HapticFeedback.vibrate();
    setState(() => _isError = true);
    _shakeController.forward(from: 0);
  }

  void _setMode(TransactionMode mode) {
    final rawText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(rawText) ?? 0;
    // Receive tab requires an amount for QR/NFC
    if (_activePage == 1 && amount <= 0 && mode != TransactionMode.manual) {
      _triggerErrorShake();
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _currentMode = mode);
  }

  // Computes dynamic scale and offset based on drag distance
  double get _dragProgress {
    final maxDist = _dragOffset.distance;
    return (maxDist / (_threshold * 1.5)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final selectedWallet = walletState is WalletLoaded
        ? walletState.selectedWallet
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentMode == TransactionMode.normal
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            if (_currentMode == TransactionMode.normal) {
              Navigator.pop(context);
            } else {
              setState(() => _currentMode = TransactionMode.normal);
            }
          },
        ),
        title: _currentMode == TransactionMode.normal
            ? _buildTabIndicator()
            : Text(
                _currentMode.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Liquid edge effect
            CustomPaint(
              painter: LiquidActionPainter(
                dragOffset: _dragOffset,
                threshold: _threshold,
                isSend: _activePage == 0,
              ),
            ),
            // Tab content with AnimatedSwitcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: _buildCurrentModeContent(selectedWallet),
            ),
            // Directional hints
            if (_currentMode == TransactionMode.normal)
              _buildDirectionalActionHints(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModeContent(dynamic wallet) {
    switch (_currentMode) {
      case TransactionMode.normal:
        return AnimatedSwitcher(
          key: const ValueKey('tab_switcher'),
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildAmountEntryView(
            wallet,
            _activePage == 0,
            key: ValueKey('page_$_activePage'),
          ),
        );
      case TransactionMode.nfc:
        return _buildNfcModeView();
      case TransactionMode.qr:
        return _buildQrModeView();
      case TransactionMode.manual:
        return _buildManualModeView();
    }
  }

  Widget _buildDirectionalActionHints() {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    return Stack(
      children: [
        if (_isNfcSupported)
          _buildAdaptiveHint(
            icon: Icons.contactless_rounded,
            alignment: Alignment.centerLeft,
            currentValue: dx,
            threshold: -_threshold,
            label: "NFC",
            isActive: dx < -(_threshold * 0.7) && dx.abs() > dy.abs(),
          ),
        _buildAdaptiveHint(
          icon: Icons.qr_code_scanner_rounded,
          alignment: Alignment.centerRight,
          currentValue: dx,
          threshold: _threshold,
          label: "QR",
          isActive: dx > (_threshold * 0.7) && dx.abs() > dy.abs(),
        ),
        _buildAdaptiveHint(
          icon: Icons.keyboard_rounded,
          alignment: Alignment.bottomCenter,
          currentValue: dy,
          threshold: _threshold,
          label: "MANUAL",
          isActive: dy > (_threshold * 0.7) && dy.abs() > dx.abs(),
          padding: const EdgeInsets.only(bottom: 60),
        ),
      ],
    );
  }

  Widget _buildAdaptiveHint({
    required IconData icon,
    required Alignment alignment,
    required double currentValue,
    required double threshold,
    required String label,
    required bool isActive,
    EdgeInsets padding = const EdgeInsets.all(40),
  }) {
    final double opacity = (currentValue.abs() / (_threshold * 0.8)).clamp(
      0.0,
      1.0,
    );
    if (opacity < 0.1) return const SizedBox();

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isActive ? 1.3 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive ? Colors.white38 : Colors.white12,
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountEntryView(dynamic wallet, bool isSend, {Key? key}) {
    // Scale down amount display as user drags toward an action
    final scale = 1.0 - (_dragProgress * 0.22);
    // Translate towards the direction the user is pulling
    final translateX = _dragOffset.dx * 0.12;
    final translateY = _dragOffset.dy * 0.12;

    return SizedBox.expand(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Amount block: scales, translates, and shakes on error
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shakeX = _isError
                  ? 10 *
                        (1 - _shakeController.value) *
                        (_shakeController.value * 10 % 2 < 1 ? 1 : -1)
                  : 0.0;
              return Transform.translate(
                offset: Offset(translateX + shakeX, translateY),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAmountTextField(),
                  const SizedBox(height: 12),
                  _buildLiveQuote(),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAmountTextField() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: IntrinsicWidth(
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) => child!,
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textAlign: TextAlign.center,
                  inputFormatters: [_BtcAmountInputFormatter()],
                  style: TextStyle(
                    // Turn red + slightly larger on error
                    color: _isError ? const Color(0xFFFF4444) : Colors.white,
                    fontSize: _isError ? 80 : 76,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    fontFamily: 'HubotSansExpanded',
                    backgroundColor: Colors.transparent,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                  onTap: () {
                    if (_amountController.text == "0") {
                      _amountController.clear();
                    }
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "BTC",
            style: TextStyle(
              color: _isError
                  ? const Color(0xFFFF4444).withValues(alpha: 0.5)
                  : Colors.white30,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveQuote() {
    return Consumer(
      builder: (context, ref, child) {
        final btcPriceAsync = ref.watch(btcPriceProvider);
        return btcPriceAsync.when(
          data: (price) {
            final valStr = _amountController.text.replaceAll(',', '.');
            final btcAmount = double.tryParse(valStr) ?? 0.0;
            final usdAmount = btcAmount * price;

            return Text(
              _formatUsd(usdAmount),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            );
          },
          loading: () => const SizedBox(height: 22),
          error: (_, __) => const SizedBox(height: 22),
        );
      },
    );
  }

  String _formatUsd(double amount) {
    if (amount == 0) return "≈ \$ 0.00";
    if (amount >= 1000) {
      final f = amount.toStringAsFixed(0);
      return "≈ \$ ${f.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
    }
    return "≈ \$ ${amount.toStringAsFixed(2)}";
  }

  // --- Mode specific views ---

  Widget _buildNfcModeView() {
    return Center(
      key: const ValueKey('nfc_view'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CyberNfcIcon(isActive: true, size: 110),
          const SizedBox(height: 40),
          Text(
            _activePage == 0 ? "APPROACH SENDER DEVICE" : "READY TO BEAM",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrModeView() {
    return Center(
      key: const ValueKey('qr_view'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activePage == 0) ...[
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 70,
              color: Colors.white24,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: const BorderSide(color: Colors.white10),
                ),
              ),
              onPressed: () async {
                final data = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
                if (data != null && mounted) _handleScannedData(data);
              },
              child: const Text(
                "OPEN SCANNER",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ] else
            Consumer(
              builder: (context, ref, _) {
                final walletState = ref.watch(walletProvider);
                if (walletState is! WalletLoaded) return const SizedBox();
                final wallet = walletState.selectedWallet;
                final rawText = _amountController.text.replaceAll(',', '.');
                final amount = double.tryParse(rawText) ?? 0;
                final uri = PaymentRequest(
                  address: wallet?.address ?? "",
                  amountBtc: amount,
                ).toBitcoinUri();

                return Column(
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(28),
                      borderRadius: BorderRadius.circular(40),
                      opacity: 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: uri,
                          version: QrVersions.auto,
                          size: 210,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      amount > 0
                          ? "${_amountController.text} BTC"
                          : "VALOR LIVRE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        fontFamily: 'HubotSansExpanded',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        wallet?.name.toUpperCase() ?? "CARTEIRA DESCONHECIDA",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      wallet?.address ?? "",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildManualModeView() {
    final receiverController = TextEditingController();
    return Padding(
      key: const ValueKey('manual_view'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white24, size: 60),
          const SizedBox(height: 40),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            borderRadius: BorderRadius.circular(24),
            opacity: 0.05,
            child: TextField(
              controller: receiverController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _activePage == 0
                    ? "Endereço Destinatário"
                    : "Referência do Pagamento",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                if (_activePage == 0) {
                  _startTransaction(receiverController.text);
                }
                setState(() => _currentMode = TransactionMode.normal);
              },
              child: Text(
                _activePage == 0 ? "CONTINUAR" : "DEFINIR REFERÊNCIA",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedData(String data) {
    setState(() => _currentMode = TransactionMode.normal);
    debugPrint("Scanned: $data");
  }

  void _startTransaction(String address) {
    if (address.isEmpty) return;
  }

  Widget _buildTabIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            label: context.l10n.send.toUpperCase(),
            isActive: _activePage == 0,
            onTap: () => setState(() => _activePage = 0),
          ),
          _TabItem(
            label: context.l10n.receive.toUpperCase(),
            isActive: _activePage == 1,
            onTap: () => setState(() => _activePage = 1),
          ),
        ],
      ),
    );
  }
}

// --- Custom Input Formatter for BTC Amounts ---

class _BtcAmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty
    if (newValue.text.isEmpty) return newValue;

    // Only allow digits and one separator
    final raw = newValue.text;

    // Replace comma with dot for internal handling, then allow only one dot
    String cleaned = raw.replaceAll(',', '.');
    final dotCount = cleaned.split('.').length - 1;

    if (dotCount > 1) {
      // Reject double separator
      return oldValue;
    }

    // Strip non-numeric characters except dot
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');

    // Limit decimals to 8 (satoshi precision)
    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts[1].length > 8) {
        cleaned = '${parts[0]}.${parts[1].substring(0, 8)}';
      }
    }

    if (cleaned == newValue.text) return newValue;

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
