import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

enum TransactionVisualFamily {
  onChain,
  lightning,
  internalTransfer,
  paymentLink,
  qrCode,
  nfc,
  deposit,
  swap,
  fee,
}

enum TransactionVisualDirection {
  incoming,
  outgoing,
  neutral,
}

class TransactionVisualSpec {
  static const Color _creditColor = Color(0xFFA8C7B1);
  static const Color _debitColor = Color(0xFFD59A9A);
  static const Color _neutralAmountColor = Color(0xFF8FA7C2);

  final TransactionVisualFamily family;
  final TransactionVisualDirection direction;
  final String label;
  final String prefix;
  final Color iconColor;
  final Color amountColor;

  const TransactionVisualSpec({
    required this.family,
    required this.direction,
    required this.label,
    required this.prefix,
    required this.iconColor,
    required this.amountColor,
  });

  bool get isIncoming => direction == TransactionVisualDirection.incoming;
  bool get isOutgoing => direction == TransactionVisualDirection.outgoing;

  static TransactionVisualSpec fromTransaction(Transaction transaction) {
    final isOutgoing = transaction.type == TransactionType.send ||
        transaction.type == TransactionType.withdrawal;

    switch (transaction.type) {
      case TransactionType.swap:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.swap,
          direction: TransactionVisualDirection.neutral,
          label: 'Swap',
          prefix: '',
          iconColor: Color(0xFF8FA7C2),
          amountColor: _neutralAmountColor,
        );
      case TransactionType.fee:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.fee,
          direction: TransactionVisualDirection.neutral,
          label: 'Taxa',
          prefix: '-',
          iconColor: Color(0xFF9AA3AE),
          amountColor: _debitColor,
        );
      case TransactionType.deposit:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.deposit,
          direction: TransactionVisualDirection.incoming,
          label: 'Depósito',
          prefix: '+',
          iconColor: Color(0xFF9EB3A4),
          amountColor: _creditColor,
        );
      case TransactionType.send:
      case TransactionType.receive:
      case TransactionType.withdrawal:
        break;
    }

    if (_looksLikeNfc(transaction)) {
      return _pair(
        family: TransactionVisualFamily.nfc,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento por NFC',
        outgoingLabel: 'Pagamento por NFC',
        iconColor: const Color(0xFF93A5B5),
      );
    }

    if (_looksLikeQr(transaction)) {
      return _pair(
        family: TransactionVisualFamily.qrCode,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento via QR',
        outgoingLabel: 'Pagamento via QR',
        iconColor: const Color(0xFF9AA6B2),
      );
    }

    if (_looksLikePaymentLink(transaction)) {
      return _pair(
        family: TransactionVisualFamily.paymentLink,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento por link',
        outgoingLabel: 'Pagamento por link',
        iconColor: const Color(0xFF9FA8B3),
      );
    }

    if (_looksLikeInternal(transaction)) {
      return _pair(
        family: TransactionVisualFamily.internalTransfer,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento interno',
        outgoingLabel: 'Envio interno',
        iconColor: const Color(0xFF8794A3),
      );
    }

    if (_looksLikeLightning(transaction)) {
      return _pair(
        family: TransactionVisualFamily.lightning,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento Lightning',
        outgoingLabel: 'Pagamento Lightning',
        iconColor: const Color(0xFFB89B64),
      );
    }

    return _pair(
      family: TransactionVisualFamily.onChain,
      isOutgoing: isOutgoing,
      incomingLabel: 'Recebimento on-chain',
      outgoingLabel: 'Envio on-chain',
      iconColor: const Color(0xFF9CA8B4),
    );
  }

  static TransactionVisualSpec _pair({
    required TransactionVisualFamily family,
    required bool isOutgoing,
    required String incomingLabel,
    required String outgoingLabel,
    required Color iconColor,
  }) {
    return TransactionVisualSpec(
      family: family,
      direction: isOutgoing
          ? TransactionVisualDirection.outgoing
          : TransactionVisualDirection.incoming,
      label: isOutgoing ? outgoingLabel : incomingLabel,
      prefix: isOutgoing ? '-' : '+',
      iconColor: iconColor,
      amountColor: isOutgoing ? _debitColor : _creditColor,
    );
  }

  static bool _looksLikePaymentLink(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return transaction.id.startsWith('pl_') ||
        description.contains('link de pagamento') ||
        description.contains('payment link') ||
        description.contains('pagamento por link') ||
        (description.contains('link') &&
            (description.contains('pag') || description.contains('payment')));
  }

  static bool _looksLikeQr(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('qr') ||
        description.contains('qr code') ||
        description.contains('qrcode');
  }

  static bool _looksLikeNfc(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('nfc') || description.contains('aproximacao');
  }

  static bool _looksLikeInternal(Transaction transaction) {
    if (transaction.isInternal) {
      return true;
    }

    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('transferencia interna') ||
        description.contains('transferência interna') ||
        description.contains('intra') ||
        description.contains('internal transfer');
  }

  static bool _looksLikeLightning(Transaction transaction) {
    if (transaction.isLightning) {
      return true;
    }

    final candidates = <String>[
      transaction.description ?? '',
      transaction.id,
      transaction.fromAddress,
      transaction.toAddress,
      transaction.blockchainTxid ?? '',
    ].map((value) => value.trim().toLowerCase());

    return candidates.any((value) {
      if (value.isEmpty) {
        return false;
      }

      return value.startsWith('lightning:') ||
          value.startsWith('lnbc') ||
          value.startsWith('lntb') ||
          value.startsWith('lnbcrt') ||
          value.startsWith('lnurl') ||
          value.contains('lightning') ||
          value.contains('bolt11') ||
          value.contains('@');
    });
  }
}

