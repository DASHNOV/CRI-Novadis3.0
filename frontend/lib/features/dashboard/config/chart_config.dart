import 'package:flutter/material.dart';

/// Configuration des couleurs et styles pour les graphiques
class ChartConfig {
  // Palette de couleurs pour les barres
  static const List<Color> barColors = [
    Color(0xFF3B82F6), // Bleu
    Color(0xFF10B981), // Vert
    Color(0xFFF59E0B), // Orange
    Color(0xFFEF4444), // Rouge
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Rose
    Color(0xFF84CC16), // Lime
  ];

  // Couleurs des lignes
  static const Color primaryLineColor = Color(0xFF3B82F6);
  static const Color secondaryLineColor = Color(0xFF10B981);
  static const Color thresholdLineColor = Color(0xFFEF4444);

  // Gradient pour les zones sous les lignes
  static List<Color> get areaGradient => [
    primaryLineColor.withOpacity(0.3),
    primaryLineColor.withOpacity(0.0),
  ];

  // Couleur du radar
  static Color get radarFillColor => primaryLineColor.withOpacity(0.3);
  static Color get radarBorderColor => primaryLineColor;

  // Couleurs de tendance
  static const Color trendUpColor = Color(0xFF10B981);
  static const Color trendDownColor = Color(0xFFEF4444);
  static const Color trendNeutralColor = Color(0xFF6B7280);

  // Dimensions
  static const double chartPadding = 16.0;
  static const double barWidth = 22.0;
  static const double lineWidth = 3.0;
  static const double dotRadius = 4.0;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Curve animationCurve = Curves.easeInOut;

  // Style des tooltips
  static BoxDecoration get tooltipDecoration => BoxDecoration(
    color: Colors.grey[800],
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static TextStyle get tooltipTextStyle => const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Style des axes
  static TextStyle get axisLabelStyle => TextStyle(
    color: Colors.grey[600],
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // Style du titre
  static TextStyle get chartTitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static TextStyle get chartSubtitleStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey[600],
  );

  // Grille
  static Color get gridLineColor => Colors.grey.withOpacity(0.2);

  // Couleurs des KPI cards
  static const Map<String, Color> kpiColors = {
    'interventions': Color(0xFF3B82F6),
    'sites': Color(0xFF10B981),
    'duration': Color(0xFFF59E0B),
    'completion': Color(0xFF8B5CF6),
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

