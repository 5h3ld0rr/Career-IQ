import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Glassmorphism Blue Palette
  static const Color primaryBlue = Color(0xFF03A9F4); // Main Cyan Blue
  static const Color lightBlue = Color(0xFFE3F2FD); // Background Light Blue
  static const Color accentBlue = Color(0xFF81D4FA); // Soft Blue Gradient start
  static const Color darkBlue = Color(0xFF0288D1);

  static const Color darkText = Color(
    0xFF1A1C1E,
  ); // Deep text color for light mode
  static const Color darkSurface = Color(0xFF0F172A); // Dark mode background
  static const Color glassWhite = Color(
    0xE6FFFFFF,
  ); // 90% White for glass effect
  static const Color glassBorder = Color(0x80FFFFFF); // 50% White border

  // Compatibility members
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF388E3C);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color mediumSlate = Color(0xFF475569);

  // Theme-aware helper methods
  static Color getScaffoldColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFF0F7FF)
        : darkSurface;
  }

  static Color getGlassColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.08);
  }

  static Color getGlassBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.12);
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF0F7FF),
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: Colors.white,
      onSurface: darkText,
      onSurfaceVariant: Colors.black54,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
          displayMedium: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleLarge: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      iconTheme: const IconThemeData(color: darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
    scaffoldBackgroundColor: darkSurface,
    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: const Color(0xFF1E293B),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
      ),
    ),
  );
}
