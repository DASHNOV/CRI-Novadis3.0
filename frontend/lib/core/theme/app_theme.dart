import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Novadis CRI 2.0
/// Palette inspirée du logo Novadis (noir, blanc, bleu clair)
/// Supporte le mode clair et sombre avec transition animée.
///
/// Les couleurs dynamiques interpolent entre light/dark via [themeT]
/// (0.0 = clair, 1.0 = sombre) pour une transition fluide.
class AppTheme {
  /// Coefficient d'interpolation light↔dark (0.0 = light, 1.0 = dark).
  /// Mis à jour frame par frame par [NovadisApp] pendant la transition.
  static double themeT = 0.0;

  static bool get _isDark => themeT > 0.5;

  // Helper pour interpoler entre deux couleurs
  static Color _lerp(Color light, Color dark) =>
      Color.lerp(light, dark, themeT)!;

  // ─── Light palette constants ───
  static const Color _lightBackground = Color(0xFFF5F6F8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFEEF1F5);
  static const Color _lightBorder = Color(0xFFDDE1E8);
  static const Color _lightBorderLight = Color(0xFFEEF1F5);
  static const Color _lightTextPrimary = Color(0xFF0A0A0A);
  static const Color _lightTextSecondary = Color(0xFF4A5568);
  static const Color _lightTextTertiary = Color(0xFF8E99A8);
  static const Color _lightPrimaryLight = Color(0xFF6BA3D6);
  static const Color _lightSuccessLight = Color(0xFFD1FAE5);
  static const Color _lightWarningLight = Color(0xFFFEF3C7);
  static const Color _lightErrorLight = Color(0xFFFEE2E2);
  static const Color _lightInfoLight = Color(0xFFD6E8F8);

  // ─── Dark palette constants ───
  static const Color _darkBackground = Color(0xFF1A1D23);
  static const Color _darkSurface = Color(0xFF22262E);
  static const Color _darkSurfaceVariant = Color(0xFF2A2F38);
  static const Color _darkBorder = Color(0xFF3D4350);
  static const Color _darkBorderLight = Color(0xFF333842);
  static const Color _darkTextPrimary = Color(0xFFF0F1F4);
  static const Color _darkTextSecondary = Color(0xFFB0B7C8);
  static const Color _darkTextTertiary = Color(0xFF828AA0);
  static const Color _darkPrimaryLight = Color(0xFFB0D4F1);
  static const Color _darkSuccessLight = Color(0xFF0D3B2E);
  static const Color _darkWarningLight = Color(0xFF5C3A10);
  static const Color _darkErrorLight = Color(0xFF5C1A1A);
  static const Color _darkInfoLight = Color(0xFF1E3D5C);

  // ─── Couleurs principales Novadis ───
  static const Color primary = Color(0xFF1A1A1A);         // Noir Novadis (fonds de boutons)
  /// Couleur adaptative pour textes/icones sur fond coloré.
  /// Noir en light, blanc cassé en dark – à utiliser au lieu de `primary`
  /// quand le but est d'être *lisible*, pas de servir de fond de bouton.
  static Color get primaryContent => _lerp(const Color(0xFF1A1A1A), const Color(0xFFF0F1F4));
  static const Color primaryBlue = Color(0xFF8BB8E8);     // Bleu clair du logo (point du 'i')
  static Color get primaryLight => _lerp(_lightPrimaryLight, _darkPrimaryLight);
  static const Color primaryDark = Color(0xFF050505);
  static const Color accent = Color(0xFF8BB8E8);          // Bleu accent Novadis

  // ─── Surfaces & Backgrounds ───
  static Color get background => _lerp(_lightBackground, _darkBackground);
  static Color get surface => _lerp(_lightSurface, _darkSurface);
  static Color get surfaceVariant =>
      _lerp(_lightSurfaceVariant, _darkSurfaceVariant);
  static Color get border => _lerp(_lightBorder, _darkBorder);
  static Color get borderLight => _lerp(_lightBorderLight, _darkBorderLight);

  // ─── Texte ───
  static Color get textPrimary => _lerp(_lightTextPrimary, _darkTextPrimary);
  static Color get textSecondary =>
      _lerp(_lightTextSecondary, _darkTextSecondary);
  static Color get textTertiary => _lerp(_lightTextTertiary, _darkTextTertiary);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Sémantique ───
  static const Color success = Color(0xFF10B981);
  static Color get successLight => _lerp(_lightSuccessLight, _darkSuccessLight);
  static const Color warning = Color(0xFFF59E0B);
  static Color get warningLight => _lerp(_lightWarningLight, _darkWarningLight);
  static const Color error = Color(0xFFEF4444);
  static Color get errorLight => _lerp(_lightErrorLight, _darkErrorLight);
  static const Color info = Color(0xFF8BB8E8);
  static Color get infoLight => _lerp(_lightInfoLight, _darkInfoLight);

