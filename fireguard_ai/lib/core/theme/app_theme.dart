import 'package:flutter/material.dart';

class AppTheme {
  // Suraksha Kavach Palette (Bright & Aesthetic)
  static const Color primaryNavy = Color(0xFF003366); // Deep Navy (Professional)
  static const Color accentSaffron = Color(0xFFFF6D00); // Vivid Orange (Bright Pop)
  static const Color softBlue = Color(0xFFE3F2FD); // Light background accent
  static const Color statusGreen = Color(0xFF00C853); // Bright Success
  static const Color statusRed = Color(0xFFD50000); // Bright Alert
  static const Color surfaceLight = Color(0xFFFAFAFA); // Bright White-Grey

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryNavy,
      secondary: accentSaffron, 
      error: statusRed,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF212121),
      tertiary: softBlue,
    ),
    scaffoldBackgroundColor: surfaceLight,
    
    // Bright & Professional AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy, // Navy Text on White AppBar (Cleaner look)
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryNavy),
      titleTextStyle: TextStyle(
        color: primaryNavy,
        fontWeight: FontWeight.bold, 
        fontSize: 22,
        letterSpacing: 0.5,
        fontFamily: 'Roboto',
      ),
    ),

    // Aesthetic Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(
        color: primaryNavy, 
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500, // Softer placeholder
        fontSize: 14,
      ),
      prefixIconColor: accentSaffron,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentSaffron, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: statusRed),
      ),
    ),

    // Soft Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x1F000000), // Soft shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    // Vivid Buttons (Saffron)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentSaffron, 
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.0,
        ),
      ),
    ),

    // Outlined Buttons (Navy)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryNavy,
        side: const BorderSide(color: primaryNavy, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.0,
        ),
      ),
    ),
    
    fontFamily: 'Roboto',
  );

  // NOTE: Dark Theme disabled as per directive to "only use light colour"
  /* 
  static final ThemeData darkTheme = ... 
  */
}
