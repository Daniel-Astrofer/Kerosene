import 'package:flutter/material.dart';

class CyberBackground extends StatelessWidget {
  final Widget child;
  final bool useScroll;
  final bool resizeToAvoidBottomInset;
  final List<Widget>? extraOverlays;
  final Color backgroundColor;

  const CyberBackground({
    super.key,
    required this.child,
    this.useScroll = true,
    this.resizeToAvoidBottomInset = true,
    this.extraOverlays,
    this.backgroundColor = const Color(0xFF050505),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          // Top-Right Blue Glow
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2962FF).withValues(alpha: 0.15),
                    const Color(0xFF2962FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-Left Purple Glow
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B61FF).withValues(alpha: 0.1),
                    const Color(0xFF7B61FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          if (extraOverlays != null) ...extraOverlays!,

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget content = child;

                if (useScroll) {
                  content = SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: child,
                        ),
                      ),
                    ),
                  );
                } else {
                  content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: child,
                    ),
                  );
                }

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }
}
