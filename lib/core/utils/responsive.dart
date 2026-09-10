import 'package:flutter/widgets.dart';
import 'package:invoice_pro/core/constants/breakpoints.dart';

class Responsive {
  Responsive._();

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isMobile(BuildContext context) => sizeOf(context).width < Breakpoints.compact;

  static bool isTablet(BuildContext context) {
    final width = sizeOf(context).width;
    return width >= Breakpoints.compact && width < Breakpoints.expanded;
  }

  static bool isDesktop(BuildContext context) => sizeOf(context).width >= Breakpoints.expanded;

  static bool useRail(BuildContext context) => sizeOf(context).width >= Breakpoints.compact;

  static bool useExtendedRail(BuildContext context) => sizeOf(context).width >= Breakpoints.expanded;

  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1120;
    if (isTablet(context)) return 840;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (Responsive.useRail(context) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
