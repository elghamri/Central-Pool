import 'package:flutter/material.dart';

/// Responsive Breakpoint thresholds.
class Breakpoints {
  Breakpoints._();

  static const double compactMax = 767.0;  // Mobile: < 768px
  static const double mediumMax = 1279.0;  // Tablet: 768px - 1279px
  static const double expandedMin = 1280.0;// Desktop: >= 1280px

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width <= compactMax;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > compactMax && width <= mediumMax;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= expandedMin;
}

/// Adaptive layout container that lazily builds the appropriate view.
class ResponsiveLayoutShell extends StatelessWidget {
  final WidgetBuilder mobileBuilder;
  final WidgetBuilder? tabletBuilder;
  final WidgetBuilder? desktopBuilder;

  const ResponsiveLayoutShell({
    super.key,
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.expandedMin && desktopBuilder != null) {
          return desktopBuilder!(context);
        } else if (constraints.maxWidth > Breakpoints.compactMax && tabletBuilder != null) {
          return tabletBuilder!(context);
        }
        return mobileBuilder(context);
      },
    );
  }
}