class TransactionTypeIconBadge extends StatelessWidget {
  final TransactionVisualSpec spec;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  const TransactionTypeIconBadge({
    super.key,
    required this.spec,
    this.size = 34,
    this.iconSize = 18,
    this.borderRadius = 8,
    this.backgroundColor = const Color(0xFF171B20),
    this.borderColor = const Color(0xFF262B31),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: CustomPaint(
          painter: _TransactionGlyphPainter(spec: spec),
        ),
      ),
    );
  }
}

class _TransactionGlyphPainter extends CustomPainter {
  final TransactionVisualSpec spec;

  const _TransactionGlyphPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = spec.iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.45, size.width * 0.1)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (spec.family) {
      case TransactionVisualFamily.onChain:
        _drawOnChain(canvas, size, paint);
        break;
      case TransactionVisualFamily.lightning:
        _drawLightning(canvas, size, paint);
        break;
      case TransactionVisualFamily.internalTransfer:
        _drawInternal(canvas, size, paint);
        break;
      case TransactionVisualFamily.paymentLink:
        _drawPaymentLink(canvas, size, paint);
        break;
      case TransactionVisualFamily.qrCode:
        _drawQr(canvas, size, paint);
        break;
      case TransactionVisualFamily.nfc:
        _drawNfc(canvas, size, paint);
        break;
      case TransactionVisualFamily.deposit:
        _drawDeposit(canvas, size, paint);
        break;
      case TransactionVisualFamily.swap:
        _drawSwap(canvas, size, paint);
        break;
      case TransactionVisualFamily.fee:
        _drawFee(canvas, size, paint);
        break;
    }

    if (_shouldDrawDirectionOverlay(spec.family, spec.direction)) {
      _drawDirectionOverlay(canvas, size, paint, spec.direction);
    }
  }

  @override
  bool shouldRepaint(covariant _TransactionGlyphPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }

  bool _shouldDrawDirectionOverlay(
    TransactionVisualFamily family,
    TransactionVisualDirection direction,
  ) {
    if (direction == TransactionVisualDirection.neutral) {
      return false;
    }

    return family == TransactionVisualFamily.onChain ||
        family == TransactionVisualFamily.lightning ||
        family == TransactionVisualFamily.paymentLink ||
        family == TransactionVisualFamily.qrCode ||
        family == TransactionVisualFamily.nfc;
  }

  void _drawOnChain(Canvas canvas, Size size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.24,
        size.width * 0.34,
        size.height * 0.34,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(rect, paint);

    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.16),
      Offset(size.width * 0.26, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.16),
      Offset(size.width * 0.44, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.32),
      Offset(size.width * 0.64, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.64, size.height * 0.50),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.58),
      Offset(size.width * 0.26, size.height * 0.66),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.58),
      Offset(size.width * 0.44, size.height * 0.66),
      paint,
    );
  }

  void _drawLightning(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.48, size.height * 0.10)
      ..lineTo(size.width * 0.28, size.height * 0.44)
      ..lineTo(size.width * 0.46, size.height * 0.44)
      ..lineTo(size.width * 0.38, size.height * 0.82)
      ..lineTo(size.width * 0.68, size.height * 0.38)
      ..lineTo(size.width * 0.50, size.height * 0.38);
    canvas.drawPath(path, paint);
  }

  void _drawInternal(Canvas canvas, Size size, Paint paint) {
    final top = Path()
      ..moveTo(size.width * 0.18, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.14,
        size.width * 0.66,
        size.height * 0.28,
      );
    canvas.drawPath(top, paint);
    _drawArrowHead(
      canvas,
      paint,
      tip: Offset(size.width * 0.72, size.height * 0.30),
      angle: -0.15,
      length: size.width * 0.10,
    );

    final bottom = Path()
      ..moveTo(size.width * 0.82, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.60,
        size.height * 0.86,
        size.width * 0.34,
        size.height * 0.72,
      );
    canvas.drawPath(bottom, paint);
    _drawArrowHead(
      canvas,
      paint,
      tip: Offset(size.width * 0.28, size.height * 0.70),
      angle: math.pi - 0.15,
      length: size.width * 0.10,
    );
  }

  void _drawPaymentLink(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.16)
      ..lineTo(size.width * 0.56, size.height * 0.16)
      ..lineTo(size.width * 0.70, size.height * 0.30)
      ..lineTo(size.width * 0.70, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.16),
      Offset(size.width * 0.56, size.height * 0.30),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.30),
      Offset(size.width * 0.70, size.height * 0.30),
      paint,
    );

    final leftLink = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.16,
        size.height * 0.10,
      ),
      Radius.circular(size.width * 0.06),
    );
    final rightLink = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.42,
        size.width * 0.16,
        size.height * 0.10,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(leftLink, paint);
    canvas.drawRRect(rightLink, paint);
  }

  void _drawQr(Canvas canvas, Size size, Paint paint) {
    final unit = size.width * 0.18;
    _drawQrFinder(
        canvas, paint, Offset(size.width * 0.12, size.height * 0.14), unit);
    _drawQrFinder(
        canvas, paint, Offset(size.width * 0.54, size.height * 0.14), unit);
    _drawQrFinder(
        canvas, paint, Offset(size.width * 0.12, size.height * 0.56), unit);

    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.50, size.height * 0.56, unit * 0.38, unit * 0.38),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.62, size.height * 0.66, unit * 0.24, unit * 0.24),
      paint,
    );
  }

  void _drawQrFinder(Canvas canvas, Paint paint, Offset origin, double size) {
    canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, size, size), paint);
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx + size * 0.28,
        origin.dy + size * 0.28,
        size * 0.44,
        size * 0.44,
      ),
      paint,
    );
  }

  void _drawNfc(Canvas canvas, Size size, Paint paint) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.44,
        size.width * 0.34,
        size.height * 0.22,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(card, paint);

    _drawWave(
      canvas,
      size,
      paint,
      radius: size.width * 0.14,
      center: Offset(size.width * 0.52, size.height * 0.54),
    );
    _drawWave(
      canvas,
      size,
      paint,
      radius: size.width * 0.22,
      center: Offset(size.width * 0.52, size.height * 0.54),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    Paint paint, {
    required double radius,
    required Offset center,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 3, math.pi * 2 / 3, false, paint);
  }

  void _drawDeposit(Canvas canvas, Size size, Paint paint) {
    final tray = Path()
      ..moveTo(size.width * 0.18, size.height * 0.60)
      ..lineTo(size.width * 0.30, size.height * 0.76)
      ..lineTo(size.width * 0.70, size.height * 0.76)
      ..lineTo(size.width * 0.82, size.height * 0.60);
    canvas.drawPath(tray, paint);

    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.18),
      Offset(size.width * 0.50, size.height * 0.54),
      paint,
    );
    _drawArrowHead(
      canvas,
      paint,
      tip: Offset(size.width * 0.50, size.height * 0.60),
      angle: math.pi / 2,
      length: size.width * 0.12,
    );
  }

  void _drawSwap(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.34),
      Offset(size.width * 0.70, size.height * 0.34),
      paint,
    );
    _drawArrowHead(
      canvas,
      paint,
      tip: Offset(size.width * 0.78, size.height * 0.34),
      angle: 0,
      length: size.width * 0.10,
    );

    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.66),
      Offset(size.width * 0.30, size.height * 0.66),
      paint,
    );
    _drawArrowHead(
      canvas,
      paint,
      tip: Offset(size.width * 0.22, size.height * 0.66),
      angle: math.pi,
      length: size.width * 0.10,
    );
  }

  void _drawFee(Canvas canvas, Size size, Paint paint) {
    final receipt = Path()
      ..moveTo(size.width * 0.22, size.height * 0.18)
      ..lineTo(size.width * 0.68, size.height * 0.18)
      ..lineTo(size.width * 0.68, size.height * 0.74)
      ..lineTo(size.width * 0.58, size.height * 0.68)
      ..lineTo(size.width * 0.48, size.height * 0.74)
      ..lineTo(size.width * 0.38, size.height * 0.68)
      ..lineTo(size.width * 0.28, size.height * 0.74)
      ..lineTo(size.width * 0.22, size.height * 0.68)
      ..close();
    canvas.drawPath(receipt, paint);

    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.34),
      Offset(size.width * 0.58, size.height * 0.34),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.48),
      Offset(size.width * 0.52, size.height * 0.48),
      paint,
    );
  }

  void _drawDirectionOverlay(
    Canvas canvas,
    Size size,
    Paint paint,
    TransactionVisualDirection direction,
  ) {
    final start = direction == TransactionVisualDirection.incoming
        ? Offset(size.width * 0.86, size.height * 0.24)
        : Offset(size.width * 0.58, size.height * 0.56);
    final end = direction == TransactionVisualDirection.incoming
        ? Offset(size.width * 0.58, size.height * 0.52)
        : Offset(size.width * 0.86, size.height * 0.24);

    canvas.drawLine(start, end, paint);
    _drawArrowHead(
      canvas,
      paint,
      tip: end,
      angle: math.atan2(end.dy - start.dy, end.dx - start.dx),
      length: size.width * 0.10,
    );
  }

  void _drawArrowHead(
    Canvas canvas,
    Paint paint, {
    required Offset tip,
    required double angle,
    required double length,
  }) {
    final left = Offset(
      tip.dx - length * math.cos(angle - math.pi / 6),
      tip.dy - length * math.sin(angle - math.pi / 6),
    );
    final right = Offset(
      tip.dx - length * math.cos(angle + math.pi / 6),
      tip.dy - length * math.sin(angle + math.pi / 6),
    );
    canvas.drawLine(tip, left, paint);
    canvas.drawLine(tip, right, paint);
  }
}
