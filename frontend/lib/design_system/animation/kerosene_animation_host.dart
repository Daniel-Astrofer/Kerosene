import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/animation/kerosene_animation_asset.dart';
import 'package:kerosene/design_system/icons.dart';

class KeroseneAnimationHost extends StatelessWidget {
  const KeroseneAnimationHost({
    super.key,
    required this.asset,
    this.child,
    this.fallbackIcon,
    this.semanticLabel,
    this.width,
    this.height,
    this.repeat = false,
  });

  final KeroseneAnimationAsset asset;
  final Widget? child;
  final IconData? fallbackIcon;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = KeroseneMotion.reduceMotion(context);
    final content = reduceMotion || child == null
        ? _KeroseneAnimationFallback(icon: fallbackIcon ?? asset.fallbackIcon)
        : child!;

    return Semantics(
      label: semanticLabel ?? asset.semanticLabel,
      image: true,
      child:
          SizedBox(width: width, height: height, child: Center(child: content)),
    );
  }
}

class _KeroseneAnimationFallback extends StatelessWidget {
  const _KeroseneAnimationFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: KeroseneBrandTokens.textSecondary, size: 32);
  }
}

extension KeroseneAnimationAssetUi on KeroseneAnimationAsset {
  IconData get fallbackIcon {
    switch (this) {
      case KeroseneAnimationAsset.successCheck:
      case KeroseneAnimationAsset.paymentReceived:
        return KeroseneIcons.success;
      case KeroseneAnimationAsset.pendingConfirmation:
      case KeroseneAnimationAsset.bitcoinConfirmation:
      case KeroseneAnimationAsset.transactionStatus:
        return KeroseneIcons.pending;
      case KeroseneAnimationAsset.secureConnection:
      case KeroseneAnimationAsset.securityShield:
      case KeroseneAnimationAsset.passkeyAuth:
        return KeroseneIcons.security;
      case KeroseneAnimationAsset.networkReview:
      case KeroseneAnimationAsset.torConnection:
        return KeroseneIcons.network;
      case KeroseneAnimationAsset.nfcReceive:
        return KeroseneIcons.nfc;
      case KeroseneAnimationAsset.emptyWallet:
        return KeroseneIcons.wallet;
    }
  }

  String get semanticLabel {
    switch (this) {
      case KeroseneAnimationAsset.successCheck:
        return 'Operação concluída com segurança.';
      case KeroseneAnimationAsset.pendingConfirmation:
        return 'Operação em confirmação.';
      case KeroseneAnimationAsset.emptyWallet:
        return 'Carteira sem atividade disponível.';
      case KeroseneAnimationAsset.secureConnection:
        return 'Conexão protegida.';
      case KeroseneAnimationAsset.paymentReceived:
        return 'Pagamento recebido.';
      case KeroseneAnimationAsset.networkReview:
        return 'Rede em revisão.';
      case KeroseneAnimationAsset.passkeyAuth:
        return 'Confirmação por passkey.';
      case KeroseneAnimationAsset.nfcReceive:
        return 'Recebimento por NFC.';
      case KeroseneAnimationAsset.transactionStatus:
        return 'Estado da transação.';
      case KeroseneAnimationAsset.securityShield:
        return 'Proteção de segurança.';
      case KeroseneAnimationAsset.bitcoinConfirmation:
        return 'Confirmação Bitcoin.';
      case KeroseneAnimationAsset.torConnection:
        return 'Conexão Tor.';
    }
  }
}
