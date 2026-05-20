import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:teste/core/theme/app_spacing.dart';

enum KeroseneWindowClass { compact, medium, expanded, wide }

/// Shared responsive metrics for Kerosene screens.
///
/// This keeps breakpoint math and text scaling in one place so individual
/// screens do not invent slightly different behavior for every device.
class KeroseneResponsiveMetrics {
  final Size size;
  final EdgeInsets viewPadding;
  final KeroseneWindowClass windowClass;
  final double systemTextScale;
  final double effectiveTextScale;

  const KeroseneResponsiveMetrics({
    required this.size,
    required this.viewPadding,
    required this.windowClass,
    required this.systemTextScale,
    required this.effectiveTextScale,
  });

  factory KeroseneResponsiveMetrics.fromMediaQuery(
    MediaQueryData mediaQuery, {
    double requestedTextScale = 1.0,
  }) {
    final width = mediaQuery.size.width;
    final systemScale = mediaQuery.textScaler.scale(1.0);
    final rawScale = systemScale * requestedTextScale;
    final windowClass = _classForWidth(width);

    return KeroseneResponsiveMetrics(
      size: mediaQuery.size,
      viewPadding: mediaQuery.viewPadding,
      windowClass: windowClass,
      systemTextScale: systemScale,
      effectiveTextScale: _scaleForWidth(width, rawScale),
    );
  }

  bool get isCompact => windowClass == KeroseneWindowClass.compact;
  bool get isMedium => windowClass == KeroseneWindowClass.medium;
  bool get isExpanded => windowClass == KeroseneWindowClass.expanded;
  bool get isWide => windowClass == KeroseneWindowClass.wide;
  bool get isTinyPhone => size.width < 360;

  double get horizontalPadding {
    return switch (windowClass) {
      KeroseneWindowClass.compact =>
        size.width < 340 ? AppSpacing.sm : AppSpacing.md,
      KeroseneWindowClass.medium => AppSpacing.lg,
      KeroseneWindowClass.expanded => AppSpacing.xl,
      KeroseneWindowClass.wide => AppSpacing.xxl,
    };
  }

  double get maxReadableWidth {
    return switch (windowClass) {
      KeroseneWindowClass.compact => size.width,
      KeroseneWindowClass.medium => 640,
      KeroseneWindowClass.expanded => 920,
      KeroseneWindowClass.wide => 1120,
    };
  }

  double get mobileContentMaxWidth {
    return switch (windowClass) {
      KeroseneWindowClass.compact => size.width,
      KeroseneWindowClass.medium => 560,
      KeroseneWindowClass.expanded => 640,
      KeroseneWindowClass.wide => 720,
    };
  }

  double get sheetMaxWidth {
    return switch (windowClass) {
      KeroseneWindowClass.compact => size.width,
      KeroseneWindowClass.medium => 560,
      KeroseneWindowClass.expanded => 640,
      KeroseneWindowClass.wide => 720,
    };
  }

  double compactFontSize({
    required double compact,
    required double regular,
    double? tiny,
    double? medium,
    double? expanded,
    double? wide,
  }) {
    if (isTinyPhone && tiny != null) return tiny;
    return switch (windowClass) {
      KeroseneWindowClass.compact => compact,
      KeroseneWindowClass.medium => medium ?? regular,
      KeroseneWindowClass.expanded => expanded ?? regular,
      KeroseneWindowClass.wide => wide ?? expanded ?? regular,
    };
  }

  double clampWidth(double desiredWidth) {
    return math.max(
      0,
      math.min(desiredWidth, size.width - (horizontalPadding * 2)),
    );
  }

  static KeroseneWindowClass _classForWidth(double width) {
    if (width < 600) return KeroseneWindowClass.compact;
    if (width < 960) return KeroseneWindowClass.medium;
    if (width < 1280) return KeroseneWindowClass.expanded;
    return KeroseneWindowClass.wide;
  }

  static double _scaleForWidth(double width, double rawScale) {
    final maxScale = switch (width) {
      < 320 => 0.88,
      < 360 => 0.92,
      < 400 => 0.98,
      < 600 => 1.04,
      < 960 => 1.12,
      _ => 1.18,
    };
    return rawScale.clamp(0.82, maxScale).toDouble();
  }
}

class KeroseneResponsiveScope extends InheritedWidget {
  final KeroseneResponsiveMetrics metrics;

  const KeroseneResponsiveScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  static KeroseneResponsiveMetrics of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<KeroseneResponsiveScope>();
    if (scope != null) {
      return scope.metrics;
    }

    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return const KeroseneResponsiveMetrics(
        size: Size(390, 844),
        viewPadding: EdgeInsets.zero,
        windowClass: KeroseneWindowClass.compact,
        systemTextScale: 1,
        effectiveTextScale: 1,
      );
    }

    return KeroseneResponsiveMetrics.fromMediaQuery(mediaQuery);
  }

  @override
  bool updateShouldNotify(KeroseneResponsiveScope oldWidget) {
    return metrics != oldWidget.metrics;
  }
}

class KeroseneResponsiveBoundary extends StatelessWidget {
  final Widget child;
  final double requestedTextScale;

  const KeroseneResponsiveBoundary({
    super.key,
    required this.child,
    this.requestedTextScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return child;
    }

    final metrics = KeroseneResponsiveMetrics.fromMediaQuery(
      mediaQuery,
      requestedTextScale: requestedTextScale,
    );

    return KeroseneResponsiveScope(
      metrics: metrics,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(metrics.effectiveTextScale),
        ),
        child: child,
      ),
    );
  }
}

extension KeroseneResponsiveContext on BuildContext {
  KeroseneResponsiveMetrics get responsive => KeroseneResponsiveScope.of(this);
}
