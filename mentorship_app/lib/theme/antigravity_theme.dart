import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AntigravityTheme {
  // Brand colors
  static const Color midnightBlue = Color(0xFF0F172A);
  static const Color pureBlack = Color(0xFF000000);
  
  // Neon/Glowing accents
  static const Color electricPurple = Color(0xFF8B5CF6);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color softRed = Color(0xFFEF4444);
  
  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Soft gray
  
  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricPurple, softBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [midnightBlue, pureBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      primaryColor: electricPurple,
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricPurple,
        brightness: Brightness.dark,
        background: pureBlack,
        surface: midnightBlue.withOpacity(0.5), // For glassmorphic bases
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontSize: 48,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: electricPurple.withOpacity(0.5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}
