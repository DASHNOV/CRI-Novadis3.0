import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Configuration des couleurs et styles pour les graphiques
class ChartConfig {
  // Palette de couleurs pour les barres
  static const List<Color> barColors = [
    Color(0xFF2563EB), // Bleu primary
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo accent
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Rose
    Color(0xFF84CC16), // Lime
  ];

  // Couleurs des lignes
  static const Color primaryLineColor = Color(0xFF2563EB);
  static const Color secondaryLineColor = Color(0xFF10B981);
  static const Color thresholdLineColor = Color(0xFFEF4444);

  // Gradient pour les zones sous les lignes
  static List<Color> get areaGradient => [
    primaryLineColor.withValues(alpha: 0.2),
    primaryLineColor.withValues(alpha: 0.0),
  ];

  // Couleur du radar
  static Color get radarFillColor => primaryLineColor.withValues(alpha: 0.2);
  static Color get radarBorderColor => primaryLineColor;

  // Couleurs de tendance
  static const Color trendUpColor = Color(0xFF10B981);
  static const Color trendDownColor = Color(0xFFEF4444);
  static const Color trendNeutralColor = Color(0xFF6B7280);

  // Dimensions
  static const double chartPadding = 16.0;
  static const double barWidth = 22.0;
  static const double lineWidth = 2.5;
  static const double dotRadius = 3.5;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Curve animationCurve = Curves.easeInOut;

  // Style des tooltips
  static BoxDecoration get tooltipDecoration => BoxDecoration(
    color: AppTheme.textPrimary,
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    boxShadow: AppTheme.shadowMd,
  );

  static TextStyle get tooltipTextStyle => const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Style des axes
  static TextStyle get axisLabelStyle => TextStyle(
    color: AppTheme.textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // Style du titre
  static TextStyle get chartTitleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static TextStyle get chartSubtitleStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppTheme.textTertiary,
  );

  // Grille
  static Color get gridLineColor => AppTheme.border.withValues(alpha: 0.5);

  // Couleurs des KPI cards
  static const Map<String, Color> kpiColors = {
    'interventions': Color(0xFF2563EB),
    'sites': Color(0xFF10B981),
    'duration': Color(0xFFF59E0B),
    'completion': Color(0xFF6366F1),
    'satisfaction': Color(0xFFFBBF24),
    'firstFix': Color(0xFF10B981),
    'escalation': Color(0xFFEF4444),
    'punctuality': Color(0xFF06B6D4),
  };

  // Obtenir une couleur de la palette
  static Color getBarColor(int index) {
    return barColors[index % barColors.length];
  }

  // Formater les valeurs des axes
  static String formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }

  // Formater le pourcentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Formater les heures
  static String formatHours(double hours) {
    final h = hours.toInt();
    final m = ((hours - h) * 60).round();
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
