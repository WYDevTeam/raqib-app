import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2E6FF2); // A strong, trustworthy blue
  static const Color secondary = Color(0xFF10C469); // Growth/Positive green
  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFF5B5B);
  static const Color warning = Color(0xFFF9C851);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  static const Color textDisabled = Color(0xFF9A9FA5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.normal),
        bodySmall: GoogleFonts.cairo(color: textSecondary, fontWeight: FontWeight.normal),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.cairo(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: GoogleFonts.cairo(color: textDisabled),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEFEFEF),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
