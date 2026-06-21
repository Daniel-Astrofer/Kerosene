import 'package:flutter/widgets.dart';
import 'package:kerosene/design_system/animation/kerosene_animation_asset.dart';
import 'package:kerosene/design_system/animation/kerosene_animation_host.dart';
import 'package:kerosene/design_system/animation/kerosene_animation_policy.dart';

class KeroseneRive extends StatelessWidget {
  const KeroseneRive({
    super.key,
    required this.asset,
    this.animation,
    this.semanticLabel,
    this.width,
    this.height,
    this.stateMachine,
  });

  final KeroseneAnimationAsset asset;
  final Widget? animation;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final KeroseneRiveStateMachine? stateMachine;

  @override
  Widget build(BuildContext context) {
    return KeroseneAnimationHost(
      asset: asset,
      semanticLabel: semanticLabel,
      width: width,
      height: height,
      repeat: KeroseneAnimationPolicy.shouldRepeat(asset),
      child: animation,
    );
  }

  static bool assetTypeIsRive(KeroseneAnimationAsset asset) {
    return asset.path.endsWith('.riv');
  }
}
