import 'package:flutter/material.dart';

/// Utilitaire responsive avec breakpoints et helpers
class Responsive {
  static const double mobile = 600;
  static const double tablet = 800;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet &&
      MediaQuery.sizeOf(context).width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (width >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.all(16);
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 48;
    if (width >= tablet) return 32;
    return 16;
  }
}
