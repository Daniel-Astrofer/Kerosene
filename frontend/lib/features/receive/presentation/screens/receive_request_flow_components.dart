// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';

const _receiveBackground = AppColors.hexFF050505;
const _receiveSurface = AppColors.hexFF121212;
const _receiveSurfaceLowest = AppColors.hexFF0E0E0E;
const _receiveSurfaceHigh = AppColors.hexFF2A2A2A;
const _receiveWarning = AppColors.hexFFF59E0B;
const _receiveSuccess = AppColors.hexFF4ADE80;
const _receiveSurfaceLow = AppColors.hexFF1C1B1B;
const _receiveBorder = AppColors.hexFF2A2A2A;
const _receiveText = AppColors.hexFFFFFFFF;
const _receiveMuted = AppColors.hexFFA3A3A3;
const _receiveBody = AppColors.hexFFC4C7C8;

class ReceiveContextHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const ReceiveContextHeader({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(icon, size: 20),
                color: _receiveText,
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  foregroundColor: _receiveText,
                ),
              ),
            ),
            Text(
              title.toUpperCase(),
              style: AppTypography.inter(
                color: _receiveMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 1.2,
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiveShellHeader extends StatelessWidget {
  const ReceiveShellHeader();

  @override
  Widget build(BuildContext context) {
    const brandLabel = 'KEROSENE';
    const avatarLabel = 'K';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _receiveBackground,
        border: Border(bottom: BorderSide(color: _receiveBorder)),
      ),
      child: Row(
        children: [
          const Icon(KeroseneIcons.menu, color: _receiveText, size: 22),
          const Spacer(),
          Text(
            brandLabel,
            style: AppTypography.newsreader(
              color: _receiveText,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _receiveSurfaceHigh,
              border: Border.all(color: _receiveBorder),
            ),
            child: Center(
              child: Text(
                avatarLabel,
                style: AppTypography.inter(
                  color: _receiveText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VaultCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const VaultCard({
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _receiveBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.hexFF1A1A1A, _receiveSurface],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ReceiveQrFrame extends StatelessWidget {
  final Widget child;

  const ReceiveQrFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _receiveBorder),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.hexFF1A1A1A, _receiveSurface],
            ),
          ),
          child: Stack(
            children: [
              const CornerAccent(alignment: Alignment.topLeft),
              const CornerAccent(alignment: Alignment.topRight),
              const CornerAccent(alignment: Alignment.bottomLeft),
              const CornerAccent(alignment: Alignment.bottomRight),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class CornerAccent extends StatelessWidget {
  final Alignment alignment;

  const CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: _receiveText.withValues(alpha: 0.20))
                : BorderSide.none,
            bottom: isTop
                ? BorderSide.none
                : BorderSide(color: _receiveText.withValues(alpha: 0.20)),
            left: isLeft
                ? BorderSide(color: _receiveText.withValues(alpha: 0.20))
                : BorderSide.none,
            right: isLeft
                ? BorderSide.none
                : BorderSide(color: _receiveText.withValues(alpha: 0.20)),
          ),
        ),
      ),
    );
  }
}

class ReceiveActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const ReceiveActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.black : _receiveText;
    return SizedBox(
      height: 56,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: primary ? _receiveText : _receiveSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: primary ? _receiveText : _receiveBorder,
            ),
          ),
          textStyle: AppTypography.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class ReceiveDetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const ReceiveDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        (monospace ? AppTypography.ibmPlexMono() : AppTypography.inter())
            .copyWith(
      color: _receiveText,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _receiveMuted, size: 17),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.inter(
              color: _receiveMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _receiveSurfaceLow,
        border: Border.all(color: _receiveBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.inter(
              color: AppColors.hexFFE5E2E1,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.inter(
              color: _receiveMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (monospace
                      ? AppTypography.ibmPlexMono()
                      : AppTypography.inter())
                  .copyWith(
                color: _receiveText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiveDivider extends StatelessWidget {
  const ReceiveDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: _receiveBorder.withValues(alpha: 0.50),
      height: 1,
      thickness: 1,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTypography.inter(
        color: _receiveMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.2,
      ),
    );
  }
}

class InlineNotice extends StatelessWidget {
  final String message;

  const InlineNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _receiveWarning.withValues(alpha: 0.08),
        border: Border.all(color: _receiveWarning.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(KeroseneIcons.warning, color: _receiveWarning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                color: _receiveBody,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String shortenReceiveAddress(String value, {int head = 6, int tail = 4}) {
  final trimmed = value.trim();
  if (trimmed.length <= head + tail + 3) return trimmed;
  if (tail <= 0) return '${trimmed.substring(0, head)}...';
  return '${trimmed.substring(0, head)}...${trimmed.substring(trimmed.length - tail)}';
}

String formatReceiveDateTime(DateTime value) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month ${local.year}, $hour:$minute';
}

class ReceiveNetworkStatusRow extends StatelessWidget {
  final bool onChainWallet;
  final bool identified;
  final int currentConfirmations;
  final int requiredConfirmations;

  const ReceiveNetworkStatusRow({
    required this.onChainWallet,
    required this.identified,
    required this.currentConfirmations,
    required this.requiredConfirmations,
  });

  @override
  Widget build(BuildContext context) {
    final waitingLabel = onChainWallet
        ? 'Aguardando confirmações ($currentConfirmations/$requiredConfirmations)'
        : identified
            ? 'Confirmado'
            : 'Aguardando confirmação';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.hexFF0A0A0A,
        border: Border.all(color: AppColors.hexFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _receiveWarning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _receiveWarning.withValues(alpha: 0.60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              onChainWallet ? 'Status da Rede' : 'Status Kerosene',
              style: AppTypography.inter(
                color: _receiveText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          Flexible(
            child: Text(
              waitingLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.inter(
                color: _receiveMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiveSuccessGraphic extends StatelessWidget {
  final Animation<double> animation;

  const ReceiveSuccessGraphic({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = animation.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.88 + pulse * 0.28,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _receiveSuccess.withValues(
                      alpha: 0.12 * (1 - pulse),
                    ),
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _receiveSurfaceLowest,
                  border: Border.all(color: _receiveBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _receiveSuccess.withValues(alpha: 0.10),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Icon(
                  KeroseneIcons.success,
                  color: _receiveSuccess,
                  size: 48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReceiveLoadingOverlay extends StatelessWidget {
  const ReceiveLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    const preparingLabel = 'Preparando recebimento';
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _receiveSurface,
              border: Border.all(color: _receiveBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _receiveText,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  preparingLabel,
                  style: AppTypography.inter(
                    color: _receiveText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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

class ReceiveAddressBlock extends StatelessWidget {
  final bool onChainWallet;
  final String addressValue;

  const ReceiveAddressBlock({
    required this.onChainWallet,
    required this.addressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(onChainWallet ? 'ENDEREÇO DA REDE' : 'DESTINO'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _receiveSurfaceLow,
              border: Border.all(color: _receiveBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              addressValue,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.ibmPlexMono(
                color: _receiveText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
