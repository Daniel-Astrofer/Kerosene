import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BitcoinRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const BitcoinRefreshIndicator({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: 108,
      refreshIndicatorExtent: 76,
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        final pullProgress =
            (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        final isRefreshing = refreshState == RefreshIndicatorMode.armed ||
            refreshState == RefreshIndicatorMode.refresh;
        final isVisible =
            pulledExtent > 0 || refreshState == RefreshIndicatorMode.done;

        return SizedBox(
          height: refreshIndicatorExtent,
          child: Center(
            child: AnimatedOpacity(
              opacity: isVisible ? Curves.easeOut.transform(pullProgress) : 0,
              duration: const Duration(milliseconds: 120),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: isRefreshing ? null : pullProgress,
                  strokeWidth: 2.4,
                  color: Colors.white.withValues(alpha: 0.84),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
