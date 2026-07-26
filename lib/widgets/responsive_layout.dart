import 'package:flutter/material.dart';

/// Responsive breakpoints used across the app.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 900;
  static const double wide = 1200;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Horizontal padding that grows with screen width.
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= wide) return w * 0.15;
    if (w >= desktop) return w * 0.10;
    if (w >= tablet) return w * 0.06;
    return 24;
  }

  /// Content max-width for form / auth screens.
  static double formMaxWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return 560;
    if (w >= tablet) return 480;
    return double.infinity;
  }

  /// Grid crossAxisCount based on available width.
  static int gridColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 720) return 3;
    return 2;
  }
}
