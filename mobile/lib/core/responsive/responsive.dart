import 'package:flutter/material.dart';

/// Screen size breakpoints
enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < _mobileBreakpoint) return ScreenSize.mobile;
    if (width < _tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) => of(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) => of(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) => of(context) == ScreenSize.desktop;

  /// True for tablet or desktop (i.e. not a phone-sized screen)
  static bool isLarge(BuildContext context) => of(context) != ScreenSize.mobile;

  /// Product grid: columns and aspect ratio for current screen size
  static int gridColumns(BuildContext context) => isLarge(context) ? 4 : 2;
  static double gridAspectRatio(BuildContext context) => 0.68;

  /// Returns the appropriate grid delegate for product grids.
  static SliverGridDelegate gridDelegate(BuildContext context) {
    if (isLarge(context)) {
      return const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );
    }
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.68,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
  }

  /// Returns one of three values based on current screen size.
  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final size = of(context);
    if (size == ScreenSize.desktop) return desktop;
    if (size == ScreenSize.tablet) return tablet ?? desktop;
    return mobile;
  }
}

/// Widget that rebuilds its child whenever the screen size category changes.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, Responsive.of(context));
}

