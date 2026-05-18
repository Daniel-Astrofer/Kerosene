import 'package:flutter/widgets.dart';

class KerosenePerformanceBoundary extends StatefulWidget {
  final Widget child;

  const KerosenePerformanceBoundary({super.key, required this.child});

  @override
  State<KerosenePerformanceBoundary> createState() =>
      _KerosenePerformanceBoundaryState();
}

class _KerosenePerformanceBoundaryState
    extends State<KerosenePerformanceBoundary> with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  bool get _tickersEnabled {
    return _lifecycleState == AppLifecycleState.resumed ||
        _lifecycleState == AppLifecycleState.inactive;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == _lifecycleState) {
      return;
    }
    setState(() {
      _lifecycleState = state;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TickerMode(
        enabled: _tickersEnabled,
        child: widget.child,
      ),
    );
  }
}
