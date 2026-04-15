import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../shared/widgets/brushed_metal_container.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_card_appearance.dart';
import '../providers/balance_settings_provider.dart';
import '../screens/wallet_config_screen.dart';

class WalletCreditCard extends ConsumerStatefulWidget {
  final Wallet? wallet;
  final int colorIndex;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isAddCard;
  final double elevation;
  final bool showDetails;
  final VoidCallback? onLongPress;
  final double tiltX;
  final double tiltY;

  const WalletCreditCard({
    super.key,
    this.wallet,
    required this.colorIndex,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.elevation = 0.0,
    this.showDetails = true,
    this.isAddCard = false,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
  });

  @override
  ConsumerState<WalletCreditCard> createState() => _WalletCreditCardState();
}

class _WalletCreditCardState extends ConsumerState<WalletCreditCard> {
  ui.Image? _textTexture;

  @override
  void initState() {
    super.initState();
    if (!widget.isAddCard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateTexture();
      });
    }
  }

  @override
  void didUpdateWidget(WalletCreditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAddCard) return;

    if (oldWidget.wallet?.name != widget.wallet?.name ||
        oldWidget.wallet?.balance != widget.wallet?.balance ||
        oldWidget.wallet?.address != widget.wallet?.address ||
        oldWidget.wallet?.cardType != widget.wallet?.cardType ||
        oldWidget.showDetails != widget.showDetails) {
      _generateTexture();
    }
  }

  Future<void> _generateTexture() async {
    const cardW = 303.0;
    const cardH = 175.0;

    final baseDpr = View.of(context).devicePixelRatio;
    final dpr = baseDpr * 2.0;

    final targetW = (cardW * dpr).toInt();
    final targetH = (cardH * dpr).toInt();

    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, cardW * dpr, cardH * dpr));

    canvas.drawColor(Colors.transparent, BlendMode.clear);
    canvas.scale(dpr);

    final textPaint = Paint()..color = Theme.of(context).colorScheme.onPrimary;

    if (widget.wallet != null) {
      // We remove the gradient paint to keep the background perfectly transparent, 
      // preventing alpha-channel interference with the shader's engrave mask.
      final chipX = cardW - 68;
      final chipY = 24.0;
      final chipRect = RRect.fromLTRBR(
          chipX, chipY, chipX + 44, chipY + 32, const Radius.circular(6));

      final chipBasePaint = Paint()
        ..color =
            Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
      canvas.drawRRect(chipRect, chipBasePaint);

      final linePaint = Paint()
        ..color = Theme.of(context).colorScheme.onSurface
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear
        ..strokeWidth = 1.0;

      final cw = 44.0;
      final ch = 32.0;
      canvas.drawLine(Offset(chipX + cw * 0.35, chipY),
          Offset(chipX + cw * 0.35, chipY + ch), linePaint);
      canvas.drawLine(Offset(chipX + cw * 0.65, chipY),
          Offset(chipX + cw * 0.65, chipY + ch), linePaint);
      canvas.drawLine(Offset(chipX, chipY + ch * 0.3),
          Offset(chipX + cw * 0.25, chipY + ch * 0.3), linePaint);
      canvas.drawLine(Offset(chipX, chipY + ch * 0.7),
          Offset(chipX + cw * 0.25, chipY + ch * 0.7), linePaint);
      canvas.drawLine(Offset(chipX + cw * 0.75, chipY + ch * 0.3),
          Offset(chipX + cw, chipY + ch * 0.3), linePaint);
      canvas.drawLine(Offset(chipX + cw * 0.75, chipY + ch * 0.7),
          Offset(chipX + cw, chipY + ch * 0.7), linePaint);
      canvas.drawCircle(Offset(chipX + cw / 2, chipY + ch / 2), 5, linePaint);

      // TEXT
      canvas.saveLayer(null, textPaint);

      final nameText = widget.wallet!.name.toUpperCase();
      final namePainter = TextPainter(
        text: TextSpan(
          text: nameText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.0,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      namePainter.layout(maxWidth: cardW - 116);
      namePainter.paint(canvas, const Offset(24, 24));

      final balanceSettings = ref.read(balanceSettingsProvider);
      final String balanceStr;
      if (balanceSettings.isHidden) {
        balanceStr = "•••••••• BTC";
      } else {
        balanceStr =
            "${widget.wallet!.balance.toStringAsFixed(balanceSettings.decimalPlaces)} BTC";
      }
      final balanceFontSize = _fitMonospaceFontSize(
        balanceStr,
        maxWidth: cardW - 48,
        baseFontSize: 22,
        minFontSize: 15,
        fontWeight: FontWeight.w900,
      );
      final balancePainter = TextPainter(
        text: TextSpan(
          text: balanceStr,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: balanceFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.0,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      balancePainter.layout();
      balancePainter.paint(
        canvas,
        Offset(
          24.0, // Center Left (padding matches the name)
          (cardH - balancePainter.height) / 2 + 4,
        ),
      );

      final addressHash = _addressHash(widget.wallet!.address);
      final hashLabel = addressHash.isNotEmpty ? _maskHash(addressHash) : '';
      final addressPainter = TextPainter(
        text: TextSpan(
          text: hashLabel.isNotEmpty ? 'HASH $hashLabel' : '',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.0,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      addressPainter.layout(maxWidth: cardW - 48);
      addressPainter.paint(
        canvas,
        Offset((cardW - addressPainter.width) / 2, 110),
      );

      canvas.restore();
    }

    try {
      final picture = recorder.endRecording();
      final img = await picture.toImage(targetW, targetH);

      if (mounted) {
        setState(() => _textTexture = img);
      }
    } catch (e) {
      debugPrint("🚨 Error creating wallet texture: $e");
    }
  }

  String _addressHash(String address) {
    final normalized = address.trim();
    if (normalized.isEmpty) return '';
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  String _maskHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  double _fitMonospaceFontSize(
    String text, {
    required double maxWidth,
    required double baseFontSize,
    required double minFontSize,
    required FontWeight fontWeight,
  }) {
    var fontSize = baseFontSize;
    while (fontSize > minFontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: 'JetBrainsMono',
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: double.infinity);

      if (painter.width <= maxWidth) {
        return fontSize;
      }

      fontSize -= 1;
    }

    return minFontSize;
  }

  String _localizedCopy({
    required BuildContext context,
    required String pt,
    required String en,
    required String es,
  }) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  @override
  Widget build(BuildContext context) {
    const width = 303.0;
    const cardHeight = 175.0;
    final appearance = widget.wallet != null
        ? WalletCardAppearance.fromCardType(widget.wallet!.cardType)
        : WalletCardAppearance.fromIndex(widget.colorIndex);
    final badgeBackground = appearance.isDark
        ? Colors.black.withValues(alpha: 0.22)
        : appearance.cardShadowColor.withValues(alpha: 0.18);
    final badgeBorder = appearance.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : appearance.cardHighlightColor.withValues(alpha: 0.18);
    final badgeTextColor = appearance.isDark
        ? Colors.white.withValues(alpha: 0.88)
        : appearance.cardHighlightColor.withValues(alpha: 0.92);
    final walletAddressHash =
        widget.wallet == null ? '' : _addressHash(widget.wallet!.address);

    ref.listen(balanceSettingsProvider, (prev, next) {
      if (prev?.isHidden != next.isHidden ||
          prev?.decimalPlaces != next.decimalPlaces) {
        _generateTexture();
      }
    });

    final showShadow = widget.isSelected || widget.elevation > 0;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
          return;
        }
        if (widget.isAddCard || widget.wallet == null) return;
        HapticFeedback.mediumImpact();

        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                WalletConfigScreen(wallet: widget.wallet!),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutBack));
              return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child));
            },
          ),
        );
      },
      child: Center(
        child: Hero(
          tag: 'card_hero_${widget.wallet?.address ?? widget.colorIndex}',
          transitionOnUserGestures: true,
          child: Container(
            height: cardHeight,
            width: width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              boxShadow: [
                if (showShadow)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  child: Stack(
                    children: [
                      BrushedMetalContainer(
                        width: width,
                        height: cardHeight,
                        materialId: appearance.paletteIndex.toDouble(),
                        tiltX: widget.tiltX,
                        tiltY: widget.tiltY,
                        baseColor: appearance.baseColor,
                        borderRadius: AppSpacing.md,
                        textTexture: _textTexture,
                      ),
                      if (widget.wallet != null && walletAddressHash.isNotEmpty)
                        Positioned(
                          bottom: 20,
                          left: 24,
                          right: 24,
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: walletAddressHash),
                              );
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _localizedCopy(
                                      context: context,
                                      pt: 'Hash copiado',
                                      en: 'Hash copied',
                                      es: 'Hash copiado',
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: badgeBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    LucideIcons.copy,
                                    size: 10,
                                    color:
                                        badgeTextColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Hash ${_maskHash(walletAddressHash)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: badgeTextColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.isAddCard)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.addCard,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