  // ─── Anciennes couleurs (backward compat) ───
  static const Color darkBlue = Color(0xFF1A3550);
  static Color get lightBlue => primaryLight;
  static Color get lightGray => surfaceVariant;
  static const Color alertRed = error;
  static Color get white => _lerp(const Color(0xFFFFFFFF), _darkSurface);
  static Color get black => textPrimary;

  // ─── Spacing System (base 4px) ───
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // ─── Border Radius ───
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ─── Shadows ───
  static List<BoxShadow> get shadowSm => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];

  static List<BoxShadow> get shadowMd => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  static List<BoxShadow> get shadowLg => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];

  // ─── Animation Durations ───
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  /// Durée de la transition de thème
  static const Duration themeTransitionDuration = Duration(milliseconds: 400);

  // ─────────────────────────────────────────────────
  //  THEME DATA BUILDERS
  // ─────────────────────────────────────────────────

  static ThemeData _buildTheme({
    required Brightness themeBrightness,
    required Color bg,
    required Color surf,
    required Color surfVar,
    required Color brd,
    required Color txtP,
    required Color txtS,
    required Color txtT,
  }) {
    final isDark = themeBrightness == Brightness.dark;
    const accentColor = accent;

    final textTheme = GoogleFonts.interTextTheme(
      isDark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: themeBrightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        primary: isDark ? accentColor : primary,
        secondary: accentColor,
        tertiary: primaryDark,
        error: error,
        surface: surf,
        onSurface: txtP,
        brightness: themeBrightness,
      ),
      scaffoldBackgroundColor: bg,

      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: txtP, fontSize: 30, fontWeight: FontWeight.w700,
          letterSpacing: -0.5, height: 1.3,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: txtP, fontSize: 24, fontWeight: FontWeight.w600,
          letterSpacing: -0.3, height: 1.3,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: txtP, fontSize: 20, fontWeight: FontWeight.w600,
          letterSpacing: -0.2, height: 1.4,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: txtP, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: txtS, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: txtP, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: txtP, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: txtS, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: txtP, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          color: txtS, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          color: txtT, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surf,
        foregroundColor: txtP,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: txtP, fontSize: 18,
          fontWeight: FontWeight.w600, letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: txtS, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surf,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: brd.withValues(alpha: 0.5)),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? accentColor : primary,
          foregroundColor: isDark ? const Color(0xFF0A0A0A) : textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: txtP,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: brd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? accentColor : primary,
        foregroundColor: isDark ? const Color(0xFF0A0A0A) : textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: brd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: brd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: txtS, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: txtT, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: error, fontSize: 12),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfVar,
        selectedColor: accentColor.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: BorderSide(color: brd),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      dividerTheme: DividerThemeData(color: brd, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: txtP, fontSize: 18, fontWeight: FontWeight.w600,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surf,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? accentColor : primary,
        unselectedLabelColor: txtT,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: isDark ? accentColor : primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: isDark ? accentColor : primary),
        unselectedIconTheme: IconThemeData(color: txtT),
        indicatorColor: accentColor.withValues(alpha: 0.1),
        backgroundColor: surf,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF333842)
            : const Color(0xFF0A0A0A),
        contentTextStyle: GoogleFonts.inter(
          color: const Color(0xFFE8EAED), fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF333842)
              : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: GoogleFonts.inter(
          color: const Color(0xFFE8EAED), fontSize: 12, fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surf,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: brd.withValues(alpha: 0.5)),
        ),
        textStyle: GoogleFonts.inter(color: txtP, fontSize: 14),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(
        themeBrightness: Brightness.light,
        bg: _lightBackground,
        surf: _lightSurface,
        surfVar: _lightSurfaceVariant,
        brd: _lightBorder,
        txtP: _lightTextPrimary,
        txtS: _lightTextSecondary,
        txtT: _lightTextTertiary,
      );

  static ThemeData get darkTheme => _buildTheme(
        themeBrightness: Brightness.dark,
        bg: _darkBackground,
        surf: _darkSurface,
        surfVar: _darkSurfaceVariant,
        brd: _darkBorder,
        txtP: _darkTextPrimary,
        txtS: _darkTextSecondary,
        txtT: _darkTextTertiary,
      );
}
