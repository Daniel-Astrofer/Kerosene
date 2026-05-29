import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

import '../../domain/entities/wallet.dart';
import '../providers/balance_settings_provider.dart';

const _creditCardWidth = 336.0;
const _creditCardHeight = 190.0;
const _creditCardRadius = 10.0;

class WalletCreditCard extends ConsumerWidget {
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

  void _openConfig(BuildContext context) {
    if (onLongPress != null) {
      onLongPress!();
      return;
    }
    if (isAddCard || wallet == null) {
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final palette = _CreditCardPalette.resolve(wallet?.cardType, colorIndex);
    final showShadow = isSelected || elevation > 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _openConfig(context),
      child: Center(
        child: Hero(
          tag: 'card_hero_${wallet?.address ?? colorIndex}',
          transitionOnUserGestures: true,
          child: SizedBox(
            width: _creditCardWidth,
            height: _creditCardHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_creditCardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: showShadow ? 0.34 : 0.18,
                    ),
                    blurRadius: showShadow ? 24 : 14,
                    offset: Offset(0, showShadow ? 14 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_creditCardRadius),
                child: isAddCard || wallet == null
                    ? _EmptyCreditCardFace(palette: palette)
                    : _PhysicalCreditCardFace(
                        wallet: wallet!,
                        palette: palette,
                        balanceSettings: balanceSettings,
                        showDetails: showDetails,
                        isSelected: isSelected,
                        tiltX: tiltX,
                        tiltY: tiltY,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhysicalCreditCardFace extends StatelessWidget {
  final Wallet wallet;
  final _CreditCardPalette palette;
  final BalanceSettings balanceSettings;
  final bool showDetails;
  final bool isSelected;
  final double tiltX;
  final double tiltY;

  const _PhysicalCreditCardFace({
    required this.wallet,
    required this.palette,
    required this.balanceSettings,
    required this.showDetails,
    required this.isSelected,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
        ),
        CustomPaint(
          painter: _CreditCardSurfacePainter(
            palette: palette,
            isSelected: isSelected,
            tiltX: tiltX,
            tiltY: tiltY,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardBrandBlock(
                      palette: palette,
                      tier: wallet.cardType.label.toUpperCase(),
                    ),
                  ),
                  _NetworkMark(color: palette.inkPrimary),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CardChip(palette: palette),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.contactless,
                    color: palette.inkPrimary.withValues(alpha: 0.72),
                    size: 24,
                  ),
                  const Spacer(),
                  if (showDetails)
                    _BalanceBlock(
                      label: _balanceLabel(wallet, balanceSettings),
                      palette: palette,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _maskedCardNumber(wallet),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.inkPrimary,
                  fontFamily: 'IBMPlexSansHebrew',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _CardTextField(
                      label: 'CARD HOLDER',
                      value: wallet.effectiveCardHolderName.toUpperCase(),
                      palette: palette,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CardTextField(
                    label: 'VALID THRU',
                    value: _expiryLabel(wallet),
                    palette: palette,
                    alignEnd: true,
                  ),
                  if (showDetails && wallet.passphraseHash.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _SecurityHashButton(
                        hash: wallet.passphraseHash.trim(),
                        palette: palette,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_creditCardRadius),
                border: Border.all(
                  color: palette.border,
                  width: isSelected ? 1.25 : 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _balanceLabel(Wallet wallet, BalanceSettings settings) {
    if (settings.isHidden) {
      return 'BTC ********';
    }
    return '${wallet.balance.toStringAsFixed(settings.decimalPlaces)} BTC';
  }

  static String _maskedCardNumber(Wallet wallet) {
    return wallet.effectiveMaskedCardNumber.replaceAll(' ', '  ');
  }

  static String _expiryLabel(Wallet wallet) {
    final expiry = wallet.cardExpiresAt ?? wallet.createdAt;
    final month = expiry.month.toString().padLeft(2, '0');
    final year = (expiry.year % 100).toString().padLeft(2, '0');
    return '$month/$year';
  }
}

class _EmptyCreditCardFace extends StatelessWidget {
  final _CreditCardPalette palette;

  const _EmptyCreditCardFace({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
            ),
          ),
        ),
        CustomPaint(
          painter: _CreditCardSurfacePainter(
            palette: palette,
            isSelected: false,
            tiltX: 0,
            tiltY: 0,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  LucideIcons.plus,
                  color: palette.inkPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr.addCard.toUpperCase(),
                style: AppTypography.bodySmall.copyWith(
                  color: palette.inkPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_creditCardRadius),
                border: Border.all(color: palette.border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardBrandBlock extends StatelessWidget {
  final _CreditCardPalette palette;
  final String tier;

  const _CardBrandBlock({required this.palette, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEROSENE',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: palette.inkPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$tier CARD',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: palette.inkSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _BalanceBlock extends StatelessWidget {
  final String label;
  final _CreditCardPalette palette;

  const _BalanceBlock({required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'BALANCE',
            style: AppTypography.caption.copyWith(
              color: palette.inkSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.bodySmall.copyWith(
                color: palette.inkPrimary,
                fontFamily: 'IBMPlexSansHebrew',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTextField extends StatelessWidget {
  final String label;
  final String value;
  final _CreditCardPalette palette;
  final bool alignEnd;

  const _CardTextField({
    required this.label,
    required this.value,
    required this.palette,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: palette.inkSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: alignEnd ? 58 : double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.bodySmall.copyWith(
                color: palette.inkPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityHashButton extends StatelessWidget {
  final String hash;
  final _CreditCardPalette palette;

  const _SecurityHashButton({required this.hash, required this.palette});

  void _copyHash(BuildContext context) {
    Clipboard.setData(ClipboardData(text: hash));
    HapticFeedback.selectionClick();
    AppNotice.showSuccess(
      context,
      title: context.tr.walletCardHashCopiedTitle,
      message: context.tr.walletCardHashCopiedMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => _copyHash(context),
        radius: 18,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: palette.isLight ? 0.18 : 0.08,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: palette.inkPrimary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            LucideIcons.copy,
            size: 13,
            color: palette.inkPrimary.withValues(alpha: 0.82),
          ),
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final _CreditCardPalette palette;

  const _CardChip({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 34,
      child: CustomPaint(painter: _CardChipPainter(palette: palette)),
    );
  }
}

class _NetworkMark extends StatelessWidget {
  final Color color;

  const _NetworkMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 2,
            child: _NetworkDisc(color: color.withValues(alpha: 0.38)),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: _NetworkDisc(color: color.withValues(alpha: 0.58)),
          ),
        ],
      ),
    );
  }
}

class _NetworkDisc extends StatelessWidget {
  final Color color;

  const _NetworkDisc({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CreditCardSurfacePainter extends CustomPainter {
  final _CreditCardPalette palette;
  final bool isSelected;
  final double tiltX;
  final double tiltY;

  const _CreditCardSurfacePainter({
    required this.palette,
    required this.isSelected,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightDx = size.width * (0.55 + (tiltY * 0.18).clamp(-0.16, 0.16));
    final highlightDy =
        size.height * (0.22 + (tiltX * 0.12).clamp(-0.10, 0.10));
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isSelected ? 0.18 : 0.10),
          Colors.white.withValues(alpha: 0.00),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(highlightDx, highlightDy),
          radius: size.width * 0.56,
        ),
      );
    canvas.drawRect(Offset.zero & size, highlightPaint);

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: palette.isLight ? 0.22 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
        const Radius.circular(_creditCardRadius - 4),
      ),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CreditCardSurfacePainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}

class _CardChipPainter extends CustomPainter {
  final _CreditCardPalette palette;

  const _CardChipPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.chipGradient,
      ).createShader(rect);
    final stroke = Paint()
      ..color = palette.inkPrimary.withValues(
        alpha: palette.isLight ? 0.18 : 0.24,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final line = Paint()
      ..color = Colors.black.withValues(alpha: palette.isLight ? 0.22 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    final x = rect.left;
    final y = rect.top;
    final w = rect.width;
    final h = rect.height;
    canvas.drawLine(
      Offset(x + w * 0.33, y + 3),
      Offset(x + w * 0.33, y + h - 3),
      line,
    );
    canvas.drawLine(
      Offset(x + w * 0.67, y + 3),
      Offset(x + w * 0.67, y + h - 3),
      line,
    );
    canvas.drawLine(
      Offset(x + 3, y + h * 0.32),
      Offset(x + w * 0.26, y + h * 0.32),
      line,
    );
    canvas.drawLine(
      Offset(x + 3, y + h * 0.68),
      Offset(x + w * 0.26, y + h * 0.68),
      line,
    );
    canvas.drawLine(
      Offset(x + w * 0.74, y + h * 0.32),
      Offset(x + w - 3, y + h * 0.32),
      line,
    );
    canvas.drawLine(
      Offset(x + w * 0.74, y + h * 0.68),
      Offset(x + w - 3, y + h * 0.68),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _CardChipPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

@immutable
class _CreditCardPalette {
  final List<Color> gradient;
  final List<Color> chipGradient;
  final Color border;
  final Color line;
  final Color inkPrimary;
  final Color inkSecondary;
  final bool isLight;

  const _CreditCardPalette({
    required this.gradient,
    required this.chipGradient,
    required this.border,
    required this.line,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.isLight,
  });

  static _CreditCardPalette resolve(WalletCardType? type, int colorIndex) {
    final resolvedType = type ??
        switch (colorIndex % 3) {
          0 => WalletCardType.bronze,
          1 => WalletCardType.white,
          _ => WalletCardType.black,
        };

    return switch (resolvedType) {
      WalletCardType.bronze => _blue,
      WalletCardType.white => _silver,
      WalletCardType.black => _black,
    };
  }

  static const _blue = _CreditCardPalette(
    gradient: [Color(0xFF191919), Color(0xFF0D0D0D), Color(0xFF161616)],
    chipGradient: [Color(0xFFE7E7E1), Color(0xFFA8A8A0), Color(0xFF686862)],
    border: Color(0xFF3A3A3A),
    line: Color(0xFFA0A09B),
    inkPrimary: Color(0xFFF1F1ED),
    inkSecondary: Color(0xFFA0A09B),
    isLight: false,
  );

  static const _silver = _CreditCardPalette(
    gradient: [Color(0xFFF1F1EC), Color(0xFFD2D2CC), Color(0xFF9A9A94)],
    chipGradient: [Color(0xFFF7F7F1), Color(0xFFC8C8C0), Color(0xFF85857E)],
    border: Color(0xFFF1F1EC),
    line: Color(0xFF555550),
    inkPrimary: Color(0xFF090909),
    inkSecondary: Color(0xFF555550),
    isLight: true,
  );

  static const _black = _CreditCardPalette(
    gradient: [Color(0xFF030303), Color(0xFF080808), Color(0xFF151515)],
    chipGradient: [Color(0xFFE2E2DC), Color(0xFF9A9A94), Color(0xFF5D5D58)],
    border: Color(0xFF2A2A2A),
    line: Color(0xFF6B6B66),
    inkPrimary: Color(0xFFF1F1ED),
    inkSecondary: Color(0xFFA0A09B),
    isLight: false,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CreditCardPalette &&
            runtimeType == other.runtimeType &&
            gradient == other.gradient &&
            chipGradient == other.chipGradient &&
            border == other.border &&
            line == other.line &&
            inkPrimary == other.inkPrimary &&
            inkSecondary == other.inkSecondary &&
            isLight == other.isLight;
  }

  @override
  int get hashCode => Object.hash(
        gradient,
        chipGradient,
        border,
        line,
        inkPrimary,
        inkSecondary,
        isLight,
      );
}
