// ignore_for_file: use_key_in_widget_constructors, unused_element

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_tokens.dart';

class LandingAudienceItem {
  final String title;
  final String body;

  const LandingAudienceItem(this.title, this.body);
}

class LandingAudienceColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<LandingAudienceItem> items;
  final Widget visual;
  final IconData icon;

  const LandingAudienceColumn({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.visual,
    this.icon = KeroseneIcons.success,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: landingDisplayStyle(context, 48)),
        const SizedBox(height: 14),
        Text(subtitle, style: landingBodyStyle(18)),
        const SizedBox(height: 34),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: landingGold, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: landingCardTitleStyle(16)),
                      const SizedBox(height: 4),
                      Text(item.body, style: landingSmallStyle(landingMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        visual,
      ],
    );
  }
}

class LandingPhoneImagePanel extends StatelessWidget {
  const LandingPhoneImagePanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.hexFF191919, AppColors.hexFF050505],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.72,
              child: Image.asset(
                'assets/welcome_phone_mockup.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingApiAccessCard extends StatelessWidget {
  const LandingApiAccessCard();

  @override
  Widget build(BuildContext context) {
    return LandingGlassPanel(
      padding: const EdgeInsets.all(32),
      borderColor: landingGold.withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr.landingApiAccessTitle,
              style: landingMonoStyle(landingGold)),
          const SizedBox(height: 16),
          Text(
            context.tr.landingApiAccessBody,
            style: landingBodyStyle(16).copyWith(color: Colors.white),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.67,
              minHeight: 8,
              backgroundColor: AppColors.hexFF353534,
              valueColor: const AlwaysStoppedAnimation<Color>(landingGold),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingAudienceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;

  const LandingAudienceCard({
    required this.icon,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return LandingGlassPanel(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 38),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: landingCardTitleStyle(20)),
                const SizedBox(height: 12),
                ...bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(KeroseneIcons.check,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(bullet, style: landingBodyStyle(15))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LandingArchitectureRail extends StatelessWidget {
  final List<LandingCardData> items;

  const LandingArchitectureRail({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final columns = constraints.maxWidth < 560 ? 1 : 4;
        final width =
            compact ? 210.0 : (constraints.maxWidth - 3 * 18) / columns;
        final content = Wrap(
          spacing: 18,
          runSpacing: 18,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: LandingArchitectureCard(data: item),
                ),
              )
              .toList(),
        );

        if (compact && constraints.maxWidth >= 560) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }
        return content;
      },
    );
  }
}

class LandingArchitectureCard extends StatelessWidget {
  final LandingCardData data;

  const LandingArchitectureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return LandingGlassPanel(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      borderColor: data.highlighted ? landingGold : null,
      child: SizedBox(
        height: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon,
                color: data.highlighted ? landingGold : Colors.white, size: 32),
            const Spacer(),
            Text(data.title, style: landingCardTitleStyle(16)),
            const SizedBox(height: 8),
            Text(data.body,
                style: landingSmallStyle(landingMuted).copyWith(height: 1.32)),
          ],
        ),
      ),
    );
  }
}

class LandingGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const LandingGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: landingPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class LandingRoundIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;

  const LandingRoundIcon({
    required this.icon,
    this.active = false,
    this.size = 62,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: active ? 0.11 : 0.045),
        border: Border.all(
          color: active
              ? landingGold.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(icon,
          color: active ? landingGold : Colors.white, size: size * 0.44),
    );
  }
}

class LandingSquareIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const LandingSquareIcon({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: active ? landingGold : AppColors.hexFF353534,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Icon(icon, color: active ? AppColors.hexFF131313 : Colors.white),
    );
  }
}

class LandingButton extends StatefulWidget {
  final String label;
  final bool filled;
  final bool large;
  final VoidCallback onPressed;

  const LandingButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.large = false,
  });

  @override
  State<LandingButton> createState() => LandingButtonState();
}

class LandingButtonState extends State<LandingButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.filled ? landingGold : Colors.transparent;
    final foreground = widget.filled ? AppColors.hexFF6B4C00 : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: KeroseneMotion.fast,
        curve: KeroseneMotion.standard,
        scale: _hover && !_reduceMotion(context) ? 1.018 : 1,
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 40 : 34,
              vertical: widget.large ? 21 : 18,
            ),
            side: BorderSide(
              color: widget.filled
                  ? landingGold
                  : Colors.white.withValues(alpha: 0.18),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: widget.large ? 17 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class LandingNavTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const LandingNavTextButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}

class LandingCenteredTitle extends StatelessWidget {
  final String text;

  const LandingCenteredTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: landingSectionTitleStyle(context, 36),
    );
  }
}

class LandingSectionShell extends StatelessWidget {
  final Widget child;
  final double topPadding;
  final double bottomPadding;

