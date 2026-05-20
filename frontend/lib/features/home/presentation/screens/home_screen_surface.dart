part of 'home_screen.dart';

class _HomePageBackground extends StatelessWidget {
  const _HomePageBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _homeBackgroundColor);
  }
}

class _HomeEntryTransition extends StatefulWidget {
  final Widget child;

  const _HomeEntryTransition({required this.child});

  @override
  State<_HomeEntryTransition> createState() => _HomeEntryTransitionState();
}

class _HomeEntryTransitionState extends State<_HomeEntryTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curve;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          transformHitTests: false,
          child: widget.child,
        ),
      ),
    );
  }
}

class _HomeGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const _HomeGlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_homePanelTopColor, _homePanelBottomColor],
        ),
        border: Border.all(color: _homePanelBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: content,
    );

    return RepaintBoundary(child: clipped);
  }
}

class _HomeLoadingContent extends StatelessWidget {
  const _HomeLoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _HomeSkeletonBox(
              width: _homeSize(40),
              height: _homeSize(40),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(22),
                borderRadius: BorderRadius.circular(_homeSize(7)),
              ),
            ),
            SizedBox(width: _homeSize(44)),
            _HomeSkeletonBox(
              width: _homeSize(24),
              height: _homeSize(24),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(16)),
            _HomeSkeletonBox(
              width: _homeSize(24),
              height: _homeSize(24),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: _homeSize(18)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(18)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(132),
                height: _homeSize(14),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(18)),
              _HomeSkeletonBox(
                width: _homeSize(160),
                height: _homeSize(16),
                borderRadius: BorderRadius.circular(_homeSize(6)),
              ),
              SizedBox(height: _homeSize(8)),
              _HomeSkeletonBox(
                width: _homeSize(220),
                height: _homeSize(12),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(22)),
              _HomeSkeletonBox(
                width: _homeSize(238),
                height: _homeSize(44),
                borderRadius: BorderRadius.circular(_homeSize(10)),
              ),
              SizedBox(height: _homeSize(10)),
              _HomeSkeletonBox(
                width: _homeSize(118),
                height: _homeSize(14),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(8)),
              _HomeSkeletonBox(
                width: _homeSize(92),
                height: _homeSize(13),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(24)),
              _HomeSkeletonBox(
                width: _homeSize(104),
                height: _homeSize(34),
                borderRadius: BorderRadius.circular(_homeSize(8)),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(50),
                borderRadius: BorderRadius.circular(_homeSize(12)),
              ),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(50),
                borderRadius: BorderRadius.circular(_homeSize(12)),
              ),
            ),
          ],
        ),
        SizedBox(height: _homeSize(14)),
        const _HomePaginationDots(count: 3, activeIndex: 0),
        SizedBox(height: _homeSize(24)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(16)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeSkeletonBox(
                      width: _homeSize(152),
                      height: _homeSize(18),
                      borderRadius: BorderRadius.circular(_homeSize(6)),
                    ),
                    SizedBox(height: _homeSize(10)),
                    _HomeSkeletonBox(
                      width: _homeSize(178),
                      height: _homeSize(38),
                      borderRadius: BorderRadius.circular(_homeSize(6)),
                    ),
                    SizedBox(height: _homeSize(16)),
                    _HomeSkeletonBox(
                      width: _homeSize(86),
                      height: _homeSize(34),
                      borderRadius: BorderRadius.circular(_homeSize(8)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _homeSize(18)),
              _HomeSkeletonBox(
                width: _homeSize(92),
                height: _homeSize(92),
                borderRadius: BorderRadius.circular(_homeSize(18)),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(28)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(16)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(154),
                height: _homeSize(16),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(20)),
              Row(
                children: [
                  _HomeSkeletonBox(
                    width: _homeSize(96),
                    height: _homeSize(96),
                    borderRadius: BorderRadius.circular(_homeSize(999)),
                  ),
                  SizedBox(width: _homeSize(24)),
                  Expanded(
                    child: Column(
                      children: [
                        _HomeSkeletonBox(
                          height: _homeSize(16),
                          borderRadius: BorderRadius.circular(_homeSize(5)),
                        ),
                        SizedBox(height: _homeSize(14)),
                        _HomeSkeletonBox(
                          height: _homeSize(16),
                          borderRadius: BorderRadius.circular(_homeSize(5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(28)),
        _HomeSkeletonBox(
          width: _homeSize(112),
          height: _homeSize(22),
          borderRadius: BorderRadius.circular(_homeSize(7)),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            _HomeSkeletonBox(
              width: _homeSize(96),
              height: _homeSize(30),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(8)),
            _HomeSkeletonBox(
              width: _homeSize(112),
              height: _homeSize(30),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: _homeSize(10)),
        const _HomeLoadingTransactionRow(),
        const _HomeLoadingTransactionRow(),
        const _HomeLoadingTransactionRow(),
      ],
    );
  }
}

class _HomeLoadingTransactionRow extends StatelessWidget {
  const _HomeLoadingTransactionRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _homeSize(14)),
      child: Row(
        children: [
          _HomeSkeletonBox(
            width: _homeSize(40),
            height: _homeSize(40),
            borderRadius: BorderRadius.circular(_homeSize(999)),
          ),
          SizedBox(width: _homeSize(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeSkeletonBox(
                  width: _homeSize(136),
                  height: _homeSize(14),
                  borderRadius: BorderRadius.circular(_homeSize(5)),
                ),
                SizedBox(height: _homeSize(7)),
                _HomeSkeletonBox(
                  width: _homeSize(104),
                  height: _homeSize(11),
                  borderRadius: BorderRadius.circular(_homeSize(5)),
                ),
              ],
            ),
          ),
          SizedBox(width: _homeSize(14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(90),
                height: _homeSize(13),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(7)),
              _HomeSkeletonBox(
                width: _homeSize(70),
                height: _homeSize(11),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _HomeSkeletonBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final skeleton = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
      ),
    );

    if (KeroseneMotion.reduceMotion(context)) {
      return skeleton;
    }

    return skeleton
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1300.ms,
          color: Colors.white.withValues(alpha: 0.08),
        );
  }
}

class _HomeHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _HomeHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: onTap,
            radius: _homeSize(24),
            child: SizedBox(
              width: _homeSize(42),
              height: _homeSize(42),
              child: Center(
                child: Icon(
                  icon,
                  size: _homeSize(24),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: _homeSize(5),
            top: _homeSize(5),
            child: Container(
              width: _homeSize(9),
              height: _homeSize(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _homeAmberColor,
                border: Border.all(color: const Color(0xFF06090B), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeBalanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _HomeBalanceActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncingButtonWrapper(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: _homeSize(48)),
        padding: EdgeInsets.symmetric(horizontal: _homeSize(14)),
        decoration: BoxDecoration(
          color: primary ? Colors.white : _homeCardColor,
          borderRadius: BorderRadius.circular(_homeSize(12)),
          border: Border.all(
            color: primary ? Colors.white : _homePanelBorderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _homeSize(18),
              color: primary ? Colors.black : Colors.white,
            ),
            SizedBox(width: _homeSize(8)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary ? Colors.black : Colors.white,
                  fontSize: _homeFontSize(14),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePaginationDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _HomePaginationDots({
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) SizedBox(width: _homeSize(6)),
          Container(
            width: _homeSize(6),
            height: _homeSize(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == activeIndex
                  ? Colors.white
                  : _homeMutedTextColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeSetupNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _HomeSetupNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(18)),
      padding: EdgeInsets.all(_homeSize(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _homeSize(42),
            height: _homeSize(42),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_homeSize(12)),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              icon,
              size: _homeSize(24),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(width: _homeSize(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: _homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: _homeSize(5)),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: _homeFontSize(12),
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: _homeSize(12)),
                TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(LucideIcons.arrowRight, size: _homeSize(15)),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: _homeAmberColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, _homeSize(34)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: _homeFontSize(14),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0,
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
