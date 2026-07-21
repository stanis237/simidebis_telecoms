import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF5B21B6);
  static const Color lightPurple = Color(0xFFEDE9FE);
  static const Color activeGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color backgroundGray = Color(0xFFF3F4F6);
  static const Color textDark = Color(0xFF1F2937);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundGray,
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: warningOrange,
        error: alertRed,
        surface: backgroundGray,
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, color: textDark),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: textDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
