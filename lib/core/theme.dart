import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Glassmorphism Blue Palette
  static const Color primaryBlue = Color(0xFF03A9F4); // Main Cyan Blue
  static const Color lightBlue = Color(0xFFE3F2FD); // Background Light Blue
  static const Color accentBlue = Color(0xFF81D4FA); // Soft Blue Gradient start
  static const Color glassWhite = Color(0xE6FFFFFF); // 90% White for glass effect
  static const Color glassBorder = Color(0x80FFFFFF); // 50% White border
  static const Color darkText = Color(0xFF1A1C1E); // Deep text color
  static const Color mediumText = Color(0xFF42474E); // Subtitle color

  // Compatibility members for older visuals
  static const Color lightSlate = Color(0xFFF0F7FF); 
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color darkBlue = Color(0xFF0288D1);
  static const Color mediumSlate = Color(0xFF475569);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color darkGray = Color(0xFF0F172A);
  
  // Newly identified missing members from errors
  static const Color error = Color(0xFFBA1A1A); // Standard Material Error Red
  static const Color success = Color(0xFF388E3C); // Standard Success Green
  static const Color lightGray = Color(0xFFF1F5F9); // Light Gray for borders/bg

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF0F7FF),
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: glassWhite,
      error: error,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
      displayMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: darkText),
      titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: darkText),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: darkText),
      iconTheme: const IconThemeData(color: darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.8),
        foregroundColor: darkText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1.5),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    textTheme: GoogleFonts.outfitTextTheme(),
  );
}
