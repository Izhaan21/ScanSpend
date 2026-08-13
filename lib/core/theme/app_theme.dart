import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Clean Light Color Palette ─────────────────────────────────────────────
  // Primary     : Electric Blue    #2563EB
  // Secondary   : Turquoise Cyan   #06B6D4
  // Background  : Light Slate      #F8FAFC
  // Surface     : Pure White       #FFFFFF
  // Outline     : Border Slate     #E2E8F0
  // Text        : Deep Slate Navy  #0F172A
  // Muted Text  : Medium Slate     #64748B
  // ─────────────────────────────────────────────────────────────────────────

  static const Color primaryColor     = Color(0xFF2563EB); // Electric Blue
  static const Color secondaryColor   = Color(0xFF06B6D4); // Turquoise Cyan
  static const Color backgroundColor  = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color surfaceColor     = Color(0xFFFFFFFF); // Pure White Surface
  static const Color errorColor       = Color(0xFFDC2626); // Clean Red Error
  static const Color outlineColor     = Color(0xFFE2E8F0); // Light Border
  static const Color textColor        = Color(0xFF0F172A); // Deep Slate Text
  static const Color textVariantColor = Color(0xFF64748B); // Muted Slate Text

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusSm      = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd      = 12.0;
  static const double radiusLg      = 16.0;
  static const double radiusXl      = 24.0;

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:     primaryColor,
        secondary:   secondaryColor,
        surface:     surfaceColor,
        error:       errorColor,
        onSurface:   textColor,
        onPrimary:   Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 48, fontWeight: FontWeight.w800,
          height: 56 / 48, letterSpacing: -0.02 * 48,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32, fontWeight: FontWeight.w700,
          height: 40 / 32, letterSpacing: -0.01 * 32,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24, fontWeight: FontWeight.w600,
          height: 32 / 24, color: textColor,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w400,
          height: 28 / 18, color: textColor,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w400,
          height: 24 / 16, color: textColor,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w600,
          height: 20 / 14, letterSpacing: 0.05 * 14,
          color: textVariantColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500,
          height: 24 / 16, color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          side: const BorderSide(color: outlineColor, width: 1),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
    );
  }

  // Dark Theme alias returning light theme
  static ThemeData get darkTheme => lightTheme;
}
