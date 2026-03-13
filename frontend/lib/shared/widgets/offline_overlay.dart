import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_status_provider.dart';
import 'v_mask_painter.dart';

class OfflineOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const OfflineOverlay({super.key, required this.child});

  @override
  ConsumerState<OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends ConsumerState<OfflineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Slightly faster for loading feel
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );

    // Start looping animation immediately if it will be used
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider);

    // We keep the controller repeating, the AnimatedOpacity handles visibility

    return RepaintBoundary(
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            ignoring: isOnline,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isOnline ? 0.0 : 1.0,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(networkStatusProvider.notifier)
                        .checkConnection();
                  },
                  color: Colors.redAccent,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withValues(
                        alpha: 0.8,
                      ), // Dark background
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: VMaskPainter(
                                      progress: _animation.value,
                                      color: Colors
                                          .redAccent, // V for Vendetta red
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "SEM CONEXÃO",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              fontFamily: 'monospace',
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Aguardando restabelecimento do sistema...",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          const Text(
                            "Arraste para atualizar",
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
