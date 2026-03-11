import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryBlue = Color(0xFF1E5EE6);
  static const Color darkBlue = Color(0xFF0F172A);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  
  // Status colors
  static const Color success = Color(0xFF16C098);
  static const Color danger = Color(0xFFFF6A55);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        background: background,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
