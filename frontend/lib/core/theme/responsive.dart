import 'package:flutter/material.dart';

/// Utilitaire responsive avec breakpoints modernes
class Responsive {
  // Breakpoints
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile &&
      MediaQuery.sizeOf(context).width < tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet &&
      MediaQuery.sizeOf(context).width < desktop;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// True si >= tablet (pour sidebar, etc.)
  static bool isDesktopOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// True si entre mobile et tablet (sidebar collapsed)
  static bool isTabletOnly(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile &&
      MediaQuery.sizeOf(context).width < tablet;

  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (width >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    if (width >= mobile) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.all(16);
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 48;
    if (width >= tablet) return 32;
    if (width >= mobile) return 24;
    return 16;
  }

  /// Nombre de colonnes pour les grilles
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 12;
    if (width >= tablet) return 8;
    return 4;
  }

  /// Nombre de colonnes KPI
  static int kpiColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return 4;
    if (width >= mobile) return 2;
    return 1;
  }

  /// Cross axis count pour les grilles de cartes
  static int cardGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 3;
    if (width >= tablet) return 2;
    if (width >= mobile) return 2;
    return 1;
  }
}
