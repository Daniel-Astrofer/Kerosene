// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import 'home_screen_dependencies.dart';
import 'home_screen.dart';

class HomePageBackground extends StatelessWidget {
  const HomePageBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: homeBackgroundColor);
  }
}

class HomeEntryTransition extends StatefulWidget {
  final Widget child;

  const HomeEntryTransition({required this.child});

  @override
  State<HomeEntryTransition> createState() => HomeEntryTransitionState();
}

class HomeEntryTransitionState extends State<HomeEntryTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.slow,
    )..forward();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: KeroseneMotion.standard,
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

class HomeGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;

  const HomeGlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: backgroundColor,
        gradient: backgroundColor == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [homePanelTopColor, homePanelBottomColor],
              )
            : null,
        border: Border.all(color: homePanelBorderColor),
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

class HomeLoadingContent extends StatelessWidget {
  const HomeLoadingContent();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 0) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.58,
        child: const Center(child: TorLoadingDots()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HomeSkeletonBox(
              width: homeSize(40),
              height: homeSize(40),
              borderRadius: BorderRadius.circular(homeSize(999)),
            ),
            SizedBox(width: homeSize(12)),
            Expanded(
              child: HomeSkeletonBox(
                height: homeSize(22),
                borderRadius: BorderRadius.circular(homeSize(7)),
              ),
            ),
            SizedBox(width: homeSize(44)),
            HomeSkeletonBox(
              width: homeSize(24),
              height: homeSize(24),
              borderRadius: BorderRadius.circular(homeSize(999)),
            ),
            SizedBox(width: homeSize(16)),
            HomeSkeletonBox(
              width: homeSize(24),
              height: homeSize(24),
              borderRadius: BorderRadius.circular(homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: homeSize(18)),
        HomeGlassPanel(
          borderRadius: BorderRadius.circular(homeSize(18)),
          padding: EdgeInsets.all(homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSkeletonBox(
                width: homeSize(132),
                height: homeSize(14),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(18)),
              HomeSkeletonBox(
                width: homeSize(160),
                height: homeSize(16),
                borderRadius: BorderRadius.circular(homeSize(6)),
              ),
              SizedBox(height: homeSize(8)),
              HomeSkeletonBox(
                width: homeSize(220),
                height: homeSize(12),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(22)),
              HomeSkeletonBox(
                width: homeSize(238),
                height: homeSize(44),
                borderRadius: BorderRadius.circular(homeSize(10)),
              ),
              SizedBox(height: homeSize(10)),
              HomeSkeletonBox(
                width: homeSize(118),
                height: homeSize(14),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(8)),
              HomeSkeletonBox(
                width: homeSize(92),
                height: homeSize(13),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(24)),
              HomeSkeletonBox(
                width: homeSize(104),
                height: homeSize(34),
                borderRadius: BorderRadius.circular(homeSize(8)),
              ),
            ],
          ),
        ),
        SizedBox(height: homeSize(16)),
        Row(
          children: [
            Expanded(
              child: HomeSkeletonBox(
                height: homeSize(50),
                borderRadius: BorderRadius.circular(homeSize(12)),
              ),
            ),
            SizedBox(width: homeSize(12)),
            Expanded(
              child: HomeSkeletonBox(
                height: homeSize(50),
                borderRadius: BorderRadius.circular(homeSize(12)),
              ),
            ),
          ],
        ),
        SizedBox(height: homeSize(14)),
        const HomePaginationDots(count: 3, activeIndex: 0),
        SizedBox(height: homeSize(24)),
        HomeGlassPanel(
          borderRadius: BorderRadius.circular(homeSize(16)),
          padding: EdgeInsets.all(homeSize(20)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeSkeletonBox(
                      width: homeSize(152),
                      height: homeSize(18),
                      borderRadius: BorderRadius.circular(homeSize(6)),
                    ),
                    SizedBox(height: homeSize(10)),
                    HomeSkeletonBox(
                      width: homeSize(178),
                      height: homeSize(38),
                      borderRadius: BorderRadius.circular(homeSize(6)),
                    ),
                    SizedBox(height: homeSize(16)),
                    HomeSkeletonBox(
                      width: homeSize(86),
                      height: homeSize(34),
                      borderRadius: BorderRadius.circular(homeSize(8)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: homeSize(18)),
              HomeSkeletonBox(
                width: homeSize(92),
                height: homeSize(92),
                borderRadius: BorderRadius.circular(homeSize(18)),
              ),
            ],
          ),
        ),
        SizedBox(height: homeSize(28)),
        HomeGlassPanel(
          borderRadius: BorderRadius.circular(homeSize(16)),
          padding: EdgeInsets.all(homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSkeletonBox(
                width: homeSize(154),
                height: homeSize(16),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(20)),
              Row(
                children: [
                  HomeSkeletonBox(
                    width: homeSize(96),
                    height: homeSize(96),
                    borderRadius: BorderRadius.circular(homeSize(999)),
                  ),
                  SizedBox(width: homeSize(24)),
                  Expanded(
                    child: Column(
                      children: [
                        HomeSkeletonBox(
                          height: homeSize(16),
                          borderRadius: BorderRadius.circular(homeSize(5)),
                        ),
                        SizedBox(height: homeSize(14)),
                        HomeSkeletonBox(
                          height: homeSize(16),
                          borderRadius: BorderRadius.circular(homeSize(5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: homeSize(28)),
        HomeSkeletonBox(
          width: homeSize(112),
          height: homeSize(22),
          borderRadius: BorderRadius.circular(homeSize(7)),
        ),
        SizedBox(height: homeSize(16)),
        Row(
          children: [
            HomeSkeletonBox(
              width: homeSize(96),
              height: homeSize(30),
              borderRadius: BorderRadius.circular(homeSize(999)),
            ),
            SizedBox(width: homeSize(8)),
            HomeSkeletonBox(
              width: homeSize(112),
              height: homeSize(30),
              borderRadius: BorderRadius.circular(homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: homeSize(10)),
        const HomeLoadingTransactionRow(),
        const HomeLoadingTransactionRow(),
        const HomeLoadingTransactionRow(),
      ],
    );
  }
}

class HomeLoadingTransactionRow extends StatelessWidget {
  const HomeLoadingTransactionRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: homeSize(14)),
      child: Row(
        children: [
          HomeSkeletonBox(
            width: homeSize(40),
            height: homeSize(40),
            borderRadius: BorderRadius.circular(homeSize(999)),
          ),
          SizedBox(width: homeSize(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSkeletonBox(
                  width: homeSize(136),
                  height: homeSize(14),
                  borderRadius: BorderRadius.circular(homeSize(5)),
                ),
                SizedBox(height: homeSize(7)),
                HomeSkeletonBox(
                  width: homeSize(104),
                  height: homeSize(11),
                  borderRadius: BorderRadius.circular(homeSize(5)),
                ),
              ],
            ),
          ),
          SizedBox(width: homeSize(14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              HomeSkeletonBox(
                width: homeSize(90),
                height: homeSize(13),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
              SizedBox(height: homeSize(7)),
              HomeSkeletonBox(
                width: homeSize(70),
                height: homeSize(11),
                borderRadius: BorderRadius.circular(homeSize(5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const HomeSkeletonBox({
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

class HomeHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const HomeHeaderIconButton({
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
            radius: homeSize(24),
            child: SizedBox(
              width: homeSize(42),
              height: homeSize(42),
              child: Center(
                child: Icon(
                  icon,
                  size: homeSize(24),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: homeSize(5),
            top: homeSize(5),
            child: Container(
              width: homeSize(9),
              height: homeSize(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: homeAmberColor,
                border: Border.all(color: AppColors.hexFF06090B, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class HomeBalanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const HomeBalanceActionButton({
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
        constraints: BoxConstraints(minHeight: homeSize(48)),
        padding: EdgeInsets.symmetric(horizontal: homeSize(14)),
        decoration: BoxDecoration(
          color: primary ? Colors.white : homeCardColor,
          borderRadius: BorderRadius.circular(homeSize(12)),
          border: Border.all(
            color: primary ? Colors.white : homePanelBorderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: homeSize(18),
              color: primary ? Colors.black : Colors.white,
            ),
            SizedBox(width: homeSize(8)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary ? Colors.black : Colors.white,
                  fontSize: homeFontSize(14),
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

class HomePaginationDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const HomePaginationDots({
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) SizedBox(width: homeSize(6)),
          Container(
            width: homeSize(6),
            height: homeSize(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == activeIndex
                  ? Colors.white
                  : homeMutedTextColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class HomeSetupNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const HomeSetupNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: homeSize(16)),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: homeSize(2)),
            child: Icon(
              icon,
              size: homeSize(24),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(width: homeSize(14)),
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
                    fontSize: homeFontSize(15),
                    fontFamily: AppTypography.serifFontFamily,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: homeSize(5)),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: homeFontSize(12),
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: homeSize(12)),
                TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(KeroseneIcons.next, size: homeSize(15)),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, homeSize(34)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: homeFontSize(14),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: homeSize(12)),
          Padding(
            padding: EdgeInsets.only(top: homeSize(2)),
            child: Icon(
              KeroseneIcons.chevronRight,
              size: homeSize(18),
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