  const LandingSectionShell({
    super.key,
    required this.child,
    this.topPadding = 54,
    this.bottomPadding = 28,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        topPadding,
        compact ? 20 : 48,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: landingContentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

class LandingCtaMapMark extends StatelessWidget {
  const LandingCtaMapMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const LandingCtaMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class LandingStatusDot extends StatelessWidget {
  final bool online;

  const LandingStatusDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? landingGreen : landingGold;
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: _reduceMotion(context) ? 0 : 12,
          ),
        ],
      ),
    );
  }
}

class LandingCheckPill extends StatelessWidget {
  final String label;
  final String status;

  const LandingCheckPill({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final ok = status.toUpperCase() == 'UP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: landingSurface,
        border: Border.all(
            color: ok ? landingGreen.withValues(alpha: 0.5) : landingGold),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr.landingStatusLine(label, status),
        style: landingSmallStyle(ok ? landingGreen : landingGold),
      ),
    );
  }
}

class LandingSkeletonBlock extends StatelessWidget {
  final double height;

  const LandingSkeletonBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.22, end: _reduceMotion(context) ? 0.22 : 0.72),
      duration: KeroseneMotion.calm,
      builder: (context, value, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(landingSurface, landingPanelSoft, value),
            border: Border.all(color: landingLine),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class LandingBackdropPainter extends CustomPainter {
  const LandingBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = landingInk);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.42, -0.78),
        radius: 0.88,
        colors: [
          AppColors.hexFF283849.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final leftGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.78, 0.02),
        radius: 0.7,
        colors: [
          AppColors.hexFF0D2A32.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, leftGlow);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var i = 0; i < 34; i++) {
      final y = size.height * (i / 34);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + math.sin(i) * 12), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LandingVaultPainter extends CustomPainter {
  const LandingVaultPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.hexFF050505);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.06, -0.08),
        radius: 0.78,
        colors: [
          landingGold.withValues(alpha: 0.26),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final center = Offset(size.width * 0.52, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.31;
    final metal = Paint()
      ..shader = RadialGradient(
        colors: const [
          AppColors.hexFF383838,
          AppColors.hexFF111111,
          AppColors.hexFF030303,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius, metal);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, radius * (0.48 + i * 0.18), stroke);
    }

    final goldStroke = Paint()
      ..color = landingGold.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.22;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.82;
      canvas.drawLine(start, end, goldStroke);
    }

    final handlePaint = Paint()
      ..color = AppColors.hexFF050505
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.18, handlePaint);
    canvas.drawCircle(center, radius * 0.1, Paint()..color = landingGold);

    final serverPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 0; x < 7; x++) {
      final left = size.width * (0.06 + x * 0.13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height * 0.08, 24, size.height * 0.76),
          const Radius.circular(6),
        ),
        serverPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LandingArchitectureConnectorPainter extends CustomPainter {
  const LandingArchitectureConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.06, 12)
      ..quadraticBezierTo(size.width * 0.18, 0, size.width * 0.30, 18)
      ..quadraticBezierTo(size.width * 0.50, 48, size.width * 0.72, 18)
      ..quadraticBezierTo(size.width * 0.88, -2, size.width * 0.95, 18);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LandingCtaMapPainter extends CustomPainter {
  const LandingCtaMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (var x = 0; x < 44; x++) {
      for (var y = 0; y < 22; y++) {
        if ((x + y) % 3 == 0 && x > y * 0.45 && x < 42 - y * 0.18) {
          canvas.drawCircle(
            Offset(size.width * (0.06 + x / 50), size.height * (0.18 + y / 34)),
            1.3,
            dotPaint,
          );
        }
      }
    }

    final markPaint = Paint()
      ..color = landingGold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width * 0.75;
    final cy = size.height * 0.52;
    final k = Path()
      ..moveTo(cx - 46, cy - 60)
      ..lineTo(cx - 46, cy + 58)
      ..moveTo(cx - 16, cy - 10)
      ..lineTo(cx + 58, cy - 68)
      ..moveTo(cx - 12, cy + 2)
      ..lineTo(cx + 64, cy + 64)
      ..moveTo(cx + 8, cy - 10)
      ..lineTo(cx + 38, cy + 36)
      ..moveTo(cx + 24, cy - 26)
      ..lineTo(cx + 74, cy + 12);
    canvas.drawPath(k, markPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LandingCardData {
  final IconData icon;
  final String title;
  final String body;
  final bool highlighted;

  const LandingCardData({
    required this.icon,
    required this.title,
    required this.body,
    this.highlighted = false,
  });
}

List<LandingCardData> landingHeroFeatureItems(BuildContext context) {
  return [
    LandingCardData(
      icon: KeroseneIcons.onchain,
      title: context.tr.landingHeroFeatureOnchainTitle,
      body: context.tr.landingHeroFeatureOnchainBody,
    ),
    LandingCardData(
      icon: KeroseneIcons.internalTransfer,
      title: context.tr.landingHeroFeatureInternalTitle,
      body: context.tr.landingHeroFeatureInternalBody,
    ),
    LandingCardData(
      icon: KeroseneIcons.security,
      title: context.tr.landingHeroFeatureSecurityTitle,
      body: context.tr.landingHeroFeatureSecurityBody,
    ),
  ];
}

List<LandingCardData> landingProductCards(BuildContext context) {
  return [
    LandingCardData(
      icon: KeroseneIcons.privacy,
      title: 'Privacidade Onion',
      body:
          'Total anonimato. Todas as conexões são roteadas nativamente via rede Tor, ocultando seu IP e localização geográfica de qualquer observador externo.',
    ),
    LandingCardData(
      icon: KeroseneIcons.lightning,
      title: 'Liquidez Lightning',
      body: landingLiquidityCardBodyText,
      highlighted: true,
    ),
    LandingCardData(
      icon: KeroseneIcons.security,
      title: 'Custódia Institucional',
      body:
          'Segurança com tecnologia MPC (Multi-Party Computation) e arquitetura segmentada para proteção contra ataques físicos e digitais.',
    ),
  ];
}

List<LandingCardData> landingArchitectureCards(BuildContext context) {
  return [
    LandingCardData(
      icon: KeroseneIcons.stack,
      title: 'Bitcoin Core',
      body: 'Validação total de nós em infraestrutura própria.',
    ),
    LandingCardData(
      icon: KeroseneIcons.globe,
      title: 'Rede Tor',
      body: 'Ofuscação de tráfego e anonimato de rede mandatórios.',
    ),
    LandingCardData(
      icon: KeroseneIcons.network,
      title: 'MPC Tech',
      body: 'Assinaturas distribuídas sem ponto único de falha.',
      highlighted: true,
    ),
    LandingCardData(
      icon: KeroseneIcons.activity,
      title: 'Auditoria Live',
      body: 'Prova de reservas criptográfica em tempo real.',
    ),
  ];
}

List<LandingCardData> landingSecurityCards(BuildContext context) {
  return [
    LandingCardData(
      icon: KeroseneIcons.passkey,
      title: context.tr.landingSecurityPasskeysTitle,
      body: context.tr.landingSecurityPasskeysBody,
    ),
    LandingCardData(
      icon: KeroseneIcons.security,
      title: context.tr.landingSecurityVaultMpcTitle,
      body: context.tr.landingSecurityVaultMpcBody,
    ),
    LandingCardData(
      icon: KeroseneIcons.privacy,
      title: context.tr.landingSecurityPrivacyTitle,
      body: context.tr.landingSecurityPrivacyBody,
    ),
    LandingCardData(
      icon: KeroseneIcons.document,
      title: context.tr.landingSecurityAuditTitle,
      body: context.tr.landingSecurityAuditBody,
    ),
  ];
}

TextStyle landingDisplayStyle(BuildContext context, double size) {
  final compact = MediaQuery.sizeOf(context).width < 760;
  return AppTypography.newsreader(
    fontSize: compact ? math.min(size, 52) : size,
    fontWeight: FontWeight.w600,
    height: 1.04,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle landingSectionTitleStyle(BuildContext context, double size) {
  final compact = MediaQuery.sizeOf(context).width < 760;
  return AppTypography.inter(
    fontSize: compact ? math.min(size, 34) : size,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: Colors.white,
  );
}

TextStyle landingEyebrowStyle() {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: landingGold,
  );
}

TextStyle landingMonoStyle(Color color) {
  return TextStyle(
    fontFamily: AppTypography.monoFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.35,
    letterSpacing: 0.6,
    color: color,
  );
}

TextStyle landingCardTitleStyle(double size) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.18,
    letterSpacing: 0,
    color: Colors.white,
  );
}

TextStyle landingBodyStyle(double size) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: landingMuted,
  );
}

TextStyle landingSmallStyle(Color color) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    height: 1.35,
    letterSpacing: 0,
    color: color,
  );
}

String landingStatusLabel(BuildContext context, Map<String, dynamic>? status) {
  final value = status?['status']?.toString().toUpperCase();
  if (value == 'UP') return context.tr.landingStatusOnline;
  if (value == 'DEGRADED') return context.tr.landingStatusDegraded;
  if (value == 'DOWN') return context.tr.landingStatusUnavailable;
  return context.tr.landingStatusChecking;
}

String landingShort(Object? value, String fallback) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return fallback;
  if (text.length <= 14) return text;
  if (text.startsWith('sha256:') && text.length > 21) {
    return '${text.substring(0, 14)}...${text.substring(text.length - 6)}';
  }
  return '${text.substring(0, 10)}...';
}

bool _reduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return media?.disableAnimations == true ||
      media?.accessibleNavigation == true;
}
