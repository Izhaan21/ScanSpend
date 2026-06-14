import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF0F172A);
  static const Color secondaryColor = Color(0xFF0D9488);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color outlineColor = Color(0xFFE0E3E5);
  static const Color textColor = Color(0xFF191C1E);
  static const Color textVariantColor = Color(0xFF45464D);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: textColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          height: 56 / 48,
          letterSpacing: -0.02 * 48,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 40 / 32,
          letterSpacing: -0.01 * 32,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 32 / 24,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 28 / 18,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: textColor,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0.05 * 14,
          color: textVariantColor,
        ),
        bodySmall: GoogleFonts.inter( // Used for data-mono
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 24 / 16,
          color: textColor,
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
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF89F5E7),
        secondary: Color(0xFF0D9488),
        surface: Color(0xFF1A1D2E),
        error: Color(0xFFFF6B6B),
        onSurface: Colors.white,
        onPrimary: Color(0xFF0F172A),
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 48, fontWeight: FontWeight.w800,
          height: 56 / 48, color: Colors.white,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32, fontWeight: FontWeight.w700,
          height: 40 / 32, color: Colors.white,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24, fontWeight: FontWeight.w600,
          height: 32 / 24, color: Colors.white,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w400,
          height: 28 / 18, color: Colors.white,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w400,
          height: 24 / 16, color: Colors.white70,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w600,
          height: 20 / 14, letterSpacing: 0.7,
          color: Colors.white60,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500,
          height: 24 / 16, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2235),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          side: const BorderSide(color: Color(0xFF2D3250), width: 1),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF89F5E7),
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(
              fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF89F5E7),
          textStyle: GoogleFonts.manrope(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF89F5E7),
          side: const BorderSide(color: Color(0xFF89F5E7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
